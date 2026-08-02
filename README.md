# Homebase Mobile

A Flutter client for [Homebase](https://github.com/avahora866/Homebase) — a personal dev tool for
triggering server endpoint jobs (random media picks, interesting facts, Zettelkasten trunk notes).
This replaces the old `job_runner_mobile` app. The app only ever talks to the production Homebase
server — there's no dev/local environment to switch between.

Visual design: the **modernist** system from the Job Runner Mobile Redesign handoff — flat,
architectural, set in Archivo, a single green accent (`#178A4F`) on paper, strong 2px dividers,
rounded corners on every card, field and result surface.

# Build command
flutter build apk --dart-define-from-file=.env
---

## Setup

### 1. Secrets

Copy `.env.example` to `.env` and fill in the real values:

```bash
cp .env.example .env
```

- `X_INTERNAL_HEADER` — sent as `X-Internal-Header` on every request.
- `GAS_SECRET` — secret for the external Google Apps Script Zettelkasten endpoint (Random Trunk job).

`.env` is gitignored and bundled as an app asset via `flutter_dotenv`, so once it's set up you don't
need to pass anything on the command line.

### 2. Install & run

```bash
flutter pub get
flutter run
```

---

## 📁 Project structure

```
lib/
├── main.dart                        # Entry point
├── config/
│   ├── app_config.dart              # ✏️ Prod base URL, GAS url/secret
│   └── job_registry.dart            # ✏️ Add your jobs/endpoints here
├── models/
│   ├── job.dart                     # Job data model
│   └── job_param.dart               # Job parameter model
├── providers/
│   └── job_provider.dart            # Job running logic, param option fetching
├── services/
│   └── api_service.dart             # HTTP client wrapper
├── theme/
│   └── app_theme.dart               # Modernist design tokens (colors, type, spacing, radius)
├── screens/
│   ├── home_screen.dart             # Job list, search, category chips, drawer
│   ├── job_detail_screen.dart       # Run a job, view results
│   └── settings_screen.dart         # About / server info
└── widgets/                         # Job card, param form, result cards, etc.
```

## ✏️ The two files you'll usually touch

### `lib/config/app_config.dart` — the production URL

```dart
static const String baseUrl = 'https://job-runner-3sjl.onrender.com'; // 👈 update if Homebase moves
```

### `lib/config/job_registry.dart` — add a job

```dart
Job(
  id: 'job_unique_id',
  name: 'Human Readable Name',
  description: 'What this endpoint does.',
  endpoint: '/your-domain/your-endpoint',
  method: 'GET', // GET | POST | PUT | DELETE
  category: JobCategory.cs,
),
```

Jobs are grouped on the home screen by `JobCategory` (`media`, `interestingFact`, `cs`) in
declaration order.


