"""Punto de entrada: FastAPI sirviendo la app y administrando MySQL.

Regla del código: nunca `async def` con una llamada PyMySQL adentro --
los endpoints son `def` a propósito para correr en threadpool y no
congelar el event loop mientras una sesión espera un lock.
"""
from __future__ import annotations

import json
import threading
import time
import webbrowser
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from app import compare, config, docx_parse, dumps, runner, schema, solutions
from app.mysql_server import MysqlBootstrapError, gestor
from app.sessions import gestor_sesiones

_baseline_filas: dict[str, dict[str, int]] = {}


def _cargar_ejercicios() -> dict:
    if not config.EJERCICIOS_JSON.exists():
        docx_parse.generar()
    datos = json.loads(config.EJERCICIOS_JSON.read_text("utf-8"))
    if config.EJERCICIOS_OVERRIDES_JSON.exists():
        overrides = json.loads(config.EJERCICIOS_OVERRIDES_JSON.read_text("utf-8"))
        for practica in datos["practicas"]:
            for ej in practica["ejercicios"]:
                if ej["id"] in overrides:
                    ej.update(overrides[ej["id"]])
    return datos


def _capturar_baseline() -> None:
    for clave in config.DUMPS:
        try:
            _baseline_filas[clave] = _contar_filas(clave)
        except Exception:
            _baseline_filas[clave] = {}


def _contar_filas(db: str) -> dict[str, int]:
    import pymysql

    conn = pymysql.connect(host=config.MYSQL_HOST, port=config.MYSQL_PORT, user="root", password="", database=db)
    try:
        with conn.cursor() as cur:
            cur.execute("SHOW TABLES")
            tablas = [r[0] for r in cur.fetchall()]
            out = {}
            for t in tablas:
                cur.execute(f"SELECT COUNT(*) FROM `{t}`")
                out[t] = cur.fetchone()[0]
            return out
    finally:
        conn.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    config.asegurar_directorios()
    try:
        gestor.iniciar()
        informes = dumps.cargar_todos(config.MYSQL_HOST, config.MYSQL_PORT)
        for clave, informe in informes.items():
            print(f"Cargada {informe.base}: {informe.tablas} tablas, {informe.filas_totales} filas "
                  f"({informe.encoding_usado})")
        _capturar_baseline()
        gestor_sesiones.iniciar_keepalive()
        if not config.EJERCICIOS_JSON.exists():
            docx_parse.generar()
        threading.Timer(1.0, lambda: webbrowser.open(f"http://{config.APP_HOST}:{config.APP_PORT}")).start()
    except MysqlBootstrapError as e:
        print("ERROR AL INICIAR MYSQL:\n", e)
    yield
    gestor_sesiones.detener_keepalive()
    gestor.detener()


app = FastAPI(title="Práctica SQL", lifespan=lifespan)


@app.get("/")
def index():
    return FileResponse(config.STATIC_DIR / "index.html")


class SinCacheStaticFiles(StaticFiles):
    """App local de un solo usuario en desarrollo constante -- el caché del
    navegador para /static sólo trae dolores de cabeza (JS/CSS viejo
    después de cada cambio) y no hay ningún beneficio real de ancho de
    banda que cuidar acá."""

    def file_response(self, *args, **kwargs):
        resp = super().file_response(*args, **kwargs)
        resp.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
        return resp


app.mount("/static", SinCacheStaticFiles(directory=str(config.STATIC_DIR)), name="static")


# ---------------------------------------------------------------------- #
# Estado / servidor
# ---------------------------------------------------------------------- #
@app.get("/api/estado")
def api_estado():
    return {
        "mysql": {
            "version": config.MYSQL_VERSION,
            "puerto": config.MYSQL_PORT,
            "proceso_vivo": gestor.proc is not None and gestor.proc.poll() is None,
        },
        "sesiones": gestor_sesiones.estado_todas(),
        "descarga": gestor.progreso_descarga(),
    }


@app.get("/api/servidor/log")
def api_servidor_log():
    return {"lineas": gestor.log_reciente(300)}


@app.post("/api/servidor/reiniciar")
def api_servidor_reiniciar():
    gestor.detener()
    gestor.iniciar()
    return api_estado()


