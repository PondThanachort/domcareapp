# DormCare — Project Handoff and Development Rules

## กฎการจัดทำเอกสารโครงงาน

- อ้างอิงโค้ด โครงสร้างไฟล์ และพฤติกรรมจริงของ domcareapp ควบคู่กับ requirement ที่ตกลงไว้เท่านั้น
- ตัวอย่าง Campus Coffee ใช้เป็นแนวทางรูปแบบเอกสาร ไม่คัดลอกเทคโนโลยี ฟีเจอร์ จำนวนไฟล์ หรือผลทดสอบมาเป็นข้อมูลของ DormCare
- ตรวจไฟล์จริงก่อนอธิบายแต่ละหัวข้อ ไม่เพิ่มโฟลเดอร์ ระบบ หรือรายละเอียดที่ไม่มีในโปรเจคเพื่อให้ตรงกับตัวอย่าง
- แยกสิ่งที่ใช้งานอยู่ โค้ด Mock/โค้ดเก่าที่เก็บอ้างอิง งานที่ยังไม่ได้ทำ และส่วนที่ยังไม่ได้ทดสอบกับฐานข้อมูลจริงให้ชัดเจนเมื่อเกี่ยวข้อง
- ระบุจำนวนไฟล์ หน้าจอ หรือผลทดสอบเฉพาะเมื่อมีหลักฐานตรวจสอบ ไม่คาดเดาและไม่อ้างผลทดสอบเก่าว่าเป็นผลปัจจุบัน

เอกสารนี้เป็นข้อมูลส่งต่องานสำหรับผู้พัฒนาหรือแชตใหม่ ให้ตรวจโค้ดจริงควบคู่กับเอกสารนี้เสมอ คำสั่งล่าสุดจากผู้ใช้มีลำดับความสำคัญสูงกว่าเนื้อหาในไฟล์นี้

## ตำแหน่งโปรเจค

- โปรเจค Flutter ที่ใช้งานจริงอยู่ที่ `/Users/itsme/vscode/domcareapp`
- Workspace เก่า `/Users/itsme/vscode/domcare` ไม่มีอยู่แล้ว อย่าแก้ไฟล์โดยอ้าง path เก่า
- Package name ใน `pubspec.yaml` คือ `domcareapp`
- โปรเจคนี้ไม่มี Git repository ของตัวเองในโฟลเดอร์ปัจจุบัน หากคำสั่ง Git ไปจับ repository จาก parent directory ให้หยุดและตรวจ path ก่อน ห้าม commit ไฟล์นอกโปรเจคโดยไม่ตั้งใจ
- Backend เก่าที่ติดมากับโปรเจคอยู่ใน `serverapi/` และยังเป็นโค้ด Coffee Product เดิม ยังไม่ใช่ DormCare API

## เป้าหมายของ Mini Project

- DormCare เป็นแอปแจ้งเรื่องสำหรับผู้พักอาศัยในหอพัก มี Flutter frontend, REST API, JSON และ JWT
- เน้นฟีเจอร์หลักให้ครบและอธิบายกับอาจารย์ได้ง่าย ไม่สร้างระบบบริหารหอพักเต็มรูปแบบ
- ใช้โปรเจค coffeeprd เป็นแนวทางด้านโครงสร้างเท่านั้น ระบบสินค้า ราคา สต็อก ตะกร้า และคำสั่งซื้อไม่อยู่ใน DormCare
- PDF proposal เป็นเอกสารอ้างอิงด้านแนวคิดและหน้าตา ข้อตกลงที่ผู้ใช้อธิบายภายหลังให้ใช้แทนส่วนที่ขัดกับ PDF

## กฎด้านโครงสร้าง Flutter

- `lib/main.dart` ต้องมี `main()`, `MyApp` และ `MaterialApp` ตามรูปแบบที่ผู้ใช้เรียนมา
- ไม่ต้องแยก `MyApp` ไปไว้ใน `app.dart`
- แยกหน้าจอ ธีม และ widget ไปไว้ในโฟลเดอร์ของตนเองได้
- `MyApp` ปัจจุบันเป็น `StatefulWidget` เพราะเก็บ `ThemeMode` และสลับ Light/Dark mode
- รักษาไฟล์ที่ผู้ใช้แก้เอง อย่าเขียนทับงานที่ไม่เกี่ยวข้อง
- หลังแก้โค้ด ให้รัน `dart format`, `flutter analyze` และ test ที่เกี่ยวข้อง

