import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import * as ctrl from './equipment.controller';
import {
  createItemSchema,
  createRequestSchema,
  decideSchema,
  idParamSchema,
  listItemsSchema,
  listRequestsSchema,
  returnSchema,
  updateItemSchema,
  updateRequestSchema,
} from './equipment.schemas';

const router = Router();
router.use(requireAuth);

// ---------- Catalog (read: any member; write: committee) ----------
router.get('/items',     validate({ query: listItemsSchema }), ctrl.listItems);
router.get('/items/:id', validate({ params: idParamSchema }),  ctrl.getItem);

const committee = requireRole('chairperson', 'secretary', 'treasurer');
router.post('/items',     committee, validate({ body: createItemSchema }),                    ctrl.createItem);
router.patch('/items/:id', committee, validate({ params: idParamSchema, body: updateItemSchema }), ctrl.updateItem);

// ---------- Requests ----------
router.post('/requests',      validate({ body: createRequestSchema }),                        ctrl.createRequest);
router.get('/requests',       validate({ query: listRequestsSchema }),                        ctrl.listRequests);
router.get('/requests/:id',   validate({ params: idParamSchema }),                             ctrl.getRequest);
router.patch('/requests/:id', validate({ params: idParamSchema, body: updateRequestSchema }),  ctrl.updateRequest);
router.post('/requests/:id/cancel', validate({ params: idParamSchema }),                       ctrl.cancelRequest);

// Committee actions
router.post('/requests/:id/decide',   committee, validate({ params: idParamSchema, body: decideSchema }), ctrl.decide);
router.post('/requests/:id/handover', committee, validate({ params: idParamSchema }),                     ctrl.handover);
router.post('/requests/:id/return',   committee, validate({ params: idParamSchema, body: returnSchema }), ctrl.returnItem);

export default router;