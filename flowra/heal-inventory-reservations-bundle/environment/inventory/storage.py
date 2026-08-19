"""SQLite persistence for inventory reservations."""

from __future__ import annotations

import sqlite3
import uuid
from datetime import datetime, timezone
from typing import Iterable

from inventory.models import Product, Reservation, ReservationStatus


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _parse_ts(value: str) -> datetime:
    dt = datetime.fromisoformat(value)
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


class SQLiteStorage:
    """Simple SQLite backend for products and reservations."""

    def __init__(self, path: str = ":memory:") -> None:
        self._path = path
        self._conn = sqlite3.connect(path, check_same_thread=False)
        self._conn.row_factory = sqlite3.Row
        self._init_schema()

    def _init_schema(self) -> None:
        self._conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS products (
                sku TEXT PRIMARY KEY,
                on_hand INTEGER NOT NULL CHECK(on_hand >= 0)
            );

            CREATE TABLE IF NOT EXISTS reservations (
                id TEXT PRIMARY KEY,
                sku TEXT NOT NULL,
                qty INTEGER NOT NULL CHECK(qty > 0),
                status TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                created_at TEXT NOT NULL,
                FOREIGN KEY (sku) REFERENCES products(sku)
            );

            CREATE INDEX IF NOT EXISTS idx_reservations_sku_status
                ON reservations(sku, status);
            """
        )
        self._conn.commit()

    def close(self) -> None:
        self._conn.close()

    def seed_product(self, sku: str, on_hand: int, *, commit: bool = True) -> None:
        self._conn.execute(
            "INSERT OR REPLACE INTO products (sku, on_hand) VALUES (?, ?)",
            (sku, on_hand),
        )
        if commit:
            self._conn.commit()

    def get_product(self, sku: str) -> Product | None:
        row = self._conn.execute(
            "SELECT sku, on_hand FROM products WHERE sku = ?",
            (sku,),
        ).fetchone()
        if row is None:
            return None
        return Product(sku=row["sku"], on_hand=row["on_hand"])

    def set_on_hand(self, sku: str, on_hand: int, *, commit: bool = True) -> None:
        self._conn.execute(
            "UPDATE products SET on_hand = ? WHERE sku = ?",
            (on_hand, sku),
        )
        if commit:
            self._conn.commit()

    def create_reservation(
        self,
        sku: str,
        qty: int,
        expires_at: datetime,
        *,
        commit: bool = True,
    ) -> Reservation:
        reservation_id = str(uuid.uuid4())
        created_at = _utcnow()
        self._conn.execute(
            """
            INSERT INTO reservations (id, sku, qty, status, expires_at, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                reservation_id,
                sku,
                qty,
                ReservationStatus.PENDING.value,
                expires_at.astimezone(timezone.utc).isoformat(),
                created_at.isoformat(),
            ),
        )
        if commit:
            self._conn.commit()
        return Reservation(
            id=reservation_id,
            sku=sku,
            qty=qty,
            status=ReservationStatus.PENDING,
            expires_at=expires_at.astimezone(timezone.utc),
            created_at=created_at,
        )

    def get_reservation(self, reservation_id: str) -> Reservation | None:
        row = self._conn.execute(
            """
            SELECT id, sku, qty, status, expires_at, created_at
            FROM reservations WHERE id = ?
            """,
            (reservation_id,),
        ).fetchone()
        if row is None:
            return None
        return Reservation(
            id=row["id"],
            sku=row["sku"],
            qty=row["qty"],
            status=ReservationStatus(row["status"]),
            expires_at=_parse_ts(row["expires_at"]),
            created_at=_parse_ts(row["created_at"]),
        )

    def update_reservation_status(
        self,
        reservation_id: str,
        status: ReservationStatus,
        *,
        commit: bool = True,
    ) -> None:
        self._conn.execute(
            "UPDATE reservations SET status = ? WHERE id = ?",
            (status.value, reservation_id),
        )
        if commit:
            self._conn.commit()

    def list_reservations(
        self,
        sku: str | None = None,
        statuses: Iterable[ReservationStatus] | None = None,
    ) -> list[Reservation]:
        clauses: list[str] = []
        params: list[object] = []
        if sku is not None:
            clauses.append("sku = ?")
            params.append(sku)
        if statuses is not None:
            status_values = [s.value for s in statuses]
            placeholders = ",".join("?" for _ in status_values)
            clauses.append(f"status IN ({placeholders})")
            params.extend(status_values)
        where = f"WHERE {' AND '.join(clauses)}" if clauses else ""
        rows = self._conn.execute(
            f"""
            SELECT id, sku, qty, status, expires_at, created_at
            FROM reservations {where}
            ORDER BY created_at ASC
            """,
            params,
        ).fetchall()
        return [
            Reservation(
                id=row["id"],
                sku=row["sku"],
                qty=row["qty"],
                status=ReservationStatus(row["status"]),
                expires_at=_parse_ts(row["expires_at"]),
                created_at=_parse_ts(row["created_at"]),
            )
            for row in rows
        ]

    def begin_immediate(self) -> None:
        self._conn.execute("BEGIN IMMEDIATE")

    def commit_tx(self) -> None:
        self._conn.commit()

    def rollback_tx(self) -> None:
        self._conn.rollback()
