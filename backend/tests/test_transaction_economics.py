from decimal import Decimal

import pytest

from app.services.portfolio_ledger import (
    TRADE_GROSS_TOLERANCE,
    TransactionEconomicError,
    validate_transaction_economics,
)


@pytest.mark.parametrize(
    ("transaction_type", "quantity", "unit_price", "gross_amount"),
    [
        ("BUY", Decimal("2"), Decimal("100"), Decimal("200")),
        ("SELL", Decimal("5"), Decimal("20"), Decimal("100")),
        ("BUY", Decimal("0.1"), Decimal("0.2"), Decimal("0.02")),
    ],
)
def test_trade_gross_matches_quantity_times_unit_price(
    transaction_type,
    quantity,
    unit_price,
    gross_amount,
):
    assert validate_transaction_economics(
        transaction_type=transaction_type,
        quantity=quantity,
        unit_price=unit_price,
        gross_amount=gross_amount,
    ) == quantity * unit_price


def test_buy_rejects_materially_inconsistent_gross():
    with pytest.raises(
        TransactionEconomicError,
        match="BUY gross amount does not match",
    ):
        validate_transaction_economics(
            transaction_type="BUY",
            quantity=Decimal("3"),
            unit_price=Decimal("100"),
            gross_amount=Decimal("200"),
        )


def test_trade_gross_accepts_numeric_storage_tolerance_only():
    calculated = Decimal("0.1") * Decimal("0.2")

    assert validate_transaction_economics(
        transaction_type="BUY",
        quantity=Decimal("0.1"),
        unit_price=Decimal("0.2"),
        gross_amount=calculated + TRADE_GROSS_TOLERANCE,
    ) == calculated

    with pytest.raises(TransactionEconomicError):
        validate_transaction_economics(
            transaction_type="BUY",
            quantity=Decimal("0.1"),
            unit_price=Decimal("0.2"),
            gross_amount=calculated + (TRADE_GROSS_TOLERANCE * Decimal("2")),
        )
