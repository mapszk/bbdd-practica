"""Comparador indulgente entre el resultado obtenido y la tabla de salida
esperada del docx. Siempre consultivo -- nunca bloquea la navegación. El
propio documento tiene salidas marcadas por su autor como erróneas
(flags.error_en_salida en P5 ej.4 y ej.10), así que un "Difiere" se debe
poder leer como "el documento está mal", no "el alumno está mal".
"""
from __future__ import annotations

import re
import unicodedata
from datetime import date, datetime
from decimal import Decimal, InvalidOperation

_RE_FECHA_DMY = re.compile(r"^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$")
_RE_FECHA_YMD = re.compile(r"^(\d{4})-(\d{1,2})-(\d{1,2})$")
# El docx no es consistente: a veces exporta fechas como MM/DD/AA (año de 2
# dígitos, estilo US -- p.ej. "06/13/14" = 13 de junio de 2014). Como el
# segundo grupo puede superar 12, se puede distinguir de DD/MM/AA sin
# ambigüedad en la mayoría de los casos reales de este dataset.
_RE_FECHA_MDY_2DIG = re.compile(r"^(\d{1,2})/(\d{1,2})/(\d{2})$")
_RE_ORDENAR = re.compile(r"(?i)ordenad|\border\b|\bordenar\b")


def _sin_acentos(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")


def _normalizar_celda(v) -> str:
    if v is None:
        return "∅"
    if isinstance(v, (int, float, Decimal)):
        try:
            return str(Decimal(str(v)).normalize())
        except InvalidOperation:
            return str(v)
    if isinstance(v, (datetime, date)):
        return v.isoformat()

    texto = str(v).strip()
    if texto == "" or texto.upper() in ("NULL", "(NULL)"):
        return "∅"

    m = _RE_FECHA_DMY.match(texto)
    if m:
        d, mo, y = m.groups()
        return f"{y}-{int(mo):02d}-{int(d):02d}"
    if _RE_FECHA_YMD.match(texto):
        return texto
    m2 = _RE_FECHA_MDY_2DIG.match(texto)
    if m2:
        mo, d, y2 = (int(x) for x in m2.groups())
        if 1 <= mo <= 12 and 1 <= d <= 31:
            y = 2000 + y2 if y2 < 70 else 1900 + y2  # regla Y2K de siempre
            return f"{y:04d}-{mo:02d}-{d:02d}"

    try:
        num = Decimal(texto.replace(",", "."))
        return str(num.normalize())
    except InvalidOperation:
        pass

    return _sin_acentos(texto).casefold()


def _normalizar_fila(fila: list) -> tuple:
    return tuple(_normalizar_celda(v) for v in fila)


def comparar(consigna: str, columnas: list[str], filas: list[list], tabla_esperada: dict | None) -> dict:
    if not tabla_esperada or not tabla_esperada.get("filas"):
        return {"veredicto": "no_comparable", "detalle": "Este ejercicio no tiene una tabla de resultado esperado."}

    filas_doc = tabla_esperada["filas"]
    if len(filas_doc) < 1:
        return {"veredicto": "no_comparable", "detalle": "Tabla esperada vacía."}

    encabezados_esperados = filas_doc[0]
    filas_esperadas_raw = filas_doc[1:]

    if not filas_esperadas_raw:
        return {
            "veredicto": "no_comparable",
            "detalle": "El docx sólo trae los encabezados esperados, no filas de datos.",
            "encabezados_esperados": encabezados_esperados,
        }

    obtenidas_norm = [_normalizar_fila(f) for f in filas]
    esperadas_norm = [_normalizar_fila(f) for f in filas_esperadas_raw]

    respeta_orden = bool(_RE_ORDENAR.search(consigna or ""))

    if respeta_orden:
        coincide_orden_exacto = obtenidas_norm == esperadas_norm
        coincide_como_conjunto = sorted(obtenidas_norm) == sorted(esperadas_norm)
    else:
        coincide_orden_exacto = None
        coincide_como_conjunto = sorted(obtenidas_norm) == sorted(esperadas_norm)

    # Emparejamos por índice (no sólo contamos) para poder mostrar, cuando
    # difiere, CUÁLES filas exactas sobran/faltan -- no sólo un número. El
    # docx suele traer pocas filas de ejemplo, así que un emparejamiento
    # O(n*m) por igualdad normalizada alcanza de sobra.
    usadas_esperadas = [False] * len(esperadas_norm)
    solo_obtenido_idx = []
    coincidentes = 0
    for i, on in enumerate(obtenidas_norm):
        encontrado = False
        for j, en in enumerate(esperadas_norm):
            if not usadas_esperadas[j] and en == on:
                usadas_esperadas[j] = True
                encontrado = True
                coincidentes += 1
                break
        if not encontrado:
            solo_obtenido_idx.append(i)
    solo_esperado_idx = [j for j, usada in enumerate(usadas_esperadas) if not usada]

    solo_esperado = len(solo_esperado_idx)
    solo_obtenido = len(solo_obtenido_idx)

    if respeta_orden and coincide_orden_exacto:
        veredicto = "coincide"
    elif coincide_como_conjunto:
        veredicto = "coincide_orden_distinto" if respeta_orden else "coincide"
    elif not solo_esperado and not solo_obtenido:
        veredicto = "coincide"
    else:
        veredicto = "difiere"

    TOPE = 50
    return {
        "veredicto": veredicto,
        "filas_esperadas": len(esperadas_norm),
        "filas_obtenidas": len(obtenidas_norm),
        "columnas_esperadas": len(encabezados_esperados),
        "columnas_obtenidas": len(columnas),
        "coincidentes": coincidentes,
        "solo_en_esperado": solo_esperado,
        "solo_en_obtenido": solo_obtenido,
        "encabezados_esperados": encabezados_esperados,
        "respeta_orden": respeta_orden,
        # Filas concretas (valores originales, sin normalizar) para que la UI
        # muestre qué difiere exactamente, no sólo cuántas filas.
        "filas_solo_en_esperado": [filas_esperadas_raw[j] for j in solo_esperado_idx[:TOPE]],
        "filas_solo_en_obtenido": [filas[i] for i in solo_obtenido_idx[:TOPE]],
        "truncado_diff": solo_esperado > TOPE or solo_obtenido > TOPE,
    }
