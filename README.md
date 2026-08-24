# Research Ledger

Research Ledger is an AI-assisted investment research workspace. It helps an
authenticated user discover ideas, run sector-aware quantitative screens,
review AI-assisted research, and track a paper portfolio through a human
decision workflow.

Research Ledger is not a financial data terminal, autonomous trading bot, live
brokerage, or order execution system. Any legacy route or UI wording that says
`execute` refers to a paper-portfolio action, not a real trade.

The intended flow is:

```text
Discover -> Quantitative Screen -> AI Research -> Human Review
         -> Paper Portfolio -> Thesis Tracking -> Re-evaluation
```

## Quick Start

### 1. Environment

```bash
cp .env.example .env
# Fill in Supabase keys and AI provider API keys
```

### 2. Docker (full stack)

```bash
docker compose up --build
```

| Service | URL |
| --- | --- |
| Frontend | http://localhost:3000 |
| Backend API | http://localhost:8000 |
| API docs | http://localhost:8000/docs |
| PostgreSQL | localhost:5432 |
| Redis | localhost:6379 |

### 3. Local development (without Docker)

**Backend:**

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate        # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload
```

**Celery (separate terminals):**

```bash
celery -A app.workers.celery_app worker --loglevel=info
celery -A app.workers.celery_app beat --loglevel=info
```

**Frontend:**

```bash
cd frontend
npm install
npm run dev
```

### 4. Supabase

Apply migrations to a hosted Supabase project:

```bash
supabase db push
```

Or use a reviewed Supabase Cloud migration workflow. Do not apply unreviewed
migrations directly to a production project.

Database tests use pgTAP and live under `supabase/tests/database/`. With a
disposable test database containing all migrations, run:

```bash
supabase test db
```

ADR 0001 remains the migration contract. Run a local dry report from
`backend/` before enabling staging persistence:

```bash
python -m app.services.portfolio_import.cli portfolio-export.xlsx \
  --spreadsheet-id YOUR_GOOGLE_SHEET_ID
```

`--persist-staging` requires `SUPABASE_ACCESS_TOKEN`; ownership is derived from
that verified JWT. Persistence writes only import batches, assets/accounts,
transaction drafts, and import errors. It never promotes a draft or inserts a
confirmed transaction.

## Project Structure

```text
Research-Ledger/
|-- docker-compose.yml
|-- .env.example
|-- AGENTS.md                # AI agent implementation rules
|-- ARCHITECTURE.md          # architecture constraints and system boundaries
|-- ROADMAP.md               # implementation sequence
|-- docs/
|   |-- investment-logic.md    # scoring and investment decision rules
|   |-- data-contracts.md      # model/table responsibilities
|   |-- testing-playbook.md    # test selection and reporting
|   |-- adr/                   # accepted architecture decision records
|   `-- migration/             # historical migration reports
|-- frontend/
|   |-- src/app/              # Next.js App Router pages
|   |-- src/components/       # shadcn/ui + domain components
|   `-- src/lib/              # Supabase client, API helpers
|-- backend/
|   `-- app/
|       |-- agents/           # LangGraph pipeline + agent nodes
|       |-- api/routes/       # FastAPI endpoints
|       |-- services/         # Screener, current yfinance-backed market data
|       |-- workers/          # Celery app + tasks
|       `-- db/               # Supabase client
`-- supabase/
    |-- migrations/           # PostgreSQL schema + RLS policies
    `-- tests/database/       # pgTAP schema, ownership, RLS, and integrity tests
```

## Main API Endpoints

| Method | Path | Description |
| --- | --- | --- |
| GET | `/health` | Health check |
| POST | `/api/screener/run` | Trigger authenticated screening manually |
| POST | `/api/screener/pipeline` | Run AI pipeline for one ticker |
| GET | `/api/analysis/inbox` | List authenticated user's analyses |
| POST | `/api/analysis/inbox/{id}/approve` | Human approval |
| POST | `/api/analysis/inbox/{id}/discard` | Human discard |
| GET | `/api/portfolio/` | List user paper holdings |
| POST | `/api/portfolio/execute/{inbox_id}` | Create a paper holding from an approved analysis; `execute` is legacy route language |
| GET | `/api/portfolio/ledger/summary` | Read owner-scoped portfolio ledger summary |
| POST | `/api/portfolio/ledger/rebuild` | Rebuild owner-scoped portfolio projections through the backend |

## Key Documentation

- [AGENTS.md](AGENTS.md) - AI implementation rules and source-of-truth order
- [ARCHITECTURE.md](ARCHITECTURE.md) - implemented architecture and constraints
- [ROADMAP.md](ROADMAP.md) - current implementation sequence
- [docs/investment-logic.md](docs/investment-logic.md) - scoring and investment decision rules
- [docs/data-contracts.md](docs/data-contracts.md) - model/table responsibilities and boundaries
- [docs/testing-playbook.md](docs/testing-playbook.md) - test selection and reporting expectations
- [docs/adr/0001-supabase-portfolio-migration-contract.md](docs/adr/0001-supabase-portfolio-migration-contract.md) - accepted portfolio migration contract
- [docs/migration/google-sheets-pr2-dry-run.md](docs/migration/google-sheets-pr2-dry-run.md) - historical PR2 migration report

## Legacy

The root `src/` folder contains the previous React/Vite prototype and is superseded by `frontend/`.
