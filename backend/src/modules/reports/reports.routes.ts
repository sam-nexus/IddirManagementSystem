import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { z } from 'zod';
import * as ctrl from './reports.controller';
import {
  financialsSchema,
  idParamSchema,
  listReportsSchema,
  publishReportSchema,
} from './reports.schemas';

const router = Router();
router.use(requireAuth);

// Published reports — everyone reads
router.get('/',    validate({ query: listReportsSchema }), ctrl.list);
router.get('/:id', validate({ params: idParamSchema }),    ctrl.getOne);

// Live aggregations — committee only
const committee = requireRole('chairperson', 'secretary', 'treasurer', 'auditor');
router.get('/_/financials',     committee, validate({ query: financialsSchema }),                          ctrl.financials);
router.get('/_/paid-vs-unpaid', committee, validate({ query: z.object({ period: z.string().regex(/^\d{4}-\d{2}-\d{2}$/) }) }), ctrl.paidVsUnpaid);

// Publish a report — treasurer or chairperson
router.post('/', requireRole('treasurer', 'chairperson'),
  validate({ body: publishReportSchema }), ctrl.publish);

export default router;