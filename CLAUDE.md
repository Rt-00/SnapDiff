# SnapDiff

> Snapshot, compare and monitor API responses over time. Detect drift before it becomes a problem.

---

## Project Overview

SnapDiff is a Ruby on Rails application that allows developers to save snapshots of API responses (JSON) over time and visually compare them to detect changes. It supports manual snapshots, scheduled captures via cron, CI/CD webhook triggers, and automatic Slack/Discord alerts when drift is detected.

---

## Tech Stack

- **Ruby**: 3.4+
- **Rails**: 8.1+
- **Database**: SQLite3 (JSON stored via `serialize :field, coder: JSON`)
- **Background Jobs**: Solid Queue (no Redis required)
- **Recurring Jobs**: Solid Queue recurring via `config/recurring.yml`
- **Authentication**: Devise (session-based) + Bearer token for API
- **HTTP Client**: Faraday
- **JSON Diff**: Hashdiff (semantic diff)
- **Cron Parsing**: Fugit
- **Frontend**: Hotwire (Turbo + Stimulus) + TailwindCSS 4.x (Gruvbox dark theme)
- **Pagination**: Pagy 43.x (`Pagy::Offset.new(count:, page:, limit:)` — no Backend/Frontend modules)
- **Testing**: Minitest + FactoryBot + WebMock + SimpleCov

---

## Architecture

### Models

```
User
├── has_many :projects
└── fields: email, encrypted_password (Devise), api_token

Project
├── belongs_to :user
└── has_many :endpoints

Endpoint
├── belongs_to :project
├── has_many :snapshots
└── fields: name, url, http_method, headers (JSON), body (JSON),
           schedule (cron string), baseline_snapshot_id

Snapshot
├── belongs_to :endpoint
└── fields: response_body (JSON), status_code, response_time_ms,
           taken_at, triggered_by (enum: manual | scheduled | ci)

DiffReport
├── belongs_to :snapshot_a (Snapshot)
├── belongs_to :snapshot_b (Snapshot)
└── fields: diff_data (JSON), summary, created_at
```

### Key Services

- `Snapshots::CaptureService` — executes the HTTP request and persists the snapshot
- `Snapshots::DiffService` — compares two snapshots using Hashdiff and creates a DiffReport
- `Snapshots::AlertService` — sends Slack/Discord webhook if changes detected
- `Endpoints::SchedulerService` — enqueues CaptureSnapshotJob based on each endpoint's cron schedule (Fugit)

### Background Jobs

- `CaptureSnapshotJob` — triggered by scheduler or CI webhook, calls CaptureService
- `DiffAndAlertJob` — runs after each capture to compare with the previous snapshot

### API

- `POST /api/v1/snapshots/capture` — trigger immediate capture (CI/CD integration)
- `PATCH /api/v1/endpoints/:id/baseline` — set latest snapshot as baseline
- Auth: `Authorization: Bearer <api_token>`

---

## Directory Structure

```
app/
├── controllers/
│   ├── projects_controller.rb
│   ├── endpoints_controller.rb
│   ├── snapshots_controller.rb
│   ├── diff_reports_controller.rb
│   └── api/
│       ├── base_controller.rb
│       └── v1/
│           ├── snapshots_controller.rb
│           └── endpoints_controller.rb
├── models/
│   ├── user.rb
│   ├── project.rb
│   ├── endpoint.rb
│   ├── snapshot.rb
│   └── diff_report.rb
├── services/
│   ├── snapshots/
│   │   ├── capture_service.rb
│   │   ├── diff_service.rb
│   │   └── alert_service.rb
│   └── endpoints/
│       └── scheduler_service.rb
├── jobs/
│   ├── capture_snapshot_job.rb
│   └── diff_and_alert_job.rb
└── views/
    ├── projects/
    ├── endpoints/
    ├── snapshots/
    └── diff_reports/
        └── show.html.erb   # Main diff viewer (Gruvbox green/red/yellow)
```

---

## Key Gems

| Gem               | Purpose                                      |
| ----------------- | -------------------------------------------- |
| `devise`          | User authentication (session + API token)    |
| `faraday`         | HTTP requests to monitored endpoints         |
| `hashdiff`        | Semantic JSON diff                           |
| `diffy`           | Text-based diff (available, not primary)     |
| `fugit`           | Cron expression parsing for scheduler        |
| `solid_queue`     | Background job processing (no Redis)         |
| `pagy`            | Pagination (43.x — use `Pagy::Offset.new`)   |
| `factory_bot_rails` | Test factories                             |
| `webmock`         | HTTP stubbing in tests                       |
| `simplecov`       | Code coverage (≥75% enforced in CI)          |

---

## Environment Variables

```bash
# Notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...

# App
SECRET_KEY_BASE=
RAILS_ENV=production
```

---

## Setup

```bash
git clone <repo>
cd SnapDiff

bundle install
rails db:create db:migrate

bin/dev
```

---

## Running Tests

```bash
bundle exec rails test                     # All tests
COVERAGE_MIN=75 bundle exec rails test     # With coverage enforcement
bundle exec rails test test/models         # Models only
bundle exec rails test test/services       # Services only
bundle exec rails test test/controllers    # Controllers only
```

---

## CI/CD Integration

SnapDiff exposes a webhook endpoint for triggering snapshots from pipelines:

```bash
POST /api/v1/snapshots/capture
Authorization: Bearer <api_token>
Content-Type: application/json

{ "endpoint_id": 42 }
```

Example GitHub Actions step:

```yaml
- name: Capture API Snapshot
  run: |
    curl -X POST https://yourdomain.com/api/v1/snapshots/capture \
      -H "Authorization: Bearer ${{ secrets.SNAPDIFF_TOKEN }}" \
      -H "Content-Type: application/json" \
      -d '{"endpoint_id": 42}'
```

Find your API token in the app's profile page, or generate one via:

```ruby
user.regenerate_api_token!
```

---

## Diff Viewer

The diff viewer (`/diff_reports/:id`) shows a side-by-side JSON comparison with:

- **Added** fields highlighted in green (Gruvbox `#b8bb26`)
- **Removed** fields highlighted in red (Gruvbox `#fb4934`)
- **Changed** values highlighted in yellow (Gruvbox `#fabd2f`)
- Summary badge with total changes count

---

## Baseline System

Each `Endpoint` can have a designated **baseline snapshot** — a reference point against which all future snapshots are compared.

Set a baseline via UI (`PATCH /endpoints/:id/set_baseline`) or API:

```bash
PATCH /api/v1/endpoints/:id/baseline
Authorization: Bearer <api_token>
```

---

## Gruvbox Theme

TailwindCSS 4.x custom theme defined in `app/assets/tailwind/application.css` via `@theme` directive. Color classes: `bg-gb-bg`, `text-gb-fg`, `text-gb-green`, `text-gb-red`, `text-gb-yellow`, `bg-gb-blue`, etc.
