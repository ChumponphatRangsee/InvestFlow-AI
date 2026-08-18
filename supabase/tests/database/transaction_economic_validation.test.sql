BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET search_path TO public, extensions;

SELECT plan(8);

SELECT has_check(
  'public',
  'transactions',
  'transactions_buy_sell_gross_matches_quantity_price',
  'confirmed transactions enforce BUY/SELL gross consistency'
);

INSERT INTO auth.users (id)
VALUES ('71000000-0000-4000-8000-000000000001');

INSERT INTO public.investment_accounts (id, user_id, name, account_type, currency)
VALUES (
  '72000000-0000-4000-8000-000000000001',
  '71000000-0000-4000-8000-000000000001',
  'Economic Validation Account',
  'BROKERAGE',
  'USD'
);

INSERT INTO public.assets (id, user_id, symbol, name, asset_type, currency)
VALUES (
  '73000000-0000-4000-8000-000000000001',
  '71000000-0000-4000-8000-000000000001',
  'TEST',
  'Economic Validation Asset',
  'STOCK',
  'USD'
);

SELECT lives_ok(
  $$
    INSERT INTO public.transactions (
      user_id, investment_account_id, asset_id, transaction_type,
      transaction_at, quantity, unit_price, gross_amount, currency, source_type
    )
    VALUES (
      '71000000-0000-4000-8000-000000000001',
      '72000000-0000-4000-8000-000000000001',
      '73000000-0000-4000-8000-000000000001',
      'BUY', now(), 2, 100, 200, 'USD', 'MANUAL'
    )
  $$,
  'BUY 2 * 100 accepts gross 200'
);

SELECT throws_ok(
  $$
    INSERT INTO public.transactions (
      user_id, investment_account_id, asset_id, transaction_type,
      transaction_at, quantity, unit_price, gross_amount, currency, source_type
    )
    VALUES (
      '71000000-0000-4000-8000-000000000001',
      '72000000-0000-4000-8000-000000000001',
      '73000000-0000-4000-8000-000000000001',
      'BUY', now(), 3, 100, 200, 'USD', 'MANUAL'
    )
  $$,
  '23514',
  NULL,
  'BUY 3 * 100 rejects gross 200'
);

SELECT lives_ok(
  $$
    INSERT INTO public.transactions (
      user_id, investment_account_id, asset_id, transaction_type,
      transaction_at, quantity, unit_price, gross_amount, currency, source_type
    )
    VALUES (
      '71000000-0000-4000-8000-000000000001',
      '72000000-0000-4000-8000-000000000001',
      '73000000-0000-4000-8000-000000000001',
      'SELL', now(), 5, 20, 100, 'USD', 'MANUAL'
    )
  $$,
  'SELL 5 * 20 accepts gross 100'
);

SELECT lives_ok(
  $$
    INSERT INTO public.transactions (
      user_id, investment_account_id, asset_id, transaction_type,
      transaction_at, quantity, unit_price, gross_amount, currency, source_type
    )
    VALUES (
      '71000000-0000-4000-8000-000000000001',
      '72000000-0000-4000-8000-000000000001',
      '73000000-0000-4000-8000-000000000001',
      'BUY', now(), 0.1, 0.2, 0.020000000000000001, 'USD', 'MANUAL'
    )
  $$,
  'one numeric fractional unit of precision tolerance is accepted'
);

SELECT throws_ok(
  $$
    INSERT INTO public.transactions (
      user_id, investment_account_id, asset_id, transaction_type,
      transaction_at, quantity, unit_price, gross_amount, currency, source_type
    )
    VALUES (
      '71000000-0000-4000-8000-000000000001',
      '72000000-0000-4000-8000-000000000001',
      '73000000-0000-4000-8000-000000000001',
      'BUY', now(), 0.1, 0.2, 0.020000000000000002, 'USD', 'MANUAL'
    )
  $$,
  '23514',
  NULL,
  'a gross difference above tolerance is rejected'
);

SELECT lives_ok(
  $$
    INSERT INTO public.transactions (
      user_id, investment_account_id, asset_id, transaction_type,
      transaction_at, quantity, unit_price, gross_amount, fee_amount,
      fee_unit, currency, source_type
    )
    VALUES (
      '71000000-0000-4000-8000-000000000001',
      '72000000-0000-4000-8000-000000000001',
      '73000000-0000-4000-8000-000000000001',
      'BUY', now(), 2, 100, 200, 15, 'QUOTE_CURRENCY', 'USD', 'MANUAL'
    )
  $$,
  'fees remain separate from gross trade notional'
);

SELECT lives_ok(
  $$
    INSERT INTO public.transactions (
      user_id, investment_account_id, asset_id, transaction_type,
      transaction_at, quantity, unit_price, currency, source_type
    )
    VALUES (
      '71000000-0000-4000-8000-000000000001',
      '72000000-0000-4000-8000-000000000001',
      '73000000-0000-4000-8000-000000000001',
      'BUY', now(), 2, 100, 'USD', 'MANUAL'
    )
  $$,
  'gross amount may be omitted because quantity * unit_price is authoritative'
);

SELECT * FROM finish();
ROLLBACK;
