import assert from 'node:assert/strict'
import { request } from 'node:http'
import { once } from 'node:events'
import app from '../app'
import connection from '../utils/db'

async function main() {
  const server = app.listen(0, '127.0.0.1')
  await once(server, 'listening')
  const port = (server.address() as { port: number }).port
  const users: number[] = []
  const ids: number[] = []
  function call(method: string, path: string, token?: string, body?: unknown): Promise<{ status: number; data: any }> {
    return new Promise((resolve, reject) => {
      const req = request({ hostname: '127.0.0.1', port, path, method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) } }, res => {
        let text = ''
        res.on('data', chunk => text += chunk)
        res.on('end', () => { try { resolve({ status: res.statusCode!, data: JSON.parse(text) }) } catch (e) { reject(e) } })
      })
      req.on('error', reject)
      req.end(body === undefined ? undefined : JSON.stringify(body))
    })
  }
  try {
    const login = await call('POST', '/api/auth/login', undefined, { username: 'admin', password: process.env.ADMIN_PASSWORD })
    assert.equal(login.status, 200)
    const admin = login.data.token
    const tokens: string[] = []
    for (let i = 0; i < 2; i++) {
      const username = `request_test_${Date.now()}_${i}`
      const body = { username, password: 'Request@123', display_name: 'ผู้พักทดสอบ API', room: `T0${i}` }
      const created = await call('POST', '/api/residents', admin, body)
      assert.equal(created.status, 201)
      users.push(created.data.user.id)
      const auth = await call('POST', '/api/auth/login', undefined, body)
      assert.equal(auth.status, 200)
      tokens.push(auth.data.token)
    }
    const content = { category: 'repair', title: 'คำร้องทดสอบ', description: 'ทดสอบบันทึกจริง' }
    assert.equal((await call('GET', '/api/requests')).status, 401)
    assert.equal((await call('POST', '/api/requests', admin, content)).status, 403)
    assert.equal((await call('POST', '/api/requests', tokens[0], { ...content, category: 'invalid' })).status, 400)
    assert.equal((await call('POST', '/api/requests', tokens[0], { ...content, title: ' ' })).status, 400)
    assert.equal((await call('POST', '/api/requests', tokens[0], { ...content, description: 'x'.repeat(2001) })).status, 400)
    const baseline = await call('GET', '/api/requests?limit=3', admin)
    assert.equal(baseline.status, 200)
    for (let i = 0; i < 4; i++) {
      const created = await call('POST', '/api/requests', tokens[0], { ...content, title: `คำร้องทดสอบ ${i}`, resident_id: users[1], room: 'SPOOF', status: 'completed' })
      assert.equal(created.status, 201)
      ids.push(created.data.request.id)
      assert.equal(created.data.request.resident_id, users[0])
      assert.equal(created.data.request.room, 'T00')
      assert.equal(created.data.request.status, 'pending')
    }
    const mine = await call('GET', '/api/requests', tokens[0])
    assert.deepEqual(mine.data.requests.map((r: any) => r.id), ids.slice().reverse())
    assert.equal((await call('GET', '/api/requests', tokens[1])).data.requests.length, 0)
    const overview = await call('GET', '/api/requests?limit=3', admin)
    assert.equal(overview.data.requests.length, 3)
    assert.deepEqual(overview.data.requests.map((r: any) => r.id), ids.slice(-3).reverse())
    assert.equal(Number(overview.data.counts.total), Number(baseline.data.counts.total) + 4)
    const path = `/api/requests/${ids[0]}`
    assert.equal((await call('GET', path, tokens[1])).status, 404)
    assert.equal((await call('PATCH', path, tokens[1], { action: 'cancel', note: 'ไม่ใช่เจ้าของ' })).status, 404)
    assert.equal((await call('PATCH', path, tokens[0], { action: 'status', status: 'completed', note: 'ไม่มีสิทธิ์' })).status, 403)
    const detail = await call('GET', path, admin)
    assert.equal(detail.data.history.length, 1)
    assert.equal(detail.data.history[0].actor_id, users[0])
    assert.equal(detail.data.history[0].from_status, null)
    assert.equal(detail.data.history[0].to_status, 'pending')
    assert.equal((await call('PATCH', path, tokens[0], { ...content, action: 'edit', title: 'แก้ไขแล้ว' })).status, 200)
    assert.equal((await call('GET', path, admin)).data.request.title, 'แก้ไขแล้ว')
    assert.equal((await call('PATCH', path, admin, { action: 'status', status: 'completed', note: 'ข้ามขั้นตอน' })).status, 409)
    assert.equal((await call('PATCH', path, admin, { action: 'status', status: 'in_progress', note: ' ' })).status, 400)
    assert.equal((await call('PATCH', path, admin, { action: 'status', status: 'in_progress', note: 'ติดต่อช่างแล้ว' })).status, 200)
    assert.equal((await call('PATCH', path, tokens[0], { ...content, action: 'edit' })).status, 409)
    assert.equal((await call('PATCH', path, tokens[0], { action: 'cancel', note: 'ยกเลิกไม่ได้' })).status, 409)
    assert.equal((await call('PATCH', path, admin, { action: 'status', status: 'completed', note: 'ซ่อมเสร็จแล้ว' })).status, 200)
    const finished = await call('GET', path, tokens[0])
    assert.equal(finished.data.request.status, 'completed')
    assert.deepEqual(finished.data.history.map((h: any) => h.to_status), ['pending', 'pending', 'in_progress', 'completed'])
    assert.equal(finished.data.history[3].actor_id, login.data.user.id)
    assert.ok(finished.data.history.every((h: any) => h.created_at && h.note))
    const cancelPath = `/api/requests/${ids[1]}`
    assert.equal((await call('PATCH', cancelPath, tokens[0], { action: 'cancel', note: ' ' })).status, 400)
    assert.equal((await call('PATCH', cancelPath, tokens[0], { action: 'cancel', note: 'แก้ไขเองแล้ว' })).status, 200)
    const cancelled = await call('GET', cancelPath, tokens[0])
    assert.equal(cancelled.data.request.status, 'cancelled')
    assert.equal(cancelled.data.request.cancellation_reason, 'แก้ไขเองแล้ว')
    assert.equal((await call('GET', '/api/requests?status=pending', tokens[0])).data.requests.length, 2)
    console.log('PASS: request creation, room/owner protection, lists, latest 3, counts, history, transitions, edit and cancellation')
  } finally {
    // Delete only records created by this test, preserving pre-existing data.
    try {
      for (const id of ids) {
        await connection.promise().execute('DELETE FROM request_status_history WHERE request_id = ?', [id])
        await connection.promise().execute('DELETE FROM repair_requests WHERE id = ?', [id])
      }
      for (const id of users) await connection.promise().execute('DELETE FROM users WHERE id = ?', [id])
    } finally { server.close(); connection.end() }
  }
}
main().catch(error => { console.error(error); process.exitCode = 1 })
