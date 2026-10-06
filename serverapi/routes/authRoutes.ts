import { Router } from 'express'
import { login } from '../controllers/authController'
import authenticateToken, { RequestWithUser } from '../middleware/authMiddleware'
const router = Router()
router.post('/login', login)
router.get('/me', authenticateToken, (req: RequestWithUser, res) => {
  res.json({ status: 'ok', user: req.user })
})
export default router
