"""Ingeniería inversa del esquema vía INFORMATION_SCHEMA (en vivo, no
parseo estático de los .sql -- el alumno crea vistas/tablas/triggers
durante las prácticas y un parseo estático quedaría desactualizado justo
cuando el diagrama importa)."""
from __future__ import annotations

from dataclasses import dataclass, field

import pymysql

from app import config


def _conectar(db: str) -> pymysql.connections.Connection:
    return pymysql.connect(
        host=config.MYSQL_HOST, port=config.MYSQL_PORT, user="root", password="",
        database=db, charset="utf8mb4",
    )


def obtener_tablas(db: str) -> list[dict]:
    conn = _conectar(db)
    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cur:
            cur.execute(
                """
                SELECT TABLE_NAME AS tabla, COLUMN_NAME AS columna, DATA_TYPE AS tipo,
                       IS_NULLABLE AS nullable, COLUMN_KEY AS clave, EXTRA AS extra,
                       ORDINAL_POSITION AS pos
                FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = %s
                ORDER BY TABLE_NAME, ORDINAL_POSITION
                """,
                (db,),
            )
            columnas = cur.fetchall()
    finally:
        conn.close()

    tablas: dict[str, dict] = {}
    for c in columnas:
        t = tablas.setdefault(c["tabla"], {"nombre": c["tabla"], "columnas": []})
        t["columnas"].append(
            {
                "nombre": c["columna"],
                "tipo": c["tipo"],
                "nullable": c["nullable"] == "YES",
                "pk": c["clave"] == "PRI",
                "extra": c["extra"],
            }
        )
    return list(tablas.values())


def obtener_fks(db: str) -> tuple[list[dict], list[dict]]:
    """Devuelve (declaradas, inferidas). Agrupa por CONSTRAINT_NAME y ordena
    por ORDINAL_POSITION: cada FK compuesta sale como UNA arista con su
    lista de columnas -- sin código especial para las 11 compuestas del
    curso ni para la autorreferencia."""
    conn = _conectar(db)
    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cur:
            cur.execute(
                """
                SELECT kcu.CONSTRAINT_NAME AS nombre, kcu.TABLE_NAME AS tabla,
                       kcu.COLUMN_NAME AS columna, kcu.ORDINAL_POSITION AS pos,
                       kcu.REFERENCED_TABLE_NAME AS tabla_ref,
                       kcu.REFERENCED_COLUMN_NAME AS columna_ref
                FROM information_schema.KEY_COLUMN_USAGE kcu
                WHERE kcu.CONSTRAINT_SCHEMA = %s AND kcu.REFERENCED_TABLE_NAME IS NOT NULL
                ORDER BY kcu.CONSTRAINT_NAME, kcu.ORDINAL_POSITION
                """,
                (db,),
            )
            filas = cur.fetchall()
    finally:
        conn.close()

    agrupadas: dict[str, dict] = {}
    for f in filas:
        g = agrupadas.setdefault(
            f["nombre"],
            {"tabla": f["tabla"], "tabla_ref": f["tabla_ref"], "columnas": [], "columnas_ref": []},
        )
        g["columnas"].append(f["columna"])
        g["columnas_ref"].append(f["columna_ref"])

    vistas_dedupe: dict[tuple, dict] = {}
    for g in agrupadas.values():
        clave = (g["tabla"], tuple(g["columnas"]), g["tabla_ref"], tuple(g["columnas_ref"]))
        vistas_dedupe.setdefault(clave, g)  # se queda con la primera -- dedupe de duplicados exactos

    declaradas = list(vistas_dedupe.values())
    inferidas = _inferir_fks_faltantes(db, declaradas)
    return declaradas, inferidas


