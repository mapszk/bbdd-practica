"""Extrae los 132 ejercicios del docx de la cátedra a datos/ejercicios.json.

Reglas validadas contra el documento real (ver el plan en
C:\\Users\\marti\\.claude\\plans\\planifica-la-implementacion-de-misty-heron.md):

- Encabezado de práctica: párrafo cuyo texto matchea
  ``^\\s*Pr[áa]ctic[ao]\\s*(N|\\d)`` -- NO el formato (negrita/subrayado/28pt
  da falsos positivos, p.ej. "Si se desea eliminar un SAVEPOINT...").
- "BASE DE DATOS: X": matchear el texto literal, no el formato (un
  marcador no está en negrita).
- Un ejercicio nuevo empieza cuando:
    (a) el párrafo tiene w:pPr/w:numPr con ilvl=0 y numFmt != bullet
        (incluye párrafos vacíos: son marcadores reales en Prácticas 11/13), o
    (b) el texto matchea a mano ``^\\s*\\d{1,2}\\s*\\)`` sin numPr.
  La numeración final es la POSICIÓN dentro de la práctica (1..N), no el
  valor mostrado por Word -- los `w:start` de Word (13, 3) sólo existen
  para que la numeración visual siga después de un tramo tipeado a mano;
  como nosotros contamos por posición de aparición, no hace falta
  replicarlos.
- Un párrafo con numPr e ilvl>=1 es un sub-paso (a, b, c...) del ejercicio
  actual.
- numId=12 es una lista de viñetas (numFmt=bullet): NO es un ejercicio
  nuevo, se agrega como línea extra a la consigna actual.
- Sólo se recorren los w:p que son hijos directos de w:body (8 numPr viven
  dentro de celdas de tabla y deben ignorarse).
"""
from __future__ import annotations

import json
import re
import sys
import zipfile
from dataclasses import asdict, dataclass, field
from pathlib import Path

from lxml import etree

from app import config

NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}


def qn(tag: str) -> str:
    prefix, local = tag.split(":")
    return f"{{{NS[prefix]}}}{local}"


RE_PRACTICA = re.compile(r"^\s*Pr[áa]ctic[ao]\s*(N|\d)", re.IGNORECASE)
RE_BASE_DATOS = re.compile(r"^\s*BASE\s+DE\s+DATOS\s*:\s*(.+)$", re.IGNORECASE)
RE_HAND_TYPED = re.compile(r"^\s*(\d{1,2})\s*\)\s*(.*)$", re.DOTALL)
RE_ERROR_SALIDA = re.compile(r"(?i)^\s*error en la salida\s*$")
RE_DESCRIBE_HEADER = re.compile(r"(?i)^field$")

SUBHEADERS_CONOCIDOS = {
    "INNER JOIN", "LEFT/RIGHT JOIN", "SELF JOIN",
    "INSERT VALUES", "UPDATE", "DELETE",
    "INSERT SELECT", "UDATE con JOIN", "DELETE con JOIN",
}

VW_CONTRATOS_HINT = (
    "-- El enunciado usa `vw_contratos` pero el documento nunca la define.\n"
    "-- Sugerencia (columnas de contratos sin sueldo/comisión):\n"
    "CREATE VIEW vw_contratos AS\n"
    "SELECT nro_contrato, dni, cuit, cod_cargo, fecha_solicitud,\n"
    "       fecha_incorporacion, fecha_finalizacion_contrato, fecha_caducidad\n"
    "FROM contratos;"
)

VECTOR_ESPERADO = [14, 16, 5, 15, 17, 4, 5, 13, 7, 7, 13, 12, 4]

# El docx trae 2 palabras con mojibake de origen (alguien pegó texto UTF-8
# interpretado como cp1252 y Word se comió el byte de continuación al
# guardar -- no es un problema de nuestra lectura, el XML interno del docx
# es UTF-8 válido). Sólo afecta datos de ejemplo en tablas, nunca consignas.
# Corrección puntual en vez de heurística: evita adivinar sobre texto sano.
MOJIBAKE_FIXES = {
    "DiseÃ±ador de Interiores": "Diseñador de Interiores",
    "Lopez StefanÃa": "Lopez Stefanía",
    "StefanÃa Lopez": "Stefanía Lopez",
    "StefanÃa": "Stefanía",
}


def _reparar_mojibake(texto: str) -> str:
    for roto, sano in MOJIBAKE_FIXES.items():
        if roto in texto:
            texto = texto.replace(roto, sano)
    return texto


@dataclass
class Subpaso:
    letra: str
    texto: str = ""


@dataclass
class Tabla:
    tipo: str  # "resultado" | "encabezados" | "describe" | "entrada"
    filas: list[list[str]] = field(default_factory=list)


