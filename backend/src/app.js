import express from 'express';
import loadExpress from './loaders/express.js';

/**
 * Builds a fully-configured Express application (security, parsing, routes,
 * error handling) WITHOUT touching external infrastructure.
 *
 * Kept side-effect free so tests can `createApp()` and drive it with supertest
 * without a MongoDB connection.
 *
 * @returns {import('express').Application}
 */
export function createApp() {
  return loadExpress(express());
}

export default createApp;
