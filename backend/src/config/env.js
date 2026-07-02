import dotenv from 'dotenv';

dotenv.config({ quiet: true });

/**
 * Centralized, validated environment configuration.
 *
 * Reads `process.env` exactly once, validates required values, coerces types,
 * and exports a frozen `config` object. The rest of the app imports `config`
 * and NEVER touches `process.env` directly — a single source of truth that
 * fails fast at boot if misconfigured.
 */

const NODE_ENV = process.env.NODE_ENV ?? 'development';
const isProd = NODE_ENV === 'production';
const isTest = NODE_ENV === 'test';

/** Collects fatal misconfiguration so we can report all problems at once. */
const errors = [];

/** Returns a required string, recording an error if absent. */
function required(name, { allowDevFallback } = {}) {
  const value = process.env[name];
  if (value && value.trim() !== '') return value;
  if (!isProd && allowDevFallback !== undefined) {
    console.warn(`[config] ${name} not set — using insecure dev fallback.`);
    return allowDevFallback;
  }
  errors.push(`Missing required env var: ${name}`);
  return undefined;
}

/** Parses an integer env var with a default. */
function int(name, fallback) {
  const raw = process.env[name];
  if (raw === undefined || raw === '') return fallback;
  const parsed = Number.parseInt(raw, 10);
  if (Number.isNaN(parsed)) {
    errors.push(`Env var ${name} must be an integer, got "${raw}"`);
    return fallback;
  }
  return parsed;
}

/** Parses a comma-separated list into a trimmed array. */
function list(name, fallback = []) {
  const raw = process.env[name];
  if (!raw) return fallback;
  return raw
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

const config = {
  env: NODE_ENV,
  isProd,
  isTest,
  isDev: NODE_ENV === 'development',

  server: {
    port: int('PORT', 4000),
    apiPrefix: process.env.API_PREFIX ?? '/api/v1',
    // Trust the first proxy hop (needed for correct client IPs behind a LB).
    trustProxy: process.env.TRUST_PROXY ?? 1,
  },

  db: {
    // In test we default to an in-memory-ish local URI; real value injected by CI.
    uri: required('MONGODB_URI', {
      allowDevFallback: 'mongodb://127.0.0.1:27017/moidshare_dev',
    }),
  },

  jwt: {
    accessSecret: required('JWT_ACCESS_SECRET', {
      allowDevFallback: 'dev-access-secret-change-me',
    }),
    refreshSecret: required('JWT_REFRESH_SECRET', {
      allowDevFallback: 'dev-refresh-secret-change-me',
    }),
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN ?? '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN ?? '30d',
  },

  security: {
    // Allowed browser origins for CORS. Empty in prod = same-origin only.
    corsOrigins: list('CORS_ORIGINS', isProd ? [] : ['*']),
    bcryptRounds: int('BCRYPT_ROUNDS', 12),
  },

  rateLimit: {
    windowMs: int('RATE_LIMIT_WINDOW_MS', 15 * 60 * 1000), // 15 minutes
    max: int('RATE_LIMIT_MAX', 300),
  },

  google: {
    // OAuth client id used to verify Google ID tokens. Empty disables Google
    // sign-in (the endpoint responds 501 Not Implemented until configured).
    clientId: process.env.GOOGLE_CLIENT_ID ?? '',
  },

  logging: {
    level: process.env.LOG_LEVEL ?? (isProd ? 'info' : 'debug'),
    // morgan format: 'combined' in prod, 'dev' otherwise.
    httpFormat: process.env.HTTP_LOG_FORMAT ?? (isProd ? 'combined' : 'dev'),
  },
};

if (errors.length > 0) {
  console.error(
    `[config] Invalid environment configuration:\n  - ${errors.join('\n  - ')}`
  );
  // Never boot with an invalid config.
  process.exit(1);
}

export default Object.freeze(config);