@dataclass
class Ejercicio:
    numero: int
    consigna: str = ""
    seccion: str | None = None
    base_datos: str | None = None
    subpasos: list[Subpaso] = field(default_factory=list)
    tablas: list[Tabla] = field(default_factory=list)
    tabla_esperada: Tabla | None = None
    flags: dict = field(default_factory=dict)
    ayuda: str | None = None


@dataclass
class Practica:
    numero: int
    titulo: str
    preambulo: list[str] = field(default_factory=list)
    ejercicios: list[Ejercicio] = field(default_factory=list)


def _texto_parrafo(p) -> str:
    return _reparar_mojibake("".join(t.text or "" for t in p.iter(qn("w:t"))))


def _numpr(p) -> tuple[int | None, int | None]:
    """Devuelve (numId, ilvl) del numPr DIRECTO de este párrafo, o (None, None)."""
    ppr = p.find(qn("w:pPr"))
    if ppr is None:
        return None, None
    numpr = ppr.find(qn("w:numPr"))
    if numpr is None:
        return None, None
    ilvl_el = numpr.find(qn("w:ilvl"))
    numid_el = numpr.find(qn("w:numId"))
    ilvl = int(ilvl_el.get(qn("w:val"))) if ilvl_el is not None else 0
    numid = int(numid_el.get(qn("w:val"))) if numid_el is not None else None
    return numid, ilvl


def _cargar_numeracion(zf: zipfile.ZipFile) -> dict[int, dict[int, str]]:
    """numId -> {ilvl: numFmt}, sólo lo que necesitamos para excluir viñetas."""
    data = zf.read("word/numbering.xml")
    root = etree.fromstring(data)

    num_a_abstract: dict[int, int] = {}
    for num in root.findall(qn("w:num")):
        numid = int(num.get(qn("w:numId")))
        abst = num.find(qn("w:abstractNumId"))
        num_a_abstract[numid] = int(abst.get(qn("w:val")))

    abstract_fmt: dict[int, dict[int, str]] = {}
    for absnum in root.findall(qn("w:abstractNum")):
        aid = int(absnum.get(qn("w:abstractNumId")))
        niveles = {}
        for lvl in absnum.findall(qn("w:lvl")):
            ilvl = int(lvl.get(qn("w:ilvl")))
            fmt_el = lvl.find(qn("w:numFmt"))
            niveles[ilvl] = fmt_el.get(qn("w:val")) if fmt_el is not None else "decimal"
        abstract_fmt[aid] = niveles

    return {
        numid: abstract_fmt.get(aid, {})
        for numid, aid in num_a_abstract.items()
    }


def _parsear_tabla(tbl) -> Tabla:
    filas = []
    for tr in tbl.findall(qn("w:tr")):
        celdas = []
        for tc in tr.findall(qn("w:tc")):
            texto = "".join(t.text or "" for t in tc.iter(qn("w:t")))
            celdas.append(_reparar_mojibake(texto).strip())
        filas.append(celdas)
    return Tabla(tipo="resultado", filas=filas)


def _clasificar_tablas(tablas: list[Tabla]) -> tuple[list[Tabla], Tabla | None]:
    if not tablas:
        return [], None
    if len(tablas) == 1:
        tablas[0].tipo = "resultado"
        return tablas, tablas[0]
    if len(tablas) == 3:
        for t in tablas:
            t.tipo = "entrada"
        return tablas, None
    # len == 2
    primera = tablas[0]
    if primera.filas and primera.filas[0] and RE_DESCRIBE_HEADER.match(
        primera.filas[0][0] if primera.filas[0] else ""
    ):
        primera.tipo = "describe"
    else:
        primera.tipo = "encabezados"
    tablas[1].tipo = "resultado"
    return tablas, tablas[1]


