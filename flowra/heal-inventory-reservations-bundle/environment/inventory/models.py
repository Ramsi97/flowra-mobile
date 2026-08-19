"""Inventory reservation domain models."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from enum import Enum


class ReservationStatus(str, Enum):
    PENDING = "pending"
    COMMITTED = "committed"
    RELEASED = "released"
    EXPIRED = "expired"


@dataclass(frozen=True)
class Product:
    sku: str
    on_hand: int


@dataclass(frozen=True)
class Reservation:
    id: str
    sku: str
    qty: int
    status: ReservationStatus
    expires_at: datetime
    created_at: datetime


class InventoryError(Exception):
    """Base error for inventory operations."""


class InsufficientStockError(InventoryError):
    """Raised when a reservation exceeds available stock."""


class NotFoundError(InventoryError):
    """Raised when a reservation id does not exist."""


class InvalidTransitionError(InventoryError):
    """Raised when an operation is illegal for the current reservation state."""
