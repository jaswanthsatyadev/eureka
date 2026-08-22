# AI Electronics Project Builder — MVP Execution Master Plan (v2.1 - Lean MVP)

One shared setup phase, a set of global technical conventions everyone follows, then five master plans — Database, Backend, Agentic AI, Frontend, Storage — each broken into detailed, dependency-checked phases. Every phase carries a **Technical Notes** section so whoever picks it up, human or AI agent, has the concrete implementation decisions already made instead of having to guess.

---

## Review Summary — Lean MVP Simplification & Refinements

This updated plan streamlines the architecture specifically for MVP velocity, eliminating unnecessary infrastructure overhead:

1. **Removed Redis & External Background Worker Daemons (`Arq`/`Celery`).** For MVP, asynchronous jobs (PDF exports, ZIP generation) run directly in FastAPI using native `BackgroundTasks` or direct async endpoints. This removes the operational complexity, provisioning, and failure modes of Redis, separate worker processes, and connection pooling.
2. **Simplified Database & Operations.** Replaced scheduled cron rollup daemons and pre-aggregated tables (`system_metrics_daily`) with real-time SQL aggregation queries for admin metrics. Data retention/archival policies (`D10`) and dynamic database-driven model routing tables (`model_routing_config`) are removed/deferred in favor of environment-driven Pydantic configuration.
3. **Streamlined AI Orchestration.** Removed the extra dynamic LLM "complexity classifier" call in Phase `A7` in favor of declarative per-node model routing (e.g., Gemini Flash for fast searches/extractions, Claude 3.5 Sonnet for circuit reasoning & conversational editing). Deferred the multimodal Datasheet Ingestion Pipeline (`A8`) since component catalog seeding is already handled directly via CSV/JSON bulk import (`B7`).
4. **Removed CI/CD Pipelines & Automated PR Checks.** Removed CI skeleton workflows, automated PR type-checks, and CI infrastructure to maximize development velocity and eliminate workflow friction for MVP.
5. **Maintained Core Strengths.** The single mutation choke point (`apply_mutation`), deterministic 3-level validation engine, LangGraph interrupt/checkpointing for user clarification, React Flow viewBox-relative pin coordinate system, and shared project-model source of truth are preserved with zero compromise.

---

## How to Use This Document

Every phase has a short ID: `SETUP` for the master setup phase, `D1`–`D9` for Database, `B1`–`B20` for Backend, `A1`–`A7` & `A9`–`A10` for Agentic AI, `F1`–`F20` for Frontend, `S1`–`S3` for Storage. 61 phases in total.

Every phase lists exactly what it **Depends on**, including dependencies on other master plans. A phase should not start until everything in its Depends on line is actually complete — not "mostly done."

**Document order is not execution order.** The plans are presented Database → Backend → Agentic AI → Frontend → Storage for readability, because that roughly matches how the *bulk* of each plan's work unlocks the next. But several individual phases depend on a plan that appears later in the document (for example, `B15` and `F7` both depend on Storage phases). The only two sources of truth for what can start when are (a) each phase's own Depends on line, and (b) the Cross-Plan Dependency Map near the end. If those ever seem to conflict with the reading order, trust the Depends on line.

Read **Global Technical Conventions** before starting *any* phase in any plan. It is short, and it removes the need to guess at a dozen small architectural decisions that would otherwise be re-decided (inconsistently) inside individual phases.

Each phase has four parts, always in this order: **Depends on**, **Goal**, **Technical Notes**, **Tasks**, **Definition of Done**. Read Technical Notes before starting the Tasks — it's the "how and why," positioned before the "what," on purpose.

### Suggested Parallel Build Order

- Run `SETUP` once, first.
- Start Database phases `D1`–`D6` and Storage phase `S1` immediately afterward, in parallel.
- Once `D1`–`D3` exist, start Backend phases `B1`–`B7`, alongside Database `D7`–`D9` and Storage `S2`.
- Once Backend's core engines (`B4`–`B13`) exist, start Agentic AI `A1` onward, alongside remaining Backend `B14`–`B18`.
- Start Frontend `F1`–`F11` as soon as their specific Backend dependencies are ready — they don't need the AI layer at all. Start Frontend `F12`/`F13` only once the matching Agentic AI graphs are complete.
- Run Backend `B19`, Frontend `F20`, and Backend `B20` last, once every other track has substantially landed.

---

## Global Technical Conventions

Read this once. These are the shared decisions that prevent every phase below from having to reinvent (and likely mis-match) the same handful of architectural choices.

1. **Identifiers.** Every primary key is a UUID (v4), generated server-side, never client-supplied and never an auto-increment integer — keeps IDs safe to expose in URLs and share links.
2. **Timestamps.** Every table gets `created_at`, and `updated_at` where the row is mutable, stored as UTC `timestamptz`. The API always serializes as ISO 8601 with a `Z` suffix. Never compare naive, timezone-less timestamps anywhere.
3. **Naming case.** `snake_case` end-to-end — Postgres columns, Python/Pydantic fields, and JSON API payloads. TypeScript on the frontend consumes `snake_case` fields as-is. This is a deliberate MVP simplification: it removes an entire class of alias/transformation bugs between backend and frontend. Revisit only if it's genuinely painful once the app is much bigger.
4. **API response shape.** A successful response returns the resource (or list) directly as the JSON body — no `{data: ...}` wrapper. Every error response uses one consistent shape: `{"error": {"code": "<machine_readable_code>", "message": "<human readable>"}}` with an appropriate HTTP status. No endpoint invents its own error format.
5. **Pagination.** List endpoints use `limit` (default 20, max 100) and `offset` (default 0) query parameters. Do not build cursor-based pagination for MVP — unnecessary complexity at this scale.
6. **Mutation request shape (Circuit Engine).** The API exposes one granular REST endpoint per operation (for example `POST /projects/{id}/components`, `PATCH /projects/{id}/components/{component_id}`, `DELETE /projects/{id}/components/{component_id}`, `POST /projects/{id}/wires`, `DELETE /projects/{id}/wires/{wire_id}`). Internally, every one of these does nothing except build a single normalized `Mutation` object (a discriminated-union-style model: `{type: "add_component" | "remove_component" | ..., payload: {...}}`) and call the one shared `apply_mutation(project_id, mutation, actor)` function. The AI tool layer calls this exact same function directly, never through HTTP, never through a second code path. If you're implementing anything mutation-related and the logic isn't inside `apply_mutation` or a direct helper it calls, it's in the wrong place.
7. **Actor attribution.** Every mutation, version, and AI-related row that records "who did this" uses the same shape: `{"actor_type": "user" | "ai", "user_id": "<uuid or null>", "ai_run_id": "<uuid or null>"}`. Exactly one of `user_id` / `ai_run_id` is populated, matching `actor_type`.
8. **Ownership enforcement helper.** Any backend code using the service-role Supabase client (which bypasses RLS) must call one shared helper — for example `assert_project_ownership(user_id, project_id)` — at the very top of the function, before touching any data. Every new service-role code path uses this helper; nobody writes a bespoke inline check. This is the single most important convention in the whole plan — it's the most likely way one user's data leaks to another if skipped.
9. **Validation finding severity.** Exactly three levels, never more: `critical` (unsafe or non-functional as wired — this is what triggers the AI's bounded auto-repair loop and must never be silently passed over), `warning` (worth attention, non-blocking), `info` (includes the explicit "cannot verify this" case — the engine isn't confident enough to claim anything either way). Every validation rule maps its output to one of these three, nothing else.
10. **Currency.** Prices are stored as a decimal (never a float) with an explicit currency code on the same row, even though MVP likely populates only one currency. Never hardcode a currency symbol in the backend — formatting for display is a frontend concern.
11. **AI run bounds.** Every LangGraph run — generation or modification — has a hard maximum on wall-clock time and on the number of tool calls it may make in one run (starting point: 25 tool calls, 3-minute timeout; tune with real data, but never leave a run genuinely unbounded). This is separate from, and in addition to, the bounded auto-repair loop that specifically limits retries after a validation failure.
12. **LangGraph state shape.** The shared state object threaded through every node contains, at minimum: `project_id`, `thread_id`, the current in-memory `circuit_graph` (always kept in sync with what's actually persisted, never a stale copy), `requirements`, `conversation_history`, `pending_clarification` (null unless the run is paused), and a `tool_call_log` for the current run. Every node reads from and writes back to this same object — no side channels.
13. **Checkpoint pause/resume mechanic.** When the `clarify` node needs to pause a run, it uses LangGraph's built-in interrupt/checkpoint mechanism (backed by the Postgres checkpointer pointed at Supabase) — not a custom "pending question" table. The frontend shows the question, the user answers, and the backend resumes the *same* `thread_id` with the answer as new input. It never starts a new run for this. This is what makes multi-turn generation feel like one continuous conversation instead of disconnected requests.
14. **Realtime payload approach.** For MVP, `project_live_state` carries the full current project-model JSON, and Supabase Realtime pushes the full row on every change — the frontend never needs a follow-up fetch to catch up. This is the simplest correct approach at MVP scale. If a project's JSON eventually grows large enough for this to matter (watch for it, don't pre-solve it), the documented fallback is to shrink the Realtime-tracked row to a lightweight invalidation signal (`{project_id, version_id, updated_at}`) and have the frontend re-fetch full state via REST on receipt.
15. **SVG pin coordinate system.** Every component's pin positions in `component_definitions` are stored as coordinates relative to the SVG's own `viewBox` — not screen pixels, not percentages of the browser window. The Storage Plan's visual standard must commit to this same convention. The frontend converts these viewBox-relative coordinates into the CSS position of each React Flow handle at render time, scaled to the node's actual rendered size. Get this wrong and pins visually drift from where wires attach — treat it as load-bearing, not a nice-to-have detail.
16. **FastAPI Background Tasks & Async Processing.** For MVP, asynchronous operations (such as PDF generation, ZIP packaging, or export tasks) run directly in FastAPI using built-in `BackgroundTasks` or direct async handlers, completely eliminating the operational overhead, provisioning, and points of failure of Redis and external worker daemons (like Arq/Celery). Jobs write their output to storage idempotently.

