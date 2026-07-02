/**
 * Standard success envelope so every endpoint returns a consistent shape:
 *   { "success": true, "data": <payload>, "meta": <optional> }
 *
 * The Flutter client's DTO layer relies on this contract. Errors use the
 * mirror shape produced by the error middleware.
 */
export function sendSuccess(res, statusCode, data, meta) {
  const body = { success: true, data };
  if (meta !== undefined) body.meta = meta;
  return res.status(statusCode).json(body);
}
