# CI/CD & DevSecOps Presentation: InternFinder
**ระยะเวลานำเสนอ:** 10 นาที (8-9 สไลด์)

---

## Slide 1: หน้าปก (Title Slide)
* **หัวข้อ:** End-to-End CI/CD & DevSecOps Pipeline: InternFinder Mobile Application
* **สมาชิก:** ทีมพัฒนา InternFinder
* **เทคโนโลยี:** Flutter • NestJS • GitHub Actions • Gitleaks • Docker
* **Key Point:** นำเสนอระบบทดสอบ ตรวจสอบความปลอดภัย และส่งมอบซอฟต์แวร์อัตโนมัติ

---

## Slide 2: ปัญหาเดิม & ทำไมต้องมี CI/CD? (Pain Points)
* **ปัญหาเดิม (Manual Process):**
  * ลืมรัน Test หรือ Linter ก่อนส่งโค้ด
  * ความเสี่ยงที่ Sensitive Keys / Passwords จะหลุดขึ้น Git
  * มี Dependency ช่องโหว่ความปลอดภัยโดยไม่รู้ตัว
  * ใช้เวลา Build และ Release แบบ Manual เสี่ยงต่อ Human Error
* **เป้าหมายของ CI/CD:**
  * Fast Feedback ตรวจจับข้อผิดพลาดทันทีตั้งแต่ Pull Request
  * Shift-Left Security ย้ายความปลอดภัยมาอยู่ในทุก Commit
  * มั่นใจก่อนส่งมอบผ่าน Automated Testing & UAT

---

## Slide 3: ภาพรวมสถาปัตยกรรม Pipeline (6 Stages Overview)
```
[1. BUILD] ➔ [2. TEST] ➔ [3. SECURITY] ➔ [4. UAT] ➔ [5. RELEASE] ➔ [6. DEPLOY]
```
* **Client Track (Flutter):** Format ➔ Analyze ➔ Unit/Widget Test ➔ Internal APK Distribution (UAT)
* **Server Track (NestJS):** Clean Install (`npm ci`) ➔ Lint ➔ Jest Test ➔ Security Audit ➔ Docker Staging

---

## Slide 4: Stage 1 & 2 — Build & Test (ควบคุมคุณภาพโค้ด)
* **Flutter Client:**
  * `dart format --set-exit-if-changed .` : คุม Code Style สม่ำเสมอทั้งทีม
  * `flutter analyze` : ดักจับ Static Warnings & Type Errors
  * `flutter test --coverage` : รัน Unit & Widget Tests อัตโนมัติ
* **NestJS Server:**
  * `npm ci --legacy-peer-deps` : ติดตั้ง Dependencies ตรงตาม `package-lock.json`
  * `npm run lint` (ESLint) : ตรวจจับ Code Quality
  * `npm run test` (Jest) : รัน Unit Tests ก่อน Compile
* **Safety Rule:** ถ้าด่านนี้ไม่ผ่าน ระบบจะ **Fail Fast** ไม่อนุญาตให้ไป Stage ถัดไป

---

## Slide 5: Stage 3 — Security Stage (DevSecOps)
* **เครื่องมือหลัก:** **Gitleaks** + **npm audit**
* **Gate 1: Gitleaks (Secret Detection):**
  * สแกนหา Hardcoded API Keys, Passwords, Tokens ทั่วทั้ง Commit History
  * ทำงานรวดเร็วใน GitHub Actions (`gitleaks-action@v2`)
* **Gate 2: Software Composition Analysis (SCA):**
  * รัน `npm audit --audit-level=high` คัดกรอง Library ที่มีช่องโหว่ CVEs ร้ายแรง

---

## Slide 6: [Highlight] ผลลัพธ์การรันจริง: Gitleaks (Security Scan)
### กรณีที่ 1: ตรวจพบ Secret หลุด (FAIL ❌)
```text
    ○
    │╲
    │ ○
    ○ ░
    ░    gitleaks

Finding:     .../nestjs/nest/master?token=abc123def456
Secret:      abc123def456
RuleID:      generic-api-key
File:        server/README.md
Line:        5
Commit:      c694d04652d1d6c5c6fa92fb6f6b226776a35ef3

9:22AM INF 58 commits scanned.
9:22AM INF scanned ~2.37 MB in 1.01s
9:22AM WRN leaks found: 1
[RESULT: FAILED ❌ -> Blocked Pull Request]
```

### กรณีที่ 2: ปลอดภัย / แก้ไขแล้ว (PASS ✅)
```text
    ○
    │╲
    │ ○
    ○ ░
    ░    gitleaks

9:22AM INF 58 commits scanned.
9:22AM INF scanned ~2.37 MB in 630ms
9:22AM INF no leaks found
[RESULT: SUCCESS ✅ -> Safe to Merge]
```

---

## Slide 7: Stage 4 & 5 — UAT & Release Flow
* **Stage 4: UAT (User Acceptance Testing):**
  * **Client:** ส่งต่อ Internal Build (APK) ผ่าน Firebase App Distribution ให้ทีม QA / Product Owner ทดสอบ
  * **Server:** Deploy ขึ้น Staging Environment พร้อม Swagger API Docs (`/api/docs`) สำหรับทดสอบ Integration
* **Stage 5: Release Automation:**
  * Auto Tagging ด้วย Semantic Versioning (`v1.0.0`)
  * สร้าง GitHub Release พร้อมแนบ Artifacts (.apk) อัตโนมัติ

---

## Slide 8: Stage 6 — Continuous Deployment (Production) & Summary
* **Production Deployment:**
  * รัน Database Migration อย่างปลอดภัย (`npm run migration:run`)
  * รัน Docker Container Service (Zero-Downtime Rollout)
* **สรุปประโยชน์ที่ทีมได้รับ:**
  1. **Speed:** ลดระยะเวลา Manual Testing & Review
  2. **Security:** ป้องกันข้อมูลรั่วไหลตั้งแต่ต้นทาง (Shift-Left)
  3. **Reliability:** ทุก Build ผ่านการทดสอบจริงทั้งระดับ Code และ UAT