---

## Quick Phase Index

**Database Master Plan** — D1 Identity and Profiles Schema · D2 Project Domain Schema · D3 Component Catalog Schema · D4 Derived and Generated Data Schema · D5 AI Domain Schema · D6 Admin and Operations Schema · D7 Row-Level Security Policy Pass · D8 Realtime Configuration · D9 Migration and Environment Strategy

**Backend Master Plan** — B1 Backend Scaffold and Core Conventions · B2 Auth Integration · B3 Project Persistence Skeleton · B4 Circuit Engine: Domain Models and Mutation Service · B5 Circuit Engine: Mutation Operations · B6 Circuit Engine: Post-Mutation Pipeline and Realtime Sync · B7 Component Database Service · B8 Validation Engine: Rule Framework · B9 Validation Engine: Initial Rule Set · B10 BOM and Cost Engine · B11 Code Generation Engine · B12 Documentation and Flowchart Generation Engine · B13 AI Orchestration Interface · B14 Versioning and History Service · B15 Export Service · B16 Sharing and Permissions · B17 Admin Dashboard and Analytics Backend · B18 AI Usage and Token Tracking Backend · B19 Security Hardening and Testing · B20 MVP Integration and Launch Readiness

**Agentic AI Master Plan** — A1 Tool and Function Contract Definition · A2 Generation Graph: Requirement Analysis and Component Selection · A3 Reference Wiring-Pattern Library · A4 Generation Graph: Circuit Construction and Validation · A5 Generation Graph: BOM, Code, and Documentation · A6 Modification Graph · A7 Model Routing and Cost Optimization · A9 Evaluation and Regression Framework · A10 Observability

**Frontend Master Plan** — F1 Frontend Scaffold and Design System · F2 Auth Screens and Session Handling · F3 Dashboard: Project List and Management · F4 Typed API Client Generation · F5 Project Workspace Shell · F6 Circuit Canvas: React Flow Base Setup · F7 Circuit Canvas: Custom Node Types and SVG Symbol Integration · F8 Circuit Canvas: Wire and Edge Styling and Interaction · F9 State Management: Store and Backend Sync · F10 Realtime Sync Integration · F11 Component Library Sidebar and Properties Panel · F12 AI Chat Panel: Generation Flow UI · F13 AI Chat Panel: Conversational Modification UI · F14 Validation and BOM Views · F15 Code and Documentation Views · F16 Export UI · F17 Sharing UI · F18 Versioning UI · F19 Admin Dashboard UI · F20 Landing Page and Final Polish

**Storage Plan** — S1 Visual Standards and Naming Convention · S2 Asset Sourcing and Upload · S3 Catalog Linking Handoff

---

## Phase 0 — Master Project Setup

**Depends on:** Nothing. Runs first, once, before any master plan begins.

**Goal:** Establish the one shared foundation every master plan builds on, so all tracks can start independently right after this.

**Technical Notes**

- Use separate Gemini and Claude API keys (or at minimum separate usage-tracked projects/labels) for dev/staging versus prod from day one — this is what stops a runaway test script during development from silently eating into a production cost budget.
- The `packages/shared-types` workspace should hold the conceptual schema definitions (the project-model shape, the mutation types) that both the Python backend and TypeScript frontend mirror deliberately — they can't literally share code across languages, but they should never be authored independently of each other.

**Tasks**

- Create the monorepo with workspaces: `apps/frontend` (Next.js), `apps/backend` (FastAPI), `packages/shared-types`
- Initialize git; agree branching model and commit/PR conventions
- Create two Cloudflare R2 buckets (or Supabase Storage buckets): a public asset bucket and a private output bucket; record bucket names and access keys
- Define the environment variable contract: `.env.example` files for frontend and backend listing every required key (Supabase URL/keys, Gemini API key, Claude API key, R2/Storage credentials)
- Scaffold the Next.js app: App Router, TypeScript, Tailwind CSS, shadcn/ui installed with a base theme
- Scaffold the FastAPI app with the domain-driven folder layout: `core/`, `db/`, `domains/`, `main.py`
- Set up Docker: a Dockerfile for the backend and a docker-compose file for local dev covering backend and the Supabase CLI local stack
- Set up linting/formatting: ESLint + Prettier for frontend, Ruff/Black + mypy for backend
- Confirm Gemini and Claude API keys are provisioned and reachable via a trivial standalone test script
- Write a root README documenting repo structure and how to run every part locally

**Definition of Done**

- A developer can clone the repo, run one documented command, and have frontend, backend, and local Supabase running together
- Every master plan below can begin its first phase without any further shared setup work

---

## 1. Database Master Plan

Structure and design only — no query syntax. Supabase-based: Postgres, Auth, Storage awareness, and Row-Level Security as the primary ownership-enforcement layer. This plan is foundational and should start first.

### D1 — Identity and Profiles Schema

**Depends on:** SETUP (Supabase project must exist)

**Goal:** A clean identity layer that extends Supabase's own auth without duplicating it.

**Technical Notes**

- Auto-create the profile row via a Postgres trigger on `auth.users` insert, not application code — guarantees a profile always exists even if the backend is briefly unavailable at signup time.
- The admin flag should be a plain boolean or a small enum (`role: "user" | "admin"`), not a separate roles/permissions table — MVP has exactly two access levels; don't over-build a permissions system for them.
- Keep `profiles` free of anything Supabase Auth already stores (email, password hash) — this table exists only for what Auth doesn't cover.

**Tasks**

- Design the `profiles` table: id (matches `auth.users`), display name, usage tier, admin role flag, `created_at`
- Design the RLS policy: a user may select/update only their own profile row
- Design the RLS exception allowing the admin role to read all profiles
- Document the requirement for a profile row to be auto-created on signup

**Definition of Done**

- The `profiles` table design is fully specified and reviewed
- RLS behavior is precise enough to implement without ambiguity

### D2 — Project Domain Schema

**Depends on:** D1

**Goal:** The core project, version, and live-state structure that almost everything else reads or writes.

**Technical Notes**

- `project_live_state` is a deliberate, separate table from `project_versions`, not a view — Realtime needs an actual table with row-level changes to subscribe to, and keeping it separate keeps the potentially large, append-only version history out of the hot, frequently-updated Realtime path.
- The `schema_version` field inside the JSONB is what lets the product evolve the shape of the circuit-graph model later without a flag day — any code reading a project's JSONB checks this field before assuming a shape.
- `current_version` on `projects` is a pointer (foreign key) to the latest row in `project_versions`, never a duplicated copy of its content.

**Tasks**

- Design `projects`: owner_id, title, category, status, favorite flag, timestamps, `current_version` pointer
- Design `project_versions`: full project-model JSONB snapshot, version number, `created_by` (actor shape, see Global Conventions), change summary, parent_version pointer
- Design `project_live_state`: one mutable row per project holding latest state, the Realtime subscription target
- Design the `project_categories` lookup table
- Define the internal JSONB shape convention: `schema_version`, `components[]`, `nets[]`, `requirements{}`, `metadata{}`
- Design RLS: owner-only on `projects`, `project_versions`, `project_live_state`; insert requires `owner_id` to match the caller

**Definition of Done**

- Every table's fields, relationships, and RLS behavior are fully specified
- The JSONB internal shape is documented clearly enough that Backend `B4` can build its data models directly from it

### D3 — Component Catalog Schema

**Depends on:** D1

**Goal:** The reusable component knowledge base that circuit construction, BOM, and the frontend library all depend on.

**Technical Notes**

- Treat `component_alternatives` as needing to be queried in both directions — if A lists B as an alternative, a lookup for B's alternatives should also surface A. Either store the relationship bidirectionally, or make every query check both sides. Getting this wrong silently breaks cost optimization (`B10`/`A5`) for half of all pairs.
- Plan to use Postgres's trigram (`pg_trgm`) or full-text search (`tsvector`) capability on name/category/purpose fields rather than naive substring matching — this table is queried on nearly every AI generation run and every frontend keystroke, so it needs to stay fast as it grows.
- The `data_source/confidence` flag exists specifically to support AI Phase `A8` — an AI-extracted entry must be visibly distinguishable from a human-verified one until reviewed.

