"""Script de verificación (no se persiste en el repo como parte de la app):
ejecuta la solución ideal de cada ejercicio P1-P6 contra la base real y
compara el resultado con la tabla_esperada (override si existe, si no la
del docx), usando la misma lógica de comparación que usa la app.
Sólo toca prácticas de solo-lectura (SELECT); no ejecuta nada de P7-P13
para no arriesgar tocar vistas/rutinas/triggers/datos reales.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pymysql

from app import compare

RAIZ = Path(__file__).resolve().parent.parent
DATOS = RAIZ / "datos"


def mapear_db(nombre_docx: str | None) -> str:
    n = (nombre_docx or "").lower()
    if "agencia" in n:
        return "agencia_personal"
    if "afatse" in n:
        return "afatse"
    return n


def conectar(db: str):
    return pymysql.connect(host="127.0.0.1", port=3307, user="root", password="", database=db, charset="utf8mb4")


def ejecutar_sql(db: str, sql: str):
    conn = conectar(db)
    try:
        with conn.cursor() as cur:
            stmts = [s.strip() for s in sql.split(";") if s.strip()]
            columnas, filas = [], []
            for st in stmts:
                cur.execute(st)
                if cur.description:
                    columnas = [d[0] for d in cur.description]
                    filas = [list(r) for r in cur.fetchall()]
                else:
                    columnas, filas = [], []
            return columnas, filas
    finally:
        conn.close()


def main():
    ejercicios = json.loads((DATOS / "ejercicios.json").read_text("utf-8"))
    overrides = json.loads((DATOS / "ejercicios_overrides.json").read_text("utf-8"))
    ideales = json.loads((DATOS / "soluciones_ideales.json").read_text("utf-8"))

    ok, difiere, sin_ideal, sin_esperado, con_error = [], [], [], [], []

    for p in ejercicios["practicas"]:
        if p["numero"] > 6:
            continue
        for e in p["ejercicios"]:
            eid = e["id"]
            tabla_esperada = (overrides.get(eid) or {}).get("tabla_esperada") or e.get("tabla_esperada")
            if not tabla_esperada or tabla_esperada.get("tipo") != "resultado":
                continue
            ideal = ideales.get(eid)
            if not ideal or not ideal.get("sql"):
                sin_ideal.append(eid)
                continue
            db = mapear_db(e.get("base_datos"))
            try:
                columnas, filas = ejecutar_sql(db, ideal["sql"])
            except Exception as ex:
                con_error.append((eid, str(ex)))
                continue
            r = compare.comparar(e.get("consigna", ""), columnas, filas, tabla_esperada)
            if r["veredicto"] in ("coincide", "coincide_orden_distinto"):
                ok.append(eid)
            else:
                difiere.append((eid, r, columnas, filas, tabla_esperada))

    print(f"OK: {len(ok)}")
    print(f"Sin solución ideal: {sin_ideal}")
    print(f"Con error al ejecutar: {con_error}")
    print(f"DIFIEREN: {len(difiere)}")
    for eid, r, columnas, filas, tabla_esperada in difiere:
        print("=" * 70)
        print(eid, "veredicto:", r["veredicto"], "obtenidas:", r["filas_obtenidas"], "esperadas:", r["filas_esperadas"])
        print("columnas obtenidas:", columnas)
        print("filas obtenidas (primeras 10):")
        for f in filas[:10]:
            print("  ", f)
        print("esperado (encabezado + filas del docx/override):")
        print("  ", r.get("encabezados_esperados"))
        for f in tabla_esperada["filas"][1:11]:
            print("  ", f)


if __name__ == "__main__":
    main()
