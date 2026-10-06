import { Router } from 'express'
import * as residentController from '../controllers/residentController'
import authenticateToken from '../middleware/authMiddleware'
import requireAdmin from '../middleware/requireAdmin'

const router = Router()

router.get('/', authenticateToken, requireAdmin, residentController.getAllResidents)
router.post('/', authenticateToken, requireAdmin, residentController.createResident)
router.put('/:id', authenticateToken, requireAdmin, residentController.updateResident)
router.delete('/:id', authenticateToken, requireAdmin, residentController.deleteResident)

export default router
