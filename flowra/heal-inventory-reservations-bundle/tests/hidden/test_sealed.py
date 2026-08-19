"""Sealed hidden tests — not visible to the agent during rollout."""

from __future__ import annotations

import concurrent.futures
import random
import string
from datetime import datetime, timedelta, timezone

import pytest

from inventory import (
    InsufficientStockError,
    InvalidTransitionError,
    InventoryService,
    ReservationStatus,
    SQLiteStorage,
)


def _random_sku() -> str:
    suffix = "".join(random.choices(string.ascii_lowercase, k=8))
    return f"sku-{suffix}"


def test_pending_holds_reduce_availability() -> None:
    storage = SQLiteStorage(":memory:")
    svc = InventoryService(storage)
    sku = _random_sku()
    svc.seed(sku, 12)

    svc.reserve(sku, 4)
    svc.reserve(sku, 3)
    assert svc.available(sku) == 5


def test_concurrent_reserve_never_oversells() -> None:
    storage = SQLiteStorage(":memory:")
    svc = InventoryService(storage)
    sku = _random_sku()
    svc.seed(sku, 20)

    def attempt() -> str | None:
        try:
            return svc.reserve(sku, 3)
        except InsufficientStockError:
            return None

    with concurrent.futures.ThreadPoolExecutor(max_workers=16) as pool:
        results = list(pool.map(lambda _: attempt(), range(30)))

    successes = [r for r in results if r is not None]
    assert len(successes) <= 6  # 20 // 3
    assert svc.available(sku) >= 0
    product = storage.get_product(sku)
    assert product is not None
    pending = sum(
        r.qty
        for r in storage.list_reservations(
            sku=sku, statuses=[ReservationStatus.PENDING]
        )
    )
    assert product.on_hand - pending == svc.available(sku)


def test_double_commit_is_rejected_and_stock_safe() -> None:
    storage = SQLiteStorage(":memory:")
    svc = InventoryService(storage)
    sku = _random_sku()
    svc.seed(sku, 8)
    rid = svc.reserve(sku, 5)
    svc.commit(rid)
    with pytest.raises(InvalidTransitionError):
        svc.commit(rid)
    product = storage.get_product(sku)
    assert product is not None
    assert product.on_hand == 3


def test_expire_uses_utc_not_local() -> None:
    storage = SQLiteStorage(":memory:")
    svc = InventoryService(storage)
    sku = _random_sku()
    svc.seed(sku, 15)

    past_utc = datetime.now(timezone.utc) - timedelta(seconds=30)
    reservation = storage.create_reservation(sku, 7, past_utc)
    assert svc.available(sku) == 8

    expired = svc.expire_stale()
    assert expired == 1
    assert svc.available(sku) == 15
    updated = storage.get_reservation(reservation.id)
    assert updated is not None
    assert updated.status == ReservationStatus.EXPIRED


def test_commit_after_release_rejected() -> None:
    storage = SQLiteStorage(":memory:")
    svc = InventoryService(storage)
    sku = _random_sku()
    svc.seed(sku, 6)
    rid = svc.reserve(sku, 2)
    svc.release(rid)
    with pytest.raises(InvalidTransitionError):
        svc.commit(rid)
    product = storage.get_product(sku)
    assert product is not None
    assert product.on_hand == 6


def test_multi_sku_isolation() -> None:
    storage = SQLiteStorage(":memory:")
    svc = InventoryService(storage)
    sku_a = _random_sku()
    sku_b = _random_sku()
    svc.seed(sku_a, 5)
    svc.seed(sku_b, 9)

    svc.reserve(sku_a, 5)
    assert svc.available(sku_b) == 9
    with pytest.raises(InsufficientStockError):
        svc.reserve(sku_a, 1)


def test_partial_score_reserve_only() -> None:
    """Monotone partial credit: fixing availability alone helps."""
    storage = SQLiteStorage(":memory:")
    svc = InventoryService(storage)
    sku = _random_sku()
    svc.seed(sku, 10)
    svc.reserve(sku, 6)
    # Broken code returns 10; fixed returns 4
    assert svc.available(sku) == 4
