import 'dotenv/config'
import bcrypt from 'bcrypt'
import { RowDataPacket } from 'mysql2'
import connection from '../utils/db'

async function main() {
  const password = process.env.ADMIN_PASSWORD
  if (!password || Buffer.byteLength(password, 'utf8') > 72) throw new Error('Set ADMIN_PASSWORD (1–72 bytes)')
  const db = connection.promise()
  const [rows] = await db.execute<RowDataPacket[]>('SELECT id, role, password_hash FROM users WHERE username = ?', ['admin'])
  if (rows.length) {
    if (rows[0].role !== 'admin' || !await bcrypt.compare(password, rows[0].password_hash)) {
      throw new Error('Username admin already exists with different credentials; no changes made')
    }
    console.log('Admin account already exists and credentials match')
    return
  }
  const hash = await bcrypt.hash(password, 12)
  await db.execute('INSERT INTO users (username, password_hash, display_name, room, role) VALUES (?, ?, ?, ?, ?)', ['admin', hash, 'ผู้ดูแลระบบ', null, 'admin'])
  console.log('Created admin account with bcrypt password hash')
}
main().catch(e => { console.error(e.message); process.exitCode = 1 }).finally(() => connection.end())
