import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import * as ctrl from './announcements.controller';
import {
  createAnnouncementSchema,
  idParamSchema,
  listAnnouncementsSchema,
  updateAnnouncementSchema,
} from './announcements.schemas';

const router = Router();
router.use(requireAuth);

router.get('/',    validate({ query: listAnnouncementsSchema }), ctrl.list);
router.get('/:id', validate({ params: idParamSchema }),          ctrl.getOne);

const committee = requireRole('chairperson', 'secretary');
router.post('/',       committee, validate({ body: createAnnouncementSchema }),                       ctrl.create);
router.patch('/:id',   committee, validate({ params: idParamSchema, body: updateAnnouncementSchema }), ctrl.update);
router.delete('/:id',  committee, validate({ params: idParamSchema }),                                 ctrl.remove);

export default router;