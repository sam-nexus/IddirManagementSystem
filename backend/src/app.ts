import express, { Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { isDev } from './config/env';
import { requestContext } from './middleware/requestContext';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { pingDb } from './config/database';
import authRoutes from './modules/auth/auth.routes';
import membersRoutes from './modules/members/members.routes';
import contributionsRoutes from './modules/contributions/contributions.routes';
import supportRoutes from './modules/support/support.routes';

export function createApp(): Express {
  const app = express();
  app.use(helmet());
  app.use(cors({ origin: true, credentials: true }));
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true }));
  if (isDev) app.use(morgan('dev'));
  app.use(requestContext);

  app.get('/health', async (_req, res) => {
    const dbOk = await pingDb();
    res.status(dbOk ? 200 : 503).json({
      success: dbOk,
      message: dbOk ? 'ok' : 'db unreachable',
      data: { uptime: process.uptime(), db: dbOk },
    });
  });

  app.use('/auth',          authRoutes);
  app.use('/members',       membersRoutes);
  app.use('/contributions', contributionsRoutes);
  app.use('/support',       supportRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}