import assert from 'node:assert/strict'
import knexFactory, { Knex } from 'knex'
import { up, down } from '../migrations/20261001000000_create_dormcare_tables'

// Compile real MySQL DDL without opening a connection. Capture column metadata
// from the compiled schema to exercise adoption and interrupted-run recovery.
async function main() {
  const compiler = knexFactory({ client: 'mysql2' })
  const statements: string[] = []
  const schemas: Record<string, Record<string, { type: string }>> = {}
  const existing = new Set<string>()
  const adapter = ((name: string) => ({ columnInfo: async () => schemas[name] })) as unknown as Knex
  Object.assign(adapter, {
    fn: compiler.fn, raw: compiler.raw.bind(compiler),
    schema: {
      hasTable: async (name: string) => existing.has(name),
      createTable: async (name: string, build: (table: Knex.CreateTableBuilder) => void) => {
        const queries = compiler.schema.createTable(name, build).toSQL() as unknown as { sql: string }[]
        const sql = queries.map(q => q.sql)
        statements.push(...sql)
        schemas[name] = {}
        for (const match of sql[0].matchAll(/`(\w+)` (int|varchar|text|datetime)\b/g)) {
          schemas[name][match[1]] = { type: match[2] }
        }
        existing.add(name)
      },
    },
  })
  try {
    await up(adapter)
    assert.deepEqual([...existing], ['users', 'repair_requests', 'request_status_history'])
    const sql = statements.join('\n')
    assert.match(sql, /`id` int unsigned not null auto_increment primary key/)
    assert.match(sql, /unique.*\(`username`\)/)
    assert.match(sql, /`role` varchar\(20\).*default 'resident'/)
    assert.match(sql, /`status` varchar\(20\).*default 'pending'/)
    assert.match(sql, /foreign key \(`resident_id`\) references `users` \(`id`\) on update RESTRICT on delete RESTRICT/i)
    assert.match(sql, /foreign key \(`request_id`\) references `repair_requests`/)
    assert.match(sql, /foreign key \(`actor_id`\) references `users`/)
    assert.match(sql, /CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP/)
    assert.doesNotMatch(sql, /\benum\b|products|firstname|lastname/)
    statements.length = 0
    await up(adapter)
    assert.equal(statements.length, 0, 'Existing compatible tables must not be changed')
    existing.delete('request_status_history')
    schemas.users.role.type = 'enum'
    await assert.rejects(up(adapter), /users.role/)
    assert.equal(statements.length, 0, 'Incompatible schemas must fail before creating missing tables')
    schemas.users.role.type = 'varchar'
    await up(adapter)
    assert.ok(statements.some(s => s.startsWith('create table `request_status_history`')))
    assert.ok(!statements.some(s => s.startsWith('create table `users`')))
    await assert.rejects(down(), /cannot be rolled back/)
    console.log('PASS: fresh schema SQL, keys, VARCHAR, existing table adoption, incompatible schema rejection, partial setup recovery, rollback protection')
  } finally { await compiler.destroy() }
}
main().catch(error => { console.error(error); process.exitCode = 1 })
