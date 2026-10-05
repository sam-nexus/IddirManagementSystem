import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import * as ctrl from './audit.controller';

const router = Router();
router.use(requireAuth);

// Auditor (plus chairperson) can view
router.use(requireRole('auditor', 'chairperson'));

router.get('/',     ctrl.list);
router.get('/:id',  ctrl.getOne);

export default router;