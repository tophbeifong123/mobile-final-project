# InternFinder — Architecture

แบบระบบของแอปฝึกงาน InternFinder ยึด [REQUIREMENTS.md](REQUIREMENTS.md) เป็นขอบเขตฟีเจอร์ รายละเอียดตารางอยู่ใน [DATABASE.md](DATABASE.md)

สถานะตอนนี้ในรีโปคือสแคฟโฟลด์: NestJS ที่ `server/src` และ Flutter ที่เปิด `HomeScreen` ตรงจาก `client/lib/main.dart` เอกสารนี้คือแบบที่โค้ดใหม่ต้องเดินตาม

## 1. ภาพรวม

แอปมือถือ Flutter เรียก REST API ของ NestJS ผ่าน Nginx ตัว API ไม่เก็บ session และไม่เก็บไฟล์บนดิสก์ของตัวเอง

- ข้อมูลจริงอยู่ใน PostgreSQL
- Resume PDF และ logo อยู่ใน MinIO
- Redis ใช้เป็น cache, คิว, pub/sub และล็อกระยะสั้น
- HTTP adapter คือ Express ไม่ใช้ Fastify
- สัญญาของ API คือ Swagger ที่ `GET /api/docs`

```mermaid
flowchart LR
  app[FlutterApp] --> nginx[Nginx]
  nginx --> api1[NestAPI]
  nginx --> api2[NestAPI]
  api1 --> primary[(PostgresPrimary)]
  api2 --> replica[(PostgresReplica)]
  api1 --> redis[(Redis)]
  api2 --> redis
  worker[BullMQWorker] --> redis
  worker --> primary
  api1 --> minio[ObjectStorage]
  api2 --> minio
```

เครื่องพัฒนาใน `docker-compose.yml` รัน API, PostgreSQL, Redis และ MinIO อย่างละหนึ่งตัว Production profile เพิ่ม Nginx, PostgreSQL replica และ Redis หลายโหนด โค้ดใช้ TypeORM replication กับ JWT ที่ไม่ผูกเครื่อง ดังนั้นเพิ่มอินสแตนซ์ได้โดยไม่เปลี่ยนกติกาธุรกิจ

Read ของ job feed ชี้ replica Write ทุกชนิดชี้ primary

## 2. ทำไมใช้ Express

ใช้ `@nestjs/platform-express` ที่มีอยู่ใน `server/package.json` แล้ว Swagger ใน `server/src/main.ts` ทำงานบน Express อยู่แล้ว

- อัปโหลด Resume และ logo ใช้ `FileInterceptor` กับ multipart ซึ่งเป็นเส้นทางมาตรฐานของ NestJS บน Express
- Bull Board และ `@nestjs/terminus` เข้ากับ Express โดยไม่ต้องเขียนอะแดปเตอร์เพิ่ม
- คอขวดของแอปนี้อยู่ที่ PostgreSQL, Redis และไฟล์ ไม่ได้อยู่ที่ตัวรับ HTTP

ไม่ย้ายไป `@nestjs/platform-fastify`

## 3. Swagger

คง OpenAPI ที่ `GET /api/docs` เอกสารต้องตรงกับ route จริง ชื่อเอกสารคือ InternFinder API และมี Bearer auth

- แยก tag ตามโมดูล: Auth, Students, Companies, Provinces, Jobs, Applications, Notifications, Health
- DTO ทุกตัวมี `@ApiProperty` รวม enum และฟิลด์ที่ required
- endpoint ทุกตัวมี `@ApiOperation` และ `@ApiResponse` ของสถานะที่ใช้จริง เช่น 200, 201, 400, 401, 403, 409
- endpoint ที่ต้อง login มี `@ApiBearerAuth`
- อัปโหลด Resume และ logo ระบุว่าเป็น `multipart/form-data`
- ฝั่ง Flutter เรียกเฉพาะเส้นทางที่มีใน Swagger นี้

Prefix ของ API คือ `/api` ตาม `app.setGlobalPrefix('api')` ใน `server/src/main.ts`

## 4. โมดูล NestJS

โมดูลละหนึ่งขอบเขตธุรกิจ ไม่มีโมดูล Admin

