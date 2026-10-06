import { Router } from 'express'
import * as requestController from '../controllers/requestController'
import authenticateToken from '../middleware/authMiddleware'

const router = Router()

router.get('/', authenticateToken, requestController.getAllRequests)
router.get('/:id', authenticateToken, requestController.getRequestById)
router.post('/', authenticateToken, requestController.createRequest)
router.patch('/:id', authenticateToken, requestController.updateRequest)

export default router