def parsear_docx(ruta: Path) -> list[Practica]:
    with zipfile.ZipFile(ruta) as zf:
        numeracion = _cargar_numeracion(zf)
        doc = etree.fromstring(zf.read("word/document.xml"))

    body = doc.find(qn("w:body"))

    practicas: list[Practica] = []
    practica_actual: Practica | None = None
    ejercicio_actual: Ejercicio | None = None
    subpaso_actual: Subpaso | None = None
    base_actual: str | None = None
    seccion_actual: str | None = None
    contador_ejercicio = 0
    tablas_pendientes: list[Tabla] = []

    def cerrar_ejercicio():
        nonlocal ejercicio_actual, tablas_pendientes
        if ejercicio_actual is not None and tablas_pendientes:
            clasificadas, esperada = _clasificar_tablas(tablas_pendientes)
            ejercicio_actual.tablas = clasificadas
            ejercicio_actual.tabla_esperada = esperada
        tablas_pendientes = []

    for child in body:
        tag = etree.QName(child).localname

        if tag == "tbl":
            tablas_pendientes.append(_parsear_tabla(child))
            continue

        if tag != "p":
            continue

        texto = _texto_parrafo(child).strip()
        numid, ilvl = _numpr(child)

        if RE_PRACTICA.match(texto):
            cerrar_ejercicio()
            contador_ejercicio = 0
            base_actual = None
            seccion_actual = None
            ejercicio_actual = None
            subpaso_actual = None
            practica_actual = Practica(numero=len(practicas) + 1, titulo=texto)
            practicas.append(practica_actual)
            continue

        if practica_actual is None:
            continue  # texto antes de la primera práctica (portada)

        m_base = RE_BASE_DATOS.match(texto)
        if m_base:
            base_actual = m_base.group(1).strip().rstrip(".")
            continue

        if texto in SUBHEADERS_CONOCIDOS:
            seccion_actual = texto
            continue

        es_bullet = numid is not None and numeracion.get(numid, {}).get(0) == "bullet"

        es_item_numerado = (
            numid is not None and ilvl == 0 and not es_bullet
        )
        m_hand = RE_HAND_TYPED.match(texto) if numid is None else None

        if es_item_numerado or m_hand:
            cerrar_ejercicio()
            contador_ejercicio += 1
            consigna_inicial = m_hand.group(2).strip() if m_hand else texto
            ejercicio_actual = Ejercicio(
                numero=contador_ejercicio,
                consigna=consigna_inicial,
                seccion=seccion_actual,
                base_datos=base_actual,
            )
            practica_actual.ejercicios.append(ejercicio_actual)
            subpaso_actual = None
            continue

        if ejercicio_actual is None:
            if texto:
                practica_actual.preambulo.append(texto)
            continue

        if numid is not None and ilvl >= 1 and not es_bullet:
            letra = chr(ord("a") + len(ejercicio_actual.subpasos))
            subpaso_actual = Subpaso(letra=letra, texto=texto)
            ejercicio_actual.subpasos.append(subpaso_actual)
            continue

        if es_bullet:
            ejercicio_actual.consigna += f"\n- {texto}"
            continue

        if RE_ERROR_SALIDA.match(texto):
            ejercicio_actual.flags["error_en_salida"] = True
            continue

        if not texto:
            continue

        # Texto libre: continuación del sub-paso abierto, o de la consigna.
        if subpaso_actual is not None:
            subpaso_actual.texto += ("\n" if subpaso_actual.texto else "") + texto
        else:
            ejercicio_actual.consigna += ("\n" if ejercicio_actual.consigna else "") + texto

    cerrar_ejercicio()

    # Ayuda puntual: vw_contratos no está definida en ningún lado del docx.
    for practica in practicas:
        for ej in practica.ejercicios:
            if "vw_contratos" in ej.consigna and not ej.ayuda:
                ej.ayuda = VW_CONTRATOS_HINT

    return practicas


def a_json(practicas: list[Practica]) -> dict:
    return {
        "practicas": [
            {
                "numero": p.numero,
                "titulo": p.titulo,
                "preambulo": p.preambulo,
                "ejercicios": [
                    {
                        "id": f"p{p.numero}e{e.numero}",
                        "numero": e.numero,
                        "consigna": e.consigna,
                        "seccion": e.seccion,
                        "base_datos": e.base_datos,
                        "subpasos": [asdict(s) for s in e.subpasos],
                        "tablas": [asdict(t) for t in e.tablas],
                        "tabla_esperada": asdict(e.tabla_esperada) if e.tabla_esperada else None,
                        "flags": e.flags,
                        "ayuda": e.ayuda,
                    }
                    for e in p.ejercicios
                ],
            }
            for p in practicas
        ]
    }


def generar(ruta_docx: Path = config.DOCX_PATH, ruta_salida: Path = config.EJERCICIOS_JSON) -> dict:
    practicas = parsear_docx(ruta_docx)
    datos = a_json(practicas)
    ruta_salida.parent.mkdir(parents=True, exist_ok=True)
    ruta_salida.write_text(json.dumps(datos, ensure_ascii=False, indent=2), encoding="utf-8")
    return datos


def validar(datos: dict) -> bool:
    vector = [len(p["ejercicios"]) for p in datos["practicas"]]
    total = sum(vector)
    ok = vector == VECTOR_ESPERADO and total == 132
    print(f"Prácticas: {len(datos['practicas'])}")
    print(f"Vector de ejercicios: {vector}")
    print(f"Esperado:              {VECTOR_ESPERADO}")
    print(f"Total: {total} (esperado 132)")
    print("VALIDACIÓN:", "OK" if ok else "FALLÓ")
    if not ok:
        for i, (real, esperado) in enumerate(zip(vector, VECTOR_ESPERADO), start=1):
            if real != esperado:
                print(f"  Práctica {i}: {real} != {esperado}")
    return ok


if __name__ == "__main__":
    datos = generar()
    if "--validate" in sys.argv:
        ok = validar(datos)
        sys.exit(0 if ok else 1)
    print(f"Generado {config.EJERCICIOS_JSON} con {sum(len(p['ejercicios']) for p in datos['practicas'])} ejercicios.")
