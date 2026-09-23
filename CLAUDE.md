# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this workspace is

This is **not an application repo** — it is a training-lab template for a course on agent-assisted development (sessions S2–S6). The root folder (`citas/`) is an orchestration workspace, not itself a Git repository. It contains **two independent Git repositories** that a student builds out from scratch during the course:

- `citas-api/` — Java 21 + Spring Boot 3.5.x backend. Currently contains only `README.md`, `AGENTS.md.template`, `.env.example`, and empty `docs/`/`automations/` scaffolding (`.gitkeep` files). **No source code, no `pom.xml`, no Spring project exists yet.**
- `citas-web/` — TypeScript frontend (React or Angular, decided later via Stitch/Google AI Studio export). Currently contains only `README.md`, `AGENTS.md.template`, `.env.example`. **No frontend project exists yet.**

Each has its own `.git`, its own `main`/`develop` branches, and must be committed to independently. Do not turn the root `citas/` folder into a third Git repo, and do not add business logic to the root — backend logic belongs in `citas-api`, UI belongs in `citas-web`.

Because no implementation exists yet, there are **no build/lint/test commands to run** until a student initializes the Spring Boot project and imports the frontend. Once those exist, standard Maven (`./mvnw test`, `./mvnw spring-boot:run`) and Node/Vite or Angular CLI commands apply — check each repo's own generated config (`pom.xml`, `package.json`) rather than assuming, since the framework choice for the frontend is made per-student.

## Infrastructure commands (PowerShell, run from repo root)

```powershell
Copy-Item .env.example .env          # required before any docker command
.\scripts\preflight.ps1              # validates required files, Docker, and ports
docker compose up -d mysql           # start only MySQL
docker compose ps
.\scripts\db-smoke-test.ps1          # verifies db.sql loaded and is queryable
docker compose --profile dev up -d   # optional: Java/Maven + Node dev containers (mount empty repos, no app inside)
.\scripts\reset-db.ps1               # DESTRUCTIVE: drops the mysql volume, recreates, reseeds
.\scripts\init-repos.ps1             # idempotent: git init + main/develop for citas-api and citas-web if missing
```

MySQL listens on host port `3307` by default (mapped from container `3306`); the API dev container reaches it at `mysql:3306`. Backend/frontend dev servers run inside `citas-api-dev` (port `8080`) and `citas-web-dev` (ports `5173` React / `4200` Angular) containers, which only provide toolchains — the student's project code must be created inside the mounted `citas-api`/`citas-web` folders.

## Architecture the student must build

### Backend (`citas-api`)
- Java 21, Spring Boot 3.5.x, Maven, **hexagonal architecture** (domain/application independent of adapters).
- Spring Data JPA + MySQL 8.4 + Flyway migrations.
- Spring Security with JWT access + refresh tokens (separate secrets), password hashing via BCrypt/Argon2.
- Pure REST/JSON API — **no BFF, no Express layer**; `citas-web` calls `citas-api` directly.
- Documentation lives under `citas-api/docs/wiki/`:
  - `scrum/` — epics/user stories, written **only** by the `scrum-spec-orchestrator` skill (never implements code).
  - `llm-wiki/` — the single global project wiki (RAW/WIKI/SCHEMA pattern; see `prompts/agents/PROMPT_AGENT_ORQUESTADOR.md`), maintained by the orchestrator agent.
- n8n workflow JSON exports are versioned in `citas-api/automations/n8n/` (see the `WF-00x-*.md` specs already present there).

### Frontend (`citas-web`)
- Framework choice (React or Angular) is made per-student when exporting from Stitch → Google AI Studio; do not assume one over the other — check `package.json`/`angular.json` once the project exists.
- Node.js 24 LTS runtime. Backend URL is environment-configurable (see `VITE_API_URL` in `.env.example`).
- Built by importing generated code from Google AI Studio, then reconciled against the Stitch-approved design using the `stitch-design-to-frontend` skill.

