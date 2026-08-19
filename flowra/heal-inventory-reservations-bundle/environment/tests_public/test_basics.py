"""Public smoke tests — visible to the agent for local self-check."""

from datetime import datetime, timedelta, timezone

import pytest

from inventory import (
    InsufficientStockError,
    InvalidTransitionError,
    InventoryService,
    SQLiteStorage,
)


@pytest.fixture()
def service() -> InventoryService:
    storage = SQLiteStorage(":memory:")
    svc = InventoryService(storage)
    svc.seed("widget-a", 10)
    return svc


def test_reserve_and_commit_reduces_on_hand(service: InventoryService) -> None:
    rid = service.reserve("widget-a", 3)
    assert service.available("widget-a") == 7
    service.commit(rid)
    storage = service._storage
    product = storage.get_product("widget-a")
    assert product is not None
    assert product.on_hand == 7


def test_release_frees_pending_hold(service: InventoryService) -> None:
    rid = service.reserve("widget-a", 4)
    assert service.available("widget-a") == 6
    service.release(rid)
    assert service.available("widget-a") == 10


def test_cannot_reserve_more_than_available(service: InventoryService) -> None:
    service.reserve("widget-a", 8)
    with pytest.raises(InsufficientStockError):
        service.reserve("widget-a", 5)


def test_double_commit_rejected(service: InventoryService) -> None:
    rid = service.reserve("widget-a", 2)
    service.commit(rid)
    with pytest.raises(InvalidTransitionError):
        service.commit(rid)


def test_expire_makes_stock_available(service: InventoryService) -> None:
    storage = service._storage
    past = datetime.now(timezone.utc) - timedelta(minutes=5)
    reservation = storage.create_reservation("widget-a", 6, past)
    assert service.available("widget-a") == 4
    expired_count = service.expire_stale()
    assert expired_count == 1
    assert service.available("widget-a") == 10
    updated = storage.get_reservation(reservation.id)
    assert updated is not None
    assert updated.status.value == "expired"
