import { Knex } from 'knex'
import bcrypt from 'bcrypt'

/** Initial account only. Never clears tables, resets passwords or restores accounts. */
export async function seed(knex: Knex): Promise<void> {
  const existing = await knex('users')
    .where({ username: 'admin' }).orWhere({ role: 'admin' })
    .select('id', 'username', 'role', 'deleted_at')
  if (existing.length) {
    if (existing.length === 1 && existing[0].username === 'admin' &&
        existing[0].role === 'admin' && existing[0].deleted_at == null) {
      console.log('Admin already exists; account and password unchanged')
      return
    }
    throw new Error('Admin account or username conflict; no accounts changed. Review existing users before seeding.')
  }
  const password = process.env.ADMIN_PASSWORD
  if (!password || !password.trim() || Buffer.byteLength(password, 'utf8') > 72) {
    throw new Error('Set ADMIN_PASSWORD to a nonblank password of at most 72 UTF-8 bytes before seeding')
  }
  const hash = await bcrypt.hash(password, 12)
  // A concurrent insert of username admin fails on the unique key, never overwrites it.
  await knex('users').insert({
    username: 'admin', password_hash: hash, display_name: 'ผู้ดูแลระบบ',
    room: null, role: 'admin', deleted_at: null,
  })
  console.log('Created DormCare admin with bcrypt password hash')
}
