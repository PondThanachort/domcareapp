import { Request, Response } from 'express'
import bcrypt from 'bcrypt'
import * as userModel from '../models/User'

async function failure(res: Response, error: unknown, username?: string) {
  const code = (error as { code?: string }).code
  if (code === 'ER_DUP_ENTRY' && username) {
    try {
      if (await userModel.isArchivedUsername(username.trim())) {
        res.status(409).json({ status: 'error', message: 'ชื่อผู้ใช้นี้เป็นบัญชีที่ยกเลิกแล้วและยังเก็บประวัติไว้ กรุณาใช้ชื่อผู้ใช้อื่น' }); return
      }
    } catch { /* Fall back to the generic duplicate message. */ }
  }
  res.status(code === 'ER_DUP_ENTRY' ? 409 : 500).json({ status: 'error', message: code === 'ER_DUP_ENTRY' ? 'ชื่อผู้ใช้นี้ถูกใช้แล้ว กรุณาใช้ชื่ออื่น' : 'ไม่สามารถบันทึกข้อมูลได้ กรุณาลองใหม่' })
}
export async function getAllResidents(_req: Request, res: Response) {
  try {
    const users = await userModel.getAllResidents()
    res.json({ status: 'ok', users })
  } catch (error) { failure(res, error) }
}

function validate(body: any, creating: boolean): string | null {
  if (!body || ['username', 'display_name', 'room'].some(k => typeof body[k] !== 'string' || !body[k].trim())) return 'กรุณากรอกชื่อผู้พัก ชื่อผู้ใช้ และหมายเลขห้อง'
  if (body.username.trim().length > 50 || body.display_name.trim().length > 100 || body.room.trim().length > 20) return 'ข้อมูลยาวเกินกำหนด'
  if (body.role !== undefined && body.role !== 'resident') return 'สร้างหรือแก้ไขได้เฉพาะบัญชีผู้พัก'
  if (creating && (typeof body.password !== 'string' || !body.password.trim())) return 'กรุณากรอกรหัสผ่าน'
  if (body.password !== undefined && (typeof body.password !== 'string' || Buffer.byteLength(body.password, 'utf8') > 72 || (body.password.length > 0 && !body.password.trim()))) return 'รหัสผ่านต้องไม่เป็นช่องว่างและยาวไม่เกิน 72 ไบต์'
  return null
}
export async function createResident(req: Request, res: Response) {
  const error = validate(req.body, true)
  if (error) { res.status(400).json({ status: 'error', message: error }); return }
  try {
    const hash = await bcrypt.hash(req.body.password, 12)
    const user = await userModel.createResident({
      username: req.body.username.trim(), display_name: req.body.display_name.trim(),
      room: req.body.room.trim(), password_hash: hash,
    })
    res.status(201).json({ status: 'ok', user })
  } catch (e) { await failure(res, e, req.body.username) }
}
function validResidentId(req: Request, res: Response): boolean {
  const id = req.params.id
  if (!/^[1-9]\d*$/.test(id) || !Number.isSafeInteger(Number(id))) {
    res.status(400).json({ status: 'error', message: 'รหัสผู้พักไม่ถูกต้อง' })
    return false
  }
  return true
}

export async function updateResident(req: Request, res: Response) {
  if (!validResidentId(req, res)) return
  const error = validate(req.body, false)
  if (error) { res.status(400).json({ status: 'error', message: error }); return }
  try {
    const updated = await userModel.updateResident(req.params.id, {
      username: req.body.username.trim(), display_name: req.body.display_name.trim(),
      room: req.body.room.trim(),
      password_hash: req.body.password ? await bcrypt.hash(req.body.password, 12) : undefined,
    })
    if (!updated) { res.status(404).json({ status: 'error', message: 'ไม่พบผู้พักที่แก้ไขได้' }); return }
    res.json({ status: 'ok' })
  } catch (e) { await failure(res, e, req.body.username) }
}
export async function deleteResident(req: Request, res: Response) {
  if (!validResidentId(req, res)) return
  try {
    const result = await userModel.deleteResident(req.params.id)
    if (!result) { res.status(404).json({ status: 'error', message: 'ไม่พบผู้พักที่ลบได้' }); return }
    const { archived } = result
    res.json({ status: 'ok', archived, message: archived ? 'ยกเลิกบัญชีแล้ว โดยเก็บประวัติคำร้องไว้' : 'ลบผู้พักออกจากฐานข้อมูลแล้ว' })
  } catch (e) { failure(res, e) }
}
