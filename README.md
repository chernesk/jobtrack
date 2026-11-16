# JobTrack

A small Rails 8 + React + TypeScript app for tracking a job search: a dashboard, a filterable list, a drag-and-drop status board, and a timeline of activity for each opportunity.

![The board: one column per status, cards draggable between and within columns](docs/screenshots/board.png)

## Why it exists

It's a real tool I wanted for my own search, and a compact place to show Rails 8 and React/TypeScript working together. Rails still owns routing, auth, validations and the database. React replaces only the view layer, through Inertia, so there is no separate API to build and keep in sync.

![The dashboard: counts by status, follow-ups due and recent activity](docs/screenshots/dashboard.png)

## Stack

| Layer | Choice |
|---|---|
| Back end | Rails 8.1, Ruby 3.4, SQLite, Rails' built-in authentication (single user) |
| Front end | React 19, TypeScript (strict, no `any`), function components and hooks |
| Glue | `inertia_rails` + `@inertiajs/react`, `vite_rails` |
| Styling | Tailwind CSS 4, with a light/dark theme |
| Drag and drop | `@dnd-kit/core` |
| Ruby tests | RSpec (model and request specs), FactoryBot |
| JS tests | Vitest + React Testing Library |
| Lint and types | RuboCop (rails-omakase), ESLint (type-aware), Prettier, `tsc --noEmit`, Brakeman, bundler-audit |
| Background jobs | Solid Queue (database-backed, no Redis) |
| CI and deploy | GitHub Actions; Kamal to a single server |

## Running locally

