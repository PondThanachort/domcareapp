import jwt from 'jsonwebtoken'
import { Request, Response, NextFunction } from 'express'
import * as userModel from '../models/User'
import { jwtSecret, tokenOptions } from '../utils/auth'

export interface RequestWithUser extends Request {
  user?: { id: number; username: string; display_name: string; room: string | null; role: 'admin' | 'resident' }
}

export default async function authenticateToken(req: RequestWithUser, res: Response, next: NextFunction) {
  const match = /^Bearer ([^\s]+)$/i.exec(req.headers.authorization || '')
  if (!match) { res.status(401).json({ status: 'error', message: 'กรุณาเข้าสู่ระบบ' }); return }
  let id: string
  try {
    const payload = jwt.verify(match[1], jwtSecret(), { algorithms: ['HS256'], issuer: tokenOptions.issuer, audience: tokenOptions.audience })
    if (typeof payload === 'string' || !payload.sub || !/^\d+$/.test(payload.sub)) throw new Error('Invalid token')
    id = payload.sub
  } catch {
    res.status(401).json({ status: 'error', message: 'การเข้าสู่ระบบหมดอายุ กรุณาเข้าสู่ระบบใหม่' }); return
  }
  try {
    const user = await userModel.findActiveById(id)
    if (!user || !['resident', 'admin'].includes(user.role)) {
      res.status(401).json({ status: 'error', message: 'ไม่พบบัญชีที่ใช้งานได้' }); return
    }
    req.user = user
    next()
  } catch {
    res.status(500).json({ status: 'error', message: 'ไม่สามารถตรวจสอบบัญชีได้' })
  }
}
