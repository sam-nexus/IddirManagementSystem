import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import * as ctrl from './settings.controller';
import { keyParamSchema, updateSettingSchema } from './settings.schemas';

const router = Router();
router.use(requireAuth);

// Read: committee only (auditor + treasurer + secretary + chairperson)
const readCommittee = requireRole('chairperson', 'secretary', 'treasurer', 'auditor');
router.get('/',         readCommittee, ctrl.list);
router.get('/:key',     readCommittee, validate({ params: keyParamSchema }), ctrl.getOne);

// Write: chairperson only (settings affect money)
router.put('/:key', requireRole('chairperson'),
  validate({ params: keyParamSchema, body: updateSettingSchema }), ctrl.update);

export default router;