**Tasks**

- Design `component_definitions`: name, category, purpose, structured pins (name plus role), electrical characteristics/limits, manufacturer/part number, price (decimal + currency code), availability, asset reference (R2 key), data-source/confidence flag
- Design `component_alternatives`: component-to-component relationship, reason, price-difference note
- Design the `component_categories` lookup table
- Define indexing needs for name/category search
- Design RLS: public read, admin-only write

**Definition of Done**

- Schema is fully specified, including the denormalized-snapshot-at-time-of-use decision, documented clearly for Backend to implement consistently

### D4 — Derived and Generated Data Schema

**Depends on:** D2, D3

**Goal:** Cached or derived outputs with unambiguous staleness rules.

**Technical Notes**

- Don't build the caching layer (`validation_results`, `bom_snapshots`) speculatively "in case it's slow" — implement compute-on-read first, since both are simple aggregations, measure real latency once Backend `B6` exists, and only add caching if the numbers justify it.
- `generated_artifacts.content` stays inline (in the row) for text-based output like code and markdown docs; only reference R2 for genuinely large rendered output like PDFs.

**Tasks**

- Design `validation_results`: per-version findings list with severity, or document the compute-on-read decision
- Design `bom_snapshots` with the same caching decision documented
- Design `generated_artifacts`: source version, stale flag, content (inline or R2 reference)
- Design `export_jobs`: status, requested format, output R2 key, requester
- Design RLS: owner-scoped, mirroring the parent project

**Definition of Done**

- Every derived-data table's shape and staleness behavior is unambiguous for Backend `B6`, `B11`, `B12`, `B15` to build against

### D5 — AI Domain Schema

**Depends on:** D2

**Goal:** Full attribution, conversation continuity, and cost control for every AI action.

**Technical Notes**

- `ai_agent_runs.thread_id` should map directly to the LangGraph checkpointer's own thread identifier — don't invent a second ID to keep in sync.
- `model_usage_logs` needs a row per model call, not per graph run — a single run can call multiple models across multiple nodes, and cost/token tracking (`B18`) needs that granularity.
- Model routing mappings and tier definitions are configured via environment variables and application settings (Pydantic settings) rather than a database table, keeping MVP operations clean and fast.

**Tasks**

- Design `ai_agent_runs`: project, triggering request, status, timestamps, LangGraph thread/checkpoint reference
- Design `ai_action_logs`: tool name, input, output, before/after version reference, model used
- Design `ai_conversation_messages`: project-scoped chat history
- Design `model_usage_logs`: provider, node/step, tokens in, tokens out, latency, estimated cost
- Design `ai_usage_limits`: per-user rolled-up counters and configured limits
- Design RLS: owner-scoped for conversation/run history; usage and limits restricted to service-role and admin read

**Definition of Done**

- Every AI-related table is specified clearly enough for Backend `B13`/`B18` and AI `A1`/`A7`/`A10` to build directly against

### D6 — Admin and Operations Schema

**Depends on:** D1

**Goal:** Infrastructure for system-wide visibility without separate background rollup daemons.

**Technical Notes**