| โมดูล | หน้าที่ |
|---|---|
| AuthModule | สมัคร, login, refresh, logout, forgot/reset password |
| StudentsModule | โปรไฟล์นักศึกษาและ Resume |
| CompaniesModule | โปรไฟล์บริษัท, logo, จังหวัดและหมุดสำนักงาน, ตัวเลขแดชบอร์ด |
| ProvincesModule | มาสเตอร์จังหวัด 77 จังหวัด ชื่อเรียก และจุดกึ่งกลางสำหรับเปิดแผนที่ |
| JobsModule | ประกาศ, feed, บันทึกงาน, เปิดหรือปิดรับสมัคร |
| ApplicationsModule | สมัครงาน, timeline, เปลี่ยนสถานะ |
| NotificationsModule | แจ้งเตือนในแอปและ BullMQ worker |
| StorageModule | พอร์ตเก็บไฟล์ ตัวจริงคือ MinIO |
| HealthModule | liveness และ readiness |

Controller บาง: รับ DTO, เรียก service, คืนค่า ไม่ใส่กติกาธุรกิจใน controller

Service ถือกติกา เช่น สมัครได้ครั้งเดียว, ทางเดินสถานะ, บริษัทเห็นเฉพาะงานของตัวเอง

Repository เป็น Data Mapper ใช้คลาส repository ที่ฉีดเข้า service ห้ามให้ entity เรียก `.save()` เองแบบ Active Record

Dependency injection เป็น singleton เป็นค่าเริ่มต้น ไม่ใช้ request scope เพราะทำให้ dependency ทั้งสายกลายเป็นต่อ request ผู้ใช้ปัจจุบันมาจาก `JwtAuthGuard` ผ่าน `@CurrentUser()` Custom provider ใช้กับ storage driver และค่า TTL ของ cache

Validation เป็น global `ValidationPipe` แบบ `whitelist`, `forbidNonWhitelisted`, `transform` แยก DTO ของการสร้างงาน, แก้งาน, ค้นหา feed, สมัครงาน และเปลี่ยนสถานะ

เทสใช้ Vitest กับ `@nestjs/testing` mock repository แบบ Arrange, Act, Assert เคสขั้นต่ำคือสมัครซ้ำ, เปลี่ยนสถานะข้ามขั้น, และบริษัทเห็นเฉพาะผู้สมัครของตัวเอง

โครงโฟลเดอร์เป้าหมาย:

```text
server/src/
├── main.ts
├── app.module.ts
├── common/
│   ├── decorators/
│   ├── filters/
│   ├── guards/
│   └── interceptors/
├── config/
├── database/
│   └── migrations/
├── auth/
├── students/
├── companies/
├── provinces/
├── jobs/
├── applications/
├── notifications/
├── storage/
└── health/
```

แต่ละโมดูลธุรกิจมี `*.module.ts`, `*.controller.ts`, `*.service.ts`, `*.repository.ts`, `dto/`, `entities/`

## 5. เส้นทาง API

Filter ของหน้า Home เป็น query ของ `GET /jobs` ไม่มี resource แยก

จังหวัดที่ใช้ในโปรไฟล์บริษัท ฟอร์มประกาศ และตัวกรองงานอ้างอิงมาสเตอร์ 77 จังหวัดเดียวกัน ชื่อจังหวัดในประกาศยังเป็นอิสระจากโปรไฟล์บริษัท

### จังหวัด

| Method | Path | ใช้กับหน้า |
|---|---|---|
| GET | /api/provinces | Company Profile, Create / Edit Job, Filter |

ผลลัพธ์มีรหัสจังหวัด ชื่อมาตรฐาน ชื่อเรียกที่ค้นหาได้ และจุดกึ่งกลางสำหรับเปิดแผนที่ ไม่เรียกบริการค้นหาที่อยู่ภายนอก

### Auth

| Method | Path | ใครเรียก |
|---|---|---|
| POST | /api/auth/register | ยังไม่ login |
| POST | /api/auth/login | ยังไม่ login |
| POST | /api/auth/refresh | มี refresh token |
| POST | /api/auth/logout | login แล้ว |
| POST | /api/auth/forgot-password | ยังไม่ login, ส่ง email เพื่อขอลิงก์ |
| POST | /api/auth/reset-password | มีลิงก์ token ที่ยังไม่หมดอายุ |