# ---------------------------------------------------------------------- #
# Ejercicios
# ---------------------------------------------------------------------- #
@app.get("/api/practicas")
def api_practicas():
    datos = _cargar_ejercicios()
    return [
        {
            "numero": p["numero"],
            "titulo": p["titulo"],
            "cantidad": len(p["ejercicios"]),
            "ids": [e["id"] for e in p["ejercicios"]],
        }
        for p in datos["practicas"]
    ]


@app.get("/api/ejercicio/{p}/{e}")
def api_ejercicio(p: int, e: int):
    datos = _cargar_ejercicios()
    practica = next((x for x in datos["practicas"] if x["numero"] == p), None)
    if not practica:
        raise HTTPException(404, "Práctica no encontrada")
    ejercicio = next((x for x in practica["ejercicios"] if x["numero"] == e), None)
    if not ejercicio:
        raise HTTPException(404, "Ejercicio no encontrado")
    soluciones_todas = solutions.obtener_todas()["soluciones"]
    mi_solucion = soluciones_todas.get(ejercicio["id"])
    # La solución ideal sólo se entrega si el ejercicio ya está marcado
    # resuelto -- para no arruinar el intento por curiosear la respuesta.
    resuelto = bool(mi_solucion and mi_solucion.get("estado") == "resuelto")
    return {
        **ejercicio,
        "practica_titulo": practica["titulo"],
        "practica_preambulo": practica["preambulo"],
        "total_en_practica": len(practica["ejercicios"]),
        "solucion": mi_solucion,
        "solucion_ideal": solutions.obtener_ideal(ejercicio["id"]) if resuelto else None,
    }


class OverrideBody(BaseModel):
    consigna: str | None = None
    base_datos: str | None = None
    ayuda: str | None = None
    notas: str | None = None


@app.put("/api/ejercicio/{p}/{e}")
def api_corregir_ejercicio(p: int, e: int, body: OverrideBody):
    ejercicio_id = f"p{p}e{e}"
    overrides = {}
    if config.EJERCICIOS_OVERRIDES_JSON.exists():
        overrides = json.loads(config.EJERCICIOS_OVERRIDES_JSON.read_text("utf-8"))
    overrides.setdefault(ejercicio_id, {})
    for k, v in body.model_dump(exclude_none=True).items():
        overrides[ejercicio_id][k] = v
    config.EJERCICIOS_OVERRIDES_JSON.write_text(json.dumps(overrides, ensure_ascii=False, indent=2), encoding="utf-8")
    return {"ok": True}


# ---------------------------------------------------------------------- #
# Ejecución
# ---------------------------------------------------------------------- #
class EjecutarBody(BaseModel):
    sesion: str = "principal"
    sql: str
    db: str | None = None


@app.post("/api/ejecutar")
def api_ejecutar(body: EjecutarBody):
    resultado = runner.ejecutar(body.sesion, body.sql, body.db)
    return {
        "ok_general": resultado.ok_general,
        "rescate_delimiter": resultado.rescate_delimiter,
        "sentencias": [
            {
                "sql": s.sql,
                "ok": s.ok,
                "columnas": s.columnas,
                "filas": s.filas,
                "filas_afectadas": s.filas_afectadas,
                "truncado": s.truncado,
                "error": s.error,
                "warnings": s.warnings,
                "ms": s.ms,
            }
            for s in resultado.sentencias
        ],
        "estado_sesion": gestor_sesiones.sesiones[body.sesion].estado_publico(),
    }


class CompararBody(BaseModel):
    consigna: str = ""
    columnas: list[str]
    filas: list[list]
    tabla_esperada: dict | None = None


@app.post("/api/comparar")
def api_comparar(body: CompararBody):
    return compare.comparar(body.consigna, body.columnas, body.filas, body.tabla_esperada)


class CancelarBody(BaseModel):
    sesion: str = "principal"


@app.post("/api/cancelar")
def api_cancelar(body: CancelarBody):
    return {"ok": gestor_sesiones.cancelar(body.sesion)}


