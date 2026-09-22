# InternFinder — Database

สคีมาของ PostgreSQL สำหรับ [REQUIREMENTS.md](REQUIREMENTS.md) การใช้งานจาก API อยู่ใน [ARCHITECTURE.md](ARCHITECTURE.md)

ใช้ TypeORM แบบ Data Mapper เปลี่ยนสคีมาด้วย migration ที่มี `up` และ `down` เท่านั้น ห้ามแก้ตารางบนเครื่องแล้วค่อยตามแก้ entity ทีหลัง

ชื่อตารางและคอลัมน์เป็น snake_case ชนิดหลักคือ `uuid` สำหรับกุญแจ และ `timestamptz` สำหรับเวลา

## 1. ER แบบข้อความ

```text
users ||--o| student_profiles : "role = student"
users ||--o| company_profiles : "role = company"
users ||--o{ refresh_tokens : has

company_profiles ||--o{ jobs : posts
student_profiles ||--o{ saved_jobs : saves
jobs ||--o{ saved_jobs : saved_by

student_profiles ||--o{ applications : submits
jobs ||--o{ applications : receives
applications ||--o{ application_status_events : timeline
applications ||--o{ notifications : notifies
student_profiles ||--o{ notifications : receives

applications ||--o{ outbox_messages : "enqueue on status change"
```

บัญชีหนึ่งแถวใน `users` มีโปรไฟล์ได้แถวเดียว และมีได้แค่ชนิดที่ตรงกับ `role` นักศึกษาไม่มีแถวใน `company_profiles` บริษัทไม่มีแถวใน `student_profiles`

## 2. Enum

| ชื่อ | ค่า |
|---|---|
| user_role | `student`, `company` |
| work_mode | `on_site`, `hybrid`, `remote` |
| job_status | `open`, `closed` |
| application_status | `submitted`, `reviewing`, `accepted`, `rejected` |
| outbox_status | `pending`, `processing`, `sent`, `dead` |

ทางเดินของ `application_status` มีทิศทางเดียว: `submitted` ไป `reviewing` แล้วไป `accepted` หรือ `rejected` สถานะจบแล้วเปลี่ยนต่อไม่ได้

## 3. ตาราง

### users

| คอลัมน์ | ชนิด | หมายเหตุ |
|---|---|---|
| id | uuid | PK |
| email | varchar | unique, ไม่ซ้ำทั้งระบบ |
| password_hash | varchar | เก็บค่า hash ไม่เก็บรหัสตรง |
| role | user_role | ตั้งตอนสมัคร แก้ไม่ได้ |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### refresh_tokens

Access token เป็น JWT ไม่เก็บในตารางนี้ ตารางนี้เก็บ refresh token ที่ hash แล้วเพื่อหมุนและเพิกถอนตอน logout

| คอลัมน์ | ชนิด | หมายเหตุ |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK → users.id |
| token_hash | varchar | unique |
| expires_at | timestamptz | |
| revoked_at | timestamptz | null แปลว่ายังใช้ได้ |
| created_at | timestamptz | |

### student_profiles

| คอลัมน์ | ชนิด | หมายเหตุ |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | unique, FK → users.id |
| full_name | varchar | |
| university | varchar | |
| major | varchar | สาขา |
| skills | text[] | ทักษะ |
| portfolio_url | varchar | null ได้ |
| resume_object_key | varchar | คีย์ไฟล์ใน MinIO, null ได้จนกว่าจะอัปโหลด |
| resume_file_name | varchar | ชื่อไฟล์ที่ผู้ใช้เลือก |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### company_profiles

| คอลัมน์ | ชนิด | หมายเหตุ |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | unique, FK → users.id |
| name | varchar | ชื่อบริษัท |
| logo_object_key | varchar | คีย์ไฟล์ใน MinIO, null ได้ |
| business_type | varchar | ประเภทกิจการ |
| description | text | |
| created_at | timestamptz | |
| updated_at | timestamptz | |

