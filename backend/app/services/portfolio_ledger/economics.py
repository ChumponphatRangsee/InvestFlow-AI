"""Authoritative economic rules for portfolio transactions."""

from __future__ import annotations

from decimal import Decimal
from typing import Any


TRADE_TRANSACTION_TYPES = frozenset({"BUY", "SELL"})
TRADE_GROSS_TOLERANCE = Decimal("0.000000000000000001")
ZERO = Decimal("0")


class TransactionEconomicError(ValueError):
    """Raised when a transaction violates the ledger economic contract."""


def validate_transaction_economics(
    *,
    transaction_type: str,
    quantity: Any,
    unit_price: Any,
    gross_amount: Any,
) -> Decimal | None:
    """Validate and return the authoritative pre-fee BUY/SELL notional."""

    if transaction_type not in TRADE_TRANSACTION_TYPES:
        return _decimal_or_none(gross_amount)

    quantity_decimal = _decimal_or_none(quantity)
    unit_price_decimal = _decimal_or_none(unit_price)
    if quantity_decimal is None or unit_price_decimal is None:
        raise TransactionEconomicError(
            "BUY and SELL drafts require quantity and unit_price"
        )
    if quantity_decimal <= ZERO or unit_price_decimal <= ZERO:
        raise TransactionEconomicError(
            f"{transaction_type} quantity and unit price must be greater than zero."
        )

    calculated_gross = quantity_decimal * unit_price_decimal
    reported_gross = _decimal_or_none(gross_amount)
    if reported_gross is not None and (
        reported_gross <= ZERO
        or abs(reported_gross - calculated_gross) > TRADE_GROSS_TOLERANCE
    ):
        raise TransactionEconomicError(
            f"{transaction_type} gross amount does not match "
            "quantity \u00d7 unit price."
        )
    return calculated_gross


def _decimal_or_none(value: Any) -> Decimal | None:
    if value is None:
        return None
    if isinstance(value, Decimal):
        return value
    return Decimal(str(value))