Register รับ email, password และ role `student` หรือ `company` role เปลี่ยนทีหลังไม่ได้

Access token อายุสั้น Refresh token หมุนทุกครั้งที่ใช้ และเก็บเป็นค่า hash Logout คือเพิกถอน refresh token

Password recovery รองรับอีเมลที่ใช้สมัครของ Student และ Company ทุกโดเมน DTO และ PasswordRecoveryService ตรวจรูปแบบอีเมล ไม่ตรวจโดเมนตอนขอลิงก์หรือตอนใช้ token อีเมลรูปแบบถูกต้องได้คำตอบเดียวกันไม่ว่าบัญชีมีอยู่หรือไม่ ระบบส่งลิงก์ไปยังอีเมลที่บันทึกไว้ด้วย SMTP เก็บเฉพาะ SHA-256 ของ token ใน PostgreSQL ใช้ได้ครั้งเดียวภายใน 15 นาที รีเซ็ตรหัสผ่านและเพิกถอน refresh token ใน transaction เดียวใต้ user/token lock พร้อมเพิ่ม `users.token_version` เพื่อยกเลิก access token เดิมทันที ไม่ขึ้นกับ Google Login รายละเอียด SMTP อยู่ใน [PASSWORD_RECOVERY.md](PASSWORD_RECOVERY.md)

### นักศึกษา

| Method | Path | ใช้กับหน้า |
|---|---|---|
| GET, PATCH | /api/students/me | Student Profile |
| POST | /api/students/me/resume | Resume Upload |
| GET | /api/students/me/resume/file | Resume Preview / Download |
| GET | /api/jobs | Home / Job Feed |
| GET | /api/jobs/:id | Job Detail |
| GET | /api/jobs/:id/company-logo | โลโก้บริษัทบนฟีด รายละเอียดงาน และ Saved Jobs เฉพาะประกาศที่เปิดรับและนักศึกษาที่ login แล้ว |
| POST, DELETE | /api/jobs/:id/save | Save จาก Job Detail |
| GET | /api/jobs/saved | Saved Jobs |
| POST | /api/jobs/:id/applications | Apply Job |
| GET | /api/applications | My Applications |
| GET | /api/applications/:id | Application Detail |
| GET | /api/notifications | Notifications |
| GET | /api/notifications/stream | ช่อง SSE ของแจ้งเตือน |

`GET /api/jobs` รับ `search`, `province`, `workMode`, `category`, `hasAllowance`, `skills` (กรองด้วย PostgreSQL array overlap operator) และคืนเฉพาะงานสถานะ `open`

ค่า `province` และชื่อจังหวัดที่บันทึกในประกาศถูกแปลงเป็นชื่อมาตรฐานเดียวกันก่อนกรอง เพื่อรองรับชื่อเรียกอย่าง `กทม.` และข้อมูลเก่าอย่าง `กรุงเทพฯ`

Route `GET /api/jobs/saved` ต้องประกาศก่อน `GET /api/jobs/:id` เพื่อไม่ให้คำว่า `saved` ถูกจับเป็น id

`GET /api/jobs/:id` join โปรไฟล์บริษัทล่าสุดและคืน `companyWebsiteUrl`, `companySize`, `companyPerks`, `companyLocation`, `companyLogoAvailable` ร่วมกับชื่อ ประเภทกิจการ และคำอธิบาย ไม่เปิดเผย object key ของโลโก้ให้นักศึกษา โหลดโลโก้ผ่านเส้นทางประกาศที่ตรวจ role และสถานะงานก่อนอ่าน storage รองรับ PNG/JPEG/WEBP/GIF/SVG และคืน 404 เมื่อไม่มีไฟล์ งานปิดแล้วไม่สามารถใช้เส้นทางนี้ได้

Flutter โหลดรายละเอียดใหม่เมื่อกลับมาเปิดหน้าและโหลดโลโก้ด้วย Dio ที่มี token ไม่ใช้ URL รูปแบบสาธารณะหรือเพิ่มหน้าโปรไฟล์บริษัท แสดงตัวอักษรชื่อบริษัทแทนเมื่อไม่มีโลโก้หรือโหลดล้มเหลว; SVG แสดงด้วย `flutter_svg`

