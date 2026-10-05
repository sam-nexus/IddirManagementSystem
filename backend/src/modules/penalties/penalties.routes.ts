import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import * as ctrl from './penalties.controller';
import {
  idParamSchema,
  listPenaltiesSchema,
  manualPenaltySchema,
  waivePenaltySchema,
} from './penalties.schemas';

const router = Router();
router.use(requireAuth);

// My summary — any member
router.get('/my-summary', ctrl.mySummary);

// List — member sees own, committee sees all
router.get('/', validate({ query: listPenaltiesSchema }), ctrl.list);

// Get one — owner or committee
router.get('/:id', validate({ params: idParamSchema }), ctrl.getOne);

// Committee actions
router.post('/manual',
  requireRole('treasurer', 'chairperson'),
  validate({ body: manualPenaltySchema }),
  ctrl.createManual
);

router.post('/:id/waive',
  requireRole('treasurer', 'chairperson'),
  validate({ params: idParamSchema, body: waivePenaltySchema }),
  ctrl.waive
);

router.post('/:id/mark-paid',
  requireRole('treasurer', 'chairperson'),
  validate({ params: idParamSchema }),
  ctrl.markPaid
);

export default router;