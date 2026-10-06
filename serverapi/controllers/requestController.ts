import { Response } from 'express'
import { RequestWithUser } from '../middleware/authMiddleware'
import * as requestModel from '../models/RepairRequest'
import { ModelError } from '../models/ModelError'

const categories = ['repair', 'cleaning', 'move_out', 'other_emergency']
const statuses = ['pending', 'in_progress', 'completed', 'cancelled']
function error(res: Response, status: number, message: string) { res.status(status).json({ status: 'error', message }) }
function text(value: unknown, max: number): value is string { return typeof value === 'string' && value.trim().length > 0 && value.trim().length <= max }
function validContent(body: any) { return body && categories.includes(body.category) && text(body.title, 200) && text(body.description, 2000) }


function failure(res: Response, cause: unknown, message: string) {
  error(res, cause instanceof ModelError ? cause.status : 500, cause instanceof ModelError ? cause.message : message)
}

export async function getAllRequests(req: RequestWithUser, res: Response) {
  const status = req.query.status
  if (status !== undefined && !statuses.includes(status as string)) { error(res, 400, 'สถานะไม่ถูกต้อง'); return }
  if (req.query.limit !== undefined && req.query.limit !== '3') { error(res, 400, 'จำนวนรายการไม่ถูกต้อง'); return }
  try {
    const result = await requestModel.getAll(req.user!, status as string | undefined, req.query.limit === '3' ? 3 : undefined)
    res.json({ status: 'ok', ...result })
  } catch (cause) { failure(res, cause, 'ไม่สามารถโหลดคำร้องได้ กรุณาลองใหม่') }
}

export async function createRequest(req: RequestWithUser, res: Response) {
  if (req.user!.role !== 'resident') { error(res, 403, 'เฉพาะผู้พักเท่านั้นที่ส่งคำร้องได้'); return }
  if (!validContent(req.body)) { error(res, 400, 'กรุณาระบุหมวดหมู่ หัวข้อไม่เกิน 200 ตัวอักษร และรายละเอียดไม่เกิน 2000 ตัวอักษร'); return }
  try {
    const request = await requestModel.create(req.user!, req.body)
    res.status(201).json({ status: 'ok', request })
  } catch (cause) { failure(res, cause, 'ไม่สามารถส่งคำร้องได้ กรุณาลองใหม่') }
}

export async function getRequestById(req: RequestWithUser, res: Response) {
  if (!/^\d+$/.test(req.params.id)) { error(res, 400, 'เลขคำร้องไม่ถูกต้อง'); return }
  try {
    res.json({ status: 'ok', ...await requestModel.getById(req.params.id, req.user!) })
  } catch (cause) { failure(res, cause, 'ไม่สามารถโหลดรายละเอียดได้') }
}

export async function updateRequest(req: RequestWithUser, res: Response) {
  if (!/^\d+$/.test(req.params.id)) { error(res, 400, 'เลขคำร้องไม่ถูกต้อง'); return }
  const action = req.body?.action
  const admin = req.user!.role === 'admin'
  if (admin ? action !== 'status' : !['edit', 'cancel'].includes(action)) { error(res, 403, 'ไม่มีสิทธิ์ดำเนินการนี้'); return }
  if ((action === 'edit' && !validContent(req.body)) || (action !== 'edit' && !text(req.body.note, 2000)) || (action === 'status' && !['in_progress', 'completed'].includes(req.body.status))) { error(res, 400, 'กรุณากรอกข้อมูลและหมายเหตุให้ครบถ้วน'); return }
  try {
    await requestModel.update(req.params.id, req.user!, req.body)
    res.json({ status: 'ok' })
  } catch (cause) { failure(res, cause, 'ไม่สามารถบันทึกคำร้องได้') }
}