You need Ruby 3.4 and Node 22 (versions are in `.tool-versions`, so [mise](https://mise.jdx.dev) can install both). There is no database server to run: SQLite files live in `storage/`.

```sh
bin/setup --skip-server   # installs gems and packages, creates and seeds the database
bin/dev                   # Rails + Vite on http://localhost:3000
```

Sign in with the seeded demo account: `demo@example.com` / `password`. The seed data is entirely fictional (made-up companies, `example.com` URLs). If port 3000 is busy, use `PORT=3100 bin/dev`.

![The sign-in page](docs/screenshots/sign-in.png)

Everything except sign-in requires an account, so there is no public live demo. The screenshots above show the app with the seeded fictional data.

## Tests and CI

```sh
bin/rspec            # Ruby specs
npm test             # Vitest
npm run typecheck    # tsc --noEmit
npm run lint         # ESLint
bin/ci               # everything CI runs, locally
```

GitHub Actions runs RuboCop, Brakeman, bundler-audit, RSpec, ESLint, Prettier, `tsc` and Vitest on every pull request.

## Design notes

**Inertia over a separate SPA.** A controller renders `render inertia: "Opportunities/Show", props: {...}` and that hash is the React page's props. Sessions, CSRF, flash messages, redirects and validations stay ordinary Rails. The cost is that React is coupled to Rails; a mobile client would need a real API. `app/frontend/types.ts` pins down each page's props, and request specs assert the same shapes.

**Filters live in the URL.** The opportunities list keeps its search, status, type and sort in the query string. Each change is a normal GET that Rails answers with fresh props, so links are shareable, a reload keeps the filters, and there is no client-side filtering logic to keep in step with the server. The search box is debounced.

**Optimistic drag and drop.** On the board, dropping a card updates the columns immediately and sends `PATCH /opportunities/:id/move`. The move logic is pure functions (`app/frontend/lib/board.ts`) with their own tests. If the server rejects the move, or the request fails, the card goes back and a message explains. A single check in the request's `onFinish` covers every failure. Fresh props from Rails always replace the local state. Dragging works with the keyboard too (Space to pick up, arrows to jump between cards and columns).

**Forms.** One `OpportunityForm` serves new and edit with Inertia's `useForm`. Required fields are checked in the browser for instant feedback, and Rails' validation errors come back per field and render next to the right input through a small accessible `Field` component. The server is the authority.

**A recurring job for time-based state.** An opportunity becomes "due" when its follow-up date arrives, which is not an edit, so nothing in a request would notice. A stored `due` flag keeps the dashboard to one indexed query. A `before_save` callback keeps it right when you edit a record, and `FollowUpReminderJob` (Solid Queue, declared in `config/recurring.yml`, 7am Eastern) rolls it over each morning, turning it on for newly due records and off for any that no longer qualify. The rule lives in one scope, `Opportunity.follow_up_due`, and specs check the callback and the job agree with it. Solid Queue is database-backed, so there is no Redis. In development nothing runs the scheduler; run `bin/rails runner FollowUpReminderJob.perform_now` to refresh the flags by hand.

**SQLite in production.** This is a single-user app, so SQLite is a good fit and removes a moving part: Rails 8 runs the app, Solid Queue (jobs), Solid Cache and Solid Cable each in their own SQLite file on one persistent volume. The one place the model had to care was search: it uses Arel's `matches` (a case-insensitive `LIKE` with explicit escaping) rather than Postgres-only `ILIKE`. Development, CI and production all use the same database, so there is no "works on my Postgres" gap. The trade-offs are one writer at a time and one server; neither matters here.

**Rails enums.** Status, kind, source and pay unit are string-backed enums with `validate: true`, so a bad value is a normal validation error rather than an exception.

## JSON API

The web UI is Inertia, so it has no public API. A small token-authenticated one lives under `/api/v1/opportunities` for scripts and other clients: list (`q`, `status`, `kind`, `dir` filters), show, create and update, with the same fields and validations as the form.

```sh
bin/rails 'api_tokens:create[you@example.com,laptop]'   # prints a token once
curl -H "Authorization: Bearer $TOKEN" https://your.host/api/v1/opportunities?status=talking
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"opportunity":{"company":"Acme Logistics","role":"Rails Engineer"}}' https://your.host/api/v1/opportunities
```

Errors are JSON: 401 for a missing or wrong token, 404 for an unknown id, 422 with `{"errors": {"field": ["message"]}}` for invalid data, 400 for a body without `opportunity`.

**Design notes.** The API controllers inherit from `ActionController::API`, so there are no cookies, sessions or CSRF to reason about, and a browser session does not authenticate an API call. Only a SHA-256 digest of each token is stored (tokens are long random strings, so a slow password hash is unnecessary and the indexed lookup stays cheap), and the plaintext is shown once when issued. Requests are rate limited to 120 a minute. The editable fields come from one constant, `Opportunity::EDITABLE_ATTRIBUTES`, shared with the web form, so the two cannot drift. There is no delete, pagination or board-move endpoint yet, because the app has none of those in the UI either.

## How it was built

This was built with AI assistance: agents drafted each task in its own git worktree and branch, one pull request per task, each with tests. I scoped the work, reviewed every pull request, ran each change in a real browser, and can explain the decisions in it. The commit and pull request history shows the sequence.

## Deploying

The app deploys to a single server with [Kamal](https://kamal-deploy.org) (Docker, with automatic HTTPS from Let's Encrypt). You need a Linux server you can SSH into as root, a domain name pointing at it, Docker on your machine, and a GitHub token with the `write:packages` scope (images go to `ghcr.io`).

```sh
export DEPLOY_SERVER_IP=203.0.113.10        # your server
export DEPLOY_HOST=jobtrack.example.com     # your domain
export KAMAL_REGISTRY_PASSWORD=ghp_...      # GitHub token, write:packages

bin/kamal setup                             # first time: installs Docker, boots the app
bin/kamal app exec -i "bin/rails 'users:create[you@example.com]'"   # prompts for a password
```

Later deploys are `bin/kamal deploy`. Notes:

- Demo seed data is never loaded in production, and no default login exists; the only user is the one you create.
- The database lives on a Docker volume (`jobtrack_storage`), so it survives deploys. Back it up with `bin/kamal app exec "sqlite3 storage/production.sqlite3 .dump"` or by copying the volume.
- The job queue runs inside the web process (`SOLID_QUEUE_IN_PUMA`), which is where the daily 7am follow-up job runs.
- `bin/kamal logs` and `bin/kamal console` are shortcuts defined in `config/deploy.yml`.

## Running in a container

For personal use, the simplest setup is one container on a machine you own (a home server, a NAS), with the data on a volume. Nothing is exposed to the internet and there is no domain or certificate to manage. The image is built by the `Publish image` workflow and pulled from `ghcr.io/chernesk/jobtrack`.

```sh
cp compose.env.example .env                  # then set SECRET_KEY_BASE=$(openssl rand -hex 64)
docker compose up -d                         # http://localhost:3200
docker compose exec jobtrack bin/rails 'users:create[you@example.com]'   # prompts for a password
```

To build from a checkout instead of pulling: `docker compose -f compose.yaml -f compose.build.yaml up -d --build`.

**TrueNAS (24.10 or later).** In Apps, choose Discover Apps, then Custom App, then Install via YAML, and paste `compose.yaml` with `SECRET_KEY_BASE` set to a real value (there is no `.env` file there; change the port if 3200 is taken). Open a shell on the app (Apps, the app's workloads, Shell) to run the `users:create` command above. To keep the data in a dataset you control, replace the named volume with a host path such as `/mnt/<pool>/apps/jobtrack:/rails/storage`, and give it to the container's user first: `chown 1000:1000 /mnt/<pool>/apps/jobtrack`. The package is private by default; either make it public in the repository's package settings (simplest) or give the host a `ghcr.io` login with a GitHub token that has `read:packages`.

Notes:

- The container serves plain HTTP (`FORCE_SSL=false`), so keep it on your home network. To reach it from outside, put a reverse proxy that terminates HTTPS in front and remove that setting.
- All state is in `/rails/storage` (the app, queue, cache and cable SQLite files). Keep `SECRET_KEY_BASE` stable: changing it signs you out but loses nothing.
- Back up by copying that directory while the container is stopped, or with `docker compose exec jobtrack sqlite3 storage/production.sqlite3 ".backup storage/backup.sqlite3"`.
- To upgrade, pull the new image and recreate: `docker compose pull && docker compose up -d`. The entrypoint runs `db:prepare`, so migrations apply on start.
- Your real data lives only in that volume. Never commit it; the repo's seeds are fictional on purpose, and they never load in production.

## License

[MIT](LICENSE).
