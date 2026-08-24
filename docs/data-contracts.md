# Data Contracts

## 1. Purpose

This document explains the responsibility of important Research Ledger data
models so future work does not confuse screener identity, research review,
legacy paper holdings, and the portfolio ledger.

Supabase migrations remain authoritative for exact table definitions, columns,
constraints, indexes, grants, RLS policies, functions, and views. This document
describes roles and boundaries.

## 2. Source-of-Truth Hierarchy

Use this order when documents disagree:

1. GitHub code and Supabase migrations define what currently exists.
2. This document explains model and table responsibilities.
3. [docs/investment-logic.md](investment-logic.md) defines investment decision
   logic and scoring separation.
4. [docs/adr/0001-supabase-portfolio-migration-contract.md](adr/0001-supabase-portfolio-migration-contract.md)
   defines the accepted portfolio migration contract.
5. [ROADMAP.md](../ROADMAP.md) defines implementation sequencing.
6. [ARCHITECTURE.md](../ARCHITECTURE.md) defines architectural constraints.
7. [docs/testing-playbook.md](testing-playbook.md) defines test selection and
   reporting expectations.
8. [README.md](../README.md) provides onboarding and setup.

Do not treat README summaries as more authoritative than migrations.

## 3. Core Identity Models

### tickers

`tickers` is the shared stock screener identity model. It represents securities
used by discovery, screening, research, and legacy paper holdings.

It is not the universal portfolio identity model. Non-stock assets do not need
a ticker row.

### assets

`assets` is the owner-scoped universal portfolio asset identity model. It
supports Stock, ETF, Crypto, Cash, Bond, Mutual fund, and Other. A stock asset
may optionally link to one shared `tickers` row for the same owner boundary, but
portfolio logic should key portfolio assets through `assets`, not `tickers`.

### investment_accounts

`investment_accounts` is the owner-scoped account model for brokerages,
exchanges, wallets, bank accounts, cash accounts, and other portfolio accounts.
Portfolio ledger calculations are partitioned by account and asset.

## 4. Screener Data Models

### screening_runs

`screening_runs` records authenticated, owner-scoped screener executions,
criteria, status, counters, and timing.

### screening_results

`screening_results` records per-run screening output including score,
confidence, normalized metrics, explanations, warnings, and failure details.
It belongs to a `screening_run` and should not be used as confirmed investment
truth.

Quantitative score and confidence remain separate.

### market_data_snapshots

`market_data_snapshots` is a backend-managed normalized market-data cache. It
stores provider, snapshot type, normalized payload, observation time, retrieval
time, and expiry. It is shared backend cache data, not user-owned portfolio
truth.

Frontend clients must not receive service-role credentials or directly manage
this cache.

## 5. Research Data Models

### analysis_inbox

`analysis_inbox` is the human-review breakpoint for AI research. Research
pipeline output lands here before the user approves, discards, or later takes a
paper-portfolio action.

AI research may support decisions, but it must not bypass review or directly
confirm portfolio transactions.

## 6. Portfolio Ledger Data Models

### transaction_import_batches

`transaction_import_batches` records owner-scoped import runs and source
metadata. It provides audit context for staged rows.

### transaction_import_errors

`transaction_import_errors` records ambiguous or invalid import rows while
preserving raw source evidence. It is not a transaction table.

### transaction_drafts

`transaction_drafts` contains proposed transactions from imports, manual entry,
screenshots, AI extraction, or correction workflows. Drafts exist before human
confirmation. They may be edited only while still mutable and unconfirmed.

Draft rows preserve source evidence, native transaction values, historical FX
inputs, fee units, and review notes.

### transactions

`transactions` contains immutable confirmed ledger facts. Confirmed rows are
append-only and replayed deterministically. They must not be updated or deleted
in place; corrections require linked reversal or correcting transactions.

Ownership is derived from authenticated backend context, not client-supplied
`user_id`.

## 7. Derived / Projection Models

### portfolio_position_projections

`portfolio_position_projections` is rebuildable derived state calculated from
confirmed transactions. It is not source-of-truth data and must not be manually
edited as if it were ledger truth.

The canonical replacement path is the backend-only
`replace_portfolio_position_projections(UUID, JSONB)` RPC. Authenticated users
may read their own projection rows but must not insert, update, delete, or
rebuild them directly.

Projection metadata records freshness and replay provenance, including:

- `as_of_transaction_at`;
- `as_of_ledger_sequence`;
- `source_transaction_count`; and
- canonical `source_metadata`.

### portfolio_positions / portfolio_summary

`portfolio_positions` and `portfolio_summary` are user-facing
`security_invoker` views over projection rows. They expose readable portfolio
state while preserving underlying RLS behavior.

## 8. Legacy Models

### portfolios

`portfolios` is the legacy paper-holding implementation created from approved
analysis inbox items. It is not the confirmed transaction ledger and must not
be reused as the ledger source of truth.

Preserve it until an explicitly scoped cutover retires or replaces its
responsibilities.

## 9. Ownership and RLS Expectations

User ownership must come from verified Supabase JWT identity. A client-supplied
`user_id` is never authoritative.

Every exposed user-owned table requires:

- RLS enabled;
- indexed owner predicates;
- explicit least-privilege grants;
- owner-scoped policies;
- cross-user tests for sensitive changes; and
- backend queries scoped by the authenticated owner even when using service
  role.

Service-role credentials are backend-only. RLS and grants are separate required
controls.

## 10. Rules AI Must Not Violate

- Do not use `portfolios` as the confirmed transaction ledger.
- Do not use `tickers` as the universal portfolio identity model.
- Do not manually edit derived projections as source-of-truth data.
- Do not bypass draft review or confirmation boundaries.
- Do not mutate confirmed transactions.
- Do not trust a client-supplied `user_id`.
- Do not weaken RLS, grants, owner filters, or service-role boundaries.
- Do not convert missing financial values to zero.
- Do not introduce PR5 price, FX, valuation, or performance features while
  doing documentation-only work.
