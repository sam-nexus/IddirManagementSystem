export class AppError extends Error {
  status: number;
  code?: string;
  details?: unknown;

  constructor(message: string, status = 400, code?: string, details?: unknown) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export class BadRequestError   extends AppError { constructor(m: string, d?: unknown) { super(m, 400, 'BAD_REQUEST', d); } }
export class UnauthorizedError extends AppError { constructor(m = 'Unauthorized')   { super(m, 401, 'UNAUTHORIZED'); } }
export class ForbiddenError    extends AppError { constructor(m = 'Forbidden')      { super(m, 403, 'FORBIDDEN'); } }
export class NotFoundError     extends AppError { constructor(m = 'Not found')      { super(m, 404, 'NOT_FOUND'); } }
export class ConflictError     extends AppError { constructor(m: string)            { super(m, 409, 'CONFLICT'); } }
export class TooManyError      extends AppError { constructor(m = 'Too many requests') { super(m, 429, 'TOO_MANY'); } }