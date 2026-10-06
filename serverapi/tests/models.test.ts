import assert from 'node:assert/strict'
import connection from '../utils/db'
import * as requests from '../models/RepairRequest'
import * as users from '../models/User'
import { ModelError } from '../models/ModelError'

// Exercise the real model methods with a scripted SQL connection, without
// accessing the live database. Integration suites remain available separately.
type Step = { sql: RegExp; result?: unknown; fail?: Error }
let steps: Step[] = []
let events: string[] = []
let bindings: unknown[][] = []
const sql = async (statement: string, values: unknown[] = []) => {
  const step = steps.shift()
  assert.ok(step, `Unexpected SQL: ${statement}`)
  assert.match(statement, step.sql)
  bindings.push(values)
  events.push('sql')
  if (step.fail) throw step.fail
  return [step.result ?? []]
}
const transaction = {
  execute: sql,
  beginTransaction: async () => { events.push('begin') },
  commit: async () => { events.push('commit') },
  rollback: async () => { events.push('rollback') },
  release: () => { events.push('release') },
}
const pool = { execute: sql, query: sql, getConnection: async () => transaction }
const original = connection.promise
connection.promise = (() => pool) as typeof connection.promise
function setup(next: Step[]) { assert.equal(steps.length, 0); steps = next; events = []; bindings = [] }
const resident: requests.RequestActor = { id: 7, role: 'resident' }
const admin: requests.RequestActor = { id: 1, role: 'admin' }

async function main() {
  try {
    setup([{ sql: /WHERE r.resident_id = \?$/, result: [{ total: 1 }] }, { sql: /WHERE r.resident_id = \? AND r.status = \?.*LIMIT 3$/, result: [{ id: 12 }] }])
    const list = await requests.getAll(resident, 'pending', 3)
    assert.equal(list.requests[0].id, 12)
    assert.deepEqual(bindings, [[7], [7, 'pending']])

    setup([{ sql: /AND r.resident_id = \?$/, result: [] }])
    await assert.rejects(requests.getById('12', resident), (e: unknown) => e instanceof ModelError && e.status === 404)

    const input = { category: 'repair', title: ' Test ', description: ' Details ' }
    const createSteps: Step[] = [
      { sql: /SELECT room.*FOR UPDATE/, result: [{ room: '305' }] },
      { sql: /INSERT INTO repair_requests/, result: { insertId: 12 } },
      { sql: /INSERT INTO request_status_history/ },
      { sql: /SELECT r\.\*/, result: [{ id: 12 }] },
    ]
    setup(createSteps.slice())
    assert.equal((await requests.create(resident, input)).id, 12)
    assert.deepEqual(bindings[1], [7, '305', 'repair', 'Test', 'Details'])
    assert.deepEqual(bindings[2], [12, 7, null, 'pending', 'ส่งคำร้อง'])
    assert.deepEqual(events.slice(-2), ['commit', 'release'])

    setup([...createSteps.slice(0, 2), { sql: /INSERT INTO request_status_history/, fail: new Error('history failed') }])
    await assert.rejects(requests.create(resident, input), /history failed/)
    assert.deepEqual(events.slice(-2), ['rollback', 'release'])
    assert.ok(!events.includes('commit'))

    setup([{ sql: /FOR UPDATE/, result: [{ id: 12, resident_id: 8, status: 'pending' }] }])
    await assert.rejects(requests.update('12', resident, { action: 'cancel', note: 'reason' }), (e: unknown) => e instanceof ModelError && e.status === 404)
    assert.deepEqual(events.slice(-2), ['rollback', 'release'])

    setup([{ sql: /FOR UPDATE/, result: [{ id: 12, resident_id: 7, status: 'in_progress' }] }])
    await assert.rejects(requests.update('12', resident, { action: 'edit', ...input }), (e: unknown) => e instanceof ModelError && e.status === 409)

    setup([{ sql: /FOR UPDATE/, result: [{ id: 12, resident_id: 7, status: 'pending' }] }, { sql: /UPDATE repair_requests SET status/ }, { sql: /INSERT INTO request_status_history/ }])
    await requests.update('12', admin, { action: 'status', status: 'in_progress', note: 'Contacted technician' })
    assert.deepEqual(bindings[2], [12, 1, 'pending', 'in_progress', 'Contacted technician'])
    assert.deepEqual(events.slice(-2), ['commit', 'release'])

    setup([{ sql: /FOR UPDATE/, result: [{ id: 12, resident_id: 7, status: 'pending' }] }, { sql: /cancellation_reason = \?.*cancelled_at/ }, { sql: /INSERT INTO request_status_history/ }])
    await requests.update('12', resident, { action: 'cancel', note: 'Fixed myself' })
    assert.deepEqual(bindings[2], [12, 7, 'pending', 'cancelled', 'Fixed myself'])

    setup([{ sql: /UPDATE users SET username = \?, display_name = \?, room = \? WHERE.*role = 'resident' AND deleted_at IS NULL/, result: { affectedRows: 1 } }])
    assert.ok(await users.updateResident('7', { username: 'test', display_name: 'Test', room: '305' }))
    assert.deepEqual(bindings[0], ['test', 'Test', '305', '7'])

    setup([{ sql: /role = 'resident' FOR UPDATE/, result: [{ id: 7 }] }, { sql: /DELETE FROM users/ }])
    assert.deepEqual(await users.deleteResident('7'), { archived: false })
    const referenced = Object.assign(new Error('Referenced'), { code: 'ER_ROW_IS_REFERENCED_2' })
    setup([{ sql: /FOR UPDATE/, result: [{ id: 7 }] }, { sql: /DELETE FROM users/, fail: referenced }, { sql: /UPDATE users SET deleted_at/ }])
    assert.deepEqual(await users.deleteResident('7'), { archived: true })
    assert.deepEqual(events.slice(-2), ['commit', 'release'])
    assert.equal(steps.length, 0)
    console.log('PASS: model ownership, filtering, room binding, atomic history/rollback, status restrictions, cancellation, password preservation, delete/archive')
  } finally { connection.promise = original; connection.end() }
}
main().catch(error => { console.error(error); process.exitCode = 1 })