โครงสร้างหน้าจอหลักปัจจุบัน:

```text
lib/
├── main.dart
├── theme/app_theme.dart
├── screens/
│   ├── login_page.dart
│   ├── app_shell.dart
│   ├── home_page.dart
│   ├── requests_page.dart
│   ├── create_request_page.dart
│   ├── profile_page.dart
│   └── admin/
│       ├── admin_shell.dart
│       ├── admin_dashboard_page.dart
│       ├── admin_requests_page.dart
│       ├── admin_residents_page.dart
│       └── admin_profile_page.dart
└── widgets/
    ├── floating_pill_navbar.dart
    └── request_card.dart
```

## บทบาทและบัญชี

ระบบมี 2 บทบาทเท่านั้น:

### ผู้พักอาศัย (`resident`)

- Login ด้วย `username` และ `password` ไม่ใช่อีเมล
- ไม่มีหน้าสมัครสมาชิก ผู้ดูแลสร้างบัญชีและผูกเลขห้องให้ตอนเข้าพัก
- เลขห้องมาจากบัญชี ผู้พักไม่ต้องกรอกหรือเลือกห้องตอนสร้างคำร้อง
- ดูเฉพาะคำร้องของตนเอง
- แก้ไขรายละเอียดหรือยกเลิกคำร้องได้เฉพาะสถานะ `pending`
- การยกเลิกต้องกรอกเหตุผล และต้องเก็บคำร้องไว้เป็นประวัติ ห้าม hard delete
- เมื่อคำร้องเป็น `in_progress`, `completed` หรือ `cancelled` ผู้พักดูได้อย่างเดียว

### ผู้ดูแล (`admin`)

- Mini Project ใช้บัญชีผู้ดูแลหนึ่งบัญชี
- ดูคำร้องของผู้พักทุกคน ดูภาพรวม และเปลี่ยนสถานะพร้อมบันทึกหมายเหตุได้
- เพิ่มบัญชีผู้พักโดยระบุชื่อผู้ใช้ รหัสผ่าน และเลขห้อง
- ผู้ดูแลเป็นผู้ติดต่อช่างนอกระบบ แล้วอัปเดตสถานะตามข้อมูลจากช่าง
- ไม่มีบัญชีช่าง ไม่มีระบบรับงานหรือมอบหมายงาน

## Login จำลองในช่วงออกแบบ UI

- Login เชื่อม `POST /api/auth/login` ใน `serverapi` และตรวจบัญชีจริงในฐานข้อมูล `dormcare` แล้ว
- ไม่มี fallback ไป Mock login; แยกหน้าโดย role ที่ API ส่งกลับ
- JWT และข้อมูลผู้ใช้เก็บในหน่วยความจำ ล้างเมื่อ Logout; เปิดแอปใหม่ต้อง Login ใหม่
- บัญชี admin ถูกสร้างด้วย bcrypt แล้ว รหัสผ่านไม่ได้เก็บเป็น plaintext ในฐานข้อมูล
- คำร้อง Dashboard และการเพิ่มผู้พักยังเป็น Mock ยังไม่เชื่อม API
- ค่า API_BASE_URL ตั้งผ่าน --dart-define; iOS Simulator ใช้ http://127.0.0.1:3000
- GET /api/auth/me ตรวจ JWT และอ่านบัญชีจากฐานข้อมูล; ปิด public register และ product routes แล้ว
- migrations/seeds เดิมยังเป็น Coffee Product ห้ามรันกับ dormcare จนกว่าจะปรับให้ตรง schema

## สถานะคำร้องและสิทธิ์

ลำดับงานหลัก:

`รอดำเนินการ → กำลังตรวจสอบ/ซ่อม → เสร็จสิ้น`

ค่าที่เสนอให้ใช้ตรงกันทั้ง Flutter, API และฐานข้อมูล:

- `pending` = รอดำเนินการ
- `in_progress` = กำลังตรวจสอบ/ซ่อม
- `completed` = เสร็จสิ้น
- `cancelled` = ยกเลิก

