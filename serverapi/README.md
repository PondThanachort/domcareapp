# DormCare API — Login

Existing `dormcare.users` schema: id, username, password_hash, display_name,
room, role, created_at, updated_at. This iteration does not run migrations.
Old Coffee migrations are archived in `legacy/coffee_migrations`; they are not loaded.
Coffee seeds are archived in `legacy/coffee_seeds`; `knex:seed:run` loads only DormCare TypeScript seeds.

1. Install dependencies with `npm install` if needed.
2. Set `.env` using `.env.example`. Set JWT_SECRET to a random secret of at least 32 characters.
3. Start MySQL/MariaDB, then run `npm start` from serverapi.
4. Run Flutter. Default API: iOS Simulator `http://127.0.0.1:3000`, Android emulator `http://10.0.2.2:3000`.
   For other hosts: `flutter run --dart-define=API_BASE_URL=http://YOUR_HOST:3000`.

POST /api/auth/login accepts JSON username/password, returns token and user.
GET /api/auth/me accepts Authorization: Bearer TOKEN and rechecks the user in DB.
JWT expires after 8 hours. No public registration or product API is mounted.
The Flutter session is memory-only and cleared on logout. Request screens use the authenticated API.

Admin provisioning: set ADMIN_PASSWORD in the process environment, then run
`npm run admin:create`. It inserts username admin with a bcrypt hash. Existing
accounts are never overwritten; a different existing password/role causes an error.

Validation: `npm run build`; with ADMIN_PASSWORD set to the existing admin's
password, `npm test` checks login/me and resident management against the configured DB.
Integration tests create temporary records and remove only their own records.

## Resident management

users.deleted_at is required (sql/20260921_resident_soft_delete.sql; applied locally).
Admin-only GET/POST /api/residents and PUT/DELETE /api/residents/:id.
Fields: username, display_name, room, password. Password is required on create;
omit or leave empty on update to keep the existing hash. Role is always resident.
Accounts without references are permanently deleted, freeing their username.
Accounts with references are archived, retain their unique username and request
history, and remain visible as cancelled accounts. They cannot login or use old
tokens. Duplicate-username errors explicitly identify archived accounts.
The integration test creates a uniquely named temporary resident and request and
cleans up only its own records.

## Requests

Uses `repair_requests` and `request_status_history`; see the DormCare baseline below for setup.
All routes require a JWT and an active account.

- `POST /api/requests` — residents only. JSON: category, title (1–200 chars), description (1–2000 chars). Category: repair, cleaning, move_out, other_emergency. Owner/room are read from users; status starts at pending.
- `GET /api/requests` — resident's own requests or all for admin. Optional `status=pending|in_progress|completed|cancelled`. `limit=3` is used by the dashboard. Returns requests and counts (total, pending, in_progress, completed); counts ignore the status/limit filters.
- `GET /api/requests/:id` — authorized detail and history, including actor names.
- `PATCH /api/requests/:id` — `{action: "edit", category, title, description}` or `{action: "cancel", note}` for the owner while pending. Admin uses `{action: "status", status, note}` for pending → in_progress → completed. Notes are required and limited to 2000 chars. Cancellation preserves the request.

Creation and mutations write history atomically. New timestamps are stored in UTC; Flutter displays local time.
Flutter refreshes when switching to the relevant tab, after mutation, or by pull-to-refresh.
Photo uploads are not implemented yet.

Run `npm run build` to type-check. With ADMIN_PASSWORD set, `npm run test:requests`
exercises the complete request lifecycle against the configured DB and cleans up its test records.

## DormCare migrations

`migrations/20261001000000_create_dormcare_tables.ts` creates users, repair_requests,
and request_status_history in dependency order. Includes unsigned auto-increment IDs,
unique usernames, foreign keys with RESTRICT, indexes, timestamps, and VARCHAR
role/category/status columns. It does not create accounts; use `npm run admin:create`
for the admin account, or use the DormCare seed described below.

The database itself must already exist and match DB_DATABASE in `.env`.
From serverapi, run `npm run knex:migrate:latest` to apply the baseline.
Knex records applied versions in `dormcare_migrations`, separate from any Coffee
`migrations` ledger. Existing Coffee history is not changed.

For databases previously created via SQL, the baseline first checks required
column names and base types on existing tables. Matching tables are left intact;
missing tables are created. It does not audit/repair existing lengths, defaults,
indexes, foreign keys, or unsigned attributes. If columns are incompatible it
stops before schema creation: review the schema instead of dropping tables.
An older DormCare users table missing deleted_at needs the existing soft-delete
SQL applied first; ENUM schemas need the VARCHAR conversion SQL reviewed first.

This baseline deliberately refuses rollback, because it may adopt tables holding
existing data. Future schema changes should be new migrations. MySQL DDL is not
transactional: if a run fails partway, inspect tables and constraints before retry.

`npm run test:migrations` compiles MySQL DDL and tests adoption/error handling
without connecting to a database. This is not a live migration integration test.

## Models

Active DormCare controllers call model functions instead of containing SQL:

- `models/User.ts`: active account lookup, resident list/create/update/delete/archive.
- `models/RepairRequest.ts`: request queries, creation and changes with ownership/state checks and transactions.
- `models/RequestStatusHistory.ts`: history queries and inserts using the request transaction's connection.
- `models/ModelError.ts`: expected domain errors mapped to HTTP responses by controllers.

Routes apply authentication/role middleware and invoke controllers. Controllers
validate input, handle bcrypt/JWT, and return JSON. Models receive data/IDs, not
Express request/response objects. `Product.ts` is archived in `legacy/coffee_models`.
The Coffee product controller remains unmounted reference code.

`npm run test:models` checks model behavior with a scripted SQL connection,
including history rollback, ownership, status transitions and resident archive.
It does not replace `npm test` / `npm run test:requests` against a real database.

## DormCare seeds

`seeds/01_admin.ts` creates the initial `admin` account with display name
ผู้ดูแลระบบ, role admin, room NULL, and a bcrypt hash (cost 12).
It does not create mock residents or requests and never clears any table.
Apply migrations first. From `serverapi`, for the agreed local development account:

```bash
ADMIN_PASSWORD='@admin' npm run knex:seed:run
```

ADMIN_PASSWORD is required only when creating the account. It must be nonblank
and at most 72 UTF-8 bytes. Existing active admin accounts with username admin
are left unchanged, even if a different password is supplied. Archived accounts,
username/role conflicts, or other admin accounts cause an error without changes.
This seed is not a password reset tool. The older `admin:create` command remains
available and checks that existing credentials match the supplied password.

`npm run test:seeds` tests hashing, repeat runs, validation and conflicts with an
in-memory Knex substitute. It does not run the seed against the real database.
