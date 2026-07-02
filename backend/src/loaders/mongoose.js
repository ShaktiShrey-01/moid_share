import mongoose from 'mongoose';
import config from '../config/env.js';
import logger from '../utils/logger.js';

/**
 * Establishes the MongoDB connection.
 *
 * Mongoose buffers commands until connected, but we await the initial
 * connection so the server never starts serving traffic against a dead DB.
 * Connection-level event listeners surface transient drops/reconnects.
 *
 * @returns {Promise<typeof mongoose>}
 */
export default async function loadMongoose() {
  mongoose.set('strictQuery', true);

  mongoose.connection.on('connected', () => logger.info('[db] connected'));
  mongoose.connection.on('disconnected', () => logger.warn('[db] disconnected'));
  mongoose.connection.on('reconnected', () => logger.info('[db] reconnected'));
  mongoose.connection.on('error', (err) => logger.error('[db] error', err));

  await mongoose.connect(config.db.uri, {
    serverSelectionTimeoutMS: 10_000,
    // Reasonable pool for a horizontally scaled API tier.
    maxPoolSize: 20,
    minPoolSize: 2,
  });

  return mongoose;
}

/** Gracefully closes the DB connection during shutdown. */
export async function disconnectMongoose() {
  await mongoose.connection.close(false);
  logger.info('[db] connection closed');
}
