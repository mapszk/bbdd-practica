"""Ejecuta el SQL del alumno contra una sesión y arma la respuesta para la UI."""
from __future__ import annotations

import time
from dataclasses import dataclass, field

import pymysql

from app import config
from app.sessions import Sesion, gestor_sesiones
from app.splitter import dividir_con_rescate

TOPE_FILAS = 1000

RE_TABLA_PROHIBIDA = {"mysql", "sys", "performance_schema", "information_schema"}


@dataclass
class ResultadoSentencia:
    sql: str
    ok: bool
    columnas: list[str] = field(default_factory=list)
    filas: list[list] = field(default_factory=list)
    filas_afectadas: int | None = None
    truncado: bool = False
    error: str | None = None
    warnings: list[str] = field(default_factory=list)
    ms: int = 0


@dataclass
class ResultadoEjecucion:
    sentencias: list[ResultadoSentencia]
    rescate_delimiter: bool
    ok_general: bool


def _valores_json_seguros(fila) -> list:
    from datetime import date, datetime, time as time_cls, timedelta
    from decimal import Decimal

    out = []
    for v in fila:
        if v is None:
            out.append(None)
        elif isinstance(v, Decimal):
            out.append(float(v))
        elif isinstance(v, (datetime, date, time_cls, timedelta)):
            out.append(str(v))
        elif isinstance(v, (bytes, bytearray)):
            out.append(v.decode("utf-8", errors="replace"))
        else:
            out.append(v)
    return out


def _objetivo_prohibido(sql: str) -> bool:
    bajo = sql.lower()
    for esquema in RE_TABLA_PROHIBIDA:
        if esquema in bajo and any(
            palabra in bajo for palabra in ("drop database", "drop schema", f"use {esquema}")
        ):
            return True
    return False


def ejecutar(nombre_sesion: str, sql: str, db: str | None = None) -> ResultadoEjecucion:
    sesion = gestor_sesiones.sesiones[nombre_sesion]
    if sesion.conn is None:
        gestor_sesiones.conectar(nombre_sesion, db=db)
        sesion = gestor_sesiones.sesiones[nombre_sesion]
    elif db and sesion.db != db and not sesion.en_transaccion:
        try:
            with sesion.lock:
                with sesion.conn.cursor() as cur:
                    cur.execute(f"USE `{db}`")
                sesion.db = db
        except pymysql.err.Error as e:
            codigo = e.args[0] if e.args else None
            return ResultadoEjecucion(
                sentencias=[ResultadoSentencia(sql=f"USE `{db}`", ok=False, error=_traducir_error(codigo, str(e)))],
                rescate_delimiter=False,
                ok_general=False,
            )
    sentencias, rescate = dividir_con_rescate(sql)
    resultados: list[ResultadoSentencia] = []

    with sesion.lock:
        sesion.ocupada = True
        try:
            for st in sentencias:
                if _objetivo_prohibido(st.texto):
                    resultados.append(
                        ResultadoSentencia(
                            sql=st.texto,
                            ok=False,
                            error=(
                                "No se permite modificar los esquemas del sistema "
                                "(mysql, sys, performance_schema, information_schema) "
                                "desde acá."
                            ),
                        )
                    )
                    break
                resultados.append(_ejecutar_una(sesion, st.texto))
                if not resultados[-1].ok:
                    break
            gestor_sesiones._actualizar_estado_tx(sesion)
        finally:
            sesion.ocupada = False
            sesion.ultimo_uso = time.time()

    ok_general = bool(resultados) and all(r.ok for r in resultados)
    return ResultadoEjecucion(sentencias=resultados, rescate_delimiter=rescate, ok_general=ok_general)


def _ejecutar_una(sesion: Sesion, texto: str) -> ResultadoSentencia:
    inicio = time.time()
    try:
        with sesion.conn.cursor(pymysql.cursors.SSCursor) as cur:
            cur.execute(texto)
            columnas: list[str] = []
            filas: list[list] = []
            truncado = False
            if cur.description:
                columnas = [d[0] for d in cur.description]
                for i, fila in enumerate(cur):
                    if i >= TOPE_FILAS:
                        truncado = True
                        break
                    filas.append(_valores_json_seguros(fila))
                # drenar el resto del cursor server-side para no dejarlo colgado
                if truncado:
                    try:
                        cur.fetchall()
                    except Exception:
                        pass
            filas_afectadas = cur.rowcount if not columnas else None
            warnings = []
            with sesion.conn.cursor() as wcur:
                wcur.execute("SHOW WARNINGS")
                warnings = [f"{niv}: {msg}" for (niv, code, msg) in wcur.fetchall()]

            if texto.strip().lower().startswith("use "):
                sesion.db = texto.strip()[4:].strip().strip("`;")

            return ResultadoSentencia(
                sql=texto,
                ok=True,
                columnas=columnas,
                filas=filas,
                filas_afectadas=filas_afectadas,
                truncado=truncado,
                warnings=warnings,
                ms=int((time.time() - inicio) * 1000),
            )
    except pymysql.err.Error as e:
        codigo = e.args[0] if e.args else None
        mensaje = _traducir_error(codigo, str(e))
        return ResultadoSentencia(sql=texto, ok=False, error=mensaje, ms=int((time.time() - inicio) * 1000))


_MENSAJES_ES = {
    1205: "Se agotó el tiempo esperando un lock. Otra sesión tiene bloqueada esta fila/tabla "
          "(típico en la Práctica 11: revisá 'Ver bloqueos').",
    1142: "Permiso denegado (comando no autorizado para este usuario). Si el ejercicio pide "
          "revocar un permiso, esto puede ser el resultado esperado.",
    1044: "Permiso denegado sobre la base de datos. Si el ejercicio pide revocar un permiso, "
          "esto puede ser el resultado esperado.",
    1062: "Entrada duplicada: violás una clave primaria o UNIQIE ya existente.",
    1451: "No se puede borrar/modificar: otra fila hace referencia a esta (clave foránea).",
    1452: "No se puede insertar/actualizar: no existe la fila referenciada (clave foránea).",
}


def _traducir_error(codigo, mensaje: str) -> str:
    extra = _MENSAJES_ES.get(codigo)
    return f"{mensaje}\n→ {extra}" if extra else mensaje


def consultar_bloqueos() -> list[dict]:
    conn = gestor_sesiones.admin_conn()
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(
            """
            SELECT r.trx_mysql_thread_id AS sesion_bloqueada,
                   b.trx_mysql_thread_id AS sesion_bloqueante,
                   r.trx_query           AS consulta_bloqueada,
                   b.trx_query           AS consulta_bloqueante
            FROM performance_schema.data_lock_waits w
            JOIN information_schema.innodb_trx b ON b.trx_id = w.blocking_engine_transaction_id
            JOIN information_schema.innodb_trx r ON r.trx_id = w.requesting_engine_transaction_id
            """
        )
        filas = cur.fetchall()

    nombre_por_cid = {
        s.connection_id: s.nombre for s in gestor_sesiones.sesiones.values() if s.connection_id
    }
    for f in filas:
        f["sesion_bloqueada_nombre"] = nombre_por_cid.get(f["sesion_bloqueada"], "?")
        f["sesion_bloqueante_nombre"] = nombre_por_cid.get(f["sesion_bloqueante"], "?")
    return filas
