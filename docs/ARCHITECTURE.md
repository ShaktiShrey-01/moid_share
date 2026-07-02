# Moid-Share — Architecture

## Goals

- **Premium, minimal UI** (Material 3, Apple/Linear/Notion inspired).
- **Clean, scalable, testable** code targeting millions of users.
- **Cross-platform-ready**: the same Flutter/Dart logic runs on Android now and
  macOS later. Native behavior is reached only through explicit **seams**
  (platform channels), so the macOS Swift engineer plugs in without touching
  shared code.

## High-level shape

```
Flutter (app/)         Node.js (backend/)         Native
──────────────         ──────────────────         ──────────────
presentation  ─┐       Express REST + Socket.IO   Kotlin (Android, now)
domain         ├─ Dio ─────────────► MongoDB      Swift  (macOS, later)
data           ─┘                                 ▲
   │                                              │
   └────── platform channels (seams) ─────────────┘
```

## Client architecture — Feature-First Clean Architecture

```
app/lib/
├── main.dart            Entry point → bootstrap()
├── bootstrap.dart       Composition root: config, storage, error handlers, DI
├── app/                 MaterialApp.router + top-level screens (shell)
├── core/                Cross-cutting, feature-agnostic infrastructure
│   ├── config/          AppEnvironment (compile-time, --dart-define)
│   ├── constants/       App-wide constants, storage keys, asset paths
│   ├── di/              Riverpod providers for shared singletons
│   ├── error/           Failure hierarchy, Result<T>, AppException taxonomy
│   ├── logging/         AppLogger facade
│   ├── network/         Dio client, interceptors, ApiClient, connectivity
│   ├── router/          GoRouter + auth-guard seam
│   ├── session/         AuthStatus seam (overridden by the auth feature)
│   ├── storage/         SecureStorage + Hive KeyValueStore
│   ├── theme/           M3 tokens, typography, light/dark, theme controller
│   ├── platform/        Platform-channel seams (macOS plugs in here)
│   └── widgets/         Reusable, feature-agnostic widgets
└── features/            One folder per feature (auth, home, devices, …)
    └── <feature>/
        ├── data/        DTOs, datasources, repository implementations
        ├── domain/      Entities, repository interfaces, use-cases
        └── presentation/Riverpod controllers, screens, widgets
```

### The dependency rule

`presentation → domain ← data`. The **domain** layer imports nothing from
Flutter, Dio, or Hive. This is what keeps business logic portable and makes the
macOS seams clean.

### Error flow (one direction, one place)

1. Datasources throw `AppException` (Dio errors mapped by `DioErrorMapper`).
2. Repositories catch `AppException` and return `Result<T>` with a `Failure`.
3. Presentation pattern-matches on `Result` — no `try/catch` in the UI.

### Dependency injection

Riverpod **is** the DI container. Infrastructure is exposed as providers
(`loggerProvider`, `apiClientProvider`, storage providers…). Tests override
providers via `ProviderScope(overrides:)`; nothing constructs its own
dependencies.

### Platform seams (the macOS boundary)

`core/platform/platform_seams.dart` declares pure-Dart interfaces
(`ClipboardBridge`, `DiscoveryBridge`, `TransferReceiverBridge`). Channel names
live in `platform_channels.dart`; `NativeBridge` wraps MethodChannel/EventChannel
and maps native errors. Android implements the handlers in Kotlin today; macOS
implements the **same channel contracts** in Swift later. No Dart changes.

## Backend architecture (planned)

Layered Express app; stores **only user information** (users, registered
devices, settings) — never files or clipboard data.

```
backend/src/
├── config/         env, db connection
├── models/         Mongoose schemas (User, Device, Settings)
├── repositories/   data access
├── services/       business logic (auth, devices, pairing)
├── controllers/    request/response handling
├── routes/         REST route definitions (/api/v1/...)
├── middleware/     auth (JWT), validation, error handler, security (helmet/cors)
├── sockets/        Socket.IO namespaces (device + clipboard signaling)
└── app.js / server.js
```

## Build plan

1. **Foundation** — ✅ done (this step).
2. Backend foundation (Express, Mongoose, config, error middleware, health).
3. Auth vertical slice (backend JWT/Google + Flutter login/signup/forgot).
4. Devices & pairing → Clipboard → File transfer → Settings/History.

Each step is confirm-gated per the project workflow.