ตัวเลขแดชบอร์ดไม่เก็บเป็นคอลัมน์ นับจาก `jobs` กับ `applications` แล้วเขียนทับค่าใน Redis ถ้า Redis หายให้นับจากตารางนี้ใหม่

### jobs

| คอลัมน์ | ชนิด | หมายเหตุ |
|---|---|---|
| id | uuid | PK |
| company_id | uuid | FK → company_profiles.id |
| title | varchar | |
| description | text | |
| province | varchar | ใช้กรองจังหวัด |
| work_mode | work_mode | |
| category | varchar | หมวดงาน |
| has_allowance | boolean | มีเบี้ยเลี้ยงหรือไม่ |
| requirements | text | คุณสมบัติ |
| status | job_status | ค่าเริ่มต้น `open` |
| version | int | optimistic lock, เริ่มที่ 1 |
| created_at | timestamptz | |
| updated_at | timestamptz | |

นักศึกษาเห็นและสมัครได้เฉพาะ `status = open` งาน `closed` ยังอยู่ในการจัดการของบริษัท

### saved_jobs

| คอลัมน์ | ชนิด | หมายเหตุ |
|---|---|---|
| id | uuid | PK |
| student_id | uuid | FK → student_profiles.id |
| job_id | uuid | FK → jobs.id |
| created_at | timestamptz | |

Unique ที่ `(student_id, job_id)` บันทึกงานหนึ่งครั้งต่อหนึ่งตำแหน่ง กดซ้ำคือลบแถวนี้

### applications

| คอลัมน์ | ชนิด | หมายเหตุ |
|---|---|---|
| id | uuid | PK |
| student_id | uuid | FK → student_profiles.id |
| job_id | uuid | FK → jobs.id |
| cover_letter | text | บังคับมีตอนสมัคร |
| resume_object_key | varchar | สำเนาคีย์ Resume ตอนสมัคร ไม่ตามไฟล์ที่อัปโหลดใหม่ทีหลัง |
| status | application_status | ค่าเริ่มต้น `submitted` |
| version | int | optimistic lock, เริ่มที่ 1 |
| created_at | timestamptz | |
| updated_at | timestamptz | |

Unique ที่ `(student_id, job_id)` คือตัวกันสมัครซ้ำ แม้ request สองตัวชนกันพร้อมกัน

### application_status_events

Timeline ที่แก้หรือลบไม่ได้ แต่ละแถวคือหนึ่งครั้งที่สถานะเปลี่ยน

| คอลัมน์ | ชนิด | หมายเหตุ |
|---|---|---|
| id | uuid | PK |
| application_id | uuid | FK → applications.id |
| from_status | application_status | null ได้เฉพาะ event แรก |
| to_status | application_status | |
| actor_user_id | uuid | FK → users.id ผู้ที่ทำให้เกิด event |
| created_at | timestamptz | |

ใบสมัครใหม่มี event แรก `from_status = null`, `to_status = submitted`

### notifications

| คอลัมน์ | ชนิด | หมายเหตุ |
|---|---|---|
| id | uuid | PK |
| student_id | uuid | FK → student_profiles.id |
| application_id | uuid | FK → applications.id |
| message | varchar | ข้อความสถานะที่เปลี่ยน |
| read_at | timestamptz | null แปลว่ายังไม่อ่าน |
| created_at | timestamptz | |

เกิดหนึ่งแถวต่อการเปลี่ยนสถานะหนึ่งครั้ง สร้างโดย BullMQ worker ไม่สร้างใน request ที่บริษัทกดเปลี่ยนสถานะ

### outbox_messages