- `failed_generations` should capture enough of the actual input (the user's original request, the stage that failed, the raw error) to reproduce the failure later — a bare error message without context isn't useful weeks later.
- For MVP, admin dashboard metrics (active users, total projects created, AI token counts, failure rates) are computed on-demand via direct, fast SQL aggregation queries over `projects`, `profiles`, `model_usage_logs`, and `failed_generations`, avoiding the need for a separate scheduled cron rollup worker or pre-aggregated tables.

**Tasks**

- Design `admin_audit_logs`: administrative actions on the system itself
- Design `failed_generations`: pipeline stage, project/run reference, input context, error detail
- Design RLS: admin-only read and write

**Definition of Done**

- Schema is ready for failure-capture logic and admin audit logging to write into directly

### D7 — Row-Level Security Policy Pass

**Depends on:** D1, D2, D3, D4, D5, D6

**Goal:** One deliberate, whole-system security review, not policies added ad hoc per table.

**Technical Notes**

- Go table by table, not policy by policy — for each table, write down explicitly what select/insert/update/delete means for an owner, a share-token holder (where relevant), an admin, and the service role, even where the answer is "not allowed." A table with no explicit RLS decision recorded is a table someone will get wrong.
- Cross-check this document against Backend `B19`'s audit before `B19` is considered complete — they should agree exactly.

**Tasks**

- Confirm an explicit RLS policy exists for every table's select/insert/update/delete
- Document every table that allows service-role bypass, cross-referenced against `B19`
- Design the share-token read policy layered on the owner-only base policy, needed by `B16`
- Design the consistent admin-role read-all exception pattern

**Definition of Done**

- A single reviewed document lists every table's RLS behavior with no gaps, ready for `B19` to verify against the real implementation

### D8 — Realtime Configuration

**Depends on:** D2

**Goal:** Deliberate, narrowly-scoped use of Supabase Realtime.

**Technical Notes**

- Follow Global Convention 14: push full current state via Realtime on `project_live_state` for MVP. Don't build the lightweight-invalidation-plus-refetch fallback unless real payload-size data says you need it.
- Enable Realtime on this table and no other — resist adding it to `projects` or `project_versions` "just in case." Every table with Realtime enabled is a table whose change volume needs watching.

**Tasks**

- Decide and document that Realtime is enabled only on `project_live_state`
- Document the exact payload shape the frontend should expect

**Definition of Done**

- Backend `B6` and Frontend `F10` share one unambiguous, agreed contract for what Realtime delivers

### D9 — Migration and Environment Strategy

**Depends on:** D1 through D8

**Goal:** Schema changes that are safe and repeatable across every environment.

**Technical Notes**

- Every migration file is forward-only and reviewed like code — don't hand-edit schema in the Supabase dashboard beyond throwaway local experiments, or dev/staging/prod will drift apart silently.
- Seed data for local/dev should be obviously fake (clearly test-named users, a small recognizable component set) so nobody mistakes it for real data later.

**Tasks**

- Set up the Supabase CLI migration workflow and the `supabase/migrations` folder convention
- Document the process for applying migrations identically across dev, staging, and prod
- Define the initial seed-data strategy

**Definition of Done**

- A migration written once can be applied identically to all three environments via one documented, repeatable command sequence

---

## 2. Backend Master Plan

Python and FastAPI. The priority build. Every engine here (Circuit, Validation, BOM, Codegen, Docs) is built once and reused identically by manual edits and by the AI agent, through a single mutation choke point.

### B1 — Backend Scaffold and Core Conventions

**Depends on:** SETUP

**Goal:** A working, empty-but-correct FastAPI service carrying the conventions every later phase relies on.

**Technical Notes**

- The two Supabase client modules (user-scoped vs. service-role) should have visibly different names in code — for example `db_as_user()` vs. `db_as_service()` — not two options behind one ambiguous function. A reviewer should be able to tell which one is in use at a glance, since picking the wrong one is the core security risk in this architecture.
- Set up the ownership-check helper (`assert_project_ownership`, Global Convention 8) in this phase, even though nothing calls it yet — every later service-role path should import it from day one rather than each phase inventing its own check.
- Adopt the API error shape and pagination convention from Global Conventions now, in the shared exception handler — retrofitting a consistent shape after 15 endpoints exist in various formats is far more expensive than starting right.

**Tasks**

- Implement configuration management (pydantic-settings) reading per-environment values from env vars
- Implement the two Supabase client paths in separate modules
- Implement structured JSON logging with a request-correlation-ID middleware
- Implement a standard exception-handling layer and consistent error response shape
- Create the empty domain module skeleton (routers and services for every domain)

**Definition of Done**

- The app boots, a health-check endpoint responds, and logs show correlation IDs end to end

### B2 — Auth Integration

**Depends on:** B1, D1

**Goal:** Every protected route can reliably identify the calling user.

**Technical Notes**

- Verify the JWT against Supabase's published JWKS endpoint (with the keys cached and refreshed periodically) rather than a hardcoded secret — Supabase can rotate signing keys, and a hardcoded secret fails silently when it does.
- `current_admin` should internally call `current_user` and then check the profile's role flag — don't duplicate JWT-verification logic in a second dependency.

**Tasks**

- Implement the JWT verification dependency against Supabase JWKS
- Extract `user_id` and admin role flag into request context
- Implement reusable `current_user` and `current_admin` dependencies
- Write integration tests confirming invalid/expired tokens are rejected and valid ones pass

**Definition of Done**

- Any route can require an authenticated or admin user through one dependency, verified by tests

### B3 — Project Persistence Skeleton

**Depends on:** B2, D2

**Goal:** Projects can be created, listed, loaded, and managed before any circuit logic exists.

**Technical Notes**

- Apply the pagination convention from the start, even though a test account won't have 100 projects yet — building it in later means every frontend consumer has to change how it calls the endpoint.
- The "load project" endpoint returns the full `project_versions` JSONB for `current_version`, not a partial/summary shape — Frontend `F9`'s store expects the complete model on load.

**Tasks**

- Implement create, list, search, filter, favorite, rename, duplicate, soft-delete endpoints for projects
- Implement a load-project endpoint returning the current snapshot
- Define and validate the base project-model JSON schema, including `schema_version`
- Confirm the generated OpenAPI schema for this domain is clean and complete — Frontend `F4` depends on it directly

**Definition of Done**

- A project can be created, renamed, duplicated, and deleted, and only its owner can access it, verified against D2's RLS policies

### B4 — Circuit Engine: Domain Models and Mutation Service

**Depends on:** B3, D2, D3

**Goal:** The typed data model and the single choke-point function every structural edit must pass through.

**Technical Notes**

- Follow Global Convention 6 exactly: `apply_mutation` takes one normalized `Mutation` object and the `actor` shape, and is the only function anywhere in the codebase permitted to write to `project_live_state`'s circuit data. Code writing to that data anywhere else is a bug, not a valid second path.
- `Pin` objects need an identity that survives a component being moved (position changes) but not one that survives a component being removed and a new one added in its place — use a stable ID scoped to the component instance, not a coordinate-based identity.

**Tasks**

- Define the domain models: `ComponentInstance`, `Pin`, `Net`/`Wire`, `CircuitGraph`, `Requirements`
- Implement `apply_mutation(project_id, mutation, actor)` as the one entry point for every structural change
- Implement actor tracking on every mutation (Global Convention 7)
- Ensure `apply_mutation` always persists new state before returning

**Definition of Done**

- A trivial mutation (adding a hardcoded component) applies correctly and is reflected in persisted state

### B5 — Circuit Engine: Mutation Operations

**Depends on:** B4

**Goal:** Every supported edit operation exists, is correct, and is reachable.

**Technical Notes**

- Net resolution: model pins as nodes and wires as edges in an in-memory graph, then compute connected components (a straightforward union-find or BFS/DFS pass) — each connected component is one logical net. Recompute this fully after every wiring change rather than incrementally patching the previous net list; at MVP's scale (a handful to a few dozen components per project) a full recompute is cheap and far less error-prone.
- Removing a component with active wires should cascade-remove those wires as part of the same mutation (one atomic operation), not leave dangling wire references.
- Rotation is stored as a value (degrees, e.g. 0/90/180/270) on the component instance, not baked into pin coordinates — pin positions stay defined in the component's own local space; rotation is applied at render time on the frontend.

**Tasks**

- Implement add, remove, replace, move, rotate component operations
- Implement connect and disconnect pin operations
- Implement the update-property operation
- Implement the net-resolution algorithm
- Expose every operation as a REST endpoint under the project/circuit router
- Write unit tests per operation, including edge cases

**Definition of Done**

- Every manual editing operation from the product spec is implemented, tested, and reachable via API

### B6 — Circuit Engine: Post-Mutation Pipeline and Realtime Sync

**Depends on:** B5, D2 (project_live_state), D4, D8

**Goal:** Every mutation automatically keeps validation, BOM, and staleness correct, and the frontend can see it live.

**Technical Notes**

- This pipeline runs synchronously inside the same request that made the mutation, not handed off to a background job — validation and BOM results must be correct before the API call returns, since Frontend `F9`'s optimistic-update reconciliation depends on getting a real, final answer back immediately.
- Only staleness-marking for code/docs/flowcharts is "fire and forget" here — don't accidentally make validation or BOM async too.

**Tasks**

- After every mutation: write new state, run validation inline, recompute BOM inline, mark code/docs/flowchart artifacts stale
- Write updated state to `project_live_state`
- Confirm Supabase Realtime correctly pushes the row change using a manual test client
- Add timing instrumentation to confirm this pipeline stays fast under realistic load

**Definition of Done**

- Any mutation results in instantly correct validation and BOM, and a connected Realtime listener sees the update within a second or two

### B7 — Component Database Service

**Depends on:** D3

**Goal:** A fast, queryable, reusable component catalog service.

**Technical Notes**

- This search endpoint is used by both the AI's `search_components` tool and the frontend sidebar — design filters and response shape around what the AI needs to reason over (structured fields, not a text blob), and reuse that exact endpoint for the frontend rather than building a second, different search path.
- Bulk import validates every row against the same model used for single-component creation — no separate, looser validation path "just for import."

**Tasks**

- Implement CRUD endpoints for `component_definitions`, admin-only for writes
- Implement search/filter by category, function, protocol, price range
- Implement an alternatives-graph read endpoint
- Implement a bulk-import endpoint (CSV/JSON) for initial catalog seeding

**Definition of Done**

- The catalog can be searched and filtered fast enough for live use by both the AI's selection tool and the frontend sidebar

### B8 — Validation Engine: Rule Framework

**Depends on:** B4

**Goal:** An extensible framework for deterministic engineering checks.

**Technical Notes**

- Every rule returns findings using the three-level severity enum from Global Convention 9 — a rule inventing its own severity label breaks the AI's ability to decide whether to trigger auto-repair.
- Keep the rule interface synchronous and side-effect-free — a rule only reads the circuit graph and returns findings, never mutates anything.

**Tasks**

- Define the rule-plugin interface: a check function returning a list of findings
- Define the `Finding` model: message, severity, affected components/pins, confidence
- Implement a rule registry
- Implement `run_validation`, running every registered rule and aggregating results

**Definition of Done**

- A dummy rule can be added to the registry and appears in validation output without touching any other code

### B9 — Validation Engine: Initial Rule Set

**Depends on:** B8

**Goal:** The actual safety checks the product promises.

**Technical Notes**

- Build at least one concrete "known-good" and one "known-bad" fixture project per rule — for example, a 5V sensor output wired directly into a 3.3V-only GPIO pin as the canonical voltage-mismatch bad fixture — and keep these fixtures permanently in the test suite. They double as regression protection and living documentation of what each rule catches.
- The "cannot verify" (`info`) finding fires whenever a rule's inputs are incomplete (for example, a component missing electrical-characteristics data) rather than the rule silently passing — silence must never be mistaken for a clean bill of health.

**Tasks**

- Implement voltage-mismatch, current-limitation, power-budget-shortfall, pin-conflict, and missing-required-supporting-component rules
- Implement the low-confidence "cannot verify" finding type
- Write test cases per rule using known-good and known-bad fixtures

**Definition of Done**

- Each rule reliably fires against a crafted bad-circuit fixture and stays silent on a known-good one

### B10 — BOM and Cost Engine

**Depends on:** B7

**Goal:** An always-accurate parts list and cost, plus budget-driven optimization.

**Technical Notes**

- BOM derivation reads only from the current circuit graph's denormalized component snapshots — it must never reach back into the live `component_definitions` catalog for pricing, or a project's BOM total could change on its own when the catalog is updated, breaking the historical-accuracy decision from `D3`.
- `optimize_cost` returns a proposed set of substitutions for the caller to accept — it never silently applies changes itself. The actual mutation still goes through `apply_mutation` like any other edit, with the user or AI agent as the actor who chose to accept it.

**Tasks**

- Implement BOM derivation: aggregate current instances, quantities, denormalized unit prices, total cost
- Implement the budget-optimization function using the alternatives graph
- Expose both as callable service functions for REST and later AI tool use

**Definition of Done**

- BOM total updates correctly after any mutation; budget optimization returns a valid, compatible substitution set on a test project

### B11 — Code Generation Engine

**Depends on:** B6

**Goal:** Firmware generation that can never silently go stale.

**Technical Notes**

- Define the behavioral-logic insertion point as a named, clearly commented placeholder in the Jinja2 template — AI Phase `A5` needs an exact, stable marker to target, not a vague "somewhere in the middle."
- Pin mappings and the required-library list must be derived purely from the circuit graph's current state — never let AI-generated behavioral logic override or duplicate a pin number, since that's exactly the drift the staleness system exists to prevent.

**Tasks**

- Build Jinja2 templates for Arduino and ESP32
- Implement pin-mapping and library-list injection from the current circuit graph
- Define the AI-authored behavioral-logic slot contract
- Implement regeneration-on-stale-access

**Definition of Done**

- Correct pin-mapped code generates for a static test project, with the logic slot clearly marked and ready for AI injection

### B12 — Documentation and Flowchart Generation Engine

**Depends on:** B6

**Goal:** Deterministic documentation scaffolding ready for AI-authored prose.

**Technical Notes**

- The flowchart's structured JSON describes nodes and edges in a simple, generic shape (step id, step type such as read/decide/act, label, next-step references) — no positioning/layout information here; that belongs entirely to the frontend renderer (`F15`).
- Keep the deterministic (wiring/BOM) and AI-authored (prose) sections of a document as separate template partials, not interleaved in one big template — makes it obvious which parts regenerate purely from the model and which require a model call.

**Tasks**

- Build Jinja2 templates for the wiring-guide and BOM-table sections
- Define the AI-authored prose slots (working principle, troubleshooting)
- Implement flowchart generation as structured JSON derived from the generated code's logic
- Confirm the flowchart JSON shape is clean for Frontend `F15` to render as SVG

**Definition of Done**

- A full doc skeleton, minus AI prose, generates correctly for a test project, with a valid flowchart JSON output

### B13 — AI Orchestration Interface (Tool Layer)

**Depends on:** B4, B5, B6, B7, B8, B9, B10, B11, B12, D5

**Goal:** Every backend capability the AI needs, exposed as a typed and fully logged tool.

**Technical Notes**

- Each tool wrapper catches exceptions from the underlying service function and translates them into a structured, LLM-readable error result (a short reason string) rather than letting a raw stack trace propagate into the agent's context — the agent needs to reason about "that failed because X," not parse a Python traceback.
- Tool call logging into `ai_action_logs` happens in this wrapper layer itself, in one place, so no individual tool implementation can forget to log.

**Tasks**

- Wrap every mutation/validation/BOM/codegen/docs function as a typed tool matching AI `A1`'s contract
- Log every tool call into `ai_action_logs`
- Confirm identical behavior whether invoked through this layer or the equivalent REST endpoint

**Definition of Done**

- AI Phases `A2` onward can call every needed backend capability through this layer with nothing missing

### B14 — Versioning and History Service

**Depends on:** B4, D2

**Goal:** Nothing is ever silently lost.

**Technical Notes**

- Decide the exact snapshot-trigger rule up front and keep it consistent: snapshot after generation completes, after a modification-graph run completes, and immediately before any destructive manual action. Do not snapshot on every single mutation, or history becomes noise instead of a meaningful timeline.
- The "what changed" summary is computed by diffing component/net lists between two versions at a coarse level (added/removed/changed component names) — not a full structural JSON diff, which would be unreadable to a non-technical user.

**Tasks**

- Implement snapshot creation at meaningful checkpoints
- Implement restore-from-version and duplicate-from-version endpoints
- Implement a lightweight, component-level "what changed" summary

**Definition of Done**

- A user or test script can restore an earlier version correctly, with a readable change summary available

### B15 — Export Service

**Depends on:** B11, B12, SETUP (Storage buckets must exist)

**Goal:** Projects can leave the platform in genuinely usable form.

**Technical Notes**

- This phase does not depend on the Storage Plan's asset-sourcing work — only on the Storage/R2 buckets themselves existing, which happens in Master Setup.
- Structure the PDF's source as styled HTML/CSS assembled from the same deterministic and AI-authored content pieces used in `B12`, rather than writing PDF layout logic from scratch — WeasyPrint's whole value is letting the document be designed as a webpage.
- Async export jobs run via FastAPI's native `BackgroundTasks` or direct streaming async endpoints without Redis/Arq overhead.
- Follow Global Convention 16: a retried export job for the same request overwrites its own prior output object in storage, never creates a duplicate.

**Tasks**

- Implement export generation: PDF (WeasyPrint), PNG/SVG, raw JSON, BOM data, Arduino/ESP32 project ZIP via FastAPI async endpoints / BackgroundTasks
- Upload generated files to the private storage bucket, store the object key on `export_jobs`
- Implement a job-status polling / direct download endpoint

**Definition of Done**

- Every listed export format can be generated for a test project and downloaded via a signed URL or direct stream

### B16 — Sharing and Permissions

**Depends on:** B3, D2, D7

**Goal:** Projects can be safely shared outside the owner's account.

**Technical Notes**

- Share tokens are a separate, unguessable random value stored in `project_shares`, not a shortened project ID — the RLS policy grants access based on presenting a valid token, not on knowing the project ID at all. Treat "know the ID" and "hold the token" as two completely different security properties.
- Expired tokens fail the same way as invalid ones from the caller's perspective — don't leak whether a token merely expired versus never existed.

**Tasks**

- Implement share-link creation: token, permission level, optional expiry
- Implement the shared-view read endpoint honoring the share-token RLS policy
- Implement duplicate-from-share

**Definition of Done**

- A share link grants correct read-only access to a non-owner; expired/invalid tokens are correctly rejected

### B17 — Admin Dashboard and Analytics Backend

**Depends on:** B2, D6

**Goal:** System health, active users, project volume, and AI usage are visible in real-time without querying the database by hand.

**Technical Notes**

- Metrics are computed on-demand via fast SQL aggregation queries directly against `projects`, `profiles`, `model_usage_logs`, and `failed_generations` — no background cron rollup workers or pre-aggregated tables needed for MVP.
- Failed-generation capture hooks into the same places that already raise/catch exceptions across `B13` and AI Phases `A2`–`A5`, wired in as those phases are built, not retrofitted later.

**Tasks**

- Implement admin-only endpoints: user list, project oversight, system activity feed, real-time aggregate stats
- Implement `failed_generations` capture at every pipeline stage that can fail

**Definition of Done**

- Frontend `F19` has real endpoints for every metric described in the product's admin requirements

### B18 — AI Usage and Token Tracking Backend

**Depends on:** D5

**Goal:** AI cost is tracked and bounded before it becomes a problem.

**Technical Notes**

- The limit check happens before a new LangGraph run is allowed to start, not after — checking usage only after tokens are already spent defeats the purpose.
- Cost estimation per call uses a small, centrally maintained lookup table of per-token pricing by model/provider configured in Pydantic settings, not hardcoded inline at every call site.

**Tasks**

- Log every model call into `model_usage_logs`
- Implement per-user/day usage counters and enforce configured limits before a run starts
- Read model routing mappings and provider credentials from application settings

**Definition of Done**

- Usage and token data is visible per user and per model provider; a user over their limit is correctly blocked from starting a new AI run

### B19 — Security Hardening and Testing

**Depends on:** B1 through B18, D7

**Goal:** Real confidence before real users touch the product.

**Technical Notes**

- Add rate limiting on authentication endpoints and sensible CORS configuration restricting which origins may call the API, in addition to the ownership-check audit — these are easy to forget because nothing "looks broken" without them.
- Load-test specifically the `B6` inline pipeline under concurrent load from multiple simulated users editing different projects at once — this is the one path that must never degrade, since every single edit runs through it.

**Tasks**

- Audit every service-role code path for a manual ownership re-check
- Run a full endpoint-by-endpoint access-control review
- Expand automated test coverage on the Circuit Engine, Validation Engine, BOM Engine, and AI tool-call contract
- Load-test the inline mutation/validation/BOM pipeline

**Definition of Done**

- No service-role path is missing an ownership check; test suite passes; the hot path holds up under realistic concurrent load

### B20 — MVP Integration and Launch Readiness

**Depends on:** B1 through B19, all of the Agentic AI Master Plan, Frontend Phases F1 through F19

**Goal:** Every part of the system working together as one coherent product.

**Technical Notes**

- Run end-to-end scenarios using real, varied natural-language prompts, not just the one example from the original product brief — include at least a few prompts an AI agent could plausibly misread, to genuinely exercise the clarify-or-assume behavior.
- Treat this phase as an explicit checklist against the MVP Definition of Done at the end of this document — every item there gets verified, not assumed true because individual phases were each marked done.

**Tasks**

- Run the full end-to-end flow repeatedly with varied real prompts
- Bug-bash with deliberately messy/ambiguous inputs
- Run a performance pass on LangGraph run latency, PDF export time, code generation time

**Definition of Done**

- The complete idea-to-buildable-project flow works reliably, end to end, on realistic user input

---

## 3. Agentic AI Master Plan

LangGraph orchestration over Gemini and Claude. Two graphs: a mostly-linear generation graph for new projects, and an open-ended, tool-calling modification graph for follow-up edits. Every mutating path is structurally required to pass through validation before a run can complete.

### A1 — Tool and Function Contract Definition

**Depends on:** B4 through B12, D5

**Goal:** The single most load-bearing artifact in the AI system — a stable, typed contract.

**Technical Notes**

- Use the LangChain/LangGraph tool-binding adapter packages for each provider (an Anthropic adapter and a Google/Gemini adapter) rather than hand-rolling tool-call parsing against each provider's raw API — this is exactly the plumbing those adapters exist to standardize, and hand-rolling it risks subtly different tool-calling behavior between the two providers.
- Define every tool's schema once, in a location Backend `B13` also imports from — don't let the AI side and backend side each maintain their own copy of what `search_components` takes as input.

**Tasks**

- Define formal input/output schemas for every tool: `search_components`, `get_component_details`, `add/remove/replace/move/rotate_component`, `connect/disconnect_pins`, `update_property`, `run_validation`, `generate_bom`, `optimize_cost`, `generate_code`, `generate_docs`
- Co-develop this with Backend `B13` so the contract and implementation never drift
- Version the contract so future changes stay additive

**Definition of Done**

- Every tool has an unambiguous schema that both the LangGraph nodes and Backend `B13` implement identically

### A2 — Generation Graph: Requirement Analysis and Component Selection

**Depends on:** A1, B7

**Goal:** Turn free text into structured requirements and grounded, real component choices.

**Technical Notes**

- The `clarify` node follows Global Convention 13 exactly — pause via LangGraph's interrupt mechanism on the same thread, never spin up a second, parallel run while waiting for an answer.
- `select_components` never proceeds to the next node with an empty result for a required capability (for example, "needs a display" but nothing display-related was found) — that's itself a case for `clarify`, not something to silently skip.

**Tasks**

- Implement `analyze_requirements`: structured output (function, inputs, outputs, controller, connectivity, power, budget, ambiguities list)
- Implement the `clarify` node with checkpoint pause/resume
- Implement `select_components`, calling `search_components`, never inventing from memory
- Persist requirements output as part of the project model

**Definition of Done**

- Across varied test prompts, including deliberately ambiguous ones, the graph correctly proceeds or asks one concise clarifying question, and never fabricates a component absent from the catalog

### A3 — Reference Wiring-Pattern Library

**Depends on:** B7

**Goal:** Consistent, stable wiring output instead of a fresh guess on every run.

**Technical Notes**

- Store each pattern as data (component-pairing key to a small structured wiring template), not as prose the model has to re-interpret each time — the goal is for `construct_circuit` (`A4`) to apply a pattern as a near-direct set of `connect_pins` calls, reasoning only about how to adapt it to the specific instance.
- Start with the handful of pairings the MVP's own example scenarios use (a temperature/humidity sensor with a common microcontroller, a display over a standard protocol, a relay driving a motor/pump) — grow it from real usage after that, rather than pre-populating exhaustively before launch.

**Tasks**

- Curate known-good wiring patterns for common component pairings
- Build the lookup mechanism `construct_circuit` checks before falling back to first-principles reasoning
- Establish a lightweight process for adding new patterns

**Definition of Done**

- The most frequent component pairings observed in test usage produce identical, correct wiring on every run

### A4 — Generation Graph: Circuit Construction and Validation

**Depends on:** A2, A3, B5, B8, B9

**Goal:** The heaviest reasoning step in the system, with a structural safety guardrail attached.

**Technical Notes**

- Check the reference library (`A3`) first for a matching or close pairing before reasoning from scratch — "no matching pattern found" is the fallback path, not the default one.
- The bounded auto-repair loop's maximum attempt count should be small and explicit (for example 2 or 3), logged when hit, so the team can see in practice how often circuits need more than one construction attempt — revisit this number with real data, don't leave it as a permanent guess.

**Tasks**

- Implement `construct_circuit`, calling Circuit Engine mutation tools to wire selected components
- Integrate the reference wiring-pattern library
- Implement the `validate` node; the graph cannot terminate successfully without passing through it
- Implement the bounded auto-repair loop, routing back to `construct_circuit` on critical errors up to a fixed max attempts

**Definition of Done**

- No generation run can complete without a validation pass attached to its result; the auto-repair loop is bounded, not able to loop indefinitely

### A5 — Generation Graph: BOM, Code, and Documentation

**Depends on:** A4, B10, B11, B12

**Goal:** Complete the generation pipeline's remaining outputs.

**Technical Notes**

- `generate_code`'s AI call receives the resolved circuit graph and structured requirements as context, and targets only the named insertion point from `B11` — it must not also rewrite surrounding boilerplate, or generated code stops being reliably diffable/regenerable.
- Generate prose sections (`generate_docs`) per-section (working principle, troubleshooting) as separate, smaller model calls rather than one large call for the entire document — cheaper and easier to regenerate individually when only one section goes stale.

**Tasks**

- Implement `generate_bom` (deterministic, always runs)
- Implement `generate_code`, filling the behavioral-logic slot from `B11`
- Implement `generate_docs`, filling the prose slots from `B12`

**Definition of Done**

- A full generation run produces a complete, internally consistent project: circuit, validation, BOM, code, documentation

### A6 — Modification Graph

**Depends on:** A4, A5, B13

**Goal:** The core conversational differentiator: real edits driven by natural language.

**Technical Notes**

- Apply Global Convention 11 (AI run bounds) here specifically — this graph's tool-calling loop is open-ended by design, making it the most likely place in the system for a confused run to loop unnecessarily and rack up cost. The max-tool-calls and timeout limits are not optional here.
- Every read-only "explain" tool call is still logged to `ai_action_logs` even though it made no mutation — a full, honest run history includes what the agent looked at, not only what it changed.

**Tasks**

- Implement the dynamic tool-calling entry point interpreting a follow-up request
- Implement read-only "explain current state" tools for non-mutating questions
- Enforce the same structural guardrail as generation: any mutating path routes through `validate` before completion
- Log every tool call and run

**Definition of Done**

- Every example request type (modify, add, delete, rewire, optimize, explain, validate, document) produces a real correct change or a real correct explanation

### A7 — Model Routing and Cost Optimization

**Depends on:** D5, A2, A4, A5, A6

**Goal:** Right-sized, cost-effective model usage per graph node via clean declarative configuration.

**Technical Notes**

- Configure per-node model assignment directly in application settings (Pydantic settings): lightweight, high-speed tier (e.g. Gemini 1.5/2.0 Flash) for requirement analysis, component search ranking, and initial structuring; advanced reasoning tier (e.g. Claude 3.5 Sonnet) for circuit construction, validation auto-repair reasoning, and conversational modification graphs.
- Direct per-node routing eliminates the latency, cost, and failure surface of an extra dynamic LLM complexity classifier.
- Log which model was used per step in `model_usage_logs` for complete auditability.

**Tasks**

- Implement routing dispatch based on graph node type and configuration settings
- Implement caching for repeated/similar component-pairing lookups

**Definition of Done**

- Routing behavior matches the configured per-node assignments and can be adjusted via environment variables without code changes

### A9 — Evaluation and Regression Framework

**Depends on:** A2, A4, A5, A6

**Goal:** Confidence that changes to prompts, models, or routing never silently degrade quality.

**Technical Notes**

- Store the prompt suite and expected outcomes as versioned data in the repository, not a spreadsheet or a person's head, so it evolves with the code and can be run locally on demand.
- Distinguish "the AI chose a different but still valid component/wiring" from "the AI chose something actually wrong" when defining expected outcomes — encode acceptable alternatives explicitly, or the suite generates constant false alarms.

**Tasks**

- Build a maintained set of real sample prompts, simple through intentionally ambiguous/messy
- Define expected outcomes per prompt
- Create an evaluation runner script to test prompts and flag regressions locally

**Definition of Done**

- The suite runs on demand via a simple command and clearly flags any regression in generation or modification quality

### A10 — Observability

**Depends on:** D5, B17

**Goal:** "Why did the AI do that" is always answerable.

**Technical Notes**

- A single run's full trace (nodes visited, model per step, every tool call with input/output, total latency and cost) must be reconstructable from `ai_action_logs` plus `model_usage_logs` joined on the run ID alone. If answering "what happened in run X" requires cross-referencing five tables by hand, the logging granularity from `B13`/`B18` needs revisiting before this phase is done.

**Tasks**

- Implement full run tracing: node sequence, model per step, tool calls, latency, cost
- Surface this through `ai_action_logs`/`model_usage_logs`, feeding the admin dashboard

**Definition of Done**

- Any single AI run can be fully reconstructed and inspected after the fact by an admin

---

## 4. Frontend Master Plan

Next.js, TypeScript, Tailwind CSS, shadcn/ui, React Flow. Built as a thin, correct rendering and interaction layer over a stable backend API — it owns no circuit logic of its own.

### F1 — Frontend Scaffold and Design System

**Depends on:** SETUP

**Goal:** A consistent visual foundation before any real screen is built.

**Technical Notes**

- Install only the shadcn/ui components actually needed for near-term phases (buttons, cards, dialog, sidebar, tooltip, table) rather than the entire set — shadcn/ui is copy-in, not a dependency, so unused installed components are dead code sitting in the repo.
- Define the Tailwind theme's tokens (colors, spacing, radii) once, in the theme config, and reference them everywhere afterward — resist ad hoc one-off classes for colors that should be theme tokens.

**Tasks**

- Confirm the Next.js App Router structure with route groups: `(auth)`, `(dashboard)`, `(project)/[projectId]`
- Configure the Tailwind and shadcn/ui theme
- Build the base layout shell

**Definition of Done**

- A blank app runs with the design system in place, consistent across a test page in each route group

### F2 — Auth Screens and Session Handling

**Depends on:** F1, B2, D1

**Goal:** Users can securely sign up, log in, and stay logged in.

**Technical Notes**

- Use Supabase's official Next.js SSR helper package for session handling rather than manually managing cookies — it correctly handles the server/client split Next.js's App Router requires, which is easy to get subtly wrong by hand.
- Protected-route middleware redirects to login with a return-to path preserved, so a user linked directly to a project lands back on that project after authenticating.

**Tasks**

- Build signup, login, logout pages
- Wire Supabase SSR session handling for server and client components
- Implement protected-route middleware

**Definition of Done**

- A user can sign up, log in, refresh and stay logged in, and log out correctly; protected routes correctly block unauthenticated access

### F3 — Dashboard: Project List and Management

**Depends on:** F2, B3, D2

**Goal:** The user's project home base.

**Technical Notes**

- Use the pagination convention from day one, even with a handful of test projects, to avoid a rework once real users accumulate dozens.
- Use optimistic UI for rename/favorite/delete, reusing the same reconciliation pattern Frontend `F9` will formalize for the canvas, rather than inventing a separate one-off pattern here.

**Tasks**

- Build the project list/card view with search, filter, favorite, category
- Build the create-project flow
- Build rename/duplicate/delete with confirmation

**Definition of Done**

- Every dashboard action from the product spec works against the real backend

### F4 — Typed API Client Generation

**Depends on:** B3 (a working OpenAPI schema must exist)

**Goal:** Frontend and backend types never silently drift.

**Technical Notes**

- Run codegen via an npm script on demand (`npm run codegen:api`), pointed at the backend's live OpenAPI schema.
- Keep generated types in a clearly marked "do not hand-edit" location, with the thin wrapper (error handling, base URL, auth header injection) in a separate, hand-written file.

**Tasks**

- Set up OpenAPI-to-TypeScript codegen script in `package.json`
- Build a thin API client wrapper with consistent error handling

**Definition of Done**

- Every backend endpoint the frontend uses has a generated, type-safe client function

### F5 — Project Workspace Shell

**Depends on:** F1, F3

**Goal:** The layout skeleton the real workspace pieces slot into.

**Technical Notes**

- Build the loading and error states now, even though the panels inside are placeholders — every later phase that fills in a panel inherits this behavior, so getting it right once is much cheaper than fixing it in fifteen places later.

**Tasks**

- Build the workspace layout: canvas area, sidebar, properties panel, AI chat panel placeholders, toolbar
- Implement route/loading/error states

**Definition of Done**

- Navigating to a project opens a correctly laid-out, if mostly empty, workspace shell

### F6 — Circuit Canvas: React Flow Base Setup

**Depends on:** F5

**Goal:** A working canvas before any real circuit data touches it.

**Technical Notes**

- Use React Flow's controlled mode (state passed in as props, changes handled via callbacks) from the very start, not its uncontrolled/internal-state mode — Frontend `F9`'s store needs to be the single source of truth, and switching modes later means touching every node/edge interaction again.

**Tasks**

- Mount React Flow with pan/zoom/selection enabled
- Wire base node/edge rendering against a static, mock project model

**Definition of Done**

- The canvas pans, zooms, and correctly renders mock nodes/edges

### F7 — Circuit Canvas: Custom Node Types and SVG Symbol Integration

**Depends on:** F6, S2, D3

**Goal:** Real, recognizable component visuals wired to real pins.

**Technical Notes**

- Follow Global Convention 15 exactly: read each pin's viewBox-relative coordinate from the catalog entry and convert it into the handle's CSS position, scaled to the node's actual rendered size — never hardcode handle positions per component type, or every new catalog component requires a code change instead of a data entry.
- Fetch SVG symbol content from the public R2 asset bucket's CDN URL directly, not proxied through the backend — no reason for component visuals to add load to the API.

**Tasks**

- Build one custom React Flow node type per component category
- Render the matching SVG symbol inside each node
- Place React Flow handles at exact pin positions from the catalog

**Definition of Done**

- A real catalog component renders on canvas with correct visual and correctly positioned, connectable pins

### F8 — Circuit Canvas: Wire and Edge Styling and Interaction

**Depends on:** F7, B5

**Goal:** Wiring feels like a real schematic, not a generic diagramming tool.

**Technical Notes**

- Every interaction here calls its backend endpoint and waits for confirmation through the same optimistic-update-then-reconcile pattern Frontend `F9` defines — in practice, sequence this phase together with `F9` rather than fully finishing one before starting the other.

**Tasks**

- Build custom edge styling (orthogonal/step routing)
- Implement connect/disconnect gestures
- Implement select/drag-move/rotate interactions

**Definition of Done**

- Every manual editing interaction from the product spec works and persists via the backend

### F9 — State Management: Store and Backend Sync

**Depends on:** F6, F7, F8, B5

**Goal:** One consistent client-side source of truth mirroring the backend model.

**Technical Notes**

- On a mutation, apply the change to the store immediately (optimistic), then on the API response either confirm it or roll it back with a brief, non-blocking error — never leave the canvas showing a state the backend rejected without any indication.
- Keep React Flow's own internal state entirely derived from this store on every render — if they ever disagree, the store wins, always.

**Tasks**

- Build the Zustand store mirroring the current project model
- Implement optimistic local updates, reconciled against API responses
- Ensure React Flow renders from this store

**Definition of Done**

- Canvas state stays correct through rapid sequences of edits, including failure/rollback cases

### F10 — Realtime Sync Integration

**Depends on:** D8, B6, F9

**Goal:** AI-driven edits appear live on the canvas without a page refresh.

**Technical Notes**

- Per Global Convention 14, the incoming payload already contains full current state — merge it into the store directly rather than treating it as a signal to re-fetch.
- If an incoming Realtime update and a pending local optimistic update conflict (rare, but possible if the AI and a human edit at nearly the same moment), the server-confirmed state from Realtime wins — a reasonable, simple default for MVP. True concurrent-editing conflict resolution is explicitly out of scope.

**Tasks**

- Subscribe to Supabase Realtime changes on `project_live_state` for the open project
- Merge incoming changes into the store using the same reconciliation path as `F9`

**Definition of Done**

- An AI-driven edit appears on an open canvas within a second or two, without conflicting with a human's concurrent local edit

### F11 — Component Library Sidebar and Properties Panel

**Depends on:** B7, F9

**Goal:** Users can browse the catalog and inspect/edit the selected component.

**Technical Notes**

- Debounce the sidebar's search input before calling `B7`'s search endpoint — this is the same endpoint the AI hits, and it will be called far more often from live-typing than from an agent, so protect it accordingly.
- The properties panel's editable fields map directly to `update_property` calls per field, not one big "save all properties" action — keeps manual edits behaving identically, at the mutation level, to how the AI edits a single property.

**Tasks**

- Build catalog browsing/search in the sidebar
- Build the hover-info tooltip
- Build the properties panel wired to `update_property`

**Definition of Done**

- Every piece of hover/selection information from the product spec is visible, and every editable property persists

### F12 — AI Chat Panel: Generation Flow UI

**Depends on:** A2, A4, A5, B13

**Goal:** The initial idea-to-project experience.

**Technical Notes**

- The clarifying-question UI visually distinguishes a paused, awaiting-answer state from a normal chat turn — the person needs to immediately understand the run is stalled specifically waiting on them.
- Progress states reflect the actual generation graph stage (analyzing requirements, selecting components, wiring, validating) using the run trace from AI `A10`, not a generic spinner — cheap to build once `A10` exists and meaningfully improves perceived trust during a wait that can run from seconds to minutes.

**Tasks**

- Build the description-input flow for new projects
- Build the clarifying-question UI matching the checkpoint pause/resume behavior
- Build stage-aware loading/progress states

**Definition of Done**

- A user can describe a project, answer any clarifying question asked, and watch the workspace populate with a real generated circuit

### F13 — AI Chat Panel: Conversational Modification UI

**Depends on:** A6, F9, F10

**Goal:** The core "AI edits my project" experience.

**Technical Notes**

- Render the "actions taken" summary directly from the run's tool-call log (AI `A10`'s tracing), translated into plain language per tool (for example "connected the LED to GPIO 18"), rather than asking the model to separately narrate what it did — a narration generated in a second pass can drift from what the tool calls actually did; the log is ground truth.

