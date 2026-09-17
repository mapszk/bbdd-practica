"""Rutas y constantes centrales de la aplicación.

Regla dura: nada de lo que MySQL abre y mantiene bloqueado (datadir, venv)
puede vivir bajo OneDrive. OneDrive sincroniza archivos abiertos a mitad de
escritura y corrompe datadirs InnoDB. Este módulo es el único lugar que
decide "adentro" vs "afuera" de OneDrive.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

ES_WINDOWS = sys.platform.startswith("win")

# Carpeta del proyecto: código de la app + datos del alumno.
# Vive en OneDrive intencionalmente (respaldo automático de las soluciones).
PROJECT_DIR = Path(__file__).resolve().parent.parent

APP_DIR = PROJECT_DIR / "app"
STATIC_DIR = PROJECT_DIR / "static"
DATOS_DIR = PROJECT_DIR / "datos"
VENDOR_DIR = STATIC_DIR / "vendor" / "codemirror"

EJERCICIOS_JSON = DATOS_DIR / "ejercicios.json"
EJERCICIOS_OVERRIDES_JSON = DATOS_DIR / "ejercicios_overrides.json"
SOLUCIONES_JSON = DATOS_DIR / "soluciones.json"
SOLUCIONES_IDEALES_JSON = DATOS_DIR / "soluciones_ideales.json"
ER_LAYOUT_JSON = DATOS_DIR / "er_layout.json"
MIS_SOLUCIONES_SQL = PROJECT_DIR / "mis_soluciones.sql"

DOCX_PATH = PROJECT_DIR / "BDatos_5_PracticaEnunciado-SalidasV2023.01.docx"

DUMPS = {
    "afatse": PROJECT_DIR / "afatse_2020.sql",
    "agencia_personal": PROJECT_DIR / "agencia_personal_2020.sql",
    "ropa_siempre_limpia": PROJECT_DIR
    / "BDatos_4_AnexoI_Tintoreria_siempre_limpia_2020.sql",
    "parcial": PROJECT_DIR / "parcial.sql",
}

# Todo lo que MySQL/uv necesitan tener SIEMPRE abierto/bloqueado va afuera
# de OneDrive, en el perfil local de Windows.
if ES_WINDOWS:
    _LOCALAPPDATA = Path(os.environ.get("LOCALAPPDATA", Path.home() / "AppData" / "Local"))
    RUNTIME_DIR = _LOCALAPPDATA / "PracticaSQL"
else:
    # Fuera de Windows no hay OneDrive ni mysqld portable: usamos el mysqld
    # del sistema con un datadir propio bajo el home del usuario.
    RUNTIME_DIR = Path.home() / ".local" / "share" / "PracticaSQL"

DESCARGAS_DIR = RUNTIME_DIR / "descargas"
MYSQL_BIN_DIR = RUNTIME_DIR / "mysql"
MYSQL_DATA_DIR = RUNTIME_DIR / "data"
MYSQL_TMP_DIR = RUNTIME_DIR / "tmp"
MYSQL_LOG_DIR = RUNTIME_DIR / "log"
MYSQL_INI_PATH = RUNTIME_DIR / "my.ini"
RUNTIME_JSON = RUNTIME_DIR / "runtime.json"
VENV_DIR = RUNTIME_DIR / "venv"

MYSQL_VERSION = "8.4.11"
MYSQL_ZIP_NAME = f"mysql-{MYSQL_VERSION}-winx64.zip"
MYSQL_ZIP_URL = f"https://cdn.mysql.com/Downloads/MySQL-8.4/{MYSQL_ZIP_NAME}"
MYSQL_ZIP_SIZE = 281_191_914  # verificado por HEAD request

MYSQL_HOST = "127.0.0.1"
MYSQL_PORT = 3307
MYSQL_ROOT_USER = "root"

APP_HOST = "127.0.0.1"
APP_PORT = 8765

SISTEMA_ESQUEMAS = {"mysql", "sys", "performance_schema", "information_schema"}
USUARIOS_SISTEMA = {"root", "mysql.sys", "mysql.session", "mysql.infoschema"}


def asegurar_directorios() -> None:
    for d in (
        DATOS_DIR,
        RUNTIME_DIR,
        DESCARGAS_DIR,
        MYSQL_BIN_DIR,
        MYSQL_DATA_DIR,
        MYSQL_TMP_DIR,
        MYSQL_LOG_DIR,
    ):
        d.mkdir(parents=True, exist_ok=True)
    _assert_fuera_de_onedrive(MYSQL_DATA_DIR)
    _assert_fuera_de_onedrive(VENV_DIR)


def _assert_fuera_de_onedrive(ruta: Path) -> None:
    if not ES_WINDOWS:
        return
    partes = [p.lower() for p in ruta.parts]
    if any("onedrive" in p for p in partes):
        raise RuntimeError(
            f"Ruta insegura dentro de OneDrive: {ruta}\n"
            "MySQL y el entorno virtual NO pueden vivir en una carpeta sincronizada: "
            "OneDrive puede tocar archivos abiertos a mitad de escritura y corromper "
            "la base de datos. Revisá app/config.py."
        )
