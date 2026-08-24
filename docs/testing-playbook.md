# Testing Playbook

## 1. Purpose

This playbook helps developers and AI agents choose the right tests for a
change. It supplements, but does not replace, local judgment and existing test
coverage.

## 2. General Testing Rules

- Run narrow tests first, then broader suites.
- Do not claim tests passed if they were not run.
- Report blocked tests honestly, including missing dependencies or unavailable
  local services.
- Prefer deterministic tests over live-provider calls.
- Add tests proportional to risk, ownership impact, and blast radius.
- Run `git diff --check` before handoff.

## 3. Backend API Changes

Run focused route and service tests for the changed endpoint, then the backend
suite when behavior crosses ownership, persistence, or portfolio boundaries.

Common command:

```bash
backend/.venv/Scripts/python.exe -m pytest -q
```

For Windows PowerShell from the repo root, use the same command with backslash
paths.

## 4. Authentication and Ownership Changes

Authentication and ownership changes require spoofed-user and cross-user tests.
Verify that ownership comes from the verified Supabase JWT, not request bodies
or client-supplied IDs.

Cover:

- missing or invalid bearer token;
- spoofed `user_id`;
- user A cannot read or mutate user B data;
- Celery and LangGraph owner propagation; and
- service-role code still filters by authenticated owner.

## 5. Supabase Migration Changes

Migration changes require reviewing exact SQL, grants, indexes, constraints,
RLS policies, and function/view security.

Run relevant pgTAP tests when local Supabase is available:

```bash
supabase test db
```

Also verify migration ordering and run database advisors when applicable. Do
not claim Supabase tests passed when Docker, Supabase CLI, or the local
database is unavailable.

## 6. Portfolio Ledger Changes

Portfolio ledger changes require calculation, replay, immutability, and owner
scope tests.

Cover:

- weighted-average cost replay;
- realized and unrealized P&L calculations;
- fees, income, cash flow, and THB conversion behavior;
- chronological replay using `transaction_at` and `ledger_sequence`;
- source metadata and projection freshness;
- immutable confirmed transactions;
- reversal and correction behavior; and
- rebuildable projections through the backend-only RPC.

Do not test by manually editing projection rows as source-of-truth data.

## 7. Transaction Workflow Changes

Transaction workflow changes require draft lifecycle, confirmation, correction,
and immutability tests.

Cover:

- draft create/read/update behavior;
- atomic idempotent confirmation;
- confirmed transaction immutability;
- correction drafts;
- linked reversal rows;
- import error visibility;
- owner scoping; and
- AI, screenshot, and import code paths cannot bypass human review.

## 8. Market Data Changes

Market data changes require provider, normalization, cache, TTL, and failure
tests.

Cover:

- provider interface contract;
- normalized internal models;
- cache hit, cache miss, stale row, and write failure behavior;
- TTL and freshness boundaries;
- provider failure propagation;
- missing values remain null; and
- no provider-specific raw fields leak into domain scoring logic.

Avoid live network dependency in normal unit tests.

## 9. Screener / Scoring Changes

Screener changes require score, confidence, eligibility, missing-data, and
ranking tests.

Cover:

- business-model classification;
- strategy-specific rules;
- required-category availability;
- score and confidence separation;
- unsupported business models;
- sector-specific assumptions such as bank-specific rules;
- missing metrics remaining null; and
- top-N queueing behavior.

## 10. Frontend Changes

Frontend changes require TypeScript validation and a production build. Run from
`frontend/`:

```bash
npm run build
```

If the change is type-heavy or build output is ambiguous, also run the local
TypeScript validation command used by the project, such as:

```bash
.\node_modules\.bin\tsc.cmd --noEmit
```

For visual or responsive changes, manually inspect desktop and mobile behavior
or use a browser test/screenshot workflow.

## 11. Documentation-Only Changes

No application tests are required for documentation-only changes unless the
documentation modifies commands, paths, environment variables, or implementation
assumptions that need verification.

Still run:

```bash
git diff --check
```

Verify that only Markdown files changed.

## 12. Reporting Test Results

Report:

- exact commands run;
- pass/fail/blocked result;
- any warnings that matter;
- tests intentionally not run and why; and
- whether application behavior was changed.

Never summarize an unrun test as passed.
