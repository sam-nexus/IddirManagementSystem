import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import * as ctrl from './organization.controller';
import { keyParamSchema, updateOrganizationSchema } from './organization.schemas';

const router = Router();
router.use(requireAuth);

// Read: any logged-in member
router.get('/',    ctrl.list);
router.get('/:key', validate({ params: keyParamSchema }), ctrl.getOne);

// Write: chairperson and secretary
router.put('/:key',
  requireRole('chairperson', 'secretary'),
  validate({ params: keyParamSchema, body: updateOrganizationSchema }),
  ctrl.update
);

export default router;