import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import * as ctrl from './support.controller';
import {
  createRequestSchema,
  decideSchema,
  idParamSchema,
  listPayoutsSchema,
  listRequestsSchema,
  payoutSchema,
  updateRequestSchema,
} from './support.schemas';

const router = Router();
router.use(requireAuth);

// Member-facing
router.post('/requests',      validate({ body: createRequestSchema }),                       ctrl.create);
router.get('/requests',       validate({ query: listRequestsSchema }),                       ctrl.list);
router.get('/requests/:id',   validate({ params: idParamSchema }),                            ctrl.getOne);
router.patch('/requests/:id', validate({ params: idParamSchema, body: updateRequestSchema }), ctrl.update);

// Committee-only
const committee = requireRole('chairperson', 'secretary', 'treasurer', 'auditor');
router.post('/requests/:id/decide', committee, validate({ params: idParamSchema, body: decideSchema }), ctrl.decide);

// Payouts — treasurer and chairperson can record
router.post('/requests/:id/payout', requireRole('treasurer', 'chairperson'),
  validate({ params: idParamSchema, body: payoutSchema }), ctrl.payout);

router.get('/payouts',     committee, validate({ query: listPayoutsSchema }),  ctrl.listPayouts);
router.get('/payouts/:id', committee, validate({ params: idParamSchema }),     ctrl.getPayout);

export default router;