**Tasks**

- Build the chat interface for follow-up requests
- Display a summary of actions actually taken
- Ensure canvas updates reflect AI edits via the F9/F10 sync path

**Definition of Done**

- Every example modification request from the product spec produces a visible, correct, explained change

### F14 — Validation and BOM Views

**Depends on:** B8, B9, B10, F9

**Goal:** Trust and cost visibility, always current.

**Technical Notes**

- Style findings by the three-level severity enum consistently — don't introduce a fourth informal visual tier that doesn't correspond to an actual backend severity.
- The BOM view clearly shows which line items came from a denormalized snapshot versus current catalog pricing, if the two ever differ, so users understand why a total might not match today's live prices.

**Tasks**

- Build the warnings/errors panel with severity styling
- Build the BOM table view with quantity, unit price, total, alternatives

**Definition of Done**

- Both views update immediately after any mutation and match exactly what the backend computed

### F15 — Code and Documentation Views

**Depends on:** B11, B12

**Goal:** The buildable-project deliverables, visible directly in the app.

**Technical Notes**

- Render markdown documentation through a safe markdown renderer (one that does not execute embedded HTML/scripts), never via raw HTML injection — this content includes AI-authored prose, and should be treated as untrusted for rendering-safety purposes even though it originates from your own backend.
- The flowchart SVG rendering consumes `B12`'s generic node/edge JSON with its own simple layout pass (a straightforward top-to-bottom or left-to-right auto-layout) — don't expect the backend to hand over pre-computed pixel positions.

