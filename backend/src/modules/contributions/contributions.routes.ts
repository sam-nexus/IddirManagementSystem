import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import * as ctrl from './contributions.controller';
import {
  cashPaymentSchema,
  generateDuesSchema,
  initPaymentSchema,
  listDuesSchema,
  listPaymentsSchema,
  paymentIdParamSchema,
  verifyPaymentSchema,
} from './contributions.schemas';

const router = Router();
router.use(requireAuth);

// Plan (everyone can read)
router.get('/plan', ctrl.getPlan);

// My dues + balance (any logged-in member)
router.get('/my-dues', ctrl.myDues);

// Payment flow
router.post('/pay/init',    validate({ body: initPaymentSchema }),    ctrl.initPayment);
router.post('/pay/verify',  validate({ body: verifyPaymentSchema }),  ctrl.verifyPayment);

// Read payment history
router.get('/payments',     validate({ query: listPaymentsSchema }),  ctrl.listPayments);
router.get('/payments/:id', validate({ params: paymentIdParamSchema }), ctrl.getReceipt);

// Committee-only
const committee = requireRole('chairperson', 'secretary', 'treasurer');

router.post('/dues/generate', committee, validate({ body: generateDuesSchema }),  ctrl.generate);
router.get('/dues',           committee, validate({ query: listDuesSchema }),     ctrl.listDues);
router.post('/cash',          requireRole('treasurer', 'chairperson'), validate({ body: cashPaymentSchema }), ctrl.cashPayment);

export default router;