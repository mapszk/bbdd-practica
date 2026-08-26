"""Sesiones nombradas de MySQL: principal, secundaria, usuario, y admin
(oculta, sólo para KILL QUERY). Ver plan §D.

El estado transaccional se lee siempre del protocolo (server_status),
nunca se infiere parseando el SQL del alumno -- así no se pierden los
starts implícitos, `SET autocommit=0`, ni los commits implícitos de DDL.
"""
from __future__ import annotations

import threading
import time
from dataclasses import dataclass, field
from typing import Optional

import pymysql
from pymysql.constants import SERVER_STATUS

from app import config

NOMBRES_SLOTS = ("principal", "secundaria", "usuario")


@dataclass
class Sesion:
    nombre: str
    conn: Optional[pymysql.connections.Connection] = None
    usuario: str = "root"
    password: str = ""
    db: Optional[str] = None
    connection_id: Optional[int] = None
    en_transaccion: bool = False
    autocommit: bool = True
    only_full_group_by: bool = False
    ocupada: bool = False
    caida: bool = False
    ultimo_uso: float = field(default_factory=time.time)
    lock: threading.RLock = field(default_factory=threading.RLock)

    def estado_publico(self) -> dict:
        return {
            "nombre": self.nombre,
            "conectada": self.conn is not None and not self.caida,
            "usuario": self.usuario,
            "db": self.db,
            "connection_id": self.connection_id,
            "en_transaccion": self.en_transaccion,
            "autocommit": self.autocommit,
            "only_full_group_by": self.only_full_group_by,
            "ocupada": self.ocupada,
            "caida": self.caida,
        }


class GestorSesiones:
    def __init__(self) -> None:
        self.sesiones: dict[str, Sesion] = {n: Sesion(nombre=n) for n in NOMBRES_SLOTS}
        self._admin: Optional[pymysql.connections.Connection] = None
        self._stop = threading.Event()
        self._hilo_keepalive: Optional[threading.Thread] = None

    # ------------------------------------------------------------------ #
    def conectar(self, nombre: str, usuario: str = "root", password: str = "", db: Optional[str] = None) -> Sesion:
        sesion = self.sesiones[nombre]
        with sesion.lock:
            if sesion.conn is not None:
                try:
                    sesion.conn.close()
                except Exception:
                    pass
            sesion.conn = pymysql.connect(
                host=config.MYSQL_HOST,
                port=config.MYSQL_PORT,
                user=usuario,
                password=password,
                database=db,
                charset="utf8mb4",
                autocommit=True,
                client_flag=0,
            )
            sesion.usuario = usuario
            sesion.password = password
            sesion.db = db
            sesion.caida = False
            with sesion.conn.cursor() as cur:
                cur.execute("SELECT CONNECTION_ID()")
                (sesion.connection_id,) = cur.fetchone()
                cur.execute("SET SESSION MAX_EXECUTION_TIME = 15000")
            self._actualizar_estado_tx(sesion)
        return sesion

    def desconectar(self, nombre: str) -> None:
        sesion = self.sesiones[nombre]
        with sesion.lock:
            if sesion.conn is not None:
                try:
                    sesion.conn.close()
                except Exception:
                    pass
            sesion.conn = None
            sesion.db = None
            sesion.en_transaccion = False

    def asegurar_conectada(self, nombre: str) -> Sesion:
        sesion = self.sesiones[nombre]
        if sesion.conn is None:
            self.conectar(nombre)
        return sesion

    def admin_conn(self) -> pymysql.connections.Connection:
        if self._admin is None:
            self._admin = pymysql.connect(
                host=config.MYSQL_HOST,
                port=config.MYSQL_PORT,
                user="root",
                password="",
                charset="utf8mb4",
                autocommit=True,
            )
        else:
            try:
                self._admin.ping(reconnect=True)
            except Exception:
                self._admin = pymysql.connect(
                    host=config.MYSQL_HOST,
                    port=config.MYSQL_PORT,
                    user="root",
                    password="",
                    charset="utf8mb4",
                    autocommit=True,
                )
        return self._admin

    # ------------------------------------------------------------------ #
    def _actualizar_estado_tx(self, sesion: Sesion) -> None:
        if sesion.conn is None:
            return
        status = sesion.conn.server_status
        sesion.en_transaccion = bool(status & SERVER_STATUS.SERVER_STATUS_IN_TRANS)
        sesion.autocommit = bool(status & SERVER_STATUS.SERVER_STATUS_AUTOCOMMIT)

    def refrescar_estado(self, nombre: str) -> Sesion:
        sesion = self.sesiones[nombre]
        self._actualizar_estado_tx(sesion)
        return sesion

    # ------------------------------------------------------------------ #
    def cancelar(self, nombre: str) -> bool:
        sesion = self.sesiones[nombre]
        if sesion.connection_id is None:
            return False
        try:
            with self.admin_conn().cursor() as cur:
                cur.execute(f"KILL QUERY {sesion.connection_id}")
            return True
        except Exception:
            return False

    def commit(self, nombre: str) -> None:
        sesion = self.sesiones[nombre]
        with sesion.lock:
            if sesion.conn is not None:
                sesion.conn.commit()
                self._actualizar_estado_tx(sesion)

    def rollback(self, nombre: str) -> None:
        sesion = self.sesiones[nombre]
        with sesion.lock:
            if sesion.conn is not None:
                sesion.conn.rollback()
                self._actualizar_estado_tx(sesion)

    def set_sql_mode_group_by(self, nombre: str, activar: bool) -> None:
        sesion = self.sesiones[nombre]
        with sesion.lock:
            if sesion.conn is None:
                return
            with sesion.conn.cursor() as cur:
                if activar:
                    cur.execute("SET SESSION sql_mode = CONCAT(@@sql_mode, ',ONLY_FULL_GROUP_BY')")
                else:
                    cur.execute(
                        "SET SESSION sql_mode = REPLACE(@@sql_mode, ',ONLY_FULL_GROUP_BY', '')"
                    )
            sesion.only_full_group_by = activar

    def reconectar_si_hace_falta(self, nombre: str) -> None:
        """Tras GRANT/REVOKE los privilegios globales sólo aplican a
        conexiones nuevas -- reconectar para que el alumno vea el efecto
        real, no el estado viejo de la sesión."""
        sesion = self.sesiones[nombre]
        if sesion.conn is None or sesion.usuario == "root":
            return
        self.conectar(nombre, usuario=sesion.usuario, password=sesion.password, db=sesion.db)

    def estado_todas(self) -> dict:
        return {n: s.estado_publico() for n, s in self.sesiones.items()}

    # ------------------------------------------------------------------ #
    # Keepalive
    # ------------------------------------------------------------------ #
    def iniciar_keepalive(self) -> None:
        if self._hilo_keepalive is not None:
            return
        self._hilo_keepalive = threading.Thread(target=self._loop_keepalive, daemon=True)
        self._hilo_keepalive.start()

    def detener_keepalive(self) -> None:
        self._stop.set()

    def _loop_keepalive(self) -> None:
        while not self._stop.wait(30):
            for sesion in self.sesiones.values():
                if sesion.conn is None or sesion.ocupada:
                    continue
                if not sesion.lock.acquire(blocking=False):
                    continue
                try:
                    # Nunca reconnect=True: eso hace ROLLBACK silencioso de
                    # una transacción abierta y arruina la Práctica 11.
                    sesion.conn.ping(reconnect=False)
                except Exception:
                    if sesion.en_transaccion:
                        sesion.caida = True
                finally:
                    sesion.lock.release()


gestor_sesiones = GestorSesiones()