**Tasks**

- Build a code viewer with syntax highlighting and a "stale, regenerating" state
- Build a documentation viewer
- Render the flowchart JSON as SVG

**Definition of Done**

- All three views reflect the current project state and never silently show stale content without indicating it

### F16 — Export UI

**Depends on:** B15

**Goal:** Getting the project out of the platform.

**Technical Notes**

- Poll the export job-status endpoint on a short interval after triggering an export, rather than expecting a single request/response for what is an async job — the UI should clearly show "preparing your export" rather than appearing to hang.

**Tasks**

- Build export buttons for PDF/PNG/SVG/JSON/ZIP
- Build job-status polling/toast

**Definition of Done**

- Every export format can be triggered and downloaded successfully from the UI

### F17 — Sharing UI

**Depends on:** B16

**Goal:** Safe project sharing outside the owner's account.

**Technical Notes**

- The shared, view-only page is a genuinely separate route with its own data-loading path using the share token — not a re-use of the owner's authenticated project view with permissions checked client-side. Permission checks belong on the backend/RLS layer, never enforced only by hiding UI elements.

**Tasks**

- Build the share-link generation modal
- Build the shared, view-only project page

**Definition of Done**

- A generated share link opens a correct read-only view for a non-owner, and correctly fails when expired/invalid

