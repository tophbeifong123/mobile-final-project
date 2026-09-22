# 📱 InternFinder — โปรเจกต์มือถือ

[![Flutter CI](https://github.com/tophbeifong123/mobile-final-project/actions/workflows/client-ci.yml/badge.svg)](https://github.com/tophbeifong123/mobile-final-project/actions/workflows/client-ci.yml)
[![NestJS CI](https://github.com/tophbeifong123/mobile-final-project/actions/workflows/server-ci.yml/badge.svg)](https://github.com/tophbeifong123/mobile-final-project/actions/workflows/server-ci.yml)
[![Kanban Board](https://img.shields.io/badge/Project-Kanban%20Board-blueviolet?logo=github)](https://github.com/users/tophbeifong123/projects/2)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![NestJS](https://img.shields.io/badge/NestJS-12.x-E0234E?logo=nestjs&logoColor=white)](https://nestjs.com)

InternFinder เป็นแอปมือถือให้นักศึกษาค้นหาและสมัครงานฝึกงาน และให้บริษัทประกาศงานแล้วจัดการผู้สมัคร สร้างด้วย **Flutter** และ **NestJS บน Express** พร้อมสัญญา API ที่ **Swagger**

บัญชีหนึ่งบัญชีมีได้หนึ่งบทบาท เลือกตอนสมัครเป็นนักศึกษาหรือบริษัท แล้วเปลี่ยนทีหลังไม่ได้ ขอบเขตฟีเจอร์ 18 หน้าอยู่ใน [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md)

---

## ลิงก์และเอกสาร

| แหล่ง | ลิงก์ | ใช้ทำอะไร |
|---|---|---|
| บอร์ดคัมบัง | [บอร์ด InternFinder](https://github.com/users/tophbeifong123/projects/2) | ดูงานตามสถานะ ค้างไว้, พร้อมทำ, กำลังทำ, เสร็จ |
| แบ็กล็อก | [Issues #1–#48](https://github.com/tophbeifong123/mobile-final-project/issues) | รายการอีปิกและยูสเซอร์สตอรีทั้ง 48 รายการ |
| เอกสาร API | [Swagger](http://localhost:3000/api/docs) | ลองเรียก API ที่ `/api/docs` ตอนรันเซิร์ฟเวอร์พัฒนา |
| วิธีร่วมพัฒนา | [CONTRIBUTING.md](CONTRIBUTING.md) | Git Flow และ Conventional Commits |
| ความต้องการของระบบ | [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) | หน้า, ยูสเคส และกติกาของนักศึกษาและบริษัท |
| สถาปัตยกรรม | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | โมดูล, เส้นทาง API, Swagger, Redis และโครง Flutter |
| ฐานข้อมูล | [docs/DATABASE.md](docs/DATABASE.md) | สคีมา, ER และจุดที่ใช้ธุรกรรมกับล็อก |
| จุดเข้าของ AI | [AGENTS.md](AGENTS.md) | ให้ AI อ่านก่อนลงมือแก้โค้ด |

คนและ AI ใช้ตารางด้านบนเป็นแหล่งเดียวกัน ถ้าเอกสารกับโค้ดยังไม่ตรงกัน ให้ถือว่า [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) เป็นขอบเขตฟีเจอร์ และ [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) เป็นแบบที่โค้ดใหม่ต้องเดินตาม

### สปรินต์และแบ็กล็อก

```
สปรินต์ 1: ฐาน, ดีไซน์ และเข้าสู่ระบบ (#1–#13, #27)
 ├── พร้อมทำ: #1-#6 (รีโป, NestJS, Flutter, ฐานข้อมูล, ERD, ความลับ), #11-#13 (API เข้าสู่ระบบ), #27 (หน้าเข้าสู่ระบบ)
 └── ค้างไว้: #7-#10 (ระบบดีไซน์และโฟลว์ใน Figma)

สปรินต์ 2: โปรไฟล์และงาน (#14–#19, #28–#32)
 └── ค้างไว้: โปรไฟล์นักศึกษา, อัปโหลด Resume, สร้างแก้ประกาศ, รายการสาธารณะและการค้นหา, ฟีดใน Flutter

สปรินต์ 3: ใบสมัครและฝั่งบริษัท (#20–#25, #33–#38)
 └── ค้างไว้: ขั้นตอนใบสมัคร, แจ้งเตือนในแอป, บริษัทจัดการประกาศและผู้สมัคร

สปรินต์ 4: คุณภาพ, ขึ้นระบบ และเอกสาร (#26, #39–#48)
 └── ค้างไว้: เทสครบเส้นทางและวิดเจ็ต, Docker, ขึ้นคลาวด์, APK, เอกสารและสคริปต์เดโม
```

### วิธีเลื่อนงานบนบอร์ด

1. **ค้างไว้**: งานที่วางไว้สำหรับสปรินต์ถัดไป ยังไม่ถูกหยิบ
2. **พร้อมทำ**: งานที่จัดลำดับแล้ว เริ่มได้ทันที
3. **กำลังทำ**: มีคนทำอยู่ ชื่อสาขาเป็น `feat/<ชื่อ>` หรือ `fix/<ชื่อ>`
4. **รอตรวจ**: เปิดพูลรีเควสต์แล้ว และ CI ผ่าน
5. **เสร็จ**: ตรวจโค้ดแล้ว รวมเข้า `develop` หรือ `main` และตรวจซ้ำแล้ว

---

## โครงโปรเจกต์

```
mobile-final-project/
├── .github/                     # เวิร์กโฟลว์ GitHub และเทมเพลต Issue/PR
│   ├── ISSUE_TEMPLATE/          # เทมเพลตบั๊กและฟีเจอร์
│   ├── workflows/               # CI ของ Flutter และ NestJS
│   └── pull_request_template.md # เช็กลิสต์พูลรีเควสต์
├── client/                      # แอป Flutter
│   ├── lib/
│   │   ├── core/                # ธีม, Dio, เราเตอร์, ที่เก็บโทเคน, วิดเจ็ตร่วม
│   │   ├── features/            # auth, jobs, saved_jobs, student_profile, resume,
│   │   │                        # applications, notifications, company_dashboard,
│   │   │                        # company_profile, company_jobs
│   │   └── main.dart            # ProviderScope และ MaterialApp.router
│   ├── test/                    # เทสวิดเจ็ต
│   └── pubspec.yaml
├── server/                      # API NestJS
│   ├── src/
│   │   ├── main.ts              # จุดเริ่มเซิร์ฟเวอร์, Swagger และ CORS
│   │   ├── app.module.ts        # โมดูลรากพร้อม ConfigModule
│   │   ├── app.controller.ts
│   │   └── app.service.ts
│   ├── test/                    # เทสหน่วยและเทสครบเส้นทาง
│   ├── .env.example             # แบบตัวแปรสภาพแวดล้อม
│   ├── Dockerfile               # อิมเมจสำหรับรันจริง
│   └── package.json
├── docs/
│   ├── REQUIREMENTS.md          # หน้า, ยูสเคส และกติกา
│   ├── ARCHITECTURE.md          # แบบระบบ, API และโครงโฟลเดอร์
│   └── DATABASE.md              # สคีมาและ ER
├── .cursor/rules/               # กฎ Cursor แยกตามชั้นของโค้ด
├── AGENTS.md                    # จุดเข้าสำหรับ AI
├── docker-compose.yml           # ฐานข้อมูล PostgreSQL สำหรับพัฒนา
├── CONTRIBUTING.md              # Git Flow และ Conventional Commits
├── LICENSE                      # สัญญาอนุญาต MIT
└── README.md
```

---

## สแต็กและรูปแบบการเขียน

### แอปมือถือ (`client/`)

- **เฟรมเวิร์ก**: Flutter 3.44+ / Dart 3.12+
- **หน้าตา**: Material 3 ใน `client/lib/core/theme/app_theme.dart` ไม่ใช้ `shadcn_ui`
- **สถานะและทางเดินหน้า**: `flutter_riverpod`, `go_router`
- **เครือข่ายและไฟล์**: `dio`, `flutter_secure_storage`, `file_picker`
- **โครงโค้ด**: แบ่งตามฟีเจอร์ (`core/` กับ `features/`) แต่ละฟีเจอร์มี 3 ชั้น
  - `presentation`: หน้า, วิดเจ็ตของฟีเจอร์ และคอนโทรลเลอร์ของ Riverpod
  - `domain`: เอนทิตีและอินเทอร์เฟซของรีพอสิทอรี ไม่มีคลาสยูสเคสแยก
  - `data`: โมเดล, แหล่งข้อมูล Dio และรีพอสิทอรี
- **ตอนเปิดแอป**: Splash อ่านโทเคน แล้วไปหน้าเข้าสู่ระบบ, `/student/home` หรือ `/company/dashboard` ตามบทบาท
- **สถานะตอนนี้**: โครง 18 หน้าและแถบนำทางพร้อมแล้ว หน้าจอยังไม่ยิง API จริง รายละเอียดอยู่ใน [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **ตัวตรวจโค้ด**: กฎของ Flutter ใน `analysis_options.yaml`

### เซิร์ฟเวอร์ (`server/`)

- **เฟรมเวิร์ก**: NestJS 12.x (TypeScript) บน **Express** (`@nestjs/platform-express`) ไม่ใช้ Fastify
- **เอกสาร API**: OpenAPI / Swagger ที่ `/api/docs` DTO และเส้นทางใหม่ต้องมีเดคอเรเตอร์ของ Swagger
- **ค่าตั้ง**: `@nestjs/config` แบบทั้งแอป สำหรับไฟล์ `.env`
- **เทส**: Vitest และ Supertest สำหรับเทสหน่วยและเทสครบเส้นทาง
- **คอนเทนเนอร์**: Dockerfile แบบหลายสเตจ

### การทำงานร่วมกัน

- **CI**: GitHub Actions ตรวจรูปแบบโค้ด รันเทส และตรวจการビルด์
- **ข้อความคอมมิต**: [Conventional Commits](https://www.conventionalcommits.org/)
- **สาขา**: Git Flow (`main`, `develop`, `feat/*`, `fix/*`)

---

## วิธีรัน

### 1. สิ่งที่ต้องมี

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.27.0`)
- [Node.js](https://nodejs.org/) (`>= 20.0.0` หรือ `22.x`) และ npm
- [Docker และ Docker Compose](https://www.docker.com/) ถ้าต้องการฐานข้อมูลในเครื่อง

---

### 2. เซิร์ฟเวอร์ (`server/`)

1. เข้าโฟลเดอร์เซิร์ฟเวอร์:
   ```bash
   cd server
   ```

2. คัดลอกไฟล์สภาพแวดล้อม:
   ```bash
   cp .env.example .env
   ```

3. ติดตั้งแพ็กเกจ:
   ```bash
   npm install --legacy-peer-deps
   ```

4. เปิดเซิร์ฟเวอร์โหมดพัฒนา:
   ```bash
   npm run start:dev
   ```

5. เปิด API และเอกสาร:
   - **API**: [http://localhost:3000/api](http://localhost:3000/api)
   - **Swagger**: [http://localhost:3000/api/docs](http://localhost:3000/api/docs)

ถ้าต้องการ PostgreSQL จาก Docker ให้รันที่รากโปรเจกต์:

```bash
docker compose up -d
```

---

### 3. แอปมือถือ (`client/`)

1. เข้าโฟลเดอร์แอป:
   ```bash
   cd client
   ```

2. ติดตั้งแพ็กเกจ:
   ```bash
   flutter pub get
   ```

3. ดูอุปกรณ์ที่ต่ออยู่:
   ```bash
   flutter devices
   ```

4. เปิดแอป:
   ```bash
   flutter run
   ```

> เว็บ เดสก์ท็อป และตัวจำลอง iOS เรียก `http://localhost:3000/api` ตัวจำลอง Android เรียก `http://10.0.2.2:3000/api` มือถือจริงส่ง `--dart-define=API_BASE_URL=http://<lan-ip>:3000/api` ค่าอยู่ที่ [api_constants.dart](client/lib/core/constants/api_constants.dart)

---

## เทสและการตรวจคุณภาพ

| ส่วน | งาน | คำสั่ง |
|---|---|---|
| แอป | ตรวจการจัดรูปแบบ | `cd client && dart format --output=none --set-exit-if-changed .` |
| แอป | วิเคราะห์โค้ด | `cd client && flutter analyze` |
| แอป | รันเทส | `cd client && flutter test` |
| เซิร์ฟเวอร์ | ตรวจลินต์ | `cd server && npm run lint` |
| เซิร์ฟเวอร์ | เทสหน่วย | `cd server && npm test` |
| เซิร์ฟเวอร์ | บิลด์สำหรับรันจริง | `cd server && npm run build` |

---

## การร่วมพัฒนา

อ่าน [CONTRIBUTING.md](CONTRIBUTING.md) สำหรับกติกาการทำงานร่วมกัน วิธีแตกสาขา และรูปแบบข้อความคอมมิต

---

## สัญญาอนุญาต

โปรเจกต์นี้อยู่ภายใต้สัญญาอนุญาต MIT ดูรายละเอียดใน [LICENSE](LICENSE)
