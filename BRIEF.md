# JobTrack — project brief

A small, public Rails 8 + React + TypeScript app for tracking a job search. Built over one weekend to show production-quality React/TypeScript work alongside deep Rails experience.

**Audience:** hiring managers and engineers who open the GitHub repo for 5 minutes. It should look like work from a senior engineer: clean structure, typed front end, real tests, green CI, a clear README.

**Owner's goal:** be able to explain every React and TypeScript decision in an interview. Agents build; Chris reviews every PR and asks agents to explain anything unfamiliar.

---

> **Status:** all tasks (T0 to T11) are built and merged. This brief is the original plan; where it differs from the code (notably PostgreSQL, replaced by SQLite in T10), the code and README win.

---

## Stack

| Layer | Choice | Notes |
|---|---|---|
| Back end | Rails 8, Ruby 3.4, SQLite | Rails 8 built-in authentication generator (single user) |
| Front end | React + TypeScript (strict) | Function components and hooks only |
| Glue | `inertia_rails` + `vite_rails` | React pages served by normal Rails controllers and routes |
| Styling | Tailwind CSS | Keep it plain and tidy; no design detours |
| Drag and drop | `@dnd-kit/core` | For the status board |
| Background jobs | Solid Queue (Rails 8 default) | Recurring follow-up job |
| Ruby tests | RSpec (model, request) | FactoryBot |
| JS tests | Vitest + React Testing Library | Component behavior, not snapshots |
| Lint / types | RuboCop (rails-omakase), ESLint, `tsc --noEmit` | All run in CI |
| CI | GitHub Actions | SQLite, no service container |
| Deploy (stretch) | Kamal | Rails 8 default |

Use current stable versions of each gem and package. Pin them in the lockfiles; don't add dependencies beyond this list without noting why in the PR.

## Data model

**Opportunity**
- `company` (string, required)
- `role` (string, required)
- `kind` (enum: `full_time`, `contract_w2`, `contract_c2c`)
- `source` (enum: `network`, `recruiter`, `agency`, `job_board`, `direct`)
- `status` (enum: `not_contacted`, `contacted`, `talking`, `interviewing`, `offer`, `closed`)
- `pay_min`, `pay_max` (integer, optional); `pay_unit` (enum: `hourly`, `yearly`)
- `url` (string, optional)
- `contacted_on`, `follow_up_on` (date, optional)
- `notes` (text)
- `position` (integer, ordering within a status column)
- timestamps

**Activity** (belongs to Opportunity)
- `kind` (enum: `email`, `call`, `interview`, `note`)
- `occurred_on` (date, required)
- `body` (text, required)
- timestamps

Validations: required fields; `pay_max >= pay_min` when both present; `follow_up_on` not before `contacted_on`.

## Pages

1. **Dashboard** (`/`): counts by status, "follow-ups due" list (today or overdue), recent activity.
2. **Opportunities** (`/opportunities`): table with filters (status, kind), text search on company/role, sort by follow-up date.
3. **Board** (`/board`): columns per status; drag a card to change status and order. Optimistic UI update; roll back with an error message if the server rejects it.
4. **Opportunity detail** (`/opportunities/:id`): fields, pay range shown in the right unit, activity timeline, inline "add activity" form.
5. **New / edit** (`/opportunities/new`, `/opportunities/:id/edit`): Inertia `useForm`, client-side required-field checks, server validation errors shown per field.

All pages behind sign-in (Rails 8 authentication generator).

## Background job

`FollowUpReminderJob`, a Solid Queue recurring job, runs daily at 7am ET. It marks opportunities with `follow_up_on <= today` and an open status as due, and the dashboard shows them. RSpec covers the selection logic.

## Front-end conventions

- `app/frontend/types.ts` holds TypeScript types matching each controller's Inertia props. No `any`.
- Shared components in `app/frontend/components/`: `StatusBadge`, `PayRange`, `Field`, `Button`, `EmptyState`.
- Pages in `app/frontend/pages/<Resource>/<Action>.tsx`.
- Each component that has behavior gets a Vitest + Testing Library test.

## Seed data

**Fictional companies and people only** (e.g. "Acme Logistics", "Northwind Health"). Never commit real recruiter names, companies from the real search, or personal notes. About 15 opportunities across every status, each with 1–4 activities.

## README outline

1. One-line description and a screenshot of the Board
2. Why it exists (two sentences: a real tool, built to show Rails 8 + React + TypeScript)
3. Stack table
4. Running locally (`bin/setup`, `bin/dev`, seed)
5. Tests and CI (`bin/rspec`, `npm test`, `npm run typecheck`)
6. Design notes: Inertia over a separate SPA; optimistic drag-and-drop; Solid Queue recurring job
7. How it was built: AI-assisted, parallel git worktrees, every change reviewed and tested

---

## Task breakdown for parallel worktrees

Run T0 alone first and merge it. Then run each group in parallel; start a group when its dependencies are merged.

### T0 — Scaffold (serial, merge first)
- `rails new jobtrack` (no default JS bundling; Vite replaces it). Started on PostgreSQL; T10 moved to SQLite
- Add `vite_rails`, `inertia_rails`, React, TypeScript (strict), Tailwind
- Inertia root layout and one "Hello" page rendered from a Rails controller
- Run the Rails 8 authentication generator; seed one user
- RSpec and FactoryBot set up; Vitest + Testing Library set up with one passing test
- GitHub Actions workflow: RuboCop, RSpec, ESLint, `tsc --noEmit`, Vitest
- **Done when:** `bin/dev` serves a signed-in React page and CI is green

### Group A (parallel, after T0)
- **T1 Models:** migrations, enums, validations, factories, model specs, seeds (fictional data)
- **T2 Front-end shell:** layout, nav, shared components, `types.ts`, component tests
- **T3 Tooling:** ESLint and Prettier config, `npm` scripts (`test`, `typecheck`, `lint`), RuboCop clean

### Group B (parallel, after T1 + T2)
- **T4 Opportunities index:** controller, filters, search, sort; request specs; page component tests
- **T5 New / edit form:** `useForm`, client checks, server errors per field; request + component tests
- **T6 Detail + activities:** show page, timeline, inline add-activity form; tests
- **T8 Follow-up job:** Solid Queue recurring config, job, dashboard query; specs

### Group C (after T4)
- **T7 Board:** `@dnd-kit` columns, `PATCH /opportunities/:id/move` (status + position), optimistic update with rollback; request spec + component test for move and rollback
- **T9 Dashboard + README:** dashboard page, screenshots, README per outline

### Stretch (during the week)
- **T10 Deploy with Kamal** to a small VPS; add the live URL to the README
- **T11 JSON API:** `/api/v1/opportunities` with token auth; request specs

---

## Review checklist (for Chris, per PR)

Read each React PR for these, and have the agent explain anything unclear:

- [ ] Props typed with an interface or type, no `any`
- [ ] State lives in the lowest component that needs it; lifted only when shared
- [ ] `useEffect` used only for real side effects, with correct dependencies
- [ ] List items have stable `key`s (ids, not array indexes)
- [ ] Forms are controlled; errors shown next to fields
- [ ] Tests check behavior a user sees, not implementation details
- [ ] CI green

## Interview talking points to be ready for

- Components, props, and state; when to lift state up
- `useState`, `useEffect`, and why most data here comes from Inertia props instead of `fetch`
- Controlled forms and showing server-side validation errors
- Optimistic UI on the board: update first, roll back on failure
- TypeScript: typing props, union types for enums (`type Status = 'not_contacted' | ...`)
- Why Inertia instead of a separate React SPA plus API
- How the Solid Queue recurring job works, compared with Sidekiq