### F18 — Versioning UI

**Depends on:** B14

**Goal:** Confidence that nothing is ever truly lost.

**Technical Notes**

- Present the "what changed" summaries as the primary way to browse history (a scannable list of human-readable changes), with drilling into a specific version only as a secondary action — most users want "what happened" far more often than "the exact raw state at time T."

**Tasks**

- Build the version-history list with change summaries
- Build restore and duplicate-from-version actions

**Definition of Done**

- A user can browse history and correctly restore or branch from any prior version

### F19 — Admin Dashboard UI

**Depends on:** B17, B18, D1

**Goal:** System visibility for the team, not just via raw database access.

**Technical Notes**

- This route needs its own layout, separate from the main project workspace shell, since it's about the system as a whole, not any single project — don't force it to reuse the project-workspace layout for consistency's sake.
- Token/usage views are filterable by provider (Gemini vs. Claude) and by time range at minimum, matching the granularity `B18` actually logs at — don't build filter options the underlying data can't support.

**Tasks**

- Build the protected `/admin` route, gated by the admin flag
- Build metrics views
- Build the failed-generation log viewer
- Build AI usage/token-tracking views

**Definition of Done**

- Every metric from the product spec's admin section is visible and correctly reflects backend data

### F20 — Landing Page and Final Polish

