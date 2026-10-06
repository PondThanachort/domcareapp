import { RowDataPacket, ResultSetHeader } from 'mysql2'
import connection from '../utils/db'
import * as history from './RequestStatusHistory'
import { ModelError } from './ModelError'

export interface RequestActor { id: number; role: 'admin' | 'resident' }
export interface RequestInput { category: string; title: string; description: string }
export type RequestUpdate =
  | ({ action: 'edit' } & RequestInput)
  | { action: 'cancel'; note: string }
  | { action: 'status'; status: 'in_progress' | 'completed'; note: string }
const selectRequest = 'SELECT r.*, u.display_name AS resident_name FROM repair_requests r JOIN users u ON u.id = r.resident_id'

export async function getAll(actor: RequestActor, status?: string, limit?: 3) {
  const own = actor.role === 'resident'
  const where = own ? ' WHERE r.resident_id = ?' : ' WHERE 1 = 1'
  const params: (string | number)[] = own ? [actor.id] : []
  const [counts] = await connection.promise().execute<RowDataPacket[]>(
    `SELECT COUNT(*) AS total, COALESCE(SUM(r.status = 'pending'), 0) AS pending, COALESCE(SUM(r.status = 'in_progress'), 0) AS in_progress, COALESCE(SUM(r.status = 'completed'), 0) AS completed FROM repair_requests r${where}`, params)
  const [requests] = await connection.promise().execute<RowDataPacket[]>(
    selectRequest + where + (status ? ' AND r.status = ?' : '') + ' ORDER BY r.created_at DESC, r.id DESC' + (limit === 3 ? ' LIMIT 3' : ''), status ? [...params, status] : params)
  return { requests, counts: counts[0] }
}

export async function getById(id: string, actor: RequestActor) {
  const [rows] = await connection.promise().execute<RowDataPacket[]>(selectRequest + ' WHERE r.id = ?' + (actor.role === 'resident' ? ' AND r.resident_id = ?' : ''), actor.role === 'resident' ? [id, actor.id] : [id])
  if (!rows[0]) throw new ModelError(404, 'ไม่พบคำร้อง')
  return { request: rows[0], history: await history.getByRequestId(id) }
}

export async function create(actor: RequestActor, input: RequestInput) {
  if (actor.role !== 'resident') throw new ModelError(403, 'เฉพาะผู้พักเท่านั้นที่ส่งคำร้องได้')
  const db = await connection.promise().getConnection()
  try {
    await db.beginTransaction()
    const [users] = await db.execute<RowDataPacket[]>("SELECT room FROM users WHERE id = ? AND role = 'resident' AND deleted_at IS NULL FOR UPDATE", [actor.id])
    if (!users[0]?.room) throw new ModelError(409, 'บัญชีนี้ยังไม่มีหมายเลขห้อง กรุณาติดต่อผู้ดูแล')
    const [insert] = await db.execute<ResultSetHeader>(
      "INSERT INTO repair_requests (resident_id, room, category, title, description, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 'pending', UTC_TIMESTAMP(), UTC_TIMESTAMP())",
      [actor.id, users[0].room, input.category, input.title.trim(), input.description.trim()])
    await history.append(db, insert.insertId, actor.id, null, 'pending', 'ส่งคำร้อง')
    const [rows] = await db.execute<RowDataPacket[]>(selectRequest + ' WHERE r.id = ?', [insert.insertId])
    await db.commit()
    return rows[0]
  } catch (error) { await db.rollback(); throw error }
  finally { db.release() }
}

export async function update(id: string, actor: RequestActor, input: RequestUpdate) {
  const admin = actor.role === 'admin'
  if (admin ? input.action !== 'status' : input.action === 'status') throw new ModelError(403, 'ไม่มีสิทธิ์ดำเนินการนี้')
  const db = await connection.promise().getConnection()
  try {
    await db.beginTransaction()
    const [rows] = await db.execute<RowDataPacket[]>('SELECT * FROM repair_requests WHERE id = ? FOR UPDATE', [id])
    const row = rows[0]
    if (!row || (!admin && row.resident_id !== actor.id)) throw new ModelError(404, 'ไม่พบคำร้อง')
    const next = input.action === 'cancel' ? 'cancelled' : input.action === 'edit' ? row.status : input.status
    if (admin ? !((row.status === 'pending' && next === 'in_progress') || (row.status === 'in_progress' && next === 'completed')) : row.status !== 'pending') throw new ModelError(409, 'สถานะคำร้องเปลี่ยนไปแล้ว กรุณาโหลดข้อมูลใหม่')
    if (input.action === 'edit') {
      await db.execute('UPDATE repair_requests SET category = ?, title = ?, description = ?, updated_at = UTC_TIMESTAMP() WHERE id = ?', [input.category, input.title.trim(), input.description.trim(), row.id])
    } else if (input.action === 'cancel') {
      await db.execute("UPDATE repair_requests SET status = 'cancelled', cancellation_reason = ?, cancelled_at = UTC_TIMESTAMP(), updated_at = UTC_TIMESTAMP() WHERE id = ?", [input.note.trim(), row.id])
    } else {
      await db.execute('UPDATE repair_requests SET status = ?, updated_at = UTC_TIMESTAMP() WHERE id = ?', [next, row.id])
    }
    await history.append(db, row.id, actor.id, row.status, next, input.action === 'edit' ? 'แก้ไขรายละเอียดคำร้อง' : input.note.trim())
    await db.commit()
  } catch (error) { await db.rollback(); throw error }
  finally { db.release() }
}
