import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import * as ctrl from './members.controller';
import {
  createDependentSchema,
  createMemberSchema,
  dependentIdParamSchema,
  listMembersSchema,
  memberIdParamSchema,
  suspendMemberSchema,
  updateDependentSchema,
  updateMemberSchema,
} from './members.schemas';

const router = Router();

// All routes require auth
router.use(requireAuth);

// Read — any logged-in member can see the list of members (adjust if you prefer)
router.get('/',    validate({ query: listMembersSchema }),                                   ctrl.list);
router.get('/:id', validate({ params: memberIdParamSchema }),                                  ctrl.getOne);

// Committee-only
const committee = requireRole('chairperson', 'secretary', 'treasurer');
const adminOnly = requireRole('chairperson', 'secretary');

router.post('/',           adminOnly, validate({ body: createMemberSchema }),                 ctrl.create);
router.patch('/:id',       adminOnly, validate({ params: memberIdParamSchema, body: updateMemberSchema }), ctrl.update);
router.post('/:id/suspend',adminOnly, validate({ params: memberIdParamSchema, body: suspendMemberSchema }), ctrl.suspend);
router.post('/:id/activate', adminOnly, validate({ params: memberIdParamSchema }),             ctrl.activate);

// Dependents
router.get('/:id/dependents',              validate({ params: memberIdParamSchema }),         ctrl.listDeps);
router.post('/:id/dependents',             adminOnly, validate({ params: memberIdParamSchema, body: createDependentSchema }), ctrl.createDep);
router.patch('/:id/dependents/:depId',     adminOnly, validate({ params: dependentIdParamSchema, body: updateDependentSchema }), ctrl.updateDep);
router.delete('/:id/dependents/:depId',    adminOnly, validate({ params: dependentIdParamSchema }), ctrl.deleteDep);

export default router;