**Depends on:** F3, F12

**Goal:** A first impression that matches what the product actually does.

**Technical Notes**

- Build the landing page's demonstration using real captured output from the actual product, not a hand-designed mockup — faster once the product works, and more honest about what a visitor will actually get.
- Scope the mobile pass strictly to the priorities the product spec calls out (viewing projects, basic editing, AI chat, component inspection, documentation) — don't attempt to make the full drag-and-wire canvas mobile-first for MVP; that was explicitly deferred.

**Tasks**

- Build the marketing landing page demonstrating the real flow
- Run a responsive/mobile pass across dashboard, chat, view-only screens
- Run an accessibility pass on core flows

**Definition of Done**

- The landing page accurately represents the shipped product; core flows are usable on mobile within the defined scope

---

## 5. Storage Plan

Cloudflare R2. Short and practical — this is the track the non-technical teammate owns day to day, sourcing and uploading component visuals while the rest of the team builds the product around them.

### S1 — Visual Standards and Naming Convention

**Depends on:** SETUP (buckets must exist), D3

**Goal:** A shared standard so assets and catalog entries connect without guesswork.

**Technical Notes**

- The pin/connection-point placement convention agreed here must exactly match Global Convention 15 (viewBox-relative coordinates) that Frontend `F7` reads — write this so a non-technical person can follow it exactly without needing to understand *why* the convention exists, only *what* to do.
- Keep the standard to one page. A long, comprehensive style guide won't actually get followed consistently by someone doing this as a side task; a short, concrete checklist will.

**Tasks**

- Agree the SVG visual standard: viewBox convention, transparent background, stroke width, color palette
- Agree the pin/connection-point placement convention
- Agree the folder/naming convention
- Set up the shared tracking spreadsheet

**Definition of Done**

- A written one-page standard exists that the non-technical teammate can follow for routine components without further tech input

### S2 — Asset Sourcing and Upload

**Depends on:** S1

**Goal:** The actual asset library gets built. This is the non-technical teammate's core, ongoing work.

**Technical Notes**

- When in doubt about a component's pin count or layout, flag it in the tracking spreadsheet for tech to confirm rather than guessing — an incorrectly placed pin is a silent bug that only surfaces later on the canvas, while a flagged question gets resolved in minutes.

**Tasks**

- Source or create SVGs for the highest-frequency components first
- Follow the S1 visual standard exactly, including pin placement
- Upload via the Cloudflare dashboard's file browser
- Keep the tracking spreadsheet current

**Definition of Done**

- The highest-frequency component set has correctly standardized, uploaded SVGs, tracked in the spreadsheet

### S3 — Catalog Linking Handoff

**Depends on:** S2, B7

**Goal:** Uploaded assets actually become usable in the product.

**Technical Notes**

- Link a small batch (five to ten components) first and verify them on the real canvas before bulk-linking the rest of the spreadsheet — this catches a systemic coordinate-convention mistake after a handful of components instead of after all of them.

**Tasks**

- Tech links each asset's R2 key into its `component_definitions` entry via `B7`'s admin tools
- Spot-check a handful of linked components on the real canvas

**Definition of Done**

- Every tracked, uploaded asset is correctly linked and renders correctly, with working pins, on the real canvas

---

## 6. Cross-Plan Dependency Map

| Phase | Requires First                      |
| ----- | ----------------------------------- |
| SETUP | Nothing                             |
| D1    | SETUP                               |
| D2    | D1                                  |
| D3    | D1                                  |
| D4    | D2, D3                              |
| D5    | D2                                  |
| D6    | D1                                  |
| D7    | D1–D6                              |
| D8    | D2                                  |
| D9    | D1–D8                              |
| B1    | SETUP                               |
| B2    | B1, D1                              |
| B3    | B2, D2                              |
| B4    | B3, D2, D3                          |
| B5    | B4                                  |
| B6    | B5, D2, D4, D8                      |
| B7    | D3                                  |
| B8    | B4                                  |
| B9    | B8                                  |
| B10   | B7                                  |
| B11   | B6                                  |
| B12   | B6                                  |
| B13   | B4–B12, D5                         |
| B14   | B4, D2                              |
| B15   | B11, B12, SETUP                     |
| B16   | B3, D2, D7                          |
| B17   | B2, D6                              |
| B18   | D5                                  |
| B19   | B1–B18, D7                         |
| B20   | B1–B19, all of Agentic AI, F1–F19 |
| A1    | B4–B12, D5                         |
| A2    | A1, B7                              |
| A3    | B7                                  |
| A4    | A2, A3, B5, B8, B9                  |
| A5    | A4, B10, B11, B12                   |
| A6    | A4, A5, B13                         |
| A7    | D5, A2, A4, A5, A6                  |
| A9    | A2, A4, A5, A6                      |
| A10   | D5, B17                             |
| F1    | SETUP                               |
| F2    | F1, B2, D1                          |
| F3    | F2, B3, D2                          |
| F4    | B3                                  |
| F5    | F1, F3                              |
| F6    | F5                                  |
| F7    | F6, S2, D3                          |
| F8    | F7, B5                              |
| F9    | F6, F7, F8, B5                      |
| F10   | D8, B6, F9                          |
| F11   | B7, F9                              |
| F12   | A2, A4, A5, B13                     |
| F13   | A6, F9, F10                         |
| F14   | B8, B9, B10, F9                     |
| F15   | B11, B12                            |
| F16   | B15                                 |
| F17   | B16                                 |
| F18   | B14                                 |
| F19   | B17, B18, D1                        |
| F20   | F3, F12                             |
| S1    | SETUP, D3                           |
| S2    | S1                                  |
| S3    | S2, B7                              |

---

## 7. MVP Definition of Done

The MVP is complete when every phase above is done and, end to end, all of the following are true:

- A user can describe a project in plain language and receive structured requirements, real components grounded in the catalog, and a wired, validated 2D circuit.
- Manual edits and AI-driven edits both go through the identical Circuit Engine mutation path and produce identically synced BOM, validation, code, and documentation.
- No warning or safety claim is ever shown without a corresponding deterministic Validation Engine result behind it, enforced structurally by the AI graph, not just by a prompt instruction.
- A complete, accurate PDF documentation package can be exported at the end of the flow.
- Row-Level Security enforces ownership at the database layer, and every service-role backend code path has been manually audited for the ownership checks RLS cannot provide there.
- AI usage and token spend are tracked per model provider and correctly bounded per user, and every AI run is bounded in tool calls and wall-clock time.
- Failures anywhere in the pipeline are visible on the admin dashboard, never silent.
- The component asset library, sourced and uploaded through the Storage Plan, is fully linked and rendering correctly — pins included — on the real circuit canvas.

Everything explicitly out of scope for this MVP — 3D visualization, full PCB design and routing, ngspice simulation, KiCad export, real-time multiplayer collaboration, a marketplace, and native mobile apps — stays out of scope until this loop is proven end to end.
