import { RowDataPacket, ResultSetHeader } from 'mysql2'
import db from '../utils/db'

export interface UserData extends RowDataPacket {
  id: number
  username: string
  display_name: string
  room: string | null
  role: 'admin' | 'resident'
}
interface LoginUser extends UserData { password_hash: string }
export interface ResidentInput {
  username: string
  display_name: string
  room: string
  password_hash?: string
}
const fields = 'id, username, display_name, room, role'

export async function findActiveByUsername(username: string): Promise<LoginUser | undefined> {
  const [rows] = await db.promise().execute<LoginUser[]>(`SELECT ${fields}, password_hash FROM users WHERE username = ? AND deleted_at IS NULL LIMIT 1`, [username])
  return rows[0]
}
export async function findActiveById(id: string): Promise<UserData | undefined> {
  const [rows] = await db.promise().execute<UserData[]>(`SELECT ${fields} FROM users WHERE id = ? AND deleted_at IS NULL`, [id])
  return rows[0]
}
export async function isArchivedUsername(username: string): Promise<boolean> {
  const [rows] = await db.promise().execute<RowDataPacket[]>('SELECT deleted_at FROM users WHERE username = ?', [username])
  return Boolean(rows[0]?.deleted_at)
}
export async function getAllResidents() {
  const [users] = await db.promise().query<UserData[]>(`SELECT ${fields}, deleted_at FROM users WHERE role = 'resident' ORDER BY deleted_at IS NOT NULL, id DESC`)
  return users
}
export async function createResident(input: ResidentInput & { password_hash: string }) {
  const [result] = await db.promise().execute<ResultSetHeader>(
    "INSERT INTO users (username, password_hash, display_name, room, role) VALUES (?, ?, ?, ?, 'resident')",
    [input.username, input.password_hash, input.display_name, input.room])
  return { id: result.insertId, username: input.username, display_name: input.display_name, room: input.room, role: 'resident' }
}
export async function updateResident(id: string, input: ResidentInput): Promise<boolean> {
  const values: unknown[] = [input.username, input.display_name, input.room]
  const passwordSql = input.password_hash ? ', password_hash = ?' : ''
  if (input.password_hash) values.push(input.password_hash)
  values.push(id)
  const [result] = await db.promise().execute<ResultSetHeader>(`UPDATE users SET username = ?, display_name = ?, room = ?${passwordSql} WHERE id = ? AND role = 'resident' AND deleted_at IS NULL`, values)
  return result.affectedRows > 0
}
export async function deleteResident(id: string): Promise<{ archived: boolean } | null> {
  const conn = await db.promise().getConnection()
  try {
    await conn.beginTransaction()
    const [rows] = await conn.execute<RowDataPacket[]>("SELECT id FROM users WHERE id = ? AND role = 'resident' FOR UPDATE", [id])
    if (!rows.length) { await conn.rollback(); return null }
    let archived = false
    try {
      await conn.execute('DELETE FROM users WHERE id = ?', [id])
    } catch (error) {
      if ((error as { code?: string }).code !== 'ER_ROW_IS_REFERENCED_2') throw error
      await conn.execute('UPDATE users SET deleted_at = COALESCE(deleted_at, UTC_TIMESTAMP()) WHERE id = ?', [id])
      archived = true
    }
    await conn.commit()
    return { archived }
  } catch (error) { await conn.rollback(); throw error }
  finally { conn.release() }
}
