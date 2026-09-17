"""Descarga, inicializa y administra un MySQL 8.4 portable como proceso hijo.

Sin instalador, sin permisos de administrador, sin servicio de Windows.
Todo vive bajo %LOCALAPPDATA%\\PracticaSQL (ver app.config).
"""
from __future__ import annotations

import ctypes
import hashlib
import json
import shutil
import socket
import subprocess
import threading
import time
import urllib.request
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import pymysql

from app import config

CHUNK = 256 * 1024
CREATE_NO_WINDOW = 0x08000000 if config.ES_WINDOWS else 0
CREATE_NEW_PROCESS_GROUP = 0x00000200 if config.ES_WINDOWS else 0
_POPEN_FLAGS = {"creationflags": CREATE_NO_WINDOW | CREATE_NEW_PROCESS_GROUP} if config.ES_WINDOWS else {}


class MysqlBootstrapError(RuntimeError):
    pass


@dataclass
class EstadoServidor:
    corriendo: bool = False
    adoptado: bool = False
    puerto: int = config.MYSQL_PORT
    version: str = config.MYSQL_VERSION
    pid: Optional[int] = None
    mensaje: str = ""


class GestorMysql:
    """Administra el ciclo de vida completo del mysqld portable."""

    def __init__(self) -> None:
        self.proc: Optional[subprocess.Popen] = None
        self._log_buffer: list[str] = []
        self._log_lock = threading.Lock()
        self._progreso_descarga: dict = {"activo": False, "pct": 0, "mensaje": ""}
        self._keepalive_stop = threading.Event()

    # ------------------------------------------------------------------ #
    # Log en anillo
    # ------------------------------------------------------------------ #
    def _drenar(self, stream, prefijo: str) -> None:
        try:
            for linea in iter(stream.readline, b""):
                texto = linea.decode("utf-8", errors="replace").rstrip()
                with self._log_lock:
                    self._log_buffer.append(f"[{prefijo}] {texto}")
                    if len(self._log_buffer) > 500:
                        del self._log_buffer[: len(self._log_buffer) - 500]
        except Exception:
            pass

    def log_reciente(self, n: int = 200) -> list[str]:
        with self._log_lock:
            return list(self._log_buffer[-n:])

    def progreso_descarga(self) -> dict:
        return dict(self._progreso_descarga)

    # ------------------------------------------------------------------ #
    # Verificaciones previas
    # ------------------------------------------------------------------ #
    @staticmethod
    def _vcredist_presente() -> bool:
        system32 = Path(r"C:\Windows\System32")
        requeridos = ["vcruntime140.dll", "vcruntime140_1.dll", "msvcp140.dll"]
        return all((system32 / dll).exists() for dll in requeridos)

    def _asegurar_vcredist(self) -> None:
        if not self._vcredist_presente():
            raise MysqlBootstrapError(
                "Falta el Visual C++ Redistributable (vcruntime140.dll / msvcp140.dll). "
                "MySQL no puede arrancar sin él. Instalalo (requiere permisos de "
                "administrador, es el único paso de toda la app que los necesita) desde:\n"
                "https://aka.ms/vs/17/release/vc_redist.x64.exe\n"
                "Después volvé a abrir Práctica SQL."
            )

    # ------------------------------------------------------------------ #
    # Descarga + extracción de binarios
    # ------------------------------------------------------------------ #
    def _runtime_state(self) -> dict:
        if config.RUNTIME_JSON.exists():
            try:
                return json.loads(config.RUNTIME_JSON.read_text("utf-8"))
            except Exception:
                return {}
        return {}

    def _guardar_runtime_state(self, **kv) -> None:
        estado = self._runtime_state()
        estado.update(kv)
        config.RUNTIME_JSON.write_text(json.dumps(estado, indent=2), encoding="utf-8")

    def _mysqld_path(self) -> Path:
        if not config.ES_WINDOWS:
            # Copia propia (no la del sistema): el binario /usr/sbin/mysqld de
            # Ubuntu/Debian está confinado por AppArmor a /etc/mysql y
            # /var/lib/mysql, así que no puede leer nuestro datadir/my.ini
            # bajo el home. Un binario idéntico en otra ruta no está confinado.
            return config.MYSQL_BIN_DIR / "bin" / "mysqld"
        return config.MYSQL_BIN_DIR / "bin" / "mysqld.exe"

    def _mysqladmin_path(self) -> Path:
        if not config.ES_WINDOWS:
            return config.MYSQL_BIN_DIR / "bin" / "mysqladmin"
        return config.MYSQL_BIN_DIR / "bin" / "mysqladmin.exe"

    def _binarios_listos(self) -> bool:
        if not config.ES_WINDOWS:
            return self._mysqld_path().exists() and self._mysqladmin_path().exists()
        estado = self._runtime_state()
        mysqld = config.MYSQL_BIN_DIR / "bin" / "mysqld.exe"
        return estado.get("version") == config.MYSQL_VERSION and mysqld.exists()

    def asegurar_binarios(self) -> None:
        if self._binarios_listos():
            return

        if not config.ES_WINDOWS:
            mysqld_sistema = shutil.which("mysqld") or next(
                (p for p in ("/usr/sbin/mysqld", "/usr/bin/mysqld") if Path(p).exists()),
                None,
            )
            mysqladmin_sistema = shutil.which("mysqladmin") or next(
                (p for p in ("/usr/bin/mysqladmin",) if Path(p).exists()),
                None,
            )
            if not mysqld_sistema or not mysqladmin_sistema:
                raise MysqlBootstrapError(
                    "No se encontró mysqld/mysqladmin en el sistema. "
                    "Instalá mysql-server o mariadb-server."
                )
            self._mysqld_path().parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(mysqld_sistema, self._mysqld_path())
            shutil.copy2(mysqladmin_sistema, self._mysqladmin_path())
            self._mysqld_path().chmod(0o755)
            self._mysqladmin_path().chmod(0o755)
            return

        self._asegurar_vcredist()

        zip_path = config.DESCARGAS_DIR / config.MYSQL_ZIP_NAME
        part_path = zip_path.with_suffix(".zip.part")

        if not (zip_path.exists() and zip_path.stat().st_size == config.MYSQL_ZIP_SIZE):
            self._descargar(config.MYSQL_ZIP_URL, part_path, config.MYSQL_ZIP_SIZE)
            part_path.replace(zip_path)

        self._progreso_descarga.update(activo=True, pct=100, mensaje="Extrayendo MySQL...")
        self._extraer(zip_path)
        self._progreso_descarga.update(activo=False, pct=100, mensaje="Listo")
        self._guardar_runtime_state(version=config.MYSQL_VERSION)

    def _descargar(self, url: str, destino: Path, tamanio_esperado: int) -> None:
        existente = destino.stat().st_size if destino.exists() else 0
        headers = {}
        modo = "wb"
        if existente and existente < tamanio_esperado:
            headers["Range"] = f"bytes={existente}-"
            modo = "ab"
        elif existente >= tamanio_esperado:
            existente = 0
            modo = "wb"

        req = urllib.request.Request(url, headers=headers)
        self._progreso_descarga.update(
            activo=True, pct=0, mensaje="Descargando MySQL 8.4.11 (~268 MB)..."
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp, open(destino, modo) as f:
                recibido = existente
                while True:
                    bloque = resp.read(CHUNK)
                    if not bloque:
                        break
                    f.write(bloque)
                    recibido += len(bloque)
                    pct = int(recibido * 100 / tamanio_esperado)
                    self._progreso_descarga.update(
                        pct=min(pct, 99),
                        mensaje=f"Descargando MySQL... {recibido // (1024*1024)} MB",
                    )
        except Exception as e:
            raise MysqlBootstrapError(
                f"Falló la descarga de MySQL desde {url}: {e}\n"
                f"Solución manual: descargá el ZIP vos mismo y colocalo en "
                f"{config.DESCARGAS_DIR / config.MYSQL_ZIP_NAME} y reintentá."
            ) from e

        if destino.stat().st_size != tamanio_esperado:
            destino.unlink(missing_ok=True)
            raise MysqlBootstrapError(
                "El archivo descargado no tiene el tamaño esperado. Se descartó; reintentá."
            )

    def _extraer(self, zip_path: Path) -> None:
        if config.MYSQL_BIN_DIR.exists():
            shutil.rmtree(config.MYSQL_BIN_DIR, ignore_errors=True)
        config.MYSQL_BIN_DIR.mkdir(parents=True, exist_ok=True)

        with zipfile.ZipFile(zip_path) as zf:
            nombres = zf.namelist()
            raiz = nombres[0].split("/")[0] + "/"
            for nombre in nombres:
                if not nombre.startswith(raiz):
                    continue
                rel = nombre[len(raiz):]
                if not rel:
                    continue
                # Salteamos docs/ e include/, pero share/ es obligatorio
                # (share/english/errmsg.sys, sin eso mysqld no arranca).
                primer_segmento = rel.split("/")[0]
                if primer_segmento in ("docs", "include"):
                    continue
                destino = config.MYSQL_BIN_DIR / rel
                if nombre.endswith("/"):
                    destino.mkdir(parents=True, exist_ok=True)
                else:
                    destino.parent.mkdir(parents=True, exist_ok=True)
                    with zf.open(nombre) as src, open(destino, "wb") as dst:
                        shutil.copyfileobj(src, dst)

    # ------------------------------------------------------------------ #
    # my.ini
    # ------------------------------------------------------------------ #
    def _escribir_my_ini(self) -> None:
        def fwd(p: Path) -> str:
            return str(p).replace("\\", "/")

        # En Linux el binario copiado sigue esperando el layout FHS normal
        # (plugins en /usr/lib/mysql/plugin, mensajes en /usr/share/mysql-*),
        # así que basedir apunta al basedir real del sistema, no a nuestra
        # carpeta propia (que sólo tiene el binario copiado).
        basedir = Path("/usr") if not config.ES_WINDOWS else config.MYSQL_BIN_DIR
        plugin_dir_linea = ""
        if not config.ES_WINDOWS:
            for candidato in ("/usr/lib/mysql/plugin", "/usr/lib/x86_64-linux-gnu/mysql/plugin"):
                if Path(candidato).is_dir():
                    plugin_dir_linea = f"plugin-dir                = {candidato}\n"
                    break

        socket_linea = ""
        pid_linea = ""
        if not config.ES_WINDOWS:
            # Rutas propias: no tocar /var/run/mysqld, que es del mysqld del
            # sistema y no tenemos permiso de escritura ahí.
            socket_linea = f"socket                   = {fwd(config.MYSQL_TMP_DIR / 'mysqld.sock')}\n"
            pid_linea = f"pid-file                 = {fwd(config.MYSQL_TMP_DIR / 'mysqld.pid')}\n"

        contenido = f"""[mysqld]
basedir                  = {fwd(basedir)}
datadir                  = {fwd(config.MYSQL_DATA_DIR)}
tmpdir                   = {fwd(config.MYSQL_TMP_DIR)}
{plugin_dir_linea}{socket_linea}{pid_linea}port                     = {config.MYSQL_PORT}
bind-address             = 127.0.0.1
mysqlx                   = OFF
log-error                = {fwd(config.MYSQL_LOG_DIR / 'mysqld-error.log')}
character-set-server     = utf8mb4
collation-server         = utf8mb4_0900_ai_ci
sql_mode                 = "STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION"
innodb_lock_wait_timeout = 10
wait_timeout             = 28800
innodb_buffer_pool_size  = 128M
secure_file_priv         = ""

[client]
port = {config.MYSQL_PORT}
{f"socket                   = {fwd(config.MYSQL_TMP_DIR / 'mysqld.sock')}" if not config.ES_WINDOWS else ""}
"""
        config.MYSQL_INI_PATH.write_text(contenido, encoding="utf-8")

    # ------------------------------------------------------------------ #
    # Datadir
    # ------------------------------------------------------------------ #
    def _datadir_inicializado(self) -> bool:
        return (config.MYSQL_DATA_DIR / "ibdata1").exists() and (
            config.MYSQL_DATA_DIR / "mysql"
        ).is_dir()

    def asegurar_datadir(self) -> None:
        self._escribir_my_ini()
        if self._datadir_inicializado():
            return

        if config.MYSQL_DATA_DIR.exists() and any(config.MYSQL_DATA_DIR.iterdir()):
            roto = config.MYSQL_DATA_DIR.with_name(
                f"data.roto.{int(time.time())}"
            )
            config.MYSQL_DATA_DIR.rename(roto)
            self._log(f"Datadir incompleto movido a {roto}")
        config.MYSQL_DATA_DIR.mkdir(parents=True, exist_ok=True)

        mysqld = self._mysqld_path()
        self._log("Inicializando datadir (initialize-insecure)...")
        resultado = subprocess.run(
            [
                str(mysqld),
                f"--defaults-file={config.MYSQL_INI_PATH}",
                "--initialize-insecure",
                "--console",
            ],
            capture_output=True,
            timeout=120,
            **_POPEN_FLAGS,
        )
        salida = resultado.stderr.decode("utf-8", errors="replace")
        for linea in salida.splitlines():
            self._log(f"[init] {linea}")
        if resultado.returncode != 0 or not self._datadir_inicializado():
            raise MysqlBootstrapError(
                "Falló la inicialización del datadir de MySQL. Log:\n" + salida[-2000:]
            )

    def _log(self, msg: str) -> None:
        with self._log_lock:
            self._log_buffer.append(msg)

    # ------------------------------------------------------------------ #
    # Puerto / adopción
    # ------------------------------------------------------------------ #
    def _puerto_abierto(self, host: str, puerto: int, timeout: float = 0.3) -> bool:
        try:
            with socket.create_connection((host, puerto), timeout=timeout):
                return True
        except OSError:
            return False

    def _intentar_adoptar(self) -> Optional[str]:
        """Si algo ya escucha en el puerto, decide si es 'nuestro' mysqld o ajeno."""
        if not self._puerto_abierto(config.MYSQL_HOST, config.MYSQL_PORT):
            return None
        try:
            conn = pymysql.connect(
                host=config.MYSQL_HOST,
                port=config.MYSQL_PORT,
                user=config.MYSQL_ROOT_USER,
                password="",
                connect_timeout=3,
            )
            with conn.cursor() as cur:
                cur.execute("SELECT @@datadir")
                (datadir,) = cur.fetchone()
            conn.close()
            datadir_norm = str(Path(datadir.rstrip("\\/"))).lower()
            nuestro = str(config.MYSQL_DATA_DIR).lower()
            if datadir_norm == nuestro:
                return "adoptado"
            return "ajeno"
        except Exception:
            return "ajeno"

    # ------------------------------------------------------------------ #
    # Arranque / parada
    # ------------------------------------------------------------------ #
    def iniciar(self) -> EstadoServidor:
        config.asegurar_directorios()

        estado_puerto = self._intentar_adoptar()
        if estado_puerto == "adoptado":
            self._log("Se detectó un mysqld propio ya corriendo: adoptado.")
            return EstadoServidor(corriendo=True, adoptado=True, puerto=config.MYSQL_PORT)
        if estado_puerto == "ajeno":
            raise MysqlBootstrapError(
                f"El puerto {config.MYSQL_PORT} ya está en uso por otro proceso "
                "(no es nuestro MySQL). Cerralo o cambiá MYSQL_PORT en app/config.py."
            )

        self.asegurar_binarios()
        self.asegurar_datadir()

        mysqld = self._mysqld_path()
        self._log(f"Arrancando mysqld en el puerto {config.MYSQL_PORT}...")
        self.proc = subprocess.Popen(
            [str(mysqld), f"--defaults-file={config.MYSQL_INI_PATH}", "--console"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            **_POPEN_FLAGS,
        )
        threading.Thread(
            target=self._drenar, args=(self.proc.stdout, "out"), daemon=True
        ).start()
        threading.Thread(
            target=self._drenar, args=(self.proc.stderr, "err"), daemon=True
        ).start()

        self._esperar_listo(timeout=60 if self._datadir_inicializado() else 120)
        self._guardar_runtime_state(
            pid=self.proc.pid, port=config.MYSQL_PORT, datadir=str(config.MYSQL_DATA_DIR)
        )
        return EstadoServidor(corriendo=True, adoptado=False, puerto=config.MYSQL_PORT, pid=self.proc.pid)

    def _esperar_listo(self, timeout: int) -> None:
        limite = time.time() + timeout
        while time.time() < limite:
            if self.proc is not None and self.proc.poll() is not None:
                raise MysqlBootstrapError(
                    "mysqld terminó inesperadamente durante el arranque. "
                    "Últimas líneas del log:\n" + "\n".join(self.log_reciente(40))
                )
            try:
                conn = pymysql.connect(
                    host=config.MYSQL_HOST,
                    port=config.MYSQL_PORT,
                    user=config.MYSQL_ROOT_USER,
                    password="",
                    connect_timeout=2,
                )
                with conn.cursor() as cur:
                    cur.execute("SELECT 1")
                    cur.fetchone()
                conn.close()
                return
            except Exception:
                time.sleep(0.25)
        raise MysqlBootstrapError(
            "MySQL no respondió a tiempo. Últimas líneas del log:\n"
            + "\n".join(self.log_reciente(40))
        )

    def detener(self) -> None:
        self._keepalive_stop.set()
        if self.proc is None:
            return
        mysqladmin = self._mysqladmin_path()
        try:
            subprocess.run(
                [
                    str(mysqladmin),
                    "-u", config.MYSQL_ROOT_USER,
                    "-h", config.MYSQL_HOST,
                    "-P", str(config.MYSQL_PORT),
                    "shutdown",
                ],
                timeout=30,
                **_POPEN_FLAGS,
            )
        except Exception:
            pass
        try:
            self.proc.wait(timeout=30)
        except subprocess.TimeoutExpired:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                self.proc.kill()
        self.proc = None


gestor = GestorMysql()
