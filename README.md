	# ⚡ Eureka — AI Electronics Project Builder

> Transform natural language ideas into interactive 2D circuits, validated wiring, synchronized BOMs, microcontroller firmware, and step-by-step assembly guides.

---

## 🏗️ Monorepo Architecture

```text
eureka/
├── apps/
│   ├── backend/                     # Python 3.11+ FastAPI Service
│   │   ├── core/                    # Pydantic Settings, Structured JSON Logging, Security, Exceptions
│   │   ├── db/                      # Supabase Client Bindings (db_as_user, db_as_service, assert_project_ownership)
│   │   ├── domains/                 # Domain-Driven Routers & Services
│   │   │   ├── projects/            # Project CRUD & lifecycle management
│   │   │   ├── circuit/             # CircuitGraph, apply_mutation choke point, Net resolution
│   │   │   ├── components/          # Component catalog search, pin definitions, bulk import
│   │   │   ├── validation/          # 3-tier deterministic safety engine (critical, warning, info)
│   │   │   ├── bom/                 # BOM derivation and budget optimization
│   │   │   ├── codegen/             # Jinja2 firmware generation (Arduino / ESP32 C++)
│   │   │   ├── docs/                # Wiring guides, flowcharts, assembly instructions
│   │   │   ├── ai/                  # LangGraph generation & modification orchestration
│   │   │   ├── export/              # WeasyPrint PDF, SVG, ZIP export service
│   │   │   └── admin/               # Real-time telemetry, audit logs, failure tracking
│   │   ├── scripts/                 # Standalone utility scripts (test_ai_connectivity.py)
│   │   ├── Dockerfile               # Multi-stage container definition
│   │   ├── requirements.txt         # Python dependencies
│   │   └── main.py                  # App entrypoint, CORS, correlation IDs, exception handlers
│   │
│   └── frontend/                    # Next.js 15 (App Router), TypeScript, Tailwind CSS
│       ├── src/
│       │   ├── app/                 # Route groups: (auth), (dashboard), (project)/[projectId], admin
│       │   ├── lib/                 # Supabase browser client, API utilities
│       │   └── store/               # Zustand store for circuit graph & optimistic UI
│       └── package.json
│
├── packages/
│   └── shared-types/                # Shared schema contracts (mirrored in TS and Python)
│       └── src/                     # circuit.ts, mutation.ts, validation.ts, actor.ts, bom.ts
│
├── assets/                          # Component graphics & catalog (for team asset collection)
│   ├── component_catalog.csv        # Master component tracking & pin position mapping
│   └── components/                  # SVG assets sorted by category
│
├── supabase/
│   ├── migrations/                  # Forward-only SQL migrations (D1-D9 schemas)
│   └── seed.sql                     # Starter seed data
│
├── .env.example                     # Unified environment template
├── docker-compose.yml               # Local development stack
├── package.json                     # Root monorepo workspace scripts
├── ASSET_COLLECTION_GUIDE.md        # Guide for non-technical teammates collecting component SVGs
└── README.md                        # Project documentation & setup guide
```

---

## ⚙️ Environment Configuration

Copy the root template to create your local `.env`:

```bash
# In project root:
cp .env.example .env
```

### Required Credentials:

1. **Supabase (Auth & Database):**
   - `SUPABASE_URL` & `NEXT_PUBLIC_SUPABASE_URL`
   - `SUPABASE_ANON_KEY` & `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `SUPABASE_JWT_SECRET`
2. **AI Provider (Google Gemini API - Free Tier on Google AI Studio):**
   - `GEMINI_API_KEY` (Get FREE key from [aistudio.google.com](https://aistudio.google.com/))
   - `GEMINI_FAST_MODEL=gemini-2.0-flash`
   - `GEMINI_REASONING_MODEL=gemini-2.0-flash`
3. **Storage (Cloudflare R2 Only):**
   - `R2_ACCOUNT_ID`
   - `R2_ACCESS_KEY_ID`
   - `R2_SECRET_ACCESS_KEY`
   - `R2_ENDPOINT` (e.g. `https://<account_id>.r2.cloudflarestorage.com`)
   - `R2_PUBLIC_ASSET_BUCKET=eureka-public-assets`
   - `R2_PUBLIC_ASSET_URL=https://assets.yourdomain.com`

---

## 🏃 How to Run Different Parts of the Application

### 1. Run the Frontend (Next.js)

```bash
# Start Next.js development server on http://localhost:3000
npm run dev:frontend

# Or from project root:
npm run dev
```

- **Landing Page:** [http://localhost:3000](http://localhost:3000)
- **Project Dashboard:** [http://localhost:3000/dashboard](http://localhost:3000/dashboard)
- **Circuit Workspace:** [http://localhost:3000/project/new](http://localhost:3000/project/new)
- **Admin Telemetry:** [http://localhost:3000/admin](http://localhost:3000/admin)

---

### 2. Run the Backend (FastAPI)

```bash
# Activate virtual environment (Windows PowerShell)
.\.venv\Scripts\Activate.ps1
# On macOS / Linux: source .venv/bin/activate

# Start the FastAPI server on http://localhost:8000
python -m uvicorn apps.backend.main:app --reload --host 0.0.0.0 --port 8000

# Or via npm script:
npm run dev:backend
```

- **API Base:** [http://localhost:8000](http://localhost:8000)
- **Interactive Swagger Documentation:** [http://localhost:8000/docs](http://localhost:8000/docs)
- **Health Check:** [http://localhost:8000/health](http://localhost:8000/health)

---

### 3. Test AI Connectivity (Google Gemini)

Verify that your Google Gemini API key is responding correctly:

```bash
.\.venv\Scripts\python apps/backend/scripts/test_ai_connectivity.py
```

---

### 4. Build Shared TypeScript Contracts

Whenever you update types in `packages/shared-types`:

```bash
npm run build:types
```

---

### 5. Run Type Checking

Verify that there are zero TypeScript errors across the frontend:

```bash
npm run typecheck --workspace=apps/frontend
```

---

### 6. Run with Docker Compose

To run the containerized backend:

```bash
docker compose up --build
```
