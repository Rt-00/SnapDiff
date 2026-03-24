# SnapDiff — Implementation Task List

> Status legend: ✅ Done · 🔄 In Progress · ⬜ Pending

---

## Branch: `feature/setup`
- ⬜ Add gems: `devise`, `faraday`, `hashdiff`, `diffy`, `pagy`, `simplecov`, `factory_bot_rails`, `webmock`
- ⬜ Run `bundle install`
- ⬜ Configure SimpleCov (75% minimum coverage enforced in CI)
- ⬜ Configure Tailwind CSS with Gruvbox dark theme (`@theme` in `application.css`)
- ⬜ Rebuild application layout (sidebar nav, flash messages, Gruvbox styling)
- ⬜ Update `test/test_helper.rb` with SimpleCov + FactoryBot support

---

## Branch: `feature/auth`
- ⬜ Install Devise (`rails generate devise:install`)
- ⬜ Generate User model (`rails generate devise User`)
- ⬜ Run migration
- ⬜ Customise Devise views with Gruvbox theme (login, register, forgot password)
- ⬜ Protect all non-auth routes with `before_action :authenticate_user!`
- ⬜ Write model tests for User (validations)
- ⬜ Write request tests for auth flows (sign in, sign out, redirect when unauthenticated)

---

## Branch: `feature/projects`
- ⬜ Generate Project model & migration (`user:references name:string description:text`)
- ⬜ Add validations (`name` presence, uniqueness scoped to user)
- ⬜ `ProjectsController` — full CRUD, scoped to `current_user`
- ⬜ Views: index (project cards), show (endpoint list), new/edit forms
- ⬜ Routes: `resources :projects`
- ⬜ Set root route to `projects#index`
- ⬜ Write model tests (validations, associations)
- ⬜ Write controller/request tests (CRUD, auth enforcement)

---

## Branch: `feature/endpoints`
- ⬜ Generate Endpoint model & migration
  - `project:references name:string url:string http_method:string`
  - `headers:text body:text schedule:string baseline_snapshot_id:integer`
- ⬜ Add serialization for `headers` / `body` JSON fields
- ⬜ Add validations (`name`, `url`, `http_method` presence; valid URL format)
- ⬜ `EndpointsController` — full CRUD, nested under `projects`
- ⬜ Views: index (table in project show), new/edit forms (inline Turbo frames)
- ⬜ Routes: `resources :projects { resources :endpoints }`
- ⬜ `PATCH /api/v1/endpoints/:id/baseline` — set baseline snapshot
- ⬜ Write model tests
- ⬜ Write controller/request tests

---

## Branch: `feature/snapshots`
- ⬜ Generate Snapshot model & migration
  - `endpoint:references response_body:text status_code:integer`
  - `response_time_ms:integer taken_at:datetime triggered_by:string`
- ⬜ Add `triggered_by` enum (`manual`, `scheduled`, `ci`)
- ⬜ Implement `Snapshots::CaptureService`
  - Uses Faraday to fire HTTP request
  - Persists Snapshot record
  - Enqueues `DiffAndAlertJob` after capture
- ⬜ `SnapshotsController` — index (history), show (raw response), create (trigger manual)
- ⬜ Views: history list (Turbo-updated), raw JSON viewer, trigger button
- ⬜ Write service tests (with WebMock stubs)
- ⬜ Write model and controller tests

---

## Branch: `feature/diff-reports`
- ⬜ Generate DiffReport model & migration
  - `snapshot_a:references snapshot_b:references diff_data:text summary:string`
- ⬜ Implement `Snapshots::DiffService`
  - Uses `hashdiff` for semantic JSON diff
  - Produces structured `diff_data` (added / removed / changed)
- ⬜ `DiffReportsController` — show, create (compare any two snapshots)
- ⬜ Diff viewer (`show.html.erb`) — side-by-side JSON with Gruvbox colour coding
  - 🟢 Added — `gb-green`
  - 🔴 Removed — `gb-red`
  - 🟡 Changed — `gb-yellow`
  - Collapsible nested objects (Stimulus controller)
  - Summary badge (total change count)
- ⬜ Write service tests
- ⬜ Write model and controller tests

---

## Branch: `feature/background-jobs`
- ⬜ `CaptureSnapshotJob` — calls `Snapshots::CaptureService`
- ⬜ `DiffAndAlertJob` — calls `Snapshots::DiffService` then `Snapshots::AlertService`
- ⬜ `Snapshots::AlertService`
  - Compares diff against threshold
  - Sends Slack / Discord webhook notification (Faraday POST)
- ⬜ `Endpoints::SchedulerService` — enqueues jobs per cron schedule
- ⬜ Wire Solid Queue recurring jobs via `config/recurring.yml`
- ⬜ Write job tests (assert enqueue / perform)
- ⬜ Write AlertService tests (WebMock stubs for webhook calls)

---

## Branch: `feature/api`
- ⬜ `Api::V1::SnapshotsController#capture` — CI/CD webhook
  - `POST /api/v1/snapshots/capture`
  - Bearer token authentication (stored per-user or per-endpoint)
- ⬜ `ApiToken` model (or token column on `User`)
- ⬜ Return JSON responses with proper HTTP status codes
- ⬜ Write request tests for API authentication and capture endpoint
- ⬜ Document API in CLAUDE.md

---

## Cross-Cutting Concerns

- ⬜ **Coverage**: SimpleCov enforced at ≥ 75% — fails CI if below
- ⬜ **Pagination**: `pagy` on snapshot history and project lists
- ⬜ **Authorization**: Users can only access their own Projects / Endpoints / Snapshots
- ⬜ **Flash messages**: Turbo-compatible flash partial in layout
- ⬜ **Error pages**: Styled 404 / 500 in Gruvbox theme
- ⬜ **Responsive layout**: Sidebar collapses on mobile (Stimulus toggle)

---

## Gruvbox Dark Palette Reference

| Token          | Hex       | Usage                         |
| -------------- | --------- | ----------------------------- |
| `gb-bg`        | `#282828` | Page background               |
| `gb-bg1`       | `#3c3836` | Card / panel background       |
| `gb-bg2`       | `#504945` | Hover states, borders         |
| `gb-bg3`       | `#665c54` | Subtle dividers               |
| `gb-fg`        | `#ebdbb2` | Primary text                  |
| `gb-fg4`       | `#a89984` | Muted / secondary text        |
| `gb-red`       | `#fb4934` | Removed / error               |
| `gb-green`     | `#b8bb26` | Added / success               |
| `gb-yellow`    | `#fabd2f` | Changed / warning             |
| `gb-blue`      | `#83a598` | Links / info                  |
| `gb-purple`    | `#d3869b` | Accents                       |
| `gb-aqua`      | `#8ec07c` | Highlights                    |
| `gb-orange`    | `#fe8019` | CTA buttons / badges          |
