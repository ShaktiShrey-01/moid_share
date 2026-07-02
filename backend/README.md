# Moid-Share Backend

Node.js + **Express 5** + **MongoDB (Mongoose 8)** API and **Socket.IO** realtime
signaling. Stores **user information only** — never files or clipboard contents.

## Architecture

Layered + loaders assembly:

```
src/
├── config/       env loading + validation (fail-fast, single source of truth)
├── loaders/      express / mongoose / socket assembly (index = infra orchestrator)
├── middleware/   errorHandler, notFound, validate, rateLimiter
├── routes/       versioned routers (/api/v1), health
├── controllers/  thin request/response handlers (health)
├── services/     business logic            (added per feature)
├── repositories/ Mongoose data access      (added per feature)
├── models/       Mongoose schemas          (added per feature)
├── sockets/      Socket.IO namespaces      (added per feature)
├── utils/        logger, ApiError, ApiResponse, asyncHandler
├── app.js        createApp() → configured Express (no DB; testable)
└── server.js     lifecycle: boot infra, listen, graceful shutdown
```

**Request flow:** `route → validate → controller → service → repository → model`.
Errors are thrown as `ApiError` (or mapped from Mongoose/JWT) and rendered by one
central error middleware into a uniform envelope.

**Response envelopes**
- success: `{ "success": true, "data": ..., "meta"?: ... }`
- error:   `{ "success": false, "error": { "code", "message", "details"? } }`

## Getting started

```bash
cd backend
cp .env.example .env            # fill MONGODB_URI + JWT secrets
docker compose -f ../docker-compose.yml up -d   # optional local Mongo
npm install
npm run dev                     # nodemon, hot reload
```

Endpoints (Step 2):
- `GET /api/v1/health`        — liveness (process up)
- `GET /api/v1/health/ready`  — readiness (503 if MongoDB is down)

## Scripts

| Script          | Purpose                          |
|-----------------|----------------------------------|
| `npm run dev`   | Run with nodemon (auto-restart)  |
| `npm start`     | Production start                 |
| `npm test`      | Node built-in test runner        |
| `npm run lint`  | ESLint (flat config)             |
| `npm run format`| Prettier                         |

## Key decisions

- **ESM + Node 20+**, Express 5, Mongoose 8.
- **`bcryptjs`** instead of native `bcrypt`: identical API, no native build
  toolchain — reliable in CI/containers.
- **`node:test` + `supertest`**: zero extra test framework; `createApp()` is
  DB-free so HTTP behavior is unit-testable.
- **Fail-fast config**: `src/config/env.js` validates on boot and exits on
  invalid configuration; the rest of the app never reads `process.env`.
- Security hardening at the edge: `helmet`, scoped `cors`, `express-rate-limit`,
  bounded body size, `compression`, request-id correlation.
- **Never persists files/clipboard** — realtime is signaling only.