กฎสำคัญ:

- ไม่ใช้สถานะ Accepted และไม่แยก “กำลังตรวจสอบ” ออกจาก “กำลังซ่อม”
- ทุกการเปลี่ยนสถานะต้องเก็บเวลา ผู้ดำเนินการ และหมายเหตุ เพื่อใช้แสดง Timeline
- Backend ต้องตรวจ role, เจ้าของคำร้อง และสถานะปัจจุบันทุกครั้ง ห้ามพึ่งเพียงการซ่อนปุ่มใน Flutter
- ผู้พักแก้ไขและยกเลิกได้เฉพาะ `pending`
- ยกเลิกต้องมีเหตุผลที่ไม่ว่าง และเปลี่ยนสถานะเป็น `cancelled` แทนการลบ record

| การทำงานของผู้พัก | pending | in_progress | completed | cancelled |
| --- | --- | --- | --- | --- |
| ดูรายละเอียด/Timeline | ได้ | ได้ | ได้ | ได้ |
| แก้ไขหมวดหมู่ หัวข้อ รายละเอียด | ได้ | ไม่ได้ | ไม่ได้ | ไม่ได้ |
| ยกเลิกพร้อมเหตุผล | ได้ | ไม่ได้ | ไม่ได้ | ไม่ได้ |

## หมวดหมู่คำร้องที่ตกลงแล้ว

- แจ้งซ่อม
- แจ้งทำความสะอาด
- แจ้งย้ายออก
- แจ้งอื่น ๆ/ฉุกเฉิน

หน้า `create_request_page.dart` มี UI เลือกหมวดหมู่ หัวข้อ รายละเอียด รูปภาพ และปุ่มส่งแล้ว แต่การบันทึกและแนบรูปยังเป็น Mock

## UX ฝั่งผู้พัก

- Bottom navigation มี 3 แท็บ: หน้าแรก, คำร้อง, โปรไฟล์
- หน้า Home แสดงเฉพาะชื่อผู้พัก เลขห้อง และบล็อก “แจ้งปัญหาใหม่”
- ไม่แสดงสถิติหรือรายการคำร้องซ้ำใน Home เพราะมีแท็บคำร้องอยู่แล้ว
- คำทักทายใน `home_page.dart` เก็บใน `Map<int, String>` และสุ่มหนึ่งครั้งใน `initState()` ต่อการเปิด Home ห้ามสุ่มใน `build()` เพราะข้อความจะเปลี่ยนเมื่อ widget rebuild
- หน้า Requests ต้องพัฒนาต่อให้ดูรายละเอียด แก้ไข และยกเลิกตามสิทธิ์และสถานะด้านบน
- หน้า Profile แสดงชื่อ ห้อง username ปุ่มสลับธีม และ Logout ไม่มีอีเมล
- Logout อยู่แถวเดียวกับหัวข้อ “โปรไฟล์” ด้านขวา และต้องล้าง navigation stack เพื่อกด Back กลับเข้าแอปไม่ได้

## UX ฝั่งผู้ดูแล

- Bottom navigation มี 4 แท็บ: ภาพรวม, คำร้อง, ผู้พัก, โปรไฟล์
- Dashboard แสดงจำนวนคำร้องตามสถานะและรายการคำร้องล่าสุด
- ส่วนสถิติใช้ `Column` กับ `Row` สองแถว ไม่ใช้ `GridView` ซ้อนใน `ListView` เพราะเคยเกิดช่องว่างขนาดใหญ่ก่อนหัวข้อ “คำร้องล่าสุด”
- หน้า Requests เป็นรายการคำร้องทั้งหมดและตัวกรองสถานะ ปัจจุบันยังเป็นข้อมูล Mock
- หน้า Residents แสดงบัญชีผู้พักและ dialog เพิ่มผู้พัก ปัจจุบันยังไม่บันทึกจริง
- หน้า Profile ของผู้ดูแลให้เรียบง่าย มีข้อมูลบัญชี ปุ่มสลับ Light/Dark mode และ Logout

## แนวทางหน้าตาและ Theme

