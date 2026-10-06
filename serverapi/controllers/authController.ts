import jwt from 'jsonwebtoken'
import bcrypt from 'bcrypt'
import { Request, Response } from 'express'
import * as userModel from '../models/User'
import { jwtSecret, tokenOptions } from '../utils/auth'

export async function login(req: Request, res: Response): Promise<void> {
  const { username, password } = req.body || {}
  if (typeof username !== 'string' || !username.trim() || username.trim().length > 50 || typeof password !== 'string' || !password || Buffer.byteLength(password, 'utf8') > 72) {
    res.status(400).json({ status: 'error', message: 'กรุณากรอกชื่อผู้ใช้และรหัสผ่านให้ถูกต้อง' })
    return
  }
  try {
    const user = await userModel.findActiveByUsername(username.trim())
    if (!user || !await bcrypt.compare(password, user.password_hash)) {
      res.status(401).json({ status: 'error', message: 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง' })
      return
    }
    if (!['admin', 'resident'].includes(user.role)) {
      res.status(403).json({ status: 'error', message: 'บัญชีนี้ไม่มีสิทธิ์เข้าใช้งาน' })
      return
    }
    const token = jwt.sign({ role: user.role }, jwtSecret(), { ...tokenOptions, subject: String(user.id) })
    const { password_hash, ...publicUser } = user
    res.json({ status: 'ok', token, user: publicUser })
  } catch (error) {
    console.error('Login failed:', error instanceof Error ? error.name : 'Unknown error')
    res.status(500).json({ status: 'error', message: 'ไม่สามารถเข้าสู่ระบบได้ กรุณาลองใหม่' })
  }
}