### บริษัท

| Method | Path | ใช้กับหน้า |
|---|---|---|
| GET | /api/companies/me/dashboard | Company Dashboard |
| GET, PATCH | /api/companies/me | Company Profile |
| POST | /api/companies/me/logo | อัปโหลด logo |
| GET, POST | /api/company/jobs | Manage Jobs, Create Job |
| GET, PATCH, DELETE | /api/company/jobs/:id | อ่าน แก้ หรือลบประกาศของบริษัทนี้ |
| PATCH | /api/company/jobs/:id/status | เปิดหรือปิดรับสมัคร |
| GET | /api/company/jobs/:id/applications | Applicants List |
| GET | /api/company/jobs/:id/applications/:applicationId | Applicant Detail |
| PATCH | /api/company/jobs/:id/applications/:applicationId/status | เปลี่ยนสถานะผู้สมัคร |

บริษัทเรียกได้เฉพาะประกาศและผู้สมัครของบริษัทตัวเอง ไม่เช่นนั้นตอบ 403

`GET /api/companies/me/dashboard` คืน `totalJobs`, `openJobs`, `totalApplicants` และ `pendingApplicants`. CompaniesService กำหนดสถานะรอตรวจเป็น `submitted` และ `reviewing`; repository นับใบสมัครผ่านประกาศของบริษัทนี้เท่านั้น รวมประกาศที่ปิดแล้วและไม่นับ timeline ซ้ำ. ไม่มีข้อมูลเป็น 0; query ล้มเหลวไม่แทนด้วย 0. Flutter ใช้ CompanyTopBar และการ์ด/ปุ่มแบบ Neo ของฝั่งบริษัท เปิดหน้าใหม่โหลดสรุปใหม่ ดึงลงเพื่อ refresh และลองใหม่ได้เมื่อเกิดข้อผิดพลาด.

`PATCH /api/companies/me` รับ `provinceId`, `location` (ที่อยู่สั้น), และ `latitude`/`longitude` เป็นคู่ พิกัดต้องมีจังหวัดก่อน และการเปลี่ยนจังหวัดโดยไม่ส่งพิกัดใหม่จะล้างหมุดเก่า แผนที่บนแอปใช้แผนที่เปิด ไม่ใช้ Google Maps key

`PATCH /api/companies/me` บันทึกเว็บไซต์ ขนาดองค์กร สวัสดิการ และที่อยู่ด้วยคอลัมน์เดิม เว็บไซต์ตรวจใน CompaniesService: ว่างได้ หรือ URL HTTP/HTTPS แบบเต็มที่ไม่มี credentials ค่าไม่ถูกต้องคืน 400 พร้อมเหตุผลโดยไม่บันทึกข้อมูลส่วนอื่น Swagger ระบุฟิลด์และกติกานี้ที่ `/api/docs`

### Health

| Method | Path | ความหมาย |
|---|---|---|
| GET | /api/health/live | โปรเซสยังทำงาน |
| GET | /api/health/ready | ต่อ PostgreSQL และ Redis ได้ |

ใช้ `@nestjs/terminus` Nginx ใช้ readiness ก่อนส่งทราฟฟิก

## 6. Redis และคิว

ใช้ Redis เฉพาะจุดที่อ่านหนักหรือต้องกันการกดซ้ำ ไม่ cache สถานะใบสมัคร, แจ้งเตือน หรือ session

### Job feed เป็น cache-aside

คีย์รวม hash ของคำค้น, ตัวกรอง และเลขเวอร์ชันของ feed TTL ประมาณ 60 วินาทีบวก jitter เพื่อไม่ให้คีย์หมดอายุพร้อมกัน

ถ้า cache ไม่มี ใช้ `SET key NX EX` ให้ตัวเดียวไปอ่านฐานข้อมูล ตัวอื่นรอค่าที่ถูกเติม เป็นการกัน cache stampede

เมื่อสร้าง แก้ หรือปิดงาน ให้ `INCR jobs:feed:version` คีย์เก่าหลุดเองตาม TTL ไม่ลบคีย์ feed ทั้งก้อน

### แดชบอร์ดเป็น write-through

