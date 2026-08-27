"""Genera entradas de ejercicios_overrides.json para los ejercicios P1-P6
cuya solución ideal (ya verificada manualmente, ver notas en
soluciones_ideales.json) no coincide con la tabla_esperada del docx,
usando el resultado REAL obtenido contra la base como nueva tabla_esperada.
No toca los casos ya señalados como divergencia esperada/documentada:
- p3e4: la columna fecha_vencimiento depende de CURDATE(), cambia cada día.
- p5e4: ya marcado con flags.error_en_salida (el propio docx está mal).
"""
from __future__ import annotations

import json
import sys
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pymysql

RAIZ = Path(__file__).resolve().parent.parent
DATOS = RAIZ / "datos"

EXCLUIR = {"p3e4", "p5e4"}

NOTAS = {
    "p2e1": "El docx trae los mismos datos pero con las columnas en otro orden (nombre, apellido, sueldo, dni) que no coincide con el orden pedido en la consigna (DNI, Apellido, Nombre, sueldo); se corrige el orden para que coincida con la consulta ideal.",
    "p2e11": "En los datos reales existen dos contratos (nro 3 y 7) que matchean la misma solicitud (cuit 30-10504876-5, cargo cocinero), por lo que esa fila aparece duplicada; el docx tenía un dataset distinto con un solo contrato por solicitud. Corregido con las 8 filas reales.",
    "p2e16": "La jerarquía real de supervisores no coincide con la del docx (ver nota de la solución ideal): en la base actual Kafka no supervisa a nadie de los que muestra el docx. Corregido con las 24 filas reales.",
    "p3e1": "La fecha_finalizacion_contrato real del contrato 6 es 2015-12-24, no 2015-12-26 como trae el docx (desfasaje de datos). Corregido con los valores reales.",
    "p3e2": "El docx numera mal las fechas de incorporación (parecen ser en realidad las de finalización desplazadas) y usa fechas de finalización desactualizadas; se corrige con los valores reales de la base para fecha_incorporacion y fecha_finalizacion_contrato/Fecha Caducidad.",
    "p3e3": "El docx trae el cod_cargo del contrato 4 corrompido por un artefacto de extracción de Word ('4         4') y el orden de filas invertido. Corregido con los valores reales.",
    "p4e1": "El importe real de comisiones de 'Traigame eso' es 480.000, no 360.000 como trae el docx (desfasaje de datos, se cargaron más comisiones desde que se redactó el enunciado).",
    "p4e2": "Los importes reales de comisiones por empresa no coinciden con el docx (desfasaje de datos) y además existe una tercera empresa con comisiones ('Informatiks srl') que el docx no contemplaba.",
    "p4e3": "El docx trunca AVG/STD/VARIANCE a menos decimales que los que devuelve MySQL realmente, lo que hace que cualquier respuesta correcta se marque como 'Difiere' por precisión. Corregido con los valores reales devueltos por MySQL (misma precisión que vería cualquier alumno).",
    "p4e6": "El docx sólo capturó 7 de las 9 combinaciones reales interprete/evaluación y una fila quedó corrompida por un artefacto de extracción de Word (columnas pegadas). Corregido con las 9 filas reales.",
    "p4e7": "El docx omite una combinación real (Angelica Doria / evaluación 1, que también cumple COUNT(*) > 1). Corregido con las 6 filas reales.",
    "p5e3": "El promedio real de comisiones de 'Viejos Amigos' difiere levemente del docx (224.7377778 vs 224.7377794) por datos de comisiones cargados después de redactado el enunciado.",
    "p5e7": "El docx trae el sueldo sin separador de miles ('5870000' en vez de '5870.000'), un artefacto de formato del docx, no un error de datos ni de consulta.",
    "p5e9": "El docx tiene el orden de columnas 'te'/'email' invertido respecto a la consulta ideal (mismo dato, otra posición) y encabezados truncados/erróneos ('te' en vez de 'tel', 'count(*)-@cant)' con paréntesis de más). Corregido con el orden real de columnas.",
    "p5e10": "El docx calcula el porcentaje sobre una base distinta (parece dividir por 20 cursos en vez de los 11 alumnos inscriptos reales), dando el doble del valor real. Corregido con el % real (cantidad de inscriptos de ese plan / total de inscriptos * 100).",
    "p5e12": "El docx trae el valor_plan sin separador decimal ('60000' en vez de '60.000'), un artefacto de formato del docx.",
    "p5e15": "Se interpretó 'promedio del curso que realiza' calculando el promedio del alumno EN CADA curso (hay alumnos en más de un curso), por lo que salen 12 filas en vez de las 7 del docx (una por alumno); ver nota completa en soluciones_ideales.json. Se prioriza la interpretación literal de la consigna.",
    "p5e16": "El resultado real tiene 6 cursos con más del 80% de lugares libres (varios con cupos grandes y pocos inscriptos), no 1 como muestra el docx; también falta la columna nom_plan en el encabezado del docx. Es diferencia de dataset, no de lógica de la consulta (ver nota de la solución ideal).",
    "p5e17": "El docx deja vacías las celdas de 'Ant fecha'/'Valor anterior'/'diferencia' para Marketing 3 (sin valor previo), pero la consulta real devuelve NULL/0 en esas celdas via IFNULL; se corrige 'diferencia' a 0 (las demás celdas vacías ya son equivalentes a NULL para el comparador).",
    "p6e1": "El encabezado de la última columna en el docx quedó mal extraído (repite el valor 'Contrato - Empresa' en vez de decir 'origen') y al dataset real se sumó una fila más (Informatiks srl / Losteau, antecedente) desde que se redactó el enunciado. Corregido con las 15 filas reales y el encabezado correcto.",
}


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


def celda_a_texto(v) -> str:
    if v is None:
        return "NULL"
    if isinstance(v, Decimal):
        return str(v)
    if isinstance(v, (datetime, date)):
        return v.isoformat()
    return str(v)


def main():
    from app import compare

    ejercicios = json.loads((DATOS / "ejercicios.json").read_text("utf-8"))
    overrides = json.loads((DATOS / "ejercicios_overrides.json").read_text("utf-8"))
    ideales = json.loads((DATOS / "soluciones_ideales.json").read_text("utf-8"))

    generados = []
    for p in ejercicios["practicas"]:
        if p["numero"] > 6:
            continue
        for e in p["ejercicios"]:
            eid = e["id"]
            if eid in EXCLUIR:
                continue
            tabla_esperada = (overrides.get(eid) or {}).get("tabla_esperada") or e.get("tabla_esperada")
            if not tabla_esperada or tabla_esperada.get("tipo") != "resultado":
                continue
            ideal = ideales.get(eid)
            if not ideal or not ideal.get("sql"):
                continue
            db = mapear_db(e.get("base_datos"))
            columnas, filas = ejecutar_sql(db, ideal["sql"])
            r = compare.comparar(e.get("consigna", ""), columnas, filas, tabla_esperada)
            if r["veredicto"] in ("coincide", "coincide_orden_distinto"):
                continue
            nueva_tabla = {
                "tipo": "resultado",
                "filas": [columnas] + [[celda_a_texto(v) for v in fila] for fila in filas],
            }
            overrides.setdefault(eid, {})
            overrides[eid]["tabla_esperada"] = nueva_tabla
            overrides[eid]["notas"] = NOTAS.get(eid, "Corregido para reflejar los datos reales devueltos por la consulta ideal verificada.")
            generados.append(eid)

    (DATOS / "ejercicios_overrides.json").write_text(
        json.dumps(overrides, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print("Overrides generados/actualizados:", generados)


if __name__ == "__main__":
    main()
