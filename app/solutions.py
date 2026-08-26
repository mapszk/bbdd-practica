"""Estado de las soluciones del alumno + generación de mis_soluciones.sql.

Fuente única de verdad: datos/soluciones.json. mis_soluciones.sql es un
artefacto derivado que se regenera ENTERO en cada guardado -- nunca se
appendea, que es como estos archivos terminan duplicados o pisados a
medias.
"""
from __future__ import annotations

import json
import os
import textwrap
import time
from pathlib import Path

from app import config


def _cargar() -> dict:
    if config.SOLUCIONES_JSON.exists():
        try:
            return json.loads(config.SOLUCIONES_JSON.read_text("utf-8"))
        except Exception:
            pass
    return {"version": 1, "actualizado": None, "soluciones": {}}


def _escribir_atomico(ruta: Path, contenido: bytes) -> None:
    tmp = ruta.with_suffix(ruta.suffix + ".tmp")
    tmp.write_bytes(contenido)
    for intento in range(5):
        try:
            os.replace(tmp, ruta)
            return
        except PermissionError:
            time.sleep(0.15 * (intento + 1))
    os.replace(tmp, ruta)  # último intento, deja propagar si falla


def obtener_todas() -> dict:
    return _cargar()


def _cargar_ideales() -> dict:
    """Soluciones "ideales" de referencia, redactadas y verificadas contra
    la base real (no las escribe el alumno). Archivo a mano, formato
    {ejercicio_id: {"sql": "...", "notas": "..."}}; si no existe todavía
    para un ejercicio, simplemente no hay entrada."""
    if config.SOLUCIONES_IDEALES_JSON.exists():
        try:
            return json.loads(config.SOLUCIONES_IDEALES_JSON.read_text("utf-8"))
        except Exception:
            pass
    return {}


def obtener_ideal(ejercicio_id: str) -> dict | None:
    return _cargar_ideales().get(ejercicio_id)


def guardar(ejercicio_id: str, sql: str, estado: str, notas: str = "", ultima_ejecucion: dict | None = None) -> dict:
    datos = _cargar()
    ahora = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    datos["soluciones"][ejercicio_id] = {
        "sql": sql,
        "estado": estado,
        "notas": notas,
        "actualizado": ahora,
        "ultima_ejecucion": ultima_ejecucion,
    }
    datos["actualizado"] = ahora
    _escribir_atomico(config.SOLUCIONES_JSON, json.dumps(datos, ensure_ascii=False, indent=2).encode("utf-8"))
    return datos["soluciones"][ejercicio_id]


def exportar_sql(ejercicios_por_practica: list[dict]) -> Path:
    """Regenera mis_soluciones.sql completo, con TODOS los ejercicios
    (resueltos y sin resolver), agrupados por práctica."""
    soluciones = _cargar()["soluciones"]
    total = sum(len(p["ejercicios"]) for p in ejercicios_por_practica)
    resueltos = sum(1 for v in soluciones.values() if v.get("estado") == "resuelto")

    lineas: list[str] = []
    lineas.append("-- " + "=" * 60)
    lineas.append("--  MIS SOLUCIONES - Práctica de Bases de Datos")
    lineas.append(f"--  Generado por Práctica SQL el {time.strftime('%Y-%m-%d %H:%M')}")
    lineas.append("--  ARCHIVO GENERADO: no editar a mano, se sobrescribe.")
    lineas.append(f"--  Resueltos: {resueltos}/{total}")
    lineas.append("-- " + "=" * 60)
    lineas.append("")

    for practica in ejercicios_por_practica:
        lineas.append("-- " + "#" * 60)
        lineas.append(f"-- #  PRÁCTICA {practica['numero']} - {practica['titulo']}")
        bases = sorted({e.get("base_datos") for e in practica["ejercicios"] if e.get("base_datos")})
        if bases:
            lineas.append(f"-- #  BASE DE DATOS: {', '.join(bases)}")
        lineas.append(f"-- #  ({len(practica['ejercicios'])} ejercicios)")
        lineas.append("-- " + "#" * 60)
        if bases:
            lineas.append(f"USE {bases[0].lower()};")
        lineas.append("")

        for ej in practica["ejercicios"]:
            lineas.append("-- " + "-" * 60)
            consigna_env = textwrap.wrap(ej["consigna"] or "(sin consigna)", width=95) or ["(sin consigna)"]
            lineas.append(f"-- {practica['numero']}.{ej['numero']}) {consigna_env[0]}")
            for extra in consigna_env[1:]:
                lineas.append(f"--      {extra}")
            for sp in ej.get("subpasos", []):
                for i, linea_sp in enumerate(textwrap.wrap(sp["texto"], width=90) or [""]):
                    prefijo = f"--   {sp['letra']}. " if i == 0 else "--      "
                    lineas.append(prefijo + linea_sp)
            lineas.append("-- " + "-" * 60)

            sol = soluciones.get(ej["id"])
            if sol and sol.get("sql", "").strip():
                lineas.append(sol["sql"].rstrip())
            else:
                lineas.append("-- (sin resolver)")
            lineas.append("")

    contenido = "\r\n".join(lineas) + "\r\n"
    payload = b"\xef\xbb\xbf" + contenido.encode("utf-8")  # BOM para Notepad/Workbench
    _escribir_atomico(config.MIS_SOLUCIONES_SQL, payload)
    return config.MIS_SOLUCIONES_SQL
