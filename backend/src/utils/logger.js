import config from '../config/env.js';

/**
 * Minimal, dependency-free leveled logger.
 *
 * We deliberately avoid a heavy logging library at the foundation stage; this
 * wrapper gives us level filtering and a single choke point to later swap in
 * pino/winston or ship to a log aggregator without touching call sites.
 */
const LEVELS = { error: 0, warn: 1, info: 2, debug: 3 };
const activeLevel = LEVELS[config.logging.level] ?? LEVELS.info;

function emit(level, stream, args) {
  if (LEVELS[level] > activeLevel) return;
  const ts = new Date().toISOString();
  stream(`${ts} [${level.toUpperCase()}]`, ...args);
}

const logger = {
  error: (...args) => emit('error', console.error, args),
  warn: (...args) => emit('warn', console.warn, args),
  info: (...args) => emit('info', console.log, args),
  debug: (...args) => emit('debug', console.log, args),
};

export default logger;
