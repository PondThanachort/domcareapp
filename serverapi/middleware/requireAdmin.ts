import { Response, NextFunction } from 'express'
import { RequestWithUser } from './authMiddleware'

export default function requireAdmin(req: RequestWithUser, res: Response, next: NextFunction) {
  if (req.user?.role !== 'admin') {
    res.status(403).json({ status: 'error', message: 'เฉพาะผู้ดูแลระบบเท่านั้น' })
    return
  }
  next()
}
