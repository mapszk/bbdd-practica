"""Divide un script SQL en sentencias individuales, respetando DELIMITER.

Máquina de estados a nivel carácter. Reglas no obvias (cada una es un bug
real si se omite):

1. `--` sólo abre comentario de línea si le sigue espacio/tab/fin de línea.
   `5--3` es `5 - (-3)`, no un comentario. Es una regla propia de MySQL.
2. El delimitador vigente se chequea ANTES que los casos de un solo
   carácter: con DELIMITER $$, un ';' dentro del cuerpo de una rutina es
   un carácter común.
3. DELIMITER es una directiva de CLIENTE: se reconoce al inicio de línea
   (en un punto donde no estamos dentro de una sentencia) y nunca se
   manda al servidor.
4. No se trackea BEGIN/END: alcanza con respetar DELIMITER, y BEGIN/END
   aparecen también en transacciones, CASE, IF, LOOP, REPEAT.
5. No se eliminan comentarios: se preserva el texto original de cada
   sentencia tal cual, para que los mensajes de error del servidor sigan
   siendo interpretables.
"""
from __future__ import annotations

import re
from dataclasses import dataclass

_RE_DELIMITER = re.compile(r"(?im)^[ \t]*delimiter[ \t]+(\S+)[ \t]*\r?\n?")
_RE_CREATE_ROUTINE = re.compile(
    r"(?is)^\s*create\s+(definer\s*=\s*\S+\s+)?(procedure|function|trigger|event)\b"
)


@dataclass
class Sentencia:
    texto: str
    linea: int  # 1-indexed, línea de inicio en el texto original
    columna: int


def _contar_lineas_columnas(texto: str, hasta: int) -> tuple[int, int]:
    fragmento = texto[:hasta]
    linea = fragmento.count("\n") + 1
    ultimo_salto = fragmento.rfind("\n")
    columna = hasta - ultimo_salto if ultimo_salto >= 0 else hasta + 1
    return linea, columna


def dividir(texto: str) -> list[Sentencia]:
    """Divide `texto` en sentencias, respetando comillas, comentarios y DELIMITER."""
    resultado: list[Sentencia] = []
    delim = ";"
    i = 0
    n = len(texto)
    start = 0
    estado = "NORMAL"  # NORMAL, SQ, DQ, BT, HASH, DASH, BLOCK
    en_inicio_sentencia = True

    def emitir(fin: int) -> None:
        crudo = texto[start:fin]
        if crudo.strip():
            linea, col = _contar_lineas_columnas(texto, start)
            resultado.append(Sentencia(texto=crudo.strip("\r\n"), linea=linea, columna=col))

    while i < n:
        c = texto[i]

        if estado == "NORMAL":
            if en_inicio_sentencia:
                m = _RE_DELIMITER.match(texto, i)
                if m:
                    delim = m.group(1)
                    i = m.end()
                    start = i
                    continue

            if texto.startswith(delim, i):
                emitir(i)
                i += len(delim)
                start = i
                en_inicio_sentencia = True
                continue

            if c in " \t\r\n":
                i += 1
                continue

            en_inicio_sentencia = False

            if c == "'":
                estado = "SQ"
            elif c == '"':
                estado = "DQ"
            elif c == "`":
                estado = "BT"
            elif c == "#":
                estado = "HASH"
            elif c == "-" and texto[i + 1 : i + 2] == "-" and texto[i + 2 : i + 3] in ("", " ", "\t", "\r", "\n"):
                estado = "DASH"
            elif c == "/" and texto[i + 1 : i + 2] == "*":
                estado = "BLOCK"
                i += 1

        elif estado in ("SQ", "DQ", "BT"):
            q = {"SQ": "'", "DQ": '"', "BT": "`"}[estado]
            if estado != "BT" and c == "\\":
                i += 2
                continue
            if c == q:
                if texto[i + 1 : i + 2] == q:
                    i += 2
                    continue
                estado = "NORMAL"

        elif estado in ("HASH", "DASH"):
            if c == "\n":
                estado = "NORMAL"

        elif estado == "BLOCK":
            if c == "*" and texto[i + 1 : i + 2] == "/":
                estado = "NORMAL"
                i += 1

        i += 1

    emitir(n)
    return resultado


def dividir_con_rescate(texto: str) -> tuple[list[Sentencia], bool]:
    """Como `dividir`, pero si detecta una rutina (CREATE PROCEDURE/FUNCTION/
    TRIGGER/EVENT) partida en varios trozos por falta de un DELIMITER, junta
    todo en una sola sentencia y avisa mediante el segundo valor de retorno.
    """
    sentencias = dividir(texto)
    if len(sentencias) <= 1:
        return sentencias, False
    if _RE_DELIMITER.search(texto):
        return sentencias, False
    if not _RE_CREATE_ROUTINE.match(sentencias[0].texto):
        return sentencias, False

    completa = Sentencia(texto=texto.strip(), linea=1, columna=1)
    return [completa], True