- ใช้ Material 3 รูปทรงมน พื้นหลังอ่อน การ์ดเรียบ และ floating pill navigation ตามดีไซน์ปัจจุบัน
- ทุกหน้าต้องรองรับ Light และ Dark mode และอ่านตัวอักษรได้ชัดเจน
- ปุ่มแจ้งเตือน Dashboard และ avatar ผู้ดูแลใช้สีสลับกัน:
  - Light mode: พื้นดำ ไอคอนขาว
  - Dark mode: พื้นขาว ไอคอนดำ
- ปุ่ม Logout บน Profile ใช้พื้นและข้อความที่ปรับตาม theme
- หลีกเลี่ยง `withOpacity()` ที่ deprecated ให้ใช้ `withValues(alpha: ...)`
- ทดสอบหน้าจอขนาดประมาณ `390 × 844` และระวัง overflow ภาษาไทยกับ bottom navigation

## สถานะการพัฒนาปัจจุบัน

ทำแล้วในระดับ UI/Mock:

- Login และแยก Resident/Admin ด้วยบัญชีทดสอบ
- Light/Dark theme
- Resident shell, Home, Requests, Create Request และ Profile
- Admin shell พร้อม Dashboard, Requests, Residents และ Profile
- Logout กลับ Login พร้อมล้าง navigation stack
- หมวดหมู่คำร้อง 4 ประเภท
- Widget tests สำหรับ Login, Create Request และ Admin navigation

ยังไม่ได้ทำหรือยังไม่สมบูรณ์:

- DormCare Backend, database migrations และ seed data
- JWT authentication/authorization จริง
- Provider/service/model ที่เชื่อม API จริง
- การสร้าง แก้ไข ยกเลิก และเปลี่ยนสถานะคำร้องจริง
- Request Detail และ Timeline ที่ทำงานกับข้อมูลจริง
- การกรองคำร้องจริง
- การเพิ่มผู้พักจริง
- การแนบรูปจริง
- การคำนวณตัวเลข Dashboard จากข้อมูลจริง

## แนวทาง Backend ในงานถัดไป

- เปลี่ยน Backend เดิมใน `serverapi/` จาก products เป็น users, repair requests และ status history
- User อย่างน้อยควรมี `id`, `username`, `password_hash`, `display_name`, `room`, `role`
- Repair request อย่างน้อยควรมี `id`, `resident_id`, `category`, `title`, `description`, `status`, timestamps และข้อมูลการยกเลิก
- Status history ควรเก็บ request, สถานะ, ผู้ดำเนินการ, เวลา และหมายเหตุ
- ใช้ bcrypt hash password และ JWT Bearer token
- ปิดหรือไม่เปิด public registration ผู้พักต้องถูกสร้างโดย admin
- ใช้ transaction เมื่อเปลี่ยนสถานะพร้อมเขียนประวัติ
- API error ควรใช้ HTTP status code ที่เหมาะสมและ JSON shape เดียวกันทั้งระบบ

## สิ่งที่ไม่อยู่ในขอบเขต Mini Project

- บัญชีและแอปสำหรับช่าง
- ระบบรับงานหรือมอบหมายช่าง
- ระบบค่าเช่า สัญญาเช่า หรือบริหารห้องเต็มรูปแบบ
- Chat, Push Notification, SLA, Dashboard เชิงสถิติขั้นสูง และระบบประเมินความพึงพอใจ
- อัปโหลดหลายรูป เว้นแต่ผู้ใช้ขอเพิ่มภายหลัง

## วิธีตรวจงานก่อนส่งต่อ

```bash
cd /Users/itsme/vscode/domcareapp
dart format lib test
flutter analyze
flutter test
```

ผลตรวจล่าสุดก่อนเขียนไฟล์นี้: analyzer ผ่าน และ widget tests ผ่าน 3 รายการ อย่างไรก็ตามให้รันใหม่ทุกครั้งหลังแก้โค้ด

## Latest implementation update: resident management (2026-09-21)

- Admin Residents now uses real GET/POST/PUT/DELETE /api/residents; supersedes the Mock notes above.
- Only admins can manage residents; admin accounts are excluded and cannot be edited/deleted through these endpoints.
- Resident deletion permanently removes accounts with no foreign-key references, freeing the username. Accounts referenced by requests/history are archived with users.deleted_at and remain visible as cancelled accounts without edit/delete controls. Archived users cannot login or use existing JWTs; their username stays reserved and duplicate errors explain this.
- Blank password on edit preserves the current password. New passwords are bcrypt-hashed.
- Database role/category/status columns are VARCHAR following the user's request.
- Requests and dashboard remain Mock. Latest Flutter tests: 16 passed; resident API integration tests passed.

