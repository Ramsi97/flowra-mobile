# Heal the Broken Inventory Reservation Service

You inherited a small Python service that holds e-commerce stock while shoppers keep items in their cart. A teammate rushed a refactor last week; since then support has logged oversells, carts that never release stock, and duplicate charges at checkout.

Your job is to **repair the existing codebase** under `/app/inventory/` so it behaves correctly. Do not rewrite the module from scratch or change the public API signatures in `service.py`.

## What the service should do

The service tracks physical `on_hand` counts per SKU and manages **reservations** with these statuses:

| Status | Meaning |
|--------|---------|
| `pending` | Stock is held for a cart; not yet purchased |
| `committed` | Checkout completed; physical stock reduced |
| `released` | Cart abandoned or cancelled; hold removed |
| `expired` | Hold timed out; treated like released |

Core operations (already declared in `InventoryService`):

1. **`reserve(sku, qty, ttl_seconds)`** — Create a pending reservation if enough stock is available. Returns a reservation id. Must be safe under concurrent calls.
2. **`commit(reservation_id)`** — Finalize checkout: mark committed and deduct `on_hand`. Must reject already-committed or non-pending reservations.
3. **`release(reservation_id)`** — Cancel a pending hold without changing `on_hand`.
4. **`expire_stale()`** — Mark pending reservations past `expires_at` as expired so their quantity becomes available again.
5. **`available(sku)`** — Return how many units can still be reserved right now.

**Availability rule:** `available(sku) = on_hand - sum(qty of pending reservations for that sku)`. Committed, released, and expired reservations must not reduce availability (committed stock is already deducted from `on_hand`).

All timestamps are stored and compared in **UTC**. Reservation expiry must work regardless of server local timezone.

## What you have

```
/app/
├── inventory/
│   ├── __init__.py
│   ├── models.py
│   ├── storage.py      # SQLite persistence — likely fine
│   └── service.py      # ← bugs live here
├── tests_public/       # sample checks you can run locally
│   └── test_basics.py
└── README.md
```

Run the public smoke tests anytime:

```bash
cd /app && python -m pytest tests_public/ -v
```

These cover happy-path behaviour only. **Passing them is necessary but not sufficient** — the sealed grader exercises concurrency, expiry edge cases, and state-machine traps you cannot see.

## Constraints

- Fix logic in `service.py` (and only elsewhere if truly required).
- Keep all method signatures and return types in `InventoryService` unchanged.
- Do not delete or rename database tables/columns.
- Do not hard-code SKU names or reservation ids — the grader generates fresh data.
- The service must remain usable with the provided `SQLiteStorage` backend.

## Definition of done

When your fixes are correct:

- Concurrent `reserve` calls never oversell the same SKU.
- `available()` reflects pending holds accurately.
- `commit` is idempotent-safe: double-commit raises `InvalidTransitionError`.
- `release` and `expire_stale` free held quantity back to availability.
- Expiry honours UTC `expires_at` values even when the process timezone is not UTC.
- Public tests and all sealed verifier checks pass.

Good luck — the bugs are intertwined, so read the code carefully before changing anything.
