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
│   ├── budget.dart                  # Monthly summary + transaction models
│   ├── job.dart                     # Job data model
│   ├── job_param.dart               # Job parameter model
│   ├── learning.dart                # Learning Path fields/specialisations/topics + rating helpers
│   └── net_worth.dart               # Net worth account/category/summary models
├── providers/
│   ├── budget_provider.dart         # Budget month/filter/sort state (read-only)
│   ├── job_provider.dart            # Job running logic, param option fetching
│   ├── learning_provider.dart       # Learning Path fields + cached specialisations, all writes
│   └── net_worth_provider.dart      # Net worth accounts + add/edit/delete
├── services/
│   └── api_service.dart             # HTTP client wrapper
├── theme/
│   └── app_theme.dart               # Modernist design tokens (colors, type, spacing, radius)
├── utils/
│   └── formatting.dart              # GBP formatting
├── screens/
│   ├── home_screen.dart             # Job list, search, category chips, drawer
│   ├── job_detail_screen.dart       # Run a job, view results
│   ├── budget_screen.dart           # Finance → Budget (read-only)
│   ├── net_worth_screen.dart        # Finance → Net Worth (add/edit/delete)
│   ├── learning_path_screen.dart    # Learning Path → fields overview
│   ├── specialisation_screen.dart   # Learning Path → one specialisation's topic tree
│   ├── topic_detail_screen.dart     # Learning Path → one topic (rate, subtopics, prereqs, logs, links)
│   └── settings_screen.dart         # About / server info
└── widgets/                         # Job card, param form, result cards, etc.
```

The drawer groups the two finance screens under a **Finance** parent: **Budget** (read-only
month summary + transactions) and **Net Worth** (the hand-maintained balances behind
`finance/networth`, fully editable from the phone).

**Learning Path** mirrors HomebaseWeb's section on the same `/learning/**` endpoints: fields →
specialisations → nested topics with 1–5 confidence ratings. Only leaf topics are rated by hand
(tap a dot; tap it again to clear); anything with subtopics shows the server's derived average,
read-only. Prerequisites, logs, suggested order, project links and subtopic nesting appear only
where the field's capabilities allow them, and the server enforces the same rules. On a topic,
tapping a subtopic or any ancestor in the breadcrumb switches topics in place, so Back always
returns to the tree.

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


