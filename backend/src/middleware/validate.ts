import { Request, Response, NextFunction } from 'express';
import { ZodError, ZodSchema } from 'zod';
import { BadRequestError } from '../utils/errors';

interface Schemas {
  body?: ZodSchema;
  query?: ZodSchema;
  params?: ZodSchema;
}

function formatZodErrors(err: ZodError): Array<{ field: string; message: string }> {
  return err.errors.map((e) => ({
    field: e.path.join('.') || '(root)',
    message: e.message,
  }));
}

export function validate(schemas: Schemas) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      if (schemas.body) {
        req.body = schemas.body.parse(req.body);
      }
      if (schemas.query) {
        // Express 4: req.query is a getter — replace by assigning to a local, then reassigning via any
        const parsed = schemas.query.parse(req.query);
        (req as any).query = parsed;
      }
      if (schemas.params) {
        req.params = schemas.params.parse(req.params);
      }
      next();
    } catch (err) {
      if (err instanceof ZodError) {
        return next(
          new BadRequestError('Invalid input', formatZodErrors(err))
        );
      }
      next(err);
    }
  };
}