## Latest implementation update: real requests (2026-09-22)

- Seed update (2026-10-01): `serverapi/seeds/01_admin.ts` is the active DormCare seed; Coffee seed moved to `legacy/coffee_seeds`. Knex explicitly loads only `.ts` seeds from `./seeds`. The seed creates username admin with bcrypt cost 12 using ADMIN_PASSWORD; an existing active admin is preserved without resetting its password. Username/role/archive conflicts or other admins stop the seed. No resident/request mock data is seeded. `npm run test:seeds` passed using an in-memory Knex substitute; seed has not been applied to the live database. Supersedes earlier notes about active Coffee seeds.

- Model update (2026-10-01): `models/User.ts` owns user/auth/resident SQL; `models/RepairRequest.ts` owns request SQL, ownership/state checks under row locks, and request transactions; `models/RequestStatusHistory.ts` reads history and appends using the caller's transaction. Controllers validate inputs, hash/verify passwords, sign JWTs, and map model results/errors to HTTP responses. Authentication middleware reads active users through User. Product model moved to `legacy/coffee_models`. `npm run test:models` exercises model behavior using a scripted SQL connection, not the live database. Seeds remain unchanged. Build, model/migration tests, Flutter analyze and 22 Flutter tests passed.

- Migration update (2026-10-01): active migrations now contain a DormCare baseline for users, repair_requests, request_status_history. Coffee migrations moved to `serverapi/legacy/coffee_migrations`; Knex uses a separate `dormcare_migrations` ledger. The baseline validates existing column names/base types and creates missing tables; it does not modify existing tables or audit their constraints. Automatic rollback is intentionally refused to protect adopted tables. Models/seeds are unchanged; Coffee seeds must not be run. Migration SQL/adoption tests run offline via `npm run test:migrations`; the baseline has not been applied to the live database.

- Structure update (2026-10-01): request logic now lives in `serverapi/controllers/requestController.ts` (`getAllRequests`, `getRequestById`, `createRequest`, `updateRequest`). `routes/requestRoutes.ts` maps endpoints to these functions with `authenticateToken` on each route, matching the product route pattern. Existing request behavior is preserved.
- Resident structure update (2026-10-01): resident CRUD logic now lives in `controllers/residentController.ts`. Each route in `routes/residentRoutes.ts` calls `authenticateToken`, `middleware/requireAdmin.ts`, then the controller. ID validation remains before update/delete database operations; password and archive/delete behavior are preserved.

- Supersedes the Mock request/dashboard notes above: creation, resident/admin lists and dashboard now use `/api/requests` with the authenticated session.
- POST creates a pending request and initial history in a transaction. Resident ID and current room come from the database, never from client input.
- GET lists only the resident's own requests, or all requests for admin. `?limit=3` returns the latest three (created_at DESC, id DESC), plus counts across the full authorized list.
- Admin dashboard shows pending, in_progress, completed (all completed, not only today), and total. “ดูทั้งหมด” selects the admin requests tab and resets its filter to all.
- Lists refresh after mutations, on tab entry, and on pull-to-refresh. This is not a push/realtime subscription between devices.
- `live_request_detail_page.dart` loads real details/history. PATCH supports resident edit/cancel only while pending, and admin pending → in_progress → completed with required notes. State checks and history writes use a transaction and row lock.
- Old mock detail/model files remain as previous UI references, but are not linked from the live lists.
- Image attachment remains unimplemented; the UI explicitly explains this when tapped.
- `npm run test:requests` covers database-backed creation, ownership/room protection, latest-three/counts, edit/cancel and transitions. Requires ADMIN_PASSWORD and an accessible configured database; this task did not run it because database access was declined.
- Validation: `dart format lib test`, `flutter analyze` (no issues), `flutter test` (22 passed), and `npm run build` passed. Flutter tests use an injected test API; live database integration remains unverified for this change.
