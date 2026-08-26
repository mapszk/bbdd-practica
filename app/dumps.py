"""Carga de los dumps .sql de las 3 bases de datos de práctica."""
from __future__ import annotations

import time
from dataclasses import dataclass, field
from pathlib import Path

import pymysql

from app import config
from app.splitter import dividir


@dataclass
class InformeCarga:
    base: str
    encoding_usado: str
    sentencias_ejecutadas: int
    tablas: int
    filas_totales: int
    advertencias: list[str] = field(default_factory=list)
    ms: int = 0


def _leer_con_deteccion(ruta: Path) -> tuple[str, str]:
    """UTF-8 estricto primero; si falla, cp1252. Determinista: los bytes
    sueltos de la tintorería (0xF3, 0xF1...) son UTF-8 inválido."""
    crudo = ruta.read_bytes()
    try:
        return crudo.decode("utf-8"), "utf-8"
    except UnicodeDecodeError:
        return crudo.decode("cp1252"), "cp1252"


def cargar_dump(ruta: Path, conexion: pymysql.connections.Connection) -> InformeCarga:
    inicio = time.time()
    texto, encoding_usado = _leer_con_deteccion(ruta)
    sentencias = dividir(texto)

    advertencias: list[str] = []
    ejecutadas = 0
    with conexion.cursor() as cur:
        for st in sentencias:
            if not st.texto.strip():
                continue
            try:
                cur.execute(st.texto)
                ejecutadas += 1
            except pymysql.err.Warning:
                pass
        conexion.commit()

        # Los dumps nunca restauran esto -- si no lo hacemos, los ejercicios
        # de integridad referencial de las Prácticas 8 y 9 "pasan" en falso.
        cur.execute("SET FOREIGN_KEY_CHECKS = 1")

        # nombre de la base creada = último USE/CREATE DATABASE en el texto
        base = _extraer_nombre_base(texto)
        cur.execute(f"USE `{base}`")
        cur.execute("SHOW TABLES")
        tablas = cur.fetchall()
        filas_totales = 0
        for (tabla,) in tablas:
            cur.execute(f"SELECT COUNT(*) FROM `{tabla}`")
            filas_totales += cur.fetchone()[0]

    return InformeCarga(
        base=base,
        encoding_usado=encoding_usado,
        sentencias_ejecutadas=ejecutadas,
        tablas=len(tablas),
        filas_totales=filas_totales,
        advertencias=advertencias,
        ms=int((time.time() - inicio) * 1000),
    )


def _extraer_nombre_base(texto: str) -> str:
    import re

    m = re.search(r"(?i)CREATE\s+DATABASE\s+`?(\w+)`?", texto)
    if not m:
        raise ValueError("El dump no contiene CREATE DATABASE")
    return m.group(1)


def cargar_todos(host: str, port: int, user: str = "root", password: str = "") -> dict[str, InformeCarga]:
    informes: dict[str, InformeCarga] = {}
    for clave, ruta in config.DUMPS.items():
        conn = pymysql.connect(
            host=host, port=port, user=user, password=password, charset="utf8mb4", autocommit=False
        )
        try:
            informe = cargar_dump(ruta, conn)
            informes[clave] = informe
        finally:
            conn.close()
    return informes


def reiniciar_base(clave: str, host: str, port: int, sesiones_vivas: list = None,
                    user: str = "root", password: str = "") -> InformeCarga:
    """Reinicializa una sola base desde su dump y reconecta el USE de las
    sesiones vivas -- DROP DATABASE deja el esquema actual en NULL en toda
    otra conexión que lo tuviera seleccionado."""
    ruta = config.DUMPS[clave]
    conn = pymysql.connect(host=host, port=port, user=user, password=password, charset="utf8mb4", autocommit=False)
    try:
        informe = cargar_dump(ruta, conn)
    finally:
        conn.close()

    if sesiones_vivas:
        for sesion in sesiones_vivas:
            try:
                if sesion.conn is not None and sesion.db == informe.base:
                    with sesion.conn.cursor() as cur:
                        cur.execute(f"USE `{informe.base}`")
            except Exception:
                pass
    return informe
