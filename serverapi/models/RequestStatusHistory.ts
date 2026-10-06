import { RowDataPacket } from 'mysql2'
import { PoolConnection } from 'mysql2/promise'
import connection from '../utils/db'

export async function getByRequestId(id: string) {
  const [history] = await connection.promise().execute<RowDataPacket[]>('SELECT h.*, u.display_name AS actor_name FROM request_status_history h JOIN users u ON u.id = h.actor_id WHERE h.request_id = ? ORDER BY h.created_at, h.id', [id])
  return history
}

// The caller must supply its transaction so request and history commit together.
export async function append(db: PoolConnection, requestId: number, actorId: number, from: string | null, to: string, note: string) {
  await db.execute('INSERT INTO request_status_history (request_id, actor_id, from_status, to_status, note, created_at) VALUES (?, ?, ?, ?, ?, UTC_TIMESTAMP())', [requestId, actorId, from, to, note])
}