API แดชบอร์ดปัจจุบันอ่านจำนวนจาก PostgreSQL โดยตรงทุก request ไม่ใช้ Redis counter; แผน write-through ด้านล่างเป็นแนวทางในอนาคตและต้องไม่ทำให้ยอดรอตรวจค้างหลังเปลี่ยนสถานะ.

ตอนสร้างประกาศหรือมีใบสมัครใหม่ ให้ `INCR` ตัวเลขของบริษัทนั้นใน Redis คู่กับการเขียน PostgreSQL ถ้า Redis หาย ให้สร้างตัวเลขใหม่จากฐานข้อมูล แหล่งความจริงคือ PostgreSQL

### กันสมัครซ้ำ

`SET NX EX` ที่คู่ student กับ job กันการกดซ้ำข้ามอินสแตนซ์ Unique index ในฐานข้อมูลยังเป็นตัวตัดสินสุดท้าย

Redlock ใช้ล็อกชุดเดียวกันนี้เมื่อ production มี Redis หลายโหนด เครื่องพัฒนาใช้ Redis ตัวเดียว จึงใช้ `SET NX EX`

### แจ้งเตือนผ่าน outbox และ BullMQ

การเปลี่ยนสถานะ commit ทั้งใบสมัคร, timeline และแถว outbox ใน transaction เดียว Worker ของ BullMQ ค่อยสร้างแจ้งเตือน ถ้า Redis ล่มระหว่าง request แถว outbox ยังอยู่ใน PostgreSQL

- retry แบบ exponential backoff
- เกินจำนวนครั้งแล้วเข้า dead letter queue
- จำกัด concurrency และ rate ของ worker
- Bull Board เปิดในเครื่องพัฒนาสำหรับดูคิว

พอ worker เขียนแจ้งเตือนแล้ว publish Redis pub/sub ที่ช่องของ user นั้น API ทุกตัวที่ถือ SSE ของนักศึกษาคนนั้นส่งต่อได้โดยไม่ต้อง sticky session แหล่งความจริงที่หน้า Notifications ยังเป็น `GET /api/notifications` ไม่ใช้ push นอกแอป

## 7. กติกาที่อยู่ใน service

สมัครงานได้เมื่อนักศึกษามี Resume แล้ว งานยัง `open` และยังไม่เคยสมัครงานนี้ ใบสมัครใหม่ได้สถานะ `submitted` พร้อม event แรก

ทางเดินสถานะมีทิศทางเดียว

```text
submitted → reviewing → accepted
                      → rejected
```

`accepted` และ `rejected` เปลี่ยนต่อไม่ได้ ทุกครั้งที่บริษัทเปลี่ยนสถานะ นักศึกษาได้แจ้งเตือนหนึ่งรายการ

รายละเอียด lock และ transaction อยู่ใน [DATABASE.md](DATABASE.md)

## 8. Flutter

ใช้ Material 3 จาก [client/lib/core/theme/app_theme.dart](../client/lib/core/theme/app_theme.dart) ไม่ลง `shadcn_ui` เพราะชุดนั้นเป็นคนละ design system และทับธีมที่มีอยู่ หน้าลิสต์ ฟอร์ม Bottom Sheet และแถบนำทางใช้ widget ของ Material

แพ็กเกจที่ลงใน `client/pubspec.yaml`

- `flutter_riverpod` ฉีด dependency และถือ state
- `go_router` นำทางและตัดสินเส้นทางจาก token
- `dio` เรียก API
- `flutter_secure_storage` เก็บ access token และ refresh token
- `file_picker` เลือก Resume PDF และ logo
- `flutter_map` และปลั๊กอินหมุดลากได้แสดงที่ตั้งสำนักงานบนแผนที่เปิด พร้อมเครดิต OpenStreetMap

ไม่ใช้ GetX, Bloc หรือ `build_runner` กติกาธุรกิจอยู่ที่ API แอปไม่มีคลาส use case แยก

โครงไฟล์เป็น feature-first ใต้ `client/lib/core` และ `client/lib/features` แต่ละฟีเจอร์แยก `presentation/`, `domain/`, `data/` Widget ไม่ยิง HTTP เอง

