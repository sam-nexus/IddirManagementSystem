import { Router } from 'express';
import { validate } from '../../middleware/validate';
import { requireAuth } from '../../middleware/auth';
import * as ctrl from './auth.controller';
import {
  changePinSchema,
  loginSchema,
  logoutSchema,
  refreshSchema,
  sendOtpSchema,
  updateProfileSchema,
  verifyOtpSchema,
} from './auth.schemas';

const router = Router();

// Public
router.post('/login',       validate({ body: loginSchema }),       ctrl.login);
router.post('/otp/send',    validate({ body: sendOtpSchema }),     ctrl.sendOtp);
router.post('/otp/verify',  validate({ body: verifyOtpSchema }),   ctrl.verifyOtp);
router.post('/refresh',     validate({ body: refreshSchema }),     ctrl.refresh);

// Authenticated
router.post('/logout',        requireAuth, validate({ body: logoutSchema }),  ctrl.logout);
router.get('/me',             requireAuth,                                     ctrl.me);
router.patch('/me',           requireAuth, validate({ body: updateProfileSchema }), ctrl.updateProfile);
router.post('/change-pin',    requireAuth, validate({ body: changePinSchema }),      ctrl.changePin);

export default router;