import assert from 'node:assert/strict'
import { request } from 'node:http'
import jwt from 'jsonwebtoken'
import app from '../app'
import connection from '../utils/db'
import { RowDataPacket, ResultSetHeader } from 'mysql2'
import { jwtSecret, tokenOptions } from '../utils/auth'

const server = app.listen(0, '127.0.0.1', async () => {
  const address = server.address() as { port: number }
  let residentId: number | undefined
  let requestId: number | undefined
  function call(path: string, body?: unknown, token?: string, method?: string): Promise<{ status: number; data: any }> {
    return new Promise((resolve, reject) => {
      const req = request({ hostname: '127.0.0.1', port: address.port, path, method: method || (body === undefined ? 'GET' : 'POST'), headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) } }, res => {
        let text = ''; res.on('data', chunk => text += chunk); res.on('end', () => resolve({ status: res.statusCode!, data: JSON.parse(text) }))
      }); req.on('error', reject); req.end(body === undefined ? undefined : JSON.stringify(body))
    })
  }
  try {
    const success = await call('/api/auth/login', { username: 'admin', password: process.env.ADMIN_PASSWORD, role: 'resident' })
    assert.equal(success.status, 200)
    assert.equal(success.data.user.role, 'admin')
    assert.equal(success.data.user.password_hash, undefined)
    const payload = jwt.verify(success.data.token, jwtSecret()) as jwt.JwtPayload
    assert.ok(payload.exp && payload.sub)
    assert.equal((await call('/api/auth/me', undefined, success.data.token)).data.user.username, 'admin')
    assert.equal((await call('/api/auth/login', { username: 'admin', password: 'wrong-password' })).status, 401)
    assert.equal((await call('/api/auth/login', { username: 'nonexistent-login-test', password: 'wrong' })).status, 401)
    assert.equal((await call('/api/auth/login', { username: {}, password: 'x' })).status, 400)
    assert.equal((await call('/api/auth/me')).status, 401)
    assert.equal((await call('/api/auth/me', undefined, 'invalid')).status, 401)
    const expired = jwt.sign({}, jwtSecret(), { ...tokenOptions, subject: payload.sub, expiresIn: -1 })
    assert.equal((await call('/api/auth/me', undefined, expired)).status, 401)
    assert.equal((await call('/api/auth/register', {})).status, 404)
    assert.equal((await call('/api/products', undefined, success.data.token)).status, 404)
    const adminToken = success.data.token
    const username = `test_resident_${Date.now()}`
    const residentBody = { username, password: 'Resident@123', display_name: 'ผู้พักทดสอบ', room: 'T01' }
    assert.equal((await call('/api/residents')).status, 401)
    assert.equal((await call('/api/residents', {}, adminToken)).status, 400)
    const created = await call('/api/residents', residentBody, adminToken)
    assert.equal(created.status, 201)
    residentId = created.data.user.id
    assert.equal(created.data.user.password_hash, undefined)
    assert.equal((await call('/api/residents', residentBody, adminToken)).status, 409)
    assert.equal((await call('/api/residents', { ...residentBody, role: 'admin' }, adminToken)).status, 400)
    const listing = await call('/api/residents', undefined, adminToken)
    assert.ok(listing.data.users.some((u: any) => u.id === residentId))
    assert.ok(listing.data.users.every((u: any) => u.role === 'resident' && u.password_hash === undefined))
    const residentLogin = await call('/api/auth/login', { username, password: residentBody.password })
    assert.equal(residentLogin.status, 200)
    for (const method of ['GET', 'POST', 'PUT', 'DELETE']) {
      assert.equal((await call(method === 'GET' || method === 'POST' ? '/api/residents' : `/api/residents/${residentId}`, method === 'POST' || method === 'PUT' ? residentBody : undefined, residentLogin.data.token, method)).status, 403)
    }
    assert.equal((await call(`/api/residents/${success.data.user.id}`, residentBody, adminToken, 'PUT')).status, 404)
    assert.equal((await call(`/api/residents/${success.data.user.id}`, undefined, adminToken, 'DELETE')).status, 404)
    assert.equal((await call(`/api/residents/${residentId}`, { ...residentBody, password: '', room: 'T02' }, adminToken, 'PUT')).status, 200)
    assert.equal((await call('/api/auth/login', { username, password: residentBody.password })).status, 200)
    assert.equal((await call(`/api/residents/${residentId}`, { ...residentBody, password: 'New@123', room: 'T02' }, adminToken, 'PUT')).status, 200)
    assert.equal((await call('/api/auth/login', { username, password: residentBody.password })).status, 401)
    assert.equal((await call('/api/auth/login', { username, password: 'New@123' })).status, 200)
    const permanent = await call(`/api/residents/${residentId}`, undefined, adminToken, 'DELETE')
    assert.equal(permanent.status, 200)
    assert.equal(permanent.data.archived, false)
    const [removed] = await connection.promise().execute<RowDataPacket[]>('SELECT id FROM users WHERE id = ?', [residentId])
    assert.equal(removed.length, 0)
    const recreated = await call('/api/residents', residentBody, adminToken)
    assert.equal(recreated.status, 201)
    assert.notEqual(recreated.data.user.id, residentId)
    assert.equal((await call('/api/auth/me', undefined, residentLogin.data.token)).status, 401)
    residentId = recreated.data.user.id
    const freshLogin = await call('/api/auth/login', { username, password: residentBody.password })
    assert.equal(freshLogin.status, 200)
    const [insert] = await connection.promise().execute<ResultSetHeader>("INSERT INTO repair_requests (resident_id, room, category, title, description) VALUES (?, 'T02', 'repair', 'Integration test', 'Temporary test request')", [residentId])
    requestId = insert.insertId
    assert.equal((await call(`/api/residents/${residentId}`, undefined, adminToken, 'DELETE')).status, 200)
    assert.equal((await call('/api/auth/login', { username, password: residentBody.password })).status, 401)
    assert.equal((await call('/api/auth/me', undefined, freshLogin.data.token)).status, 401)
    assert.equal((await call('/api/auth/login', { username, password: 'New@123' })).status, 401)
    assert.equal((await call('/api/auth/me', undefined, residentLogin.data.token)).status, 401)
    assert.ok((await call('/api/residents', undefined, adminToken)).data.users.find((u: any) => u.id === residentId).deleted_at)
    const duplicateArchived = await call('/api/residents', residentBody, adminToken)
    assert.equal(duplicateArchived.status, 409)
    assert.match(duplicateArchived.data.message, /ยกเลิกแล้ว/)
    const [kept] = await connection.promise().execute<RowDataPacket[]>('SELECT id FROM repair_requests WHERE id = ?', [requestId])
    assert.equal(kept.length, 1)
    console.log('PASS: auth and resident CRUD, validation, duplicate username, admin protection, resident forbidden, password reset, soft deletion preserves requests and rejects old JWT')
  } catch (error) { console.error(error); process.exitCode = 1 }
  finally {
    try {
      if (requestId) await connection.promise().execute('DELETE FROM repair_requests WHERE id = ?', [requestId])
      if (residentId) await connection.promise().execute('DELETE FROM users WHERE id = ?', [residentId])
    } finally { server.close(); connection.end() }
  }
})