# ---------------------------------------------------------------------- #
# Sesiones
# ---------------------------------------------------------------------- #
@app.get("/api/sesiones")
def api_sesiones():
    return gestor_sesiones.estado_todas()


class ConectarBody(BaseModel):
    usuario: str = "root"
    password: str = ""
    db: str | None = None


@app.post("/api/sesiones/{nombre}/conectar")
def api_sesion_conectar(nombre: str, body: ConectarBody):
    if nombre not in gestor_sesiones.sesiones:
        raise HTTPException(404, "Sesión inexistente")
    try:
        sesion = gestor_sesiones.conectar(nombre, body.usuario, body.password, body.db)
    except Exception as e:
        import pymysql

        if isinstance(e, pymysql.err.Error):
            codigo = e.args[0] if e.args else None
            if codigo in (1044, 1045):
                # Acceso denegado a la BD indicada al conectar (sin GRANT todavía) o
                # contraseña incorrecta: reintentamos sin seleccionar base -- el
                # alumno puede no tener permisos aún, es exactamente lo que se
                # está enseñando en la Práctica 10.
                try:
                    sesion = gestor_sesiones.conectar(nombre, body.usuario, body.password, None)
                    estado = sesion.estado_publico()
                    estado["aviso"] = (
                        f"Conectado como {body.usuario}, pero sin acceso a la base "
                        f"{body.db!r} todavía (falta un GRANT). Esto puede ser el resultado "
                        "esperado del ejercicio."
                    )
                    return estado
                except Exception:
                    pass
            raise HTTPException(400, f"No se pudo conectar como {body.usuario}: {e}")
        raise HTTPException(400, str(e))
    return sesion.estado_publico()


@app.post("/api/sesiones/{nombre}/desconectar")
def api_sesion_desconectar(nombre: str):
    gestor_sesiones.desconectar(nombre)
    return {"ok": True}


class TxBody(BaseModel):
    accion: str  # "commit" | "rollback"


@app.post("/api/sesiones/{nombre}/tx")
def api_sesion_tx(nombre: str, body: TxBody):
    if body.accion == "commit":
        gestor_sesiones.commit(nombre)
    elif body.accion == "rollback":
        gestor_sesiones.rollback(nombre)
    else:
        raise HTTPException(400, "accion debe ser commit o rollback")
    return gestor_sesiones.sesiones[nombre].estado_publico()


class SqlModeBody(BaseModel):
    only_full_group_by: bool


@app.post("/api/sesiones/{nombre}/sqlmode")
def api_sesion_sqlmode(nombre: str, body: SqlModeBody):
    gestor_sesiones.set_sql_mode_group_by(nombre, body.only_full_group_by)
    return gestor_sesiones.sesiones[nombre].estado_publico()


@app.get("/api/bloqueos")
def api_bloqueos():
    return runner.consultar_bloqueos()


# ---------------------------------------------------------------------- #
# Bases de datos
# ---------------------------------------------------------------------- #
@app.get("/api/bd/estado")
def api_bd_estado():
    out = {}
    for clave in config.DUMPS:
        try:
            actual = _contar_filas(clave)
        except Exception:
            actual = {}
        base_line = _baseline_filas.get(clave, {})
        out[clave] = {"modificada": actual != base_line, "tablas": actual}
    return out


class ReiniciarBody(BaseModel):
    db: str


@app.post("/api/bd/reiniciar")
def api_bd_reiniciar(body: ReiniciarBody):
    if body.db not in config.DUMPS:
        raise HTTPException(404, "Base desconocida")
    sesiones_vivas = list(gestor_sesiones.sesiones.values())
    informe = dumps.reiniciar_base(body.db, config.MYSQL_HOST, config.MYSQL_PORT, sesiones_vivas)
    _baseline_filas[body.db] = _contar_filas(body.db)
    return {
        "base": informe.base,
        "tablas": informe.tablas,
        "filas": informe.filas_totales,
        "ms": informe.ms,
    }


