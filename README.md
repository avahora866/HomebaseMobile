# Homebase Mobile

A Flutter client for [Homebase](https://github.com/avahora866/Homebase) — a personal dev tool for
triggering server endpoint jobs (random media picks, interesting facts, Zettelkasten trunk notes)
with easy DEV/PROD environment switching. This replaces the old `job_runner_mobile` app.

Visual design: the **modernist** system from the Job Runner Mobile Redesign handoff — flat,
architectural, set in Archivo, a single green accent (`#178A4F`) on paper, strong 2px dividers,
mostly-square corners (cards, chips and the run button keep the rounding the mockup explicitly
draws them with).

---

## Setup

### 1. Secrets

Copy `.env.example` to `.env` and fill in the real values:

```bash
cp .env.example .env
```

- `X_INTERNAL_HEADER` — sent as `X-Internal-Header` on every request when running against PROD.
- `GAS_SECRET` — secret for the external Google Apps Script Zettelkasten endpoint (Random Trunk job).

`.env` is gitignored and bundled as an app asset via `flutter_dotenv`, so once it's set up you don't
need to pass anything on the command line.

### 2. Install & run

```bash
flutter pub get
flutter run
```

### 3. Android: allow cleartext HTTP for local dev

Already configured — `android/app/src/main/res/xml/network_security_config.xml` permits cleartext
traffic to `localhost` / `10.0.2.2` (the Android emulator's alias for your host machine) so DEV mode
works against a locally-running Homebase server.

On an Android emulator, `localhost` on your machine is reachable at `10.0.2.2` — update
`lib/config/app_config.dart` if you need that instead of a physical device on the same network.

---

## 📁 Project structure

```
lib/
├── main.dart                        # Entry point
├── config/
│   ├── app_config.dart              # ✏️ DEV/PROD base URLs, GAS url/secret
│   └── job_registry.dart            # ✏️ Add your jobs/endpoints here
├── models/
│   ├── job.dart                     # Job data model
│   └── job_param.dart               # Job parameter model
├── providers/
│   ├── env_provider.dart            # Environment (DEV/PROD) state
│   └── job_provider.dart            # Job running logic, param option fetching
├── services/
│   └── api_service.dart             # HTTP client wrapper
├── theme/
│   └── app_theme.dart               # Modernist design tokens (colors, type, spacing)
├── screens/
│   ├── home_screen.dart             # Job list, search, category chips, drawer
│   ├── job_detail_screen.dart       # Run a job, view results
│   └── settings_screen.dart         # Environment toggle, about
└── widgets/                         # Job card, param form, result cards, etc.
```

## ✏️ The two files you'll usually touch

### `lib/config/app_config.dart` — environment URLs

```dart
static String get baseUrl {
  switch (_currentEnv) {
    case Environment.dev:
      return 'http://localhost:8080';
    case Environment.prod:
      return 'https://job-runner-3sjl.onrender.com'; // 👈 update if Homebase moves
  }
}
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
