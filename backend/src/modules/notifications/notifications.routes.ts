import { Router } from 'express';
import { requireAuth } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import * as ctrl from './notifications.controller';
import {
  listNotificationsSchema,
  markReadSchema,
  registerDeviceSchema,
} from './notifications.schemas';

const router = Router();
router.use(requireAuth);

router.post('/devices',           validate({ body: registerDeviceSchema }), ctrl.registerDevice);
router.delete('/devices',                                                   ctrl.unregisterDevice);
router.get('/',                   validate({ query: listNotificationsSchema }), ctrl.list);
router.get('/unread-count',                                                 ctrl.unread);
router.post('/mark-read',         validate({ body: markReadSchema }),       ctrl.markRead);

export default router;