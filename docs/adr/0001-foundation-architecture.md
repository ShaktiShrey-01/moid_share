# ADR 0001 — Foundation architecture & package choices

- **Status:** Accepted
- **Date:** 2026-07-02
- **Scope:** Android Studio side (Flutter client + Node backend). macOS native
  is out of scope and connects via platform-channel seams.

## Context

Moid-Share must feel premium, scale to millions of users, and later be opened in
Xcode for native macOS work. We need an architecture that keeps business logic
portable and native behavior behind explicit boundaries.

## Decisions

### 1. Monorepo (`app/` + `backend/` + `docs/`)
Client and backend version and evolve together; a monorepo keeps the API
contract in sync and lets CI target each independently. The Node backend is kept
out of the Flutter package.

### 2. Feature-First Clean Architecture
Each feature owns `data/domain/presentation`. The dependency rule
(`presentation → domain ← data`) keeps the domain free of framework imports,
which is precisely what makes the macOS seams clean and the code testable.

### 3. State management & DI → Riverpod
Compile-safe, `BuildContext`-free, and trivially overridable in tests. It
doubles as the DI container, so we avoid a second library (`get_it`).
_Note:_ resolves to Riverpod 3.x with the current SDK.

### 4. Routing → GoRouter
Declarative, URL-based, supports redirect guards (auth gating) and deep links
(needed for the Android share-sheet entry point).

### 5. Networking → Dio
Interceptors give us JWT attach + one-shot refresh-on-401, request cancellation,
and upload/download progress — all required by the transfer layer. Errors are
mapped once (`DioErrorMapper`) into an `AppException` taxonomy.

### 6. Persistence → Hive (community edition) + flutter_secure_storage
`hive_ce` is the maintained fork of the abandoned `hive`. Non-sensitive cache
(settings, device list, history) goes to Hive; **secrets (JWTs) only** go to the
keystore/keychain via `flutter_secure_storage`.

### 7. Models → freezed + json_serializable
Immutable data classes and exhaustive sealed unions for state; codegen for JSON.
Core error/Result types are hand-written sealed classes (no codegen) so the
foundation compiles without a build_runner pass.

### 8. Error handling → `Result<T>` + `Failure`
Exceptions are thrown only in the data layer and converted to returned `Failure`
values at the repository boundary, so the domain/UI never use `try/catch`.

### 9. Theming → Material 3 from a single seed + design tokens
Light/dark derive from one seed color; spacing/radius/typography tokens keep the
UI rhythmically consistent and make a rebrand a one-line change.

### 10. Platform seams for macOS
Pure-Dart interfaces (`ClipboardBridge`, `DiscoveryBridge`,
`TransferReceiverBridge`) + a channel-name registry + `NativeBridge`. Android
implements handlers in Kotlin now; macOS implements the same contracts in Swift
later with zero Dart changes.

## Consequences

- Strong testability and a clear path to add features as isolated slices.
- A small amount of upfront boilerplate (layers, seams) traded for long-term
  scalability and cross-platform safety.
- The two lint plugins `riverpod_lint`/`custom_lint` are omitted for now due to a
  transitive `analyzer` version conflict; revisit once upstream aligns.

## Rejected alternatives

- **Bloc** — more boilerplate than Riverpod for our needs.
- **Two separate repos** — harder to keep the API contract in sync for a small
  team.
- **Storing files/clipboard server-side** — explicitly forbidden; the backend
  holds user data only.