def _inferir_fks_faltantes(db: str, declaradas: list[dict]) -> list[dict]:
    """Si el conjunto de columnas de una tabla (o un prefijo de su propia PK)
    coincide EXACTAMENTE en nombre con la PK completa de otra tabla, y no
    hay ya una FK declarada ahí, proponerla como inferida. Pesca casos como
    tratamiento_limpieza.nro_servicio -> servicios_limpieza.nro_servicio,
    que el dump nunca declaró pero es clara por el nombre."""
    tablas = obtener_tablas(db)
    pks_por_tabla = {
        t["nombre"]: [c["nombre"] for c in t["columnas"] if c["pk"]] for t in tablas
    }
    columnas_por_tabla = {t["nombre"]: [c["nombre"] for c in t["columnas"]] for t in tablas}

    ya_cubiertas = set()
    for fk in declaradas:
        ya_cubiertas.add((fk["tabla"], tuple(fk["columnas"])))

    inferidas = []
    for tabla, pk_propia in pks_por_tabla.items():
        cols_tabla = columnas_por_tabla[tabla]
        candidatos = [pk_propia] if pk_propia else []
        # prefijos de la PK propia (shape clásico de relación identificante)
        for i in range(1, len(pk_propia)):
            candidatos.append(pk_propia[:i])
        # también cualquier columna individual que matchee el nombre de una PK ajena
        for col in cols_tabla:
            candidatos.append([col])

        for cand in candidatos:
            if (tabla, tuple(cand)) in ya_cubiertas:
                continue
            for otra_tabla, pk_otra in pks_por_tabla.items():
                if otra_tabla == tabla or not pk_otra:
                    continue
                if list(cand) == pk_otra:
                    inferidas.append(
                        {
                            "tabla": tabla,
                            "columnas": cand,
                            "tabla_ref": otra_tabla,
                            "columnas_ref": pk_otra,
                        }
                    )
                    ya_cubiertas.add((tabla, tuple(cand)))
                    break
    return inferidas


def obtener_objetos(db: str) -> dict:
    conn = _conectar(db)
    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cur:
            cur.execute(
                "SELECT TABLE_NAME AS nombre FROM information_schema.VIEWS WHERE TABLE_SCHEMA=%s",
                (db,),
            )
            vistas = [r["nombre"] for r in cur.fetchall()]
            cur.execute(
                "SELECT ROUTINE_NAME AS nombre, ROUTINE_TYPE AS tipo "
                "FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=%s",
                (db,),
            )
            rutinas = cur.fetchall()
            cur.execute(
                "SELECT TRIGGER_NAME AS nombre, EVENT_MANIPULATION AS evento, "
                "EVENT_OBJECT_TABLE AS tabla FROM information_schema.TRIGGERS "
                "WHERE TRIGGER_SCHEMA=%s",
                (db,),
            )
            triggers = cur.fetchall()
    finally:
        conn.close()
    return {"vistas": vistas, "rutinas": rutinas, "triggers": triggers}


def esquema_completo(db: str) -> dict:
    tablas = obtener_tablas(db)
    declaradas, inferidas = obtener_fks(db)
    objetos = obtener_objetos(db)
    return {"db": db, "tablas": tablas, "fks": declaradas, "fks_inferidas": inferidas, **objetos}


def a_mermaid(esquema: dict) -> str:
    lineas = ["erDiagram"]
    for fk in esquema["fks"]:
        cols = ", ".join(fk["columnas"])
        lineas.append(f'    {fk["tabla_ref"]} ||--o{{ {fk["tabla"]} : "{cols}"')
    for fk in esquema.get("fks_inferidas", []):
        cols = ", ".join(fk["columnas"])
        lineas.append(f'    %% inferida, no declarada en la BD')
        lineas.append(f'    {fk["tabla_ref"]} ||..o{{ {fk["tabla"]} : "{cols}"')
    for t in esquema["tablas"]:
        lineas.append(f'    {t["nombre"]} {{')
        for c in t["columnas"]:
            marca = "PK" if c["pk"] else ""
            lineas.append(f'        {c["tipo"]} {c["nombre"]} {marca}')
        lineas.append("    }")
    return "\n".join(lineas)
