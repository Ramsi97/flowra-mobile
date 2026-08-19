"""
Inventory reservation service — BUGGY VERSION.

This module intentionally contains subtle defects introduced during a rushed
refactor. The reference solution replaces this file entirely.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from inventory.models import (
    InsufficientStockError,
    InvalidTransitionError,
    NotFoundError,
    ReservationStatus,
)
from inventory.storage import SQLiteStorage


class InventoryService:
    """Coordinate reservations against physical stock."""

    def __init__(self, storage: SQLiteStorage) -> None:
        self._storage = storage

    def seed(self, sku: str, on_hand: int) -> None:
        self._storage.seed_product(sku, on_hand)

    def available(self, sku: str) -> int:
        product = self._storage.get_product(sku)
        if product is None:
            return 0

        # BUG 1: only counts committed reservations, ignoring pending holds
        committed_qty = sum(
            r.qty
            for r in self._storage.list_reservations(
                sku=sku, statuses=[ReservationStatus.COMMITTED]
            )
        )
        return max(product.on_hand - committed_qty, 0)

    def reserve(self, sku: str, qty: int, ttl_seconds: int = 900) -> str:
        if qty <= 0:
            raise ValueError("qty must be positive")

        # BUG 2: no transactional locking — concurrent calls can oversell
        if self.available(sku) < qty:
            raise InsufficientStockError(
                f"cannot reserve {qty} of {sku}; only {self.available(sku)} available"
            )

        expires_at = datetime.now(timezone.utc) + timedelta(seconds=ttl_seconds)
        reservation = self._storage.create_reservation(sku, qty, expires_at)
        return reservation.id

    def commit(self, reservation_id: str) -> None:
        reservation = self._storage.get_reservation(reservation_id)
        if reservation is None:
            raise NotFoundError(f"reservation {reservation_id} not found")

        # BUG 3: missing pending-state guard — double commit deducts stock twice
        product = self._storage.get_product(reservation.sku)
        if product is None:
            raise NotFoundError(f"product {reservation.sku} not found")

        new_on_hand = product.on_hand - reservation.qty
        if new_on_hand < 0:
            raise InsufficientStockError("commit would drive on_hand negative")

        self._storage.set_on_hand(reservation.sku, new_on_hand)
        self._storage.update_reservation_status(
            reservation_id, ReservationStatus.COMMITTED
        )

    def release(self, reservation_id: str) -> None:
        reservation = self._storage.get_reservation(reservation_id)
        if reservation is None:
            raise NotFoundError(f"reservation {reservation_id} not found")

        if reservation.status != ReservationStatus.PENDING:
            raise InvalidTransitionError(
                f"cannot release reservation in state {reservation.status.value}"
            )

        self._storage.update_reservation_status(
            reservation_id, ReservationStatus.RELEASED
        )

    def expire_stale(self) -> int:
        # BUG 4: compares against naive local time instead of UTC-aware now
        now = datetime.now()
        expired = 0
        for reservation in self._storage.list_reservations(
            statuses=[ReservationStatus.PENDING]
        ):
            if reservation.expires_at < now:
                self._storage.update_reservation_status(
                    reservation.id, ReservationStatus.EXPIRED
                )
                expired += 1
        return expired
