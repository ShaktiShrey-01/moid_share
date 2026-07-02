# Moid-Share

Secure, high-speed **file sharing and clipboard synchronization** between
Android and macOS.

This repository is a **monorepo** containing the Flutter client and the Node.js
backend. Native macOS (Swift/AppKit) code is intentionally **not** here — it is
implemented separately in Xcode and plugs into the platform-channel seams
defined in the Flutter layer.

## Layout

```
moid_share/
├── app/        Flutter application (Android + macOS shell, Dart)
├── backend/    Node.js + Express + MongoDB API & realtime (Socket.IO)
├── docs/       Architecture notes and decision records (ADRs)
└── .github/    CI/CD workflows
```

## Status

Foundation (Step 1) is complete and runnable:

- Feature-first Clean Architecture skeleton under `app/lib/core`
- Material 3 design system (light/dark, tokens, typography)
- Networking (Dio + interceptors), storage (Hive + secure storage)
- Routing (GoRouter) with an auth-guard seam
- Platform-channel **seams** where the future macOS/Swift code connects
- Global error handling, DI via Riverpod, unit + widget tests

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) and
[`docs/adr/0001-foundation-architecture.md`](docs/adr/0001-foundation-architecture.md).

## Getting started (client)

```bash
cd app
flutter pub get
flutter run                       # uses dev defaults (API at 10.0.2.2:4000)
flutter analyze && flutter test
```

Configuration is injected at build time (no secrets in source):

```bash
flutter run --dart-define=ENV=prod \
  --dart-define=API_BASE_URL=https://api.moidshare.com/api/v1 \
  --dart-define=SOCKET_URL=wss://api.moidshare.com
```

## Backend

Not yet implemented — see the build plan in `docs/ARCHITECTURE.md`. It will run
against `MONGODB_URI` (MongoDB Atlas or a local `docker-compose` Mongo).