```text
client/lib/
├── main.dart
├── core/
│   ├── constants/api_constants.dart
│   ├── theme/app_theme.dart
│   ├── network/dio_client.dart
│   ├── network/auth_interceptor.dart
│   ├── router/app_router.dart
│   ├── router/student_shell.dart
│   ├── router/company_shell.dart
│   ├── storage/token_storage.dart
│   ├── error/app_exception.dart
│   ├── provinces/                # มาสเตอร์จังหวัดและ Bottom Sheet ที่ใช้ร่วมกัน
│   └── widgets/
│       ├── company_top_bar.dart   # แถบบนร่วมของหน้าบริษัททั้ง 6 หน้า
│       ├── job_card.dart
│       ├── status_chip.dart
│       ├── empty_state.dart
│       └── loading_view.dart
└── features/
    ├── auth/
    ├── jobs/
    ├── saved_jobs/
    ├── student_profile/
    ├── resume/
    ├── applications/
    ├── notifications/
    ├── company_dashboard/
    ├── company_profile/
    └── company_jobs/
```

แต่ละฟีเจอร์มี `presentation/screens`, `presentation/providers`, `domain/entities`, `domain/repositories`, `data/models`, `data/datasources`, `data/repositories` หน้า Filter อยู่ที่ `features/jobs/presentation/widgets/job_filter_sheet.dart` ไม่มี route ของตัวเอง

Splash ไม่ได้ยิงกติกาธุรกิจ `goRouterProvider` อ่าน session จาก `token_storage.dart` ถ้าไม่มีหรือใช้ไม่ได้ไป Login ถ้าเป็นนักศึกษาไป `/student/home` ถ้าเป็นบริษัทไป `/company/dashboard`

เชลล์นักศึกษาใน `student_shell.dart` มีแท็บ Home, Saved, Applications, Profile ไอคอนกระดิ่งไป Notifications

Route ที่ถูก push ทับเชลล์: Job Detail, Apply Job, Resume Upload, Application Detail

เชลล์บริษัทใน `company_shell.dart` มีแท็บ Dashboard, Jobs, Profile

Route ที่ถูก push: Create / Edit Job, Applicants List, Applicant Detail

ทุกหน้าของบริษัทใช้ `CompanyTopBar` เป็น `Scaffold.appBar` รวมถึงสถานะ loading/error เพื่อให้แถบบนอยู่คงที่ แสดงชื่อหน้าและป้ายบริษัท ไม่มี action แจ้งเตือน และไม่มี route `/company/notifications` หน้ารองเปิดปุ่มกลับซึ่ง pop เมื่อมีประวัติ หรือกลับไปหน้ารายการที่เกี่ยวข้องเมื่อเปิดจากลิงก์ตรง แถบบนของนักศึกษายังใช้ route `/student/notifications` ตามเดิม

Dio ใน `auth_interceptor.dart` ใส่ access token และเมื่อได้ 401 จะเรียก refresh หนึ่งครั้งก่อนล้าง session รอบโครงไฟล์นี้หน้าจอยังไม่ยิง API จริง data source โยน `AppException` จนกว่าจะต่อ endpoint

ก่อนอัปโหลด แอปต้องตรวจว่าเป็น PDF และไม่เกินขนาดที่ API กำหนด จุดเลือกไฟล์ใช้ `file_picker`

## 9. การสังเกตระบบและอิมเมจ

`server/Dockerfile` คงสองสเตจจาก `node:22-alpine` แล้วรันด้วย user ที่ไม่ใช่ root คอนเทนเนอร์เริ่มที่ `docker-entrypoint.sh` ซึ่งรัน migration ที่ค้างก่อน แล้วจึง `exec` โปรเซส API ถ้า migration ล้มเหลวคอนเทนเนอร์จบและไม่เปิดรับคำขอ

Log ใน request path เป็น JSON และมี request id ไม่ใช้ `console.log` เป็น log ของธุรกิจ

CORS เปิดให้แอปมือถือเรียกได้ตามที่มีใน `main.ts`

## 10. นอกแบบนี้

ไม่ทำแชท, นัดสัมภาษณ์, ยืนยัน email, login ด้วยโซเชียล, ถอนใบสมัคร, หน้าโปรไฟล์บริษัทแยก, Admin, push notification นอกแอป หรือการเปลี่ยน role หลังสมัคร
