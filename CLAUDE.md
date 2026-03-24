# SnapDiff

> Snapshot, compare and monitor API responses over time. Detect drift before it becomes a problem.

---

## Project Overview

SnapDiff is a Ruby on Rails application that allows developers to save snapshots of API responses (JSON) over time and visually compare them to detect changes. It supports manual snapshots, scheduled captures, and automatic alerts when drift is detected.

---

## Tech Stack

- **Ruby**: 3.4+
- **Rails**: 8.1+
- **Database**: PostgreSQL (with `jsonb` columns for JSON storage)
- **Background Jobs**: Sidekiq + Redis
- **Authentication**: Devise
- **HTTP Client**: Faraday
- **Frontend**: Hotwire (Turbo + Stimulus) + TailwindCSS
- **File Storage**: Active Storage + S3 (for large snapshot backups)
- **Testing**: RSpec + FactoryBot + WebMock

---

## Architecture

### Models

```
User
└── has_many :projects

Project
├── belongs_to :user
└── has_many :endpoints

Endpoint
├── belongs_to :project
├── has_many :snapshots
└── fields: name, url, http_method, headers (jsonb), body (jsonb),
           schedule (cron string), baseline_snapshot_id

Snapshot
├── belongs_to :endpoint
└── fields: response_body (jsonb), status_code, response_time_ms,
           taken_at, triggered_by (enum: manual | scheduled | ci)

DiffReport
├── belongs_to :snapshot_a (Snapshot)
├── belongs_to :snapshot_b (Snapshot)
└── fields: diff_data (jsonb), summary, created_at
```

### Key Services

- `Snapshots::CaptureService` — executes the HTTP request and persists the snapshot
- `Snapshots::DiffService` — compares two snapshots and generates a structured diff
- `Snapshots::AlertService` — checks if a diff exceeds threshold and triggers notifications
- `Endpoints::SchedulerService` — enqueues Sidekiq jobs based on each endpoint's cron schedule

### Background Jobs

- `CaptureSnapshotJob` — triggered by scheduler or CI webhook
- `DiffAndAlertJob` — runs after each capture to compare with the previous snapshot

---

## Directory Structure

```
app/
├── controllers/
│   ├── projects_controller.rb
│   ├── endpoints_controller.rb
│   ├── snapshots_controller.rb
│   └── diff_reports_controller.rb
├── models/
│   ├── user.rb
│   ├── project.rb
│   ├── endpoint.rb
│   ├── snapshot.rb
│   └── diff_report.rb
├── services/
│   └── snapshots/
│       ├── capture_service.rb
│       ├── diff_service.rb
│       └── alert_service.rb
├── jobs/
│   ├── capture_snapshot_job.rb
│   └── diff_and_alert_job.rb
└── views/
    ├── projects/
    ├── endpoints/
    ├── snapshots/
    └── diff_reports/
        └── show.html.erb   # Main diff viewer
```

---

## Key Gems

| Gem                 | Purpose                              |
| ------------------- | ------------------------------------ |
| `devise`            | User authentication                  |
| `faraday`           | HTTP requests to monitored endpoints |
| `diffy`             | Text-based diff generation           |
| `jsondiff`          | Semantic JSON diff                   |
| `sidekiq`           | Background job processing            |
| `sidekiq-scheduler` | Cron-based job scheduling            |
| `pagy`              | Pagination for snapshot history      |
| `scenic`            | SQL views for reporting              |

---

## Environment Variables

```bash
# Database
DATABASE_URL=postgresql://localhost/driftly_development

# Redis / Sidekiq
REDIS_URL=redis://localhost:6379/0

# Storage (S3)
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_BUCKET=driftly-snapshots
AWS_REGION=us-east-1

# Notifications
SLACK_WEBHOOK_URL=
DISCORD_WEBHOOK_URL=

# App
APP_HOST=localhost:3000
SECRET_KEY_BASE=
```

---

## Setup

```bash
git clone https://github.com/yourname/driftly.git
cd driftly

bundle install

cp .env.example .env
# Fill in your environment variables

rails db:create db:migrate db:seed

# Start Redis (required for Sidekiq)
redis-server

# In separate terminals:
bundle exec sidekiq
bin/dev
```

---

## Running Tests

```bash
bundle exec rspec                        # All tests
bundle exec rspec spec/models            # Models only
bundle exec rspec spec/services          # Services only
bundle exec rspec spec/requests          # API/request specs
```

---

## CI/CD Integration

SnapDiff exposes a webhook endpoint for triggering snapshots from pipelines:

```bash
POST /api/v1/snapshots/capture
Authorization: Bearer <API_TOKEN>

{
  "endpoint_id": 42,
  "triggered_by": "ci",
  "ref": "main",
  "sha": "abc123"
}
```

Example GitHub Actions step:

```yaml
- name: Capture API Snapshot
  run: |
    curl -X POST https://driftly.yourdomain.com/api/v1/snapshots/capture \
      -H "Authorization: Bearer ${{ secrets.DRIFTLY_TOKEN }}" \
      -H "Content-Type: application/json" \
      -d '{"endpoint_id": 42, "triggered_by": "ci"}'
```

---

## Diff Viewer

The diff viewer (`/diff_reports/:id`) shows a side-by-side JSON comparison with:

- 🟢 **Added** fields highlighted in green
- 🔴 **Removed** fields highlighted in red
- 🟡 **Changed** values highlighted in yellow
- Collapsible nested objects
- Summary badge with total changes count

---

## Baseline System

Each `Endpoint` can have a designated **baseline snapshot** — a reference point against which all future snapshots are compared. Alerts are only triggered when the current snapshot deviates from the baseline, not just the previous one.

Set a baseline via UI or API:

```bash
PATCH /api/v1/endpoints/:id/baseline
{ "snapshot_id": 101 }
```