| คอลัมน์ | ชนิด | หมายเหตุ |
|---|---|---|
| id | uuid | PK |
| type | varchar | เช่น `application.status_changed` |
| payload | jsonb | application id, student id, สถานะใหม่ |
| status | outbox_status | เริ่มที่ `pending` |
| attempts | int | จำนวนครั้งที่ worker ลองแล้ว |
| available_at | timestamptz | เวลาที่ลองครั้งถัดไปได้ |
| created_at | timestamptz | |
| processed_at | timestamptz | null จนกว่าจะส่งสำเร็จหรือเข้า dead |

Worker ที่สำเร็จแล้วตั้ง `sent` เกินจำนวน retry แล้วตั้ง `dead` ซึ่งเป็น dead letter ในตารางนี้

## 4. Index

นอกจาก primary key และ unique ที่ระบุข้างต้น

| ตาราง | คอลัมน์ | ใช้เมื่อ |
|---|---|---|
| jobs | company_id | รายการประกาศของบริษัท |
| jobs | status, province, work_mode, category, has_allowance | job feed และการกรอง |
| applications | job_id | รายชื่อผู้สมัครของหนึ่งตำแหน่ง |
| applications | student_id | ใบสมัครของนักศึกษา |
| notifications | student_id, created_at | หน้ารายการแจ้งเตือน |
| outbox_messages | status, available_at | worker ดึงงานที่ถึงเวลา |
| refresh_tokens | user_id | logout ของ user นั้น |

## 5. Transaction และ lock

ใช้คนละแบบตามปัญหา ไม่ใส่ lock ทุก write

### สมัครบัญชี

`DataSource.transaction()` สร้าง `users` พร้อม `student_profiles` หรือ `company_profiles` ที่ว่างตาม role ถ้าสร้างโปรไฟล์ไม่สำเร็จ ทั้งคู่ถูกยกเลิก

### สมัครงาน และเปิดหรือปิดรับสมัคร

ใช้ pessimistic lock ที่แถว `jobs` ด้วย `SELECT ... FOR UPDATE` ใน transaction เดียวกัน

- ตอนสมัคร: ล็อกแถวงาน ตรวจว่ายัง `open` ตรวจว่ามี Resume แล้วแทรก `applications` พร้อม event `submitted`
- ตอนปิดหรือเปิดรับ: ล็อกแถวงานแล้วค่อยเปลี่ยน `status`

กันกรณีนักศึกษาสมัครงานที่กำลังถูกปิด และกันการปิดงานขณะกำลังสร้างใบสมัคร ไม่ใช้ optimistic lock ตรงนี้ เพราะการสมัครไม่ได้แก้แถวใบสมัครเดิม

`SET NX EX` ใน Redis กันการกดซ้ำก่อนถึงฐานข้อมูล ถ้า unique `(student_id, job_id)` ชน ให้ตอบว่าสมัครแล้ว ไม่สร้างใบสมัครที่สอง

### แก้ประกาศ และเปลี่ยนสถานะใบสมัคร

ใช้ optimistic lock ที่คอลัมน์ `version` ของ `jobs` และ `applications` คนที่สองที่ส่ง version เก่าได้ 409 แล้วต้องอ่านค่าใหม่

เปลี่ยนสถานะทำใน transaction เดียว:

1. ตรวจว่าทางเดินจากสถานะปัจจุบันไปสถานะใหม่ถูกต้อง
2. เพิ่ม `version` และเขียน `applications.status`
3. แทรก `application_status_events`
4. แทรก `outbox_messages` สถานะ `pending`

ยังไม่เขียน `notifications` ใน transaction นี้ Worker อ่าน outbox แล้วค่อยสร้างแจ้งเตือน ถ้า Redis ล่มระหว่าง request แถว outbox ยังอยู่

## 6. สิ่งที่ไม่อยู่ในฐานข้อมูลนี้

ไม่เก็บไฟล์ PDF หรือรูป logo ในตาราง เก็บเฉพาะ object key ของ MinIO

ไม่เก็บตัวเลขแดชบอร์ดเป็นตารางสรุป และไม่เก็บ access token
