import { Knex } from 'knex'

// Baseline for fresh databases and installations previously created using SQL.
// Check existing columns before any DDL; never recreate or erase existing tables.
const columns: Record<string, Record<string, string>> = {
  users: {
    id: 'int', username: 'varchar', password_hash: 'varchar',
    display_name: 'varchar', room: 'varchar', role: 'varchar',
    created_at: 'datetime', updated_at: 'datetime', deleted_at: 'datetime',
  },
  repair_requests: {
    id: 'int', resident_id: 'int', room: 'varchar', category: 'varchar',
    title: 'varchar', description: 'text', image_path: 'varchar', status: 'varchar',
    cancellation_reason: 'text', cancelled_at: 'datetime',
    created_at: 'datetime', updated_at: 'datetime',
  },
  request_status_history: {
    id: 'int', request_id: 'int', actor_id: 'int', from_status: 'varchar',
    to_status: 'varchar', note: 'text', created_at: 'datetime',
  },
}

export async function up(knex: Knex): Promise<void> {
  const existing = new Set<string>()
  for (const [name, expected] of Object.entries(columns)) {
    if (!await knex.schema.hasTable(name)) continue
    existing.add(name)
    const actual = await knex(name).columnInfo() as unknown as Record<string, Knex.ColumnInfo>
    for (const [column, type] of Object.entries(expected)) {
      if (!actual[column] || actual[column].type.toLowerCase() !== type) {
        throw new Error(`DormCare baseline: ${name}.${column} must exist with type ${type}. Existing tables were not changed. Review the schema before migrating.`)
      }
    }
  }

  if (!existing.has('users')) {
    await knex.schema.createTable('users', table => {
      table.engine('InnoDB')
      table.charset('utf8mb4')
      table.collate('utf8mb4_unicode_ci')
      table.increments('id').primary()
      table.string('username', 50).notNullable().unique()
      table.string('password_hash', 255).notNullable()
      table.string('display_name', 100).notNullable()
      table.string('room', 20).nullable()
      table.string('role', 20).notNullable().defaultTo('resident')
      table.dateTime('created_at').notNullable().defaultTo(knex.fn.now())
      table.dateTime('updated_at').notNullable().defaultTo(knex.raw('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'))
      table.dateTime('deleted_at').nullable().defaultTo(null)
    })
  }
  if (!existing.has('repair_requests')) {
    await knex.schema.createTable('repair_requests', table => {
      table.engine('InnoDB')
      table.charset('utf8mb4')
      table.collate('utf8mb4_unicode_ci')
      table.increments('id').primary()
      table.integer('resident_id').unsigned().notNullable()
        .references('id').inTable('users').onDelete('RESTRICT').onUpdate('RESTRICT')
      table.string('room', 20).notNullable()
      table.string('category', 30).notNullable()
      table.string('title', 200).notNullable()
      table.text('description').notNullable()
      table.string('image_path', 255).nullable()
      table.string('status', 20).notNullable().defaultTo('pending')
      table.text('cancellation_reason').nullable()
      table.dateTime('cancelled_at').nullable()
      table.dateTime('created_at').notNullable().defaultTo(knex.fn.now())
      table.dateTime('updated_at').notNullable().defaultTo(knex.raw('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'))
      table.index(['resident_id', 'status'])
      table.index(['status', 'created_at'])
    })
  }
  if (!existing.has('request_status_history')) {
    await knex.schema.createTable('request_status_history', table => {
      table.engine('InnoDB')
      table.charset('utf8mb4')
      table.collate('utf8mb4_unicode_ci')
      table.increments('id').primary()
      table.integer('request_id').unsigned().notNullable()
        .references('id').inTable('repair_requests').onDelete('RESTRICT').onUpdate('RESTRICT')
      table.integer('actor_id').unsigned().notNullable()
        .references('id').inTable('users').onDelete('RESTRICT').onUpdate('RESTRICT')
      table.string('from_status', 20).nullable()
      table.string('to_status', 20).notNullable()
      table.text('note').nullable()
      table.dateTime('created_at').notNullable().defaultTo(knex.fn.now())
      table.index(['request_id', 'created_at'])
      table.index(['actor_id'])
    })
  }
}

export async function down(): Promise<void> {
  // A baseline may adopt tables that predate Knex. Dropping them loses real data.
  throw new Error('DormCare baseline cannot be rolled back automatically. Use a new forward migration for schema changes; restore a backup when reverting an installation.')
}

// MySQL/MariaDB DDL implicitly commits. Interrupted runs can be retried after
// reviewing the schema; completed tables are checked and adopted on the next run.
export const config = { transaction: false }
