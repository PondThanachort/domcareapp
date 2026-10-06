import assert from 'node:assert/strict'
import { Knex } from 'knex'
import bcrypt from 'bcrypt'
import { seed } from '../seeds/01_admin'

async function main() {
  const originalPassword = process.env.ADMIN_PASSWORD
  const rows: Record<string, unknown>[] = []
  const inserted: Record<string, unknown>[] = []
  // Only the read/insert operations expected of an additive seed are available.
  const knex = ((table: string) => {
    assert.equal(table, 'users')
    const query = {
      where(value: unknown) { assert.deepEqual(value, { username: 'admin' }); return query },
      orWhere(value: unknown) { assert.deepEqual(value, { role: 'admin' }); return query },
      async select() { return rows },
      async insert(value: Record<string, unknown>) { inserted.push(value); rows.push({ id: 1, ...value }) },
    }
    return query
  }) as unknown as Knex
  try {
    delete process.env.ADMIN_PASSWORD
    await assert.rejects(seed(knex), /Set ADMIN_PASSWORD/)
    process.env.ADMIN_PASSWORD = '   '
    await assert.rejects(seed(knex), /Set ADMIN_PASSWORD/)
    process.env.ADMIN_PASSWORD = 'ก'.repeat(25)
    await assert.rejects(seed(knex), /72 UTF-8 bytes/)
    assert.equal(inserted.length, 0)
    process.env.ADMIN_PASSWORD = 'SeedTest@123'
    await seed(knex)
    assert.equal(inserted.length, 1)
    const account = inserted[0]
    assert.equal(account.username, 'admin')
    assert.equal(account.role, 'admin')
    assert.equal(account.room, null)
    assert.ok(await bcrypt.compare('SeedTest@123', account.password_hash as string))
    assert.equal(bcrypt.getRounds(account.password_hash as string), 12)
    const savedHash = account.password_hash
    process.env.ADMIN_PASSWORD = 'Different@123'
    await seed(knex)
    delete process.env.ADMIN_PASSWORD
    await seed(knex)
    assert.equal(inserted.length, 1)
    assert.equal(rows[0].password_hash, savedHash)
    for (const conflict of [
      { username: 'admin', role: 'resident', deleted_at: null },
      { username: 'admin', role: 'admin', deleted_at: new Date() },
      { username: 'another_admin', role: 'admin', deleted_at: null },
    ]) {
      rows.splice(0, rows.length, conflict)
      await assert.rejects(seed(knex), /conflict/)
      assert.equal(inserted.length, 1)
    }
    console.log('PASS: bcrypt seed, password validation, repeat runs preserve accounts, role/archive conflicts rejected')
  } finally {
    if (originalPassword === undefined) delete process.env.ADMIN_PASSWORD
    else process.env.ADMIN_PASSWORD = originalPassword
  }
}
main().catch(error => { console.error(error); process.exitCode = 1 })