### Domain model (reference only — see `database/reference/`)
`database/reference/db.sql` and `erd.mmd`/`ERD_citas_FCV.*` are the **trainer's reference solution**, normalized to 3NF. Students first design their own schema from `database/REQUISITOS_NORMALIZACION_3FN.md` before comparing against the reference. Key shape to know when reasoning about the domain:
- `users` / `roles` / `user_roles` separate identity from role (USER, PROFESSIONAL, ADMIN) without duplicating personal data.
- `professionals` extends a `user` with role PROFESSIONAL; specialties and sedes (locations) are N:M via bridge tables; one specialty is marked primary.
- Insurance chain: `insurance_regimes` → `eps` → `eps_plans` → `user_insurance_affiliations` (a user's affiliation references a plan; regime/EPS are derived, never duplicated).
- Availability: a professional's `availability_blocks` (e.g. 08:00–12:00 HIC) expand into atomic 30-minute slots; a 60-minute specialty consumes two consecutive slots.
- Appointments: general appointments (`Medicina General`) auto-approve; specialized appointments start `REQUESTED` and need ADMIN approval/rejection (rejection requires a reason).
- Rescheduling is a separate entity that holds both the old and proposed slot; the original appointment is untouched until ADMIN approves/rejects.
- `appointment_status_history` is the append-only audit trail for every status transition (actor, source SYSTEM/USER/ADMIN, timestamp, optional reason) — never mutated like a normal CRUD table.
- Two fixed sedes (locations) with real public names: Hospital Internacional de Colombia (HIC) and Fundación Cardiovascular de Colombia / Instituto Cardiovascular (ICV). Everything else (patients, professionals, credentials, schedules, appointments) is synthetic — see "Data policy" below.

Full functional/business rules are enumerated in `PRD.md` (RF-01…RF-20, RN-01…RN-12) and `RESTRICCIONES_TECNICAS.md` — read both before generating specs or code for this domain.

## Skills and agent prompts

- `skills/scrum-spec-orchestrator` — generates epics/user stories/acceptance criteria/DoD into `citas-api/docs/wiki/scrum/`. Never writes implementation code.
- `skills/stitch-design-to-frontend` — governs prototyping in Stitch, design approval, handoff to Google AI Studio, and reconciliation into `citas-web`. Never invents backend behavior.
- `prompts/agents/PROMPT_AGENT_ORQUESTADOR.md` — the cross-repo orchestrator prompt (root `AGENTS.md` owner, LLM-wiki maintainer). Read this before doing cross-repo work.
- `prompts/agents/PROMPT_AGENT_CITAS_API.md` / `PROMPT_AGENT_CITAS_WEB.md` — used to generate each repo's own `AGENTS.md` once real code exists (backend after Spring Boot init; frontend after AI Studio import) — don't treat the current `AGENTS.md.template` files as real instructions.
- `prompts/goal-loop/` and `prompts/subagents/` — GOAL/LOOP exercises and Builder/Verifier subagent prompts used progressively across sessions S2–S4; see `GUIA_SESIONES_S2_S6.md` for which one applies to which session.

## Git workflow

- Two repos only: `citas-api`, `citas-web`. Work happens on `develop`; `main` is merged to only when the student considers a state stable — no merge is required per session.
- At least one traceable commit per repo per session (S2–S6); never rewrite history to hide progress (no destructive squash/rebase before evaluation).
- `.env.example` in each repo must stay free of real secrets; never commit `.env`, JWT secrets, DB passwords, OAuth/n8n credentials, or MCP tokens.

## Data policy

This is an academic simulation: sede names and public specialty names may reference real FCV public information, but all patients, professionals, credentials, EPS/plans, schedules, and appointments are synthetic. Never introduce real FCV patient/clinical/billing data. Out of scope entirely: clinical history, real billing/payments, diagnoses/treatments, SMS/WhatsApp, mandatory SMTP, mandatory CI/CD.
