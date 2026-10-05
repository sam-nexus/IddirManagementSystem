import { Router } from 'express';
import multer from 'multer';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import * as ctrl from './manual.controller';
import {
  idParamSchema,
  listManualSchema,
  rejectManualSchema,
  submitManualSchema,
} from './manual.schemas';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
});

const router = Router();
router.use(requireAuth);

// Submit — any member (multipart form)
router.post(
  '/',
  upload.single('file'),
  validate({ body: submitManualSchema }),
  ctrl.submit
);

// List
router.get('/', validate({ query: listManualSchema }), ctrl.list);

// Get one
router.get('/:id', validate({ params: idParamSchema }), ctrl.getOne);

// Approve / reject — treasurer or chairperson
router.post(
  '/:id/approve',
  requireRole('treasurer', 'chairperson'),
  validate({ params: idParamSchema }),
  ctrl.approve
);
router.post(
  '/:id/reject',
  requireRole('treasurer', 'chairperson'),
  validate({ params: idParamSchema, body: rejectManualSchema }),
  ctrl.reject
);

export default router;