@app.post("/api/bd/limpiar_usuarios")
def api_bd_limpiar_usuarios():
    import pymysql

    conn = pymysql.connect(host=config.MYSQL_HOST, port=config.MYSQL_PORT, user="root", password="")
    borrados = []
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT User, Host FROM mysql.user")
            for usuario, host in cur.fetchall():
                if usuario not in config.USUARIOS_SISTEMA and usuario != "":
                    cur.execute(f"DROP USER IF EXISTS '{usuario}'@'{host}'")
                    borrados.append(f"{usuario}@{host}")
        conn.commit()
    finally:
        conn.close()
    return {"borrados": borrados}


# ---------------------------------------------------------------------- #
# Soluciones
# ---------------------------------------------------------------------- #
@app.get("/api/soluciones")
def api_soluciones():
    return solutions.obtener_todas()


@app.get("/api/soluciones/detalle")
def api_soluciones_detalle():
    """Combina cada ejercicio con su solución guardada (si existe) -- para
    la vista "Mis soluciones" del frontend, evita hacer 132 pedidos."""
    datos = _cargar_ejercicios()
    soluciones = solutions.obtener_todas()["soluciones"]
    out = []
    for practica in datos["practicas"]:
        for ej in practica["ejercicios"]:
            sol = soluciones.get(ej["id"])
            resuelto = bool(sol and sol.get("estado") == "resuelto")
            ideal = solutions.obtener_ideal(ej["id"]) if resuelto else None
            out.append(
                {
                    "id": ej["id"],
                    "practica_numero": practica["numero"],
                    "practica_titulo": practica["titulo"],
                    "ejercicio_numero": ej["numero"],
                    "consigna": ej["consigna"],
                    "base_datos": ej["base_datos"],
                    "sql": sol["sql"] if sol else "",
                    "estado": sol["estado"] if sol else "sin_resolver",
                    "actualizado": sol["actualizado"] if sol else None,
                    "solucion_ideal": ideal["sql"] if ideal else None,
                    "solucion_ideal_notas": ideal.get("notas") if ideal else None,
                }
            )
    return out


class GuardarSolucionBody(BaseModel):
    sql: str
    estado: str = "borrador"
    notas: str = ""
    ultima_ejecucion: dict | None = None


@app.put("/api/soluciones/{ejercicio_id}")
def api_guardar_solucion(ejercicio_id: str, body: GuardarSolucionBody):
    return solutions.guardar(ejercicio_id, body.sql, body.estado, body.notas, body.ultima_ejecucion)


@app.post("/api/exportar")
def api_exportar():
    datos = _cargar_ejercicios()
    ruta = solutions.exportar_sql(datos["practicas"])
    return {"ruta": str(ruta)}


# ---------------------------------------------------------------------- #
# Esquema / ER
# ---------------------------------------------------------------------- #
@app.get("/api/esquema/{db}")
def api_esquema(db: str):
    if db not in config.DUMPS:
        raise HTTPException(404, "Base desconocida")
    return schema.esquema_completo(db)


@app.get("/api/esquema/{db}/hints")
def api_esquema_hints(db: str):
    if db not in config.DUMPS:
        raise HTTPException(404, "Base desconocida")
    tablas = schema.obtener_tablas(db)
    return {t["nombre"]: [c["nombre"] for c in t["columnas"]] for t in tablas}


@app.get("/api/esquema/{db}/mermaid")
def api_esquema_mermaid(db: str):
    if db not in config.DUMPS:
        raise HTTPException(404, "Base desconocida")
    esquema_datos = schema.esquema_completo(db)
    return JSONResponse({"mermaid": schema.a_mermaid(esquema_datos)})


@app.get("/api/esquema/{db}/layout")
def api_esquema_layout(db: str):
    if config.ER_LAYOUT_JSON.exists():
        todos = json.loads(config.ER_LAYOUT_JSON.read_text("utf-8"))
        return todos.get(db, {})
    return {}


@app.put("/api/esquema/{db}/layout")
def api_guardar_layout(db: str, body: dict):
    todos = {}
    if config.ER_LAYOUT_JSON.exists():
        todos = json.loads(config.ER_LAYOUT_JSON.read_text("utf-8"))
    todos[db] = body
    config.ER_LAYOUT_JSON.write_text(json.dumps(todos, ensure_ascii=False, indent=2), encoding="utf-8")
    return {"ok": True}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host=config.APP_HOST, port=config.APP_PORT, log_level="info")
