import 'express-async-errors';
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
import announcementsRoutes from './modules/announcements/announcements.routes';
import meetingsRoutes from './modules/meetings/meetings.routes';
import reportsRoutes from './modules/reports/reports.routes';
import notificationsRoutes from './modules/notifications/notifications.routes';
import auditRoutes from './modules/audit/audit.routes';
import settingsRoutes from './modules/settings/settings.routes';
import organizationRoutes from './modules/organization/organization.routes';
import equipmentRoutes from './modules/equipment/equipment.routes';
import penaltiesRoutes from './modules/penalties/penalties.routes';
import manualPaymentRoutes from './modules/contributions/manual.routes';


export function createApp(): Express {
  const app = express();
  app.set('etag', false);
  app.use(helmet());
  app.use(cors({
    origin: (origin, callback) => {
      // Allow any origin in dev. Lock down in production.
      callback(null, true);
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Lang'],
  }));
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

  app.use('/auth', authRoutes);
  app.use('/members', membersRoutes);
  app.use('/contributions', contributionsRoutes);
  app.use('/support', supportRoutes);
  app.use('/announcements', announcementsRoutes);
  app.use('/meetings', meetingsRoutes);
  app.use('/reports', reportsRoutes);
  app.use('/notifications', notificationsRoutes);
  app.use('/audit', auditRoutes);
  app.use('/settings', settingsRoutes);
  app.use('/organization', organizationRoutes);
  app.use('/equipment', equipmentRoutes);
  app.use('/penalties', penaltiesRoutes);
  app.use('/contributions/manual', manualPaymentRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}