import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import * as ctrl from './meetings.controller';
import {
  attendanceSchema,
  createMeetingSchema,
  idParamSchema,
  listMeetingsSchema,
  saveMinutesSchema,
  updateMeetingSchema,
} from './meetings.schemas';

const router = Router();
router.use(requireAuth);

router.get('/',    validate({ query: listMeetingsSchema }), ctrl.list);
router.get('/:id', validate({ params: idParamSchema }),     ctrl.getOne);

const committee = requireRole('chairperson', 'secretary');
router.post('/',    committee, validate({ body: createMeetingSchema }),                       ctrl.create);
router.patch('/:id', committee, validate({ params: idParamSchema, body: updateMeetingSchema }), ctrl.update);
router.delete('/:id', committee, validate({ params: idParamSchema }),                          ctrl.remove);

// Secretary records minutes; chairperson can too
router.put('/:id/minutes', requireRole('secretary', 'chairperson'),
  validate({ params: idParamSchema, body: saveMinutesSchema }), ctrl.saveMinutes);

router.put('/:id/attendance', requireRole('secretary', 'chairperson'),
  validate({ params: idParamSchema, body: attendanceSchema }), ctrl.setAttendance);

export default router;