-- BUY/SELL gross_amount is optional pre-fee trade notional. When present, it
-- must match quantity * unit_price within one numeric(38,18) fractional unit.

COMMENT ON COLUMN public.transaction_drafts.gross_amount IS
  'Optional pre-fee trade notional in transaction currency. BUY/SELL values must match quantity * unit_price within 0.000000000000000001.';

COMMENT ON COLUMN public.transactions.gross_amount IS
  'Optional pre-fee trade notional in transaction currency. BUY/SELL values must match quantity * unit_price within 0.000000000000000001.';

ALTER TABLE public.transactions
  ADD CONSTRAINT transactions_buy_sell_gross_matches_quantity_price
  CHECK (
    transaction_type NOT IN ('BUY', 'SELL')
    OR gross_amount IS NULL
    OR abs(gross_amount - (quantity * unit_price))
      <= 0.000000000000000001::NUMERIC
  ) NOT VALID;

COMMENT ON CONSTRAINT transactions_buy_sell_gross_matches_quantity_price
  ON public.transactions IS
  'Prevents new confirmed BUY/SELL rows from storing a gross amount inconsistent with pre-fee quantity * unit_price; NOT VALID preserves immutable legacy rows.';
