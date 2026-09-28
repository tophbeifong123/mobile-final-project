# CI/CD Pipeline & DevOps Lifecycle: InternFinder
**ระยะเวลานำเสนอ:** 10 นาที (โครงสร้าง 9 สไลด์อย่างเป็นทางการ)

---

## 📋 ภาพรวมลำดับสไลด์ (10 นาที)

| สไลด์ | หัวข้อ | เวลาโดยประมาณ |
| :--- | :--- | :--- |
| **Slide 1** | หน้าปก: End-to-End DevOps & CI/CD Pipeline | 1.0 นาที |
| **Slide 2** | ภาพรวม DevOps Lifecycle (Plan ➔ Code ➔ Build ➔ Test ➔ Release ➔ Deploy ➔ Operate) | 1.5 นาที |
| **Slide 3** | Stage 1 & 2: Plan & Code (เครื่องมือ & Branching Strategy) | 1.0 นาที |
| **Slide 4** | Stage 3 & 4: Build & Test + DevSecOps (Gitleaks) | 1.5 นาที |
| **Slide 5** | Stage 5 & 6: Release & Deploy (Staging, UAT & Production) | 1.5 นาที |
| **Slide 6** | Stage 7: Operate & Monitor (การดูแลระบบหลังขึ้น Production) | 1.0 นาที |
| **Slide 7** | Pull Request Flow & Quality Gate (ระบบบล็อก PR ป้องกันโค้ดพัง) | 1.0 นาที |
| **Slide 8** | ผลลัพธ์การรันจริง (Fail-Fast: พังแล้วหยุดเลย vs ผ่านฉลุย) | 1.0 นาที |
| **Slide 9** | สรุปคุณค่าที่ทีมได้รับ & Q&A | 0.5 นาที |

---

## 🛠️ ตารางสรุป 7 Stages & เครื่องมือที่ใช้ (Tooling Matrix)

| Stage | เป้าหมาย | เครื่องมือที่ใช้ (Tools) | กิจกรรมหลัก |
| :--- | :--- | :--- | :--- |
| **1. PLAN** | วางแผนฟีเจอร์ & กติการะบบ | • GitHub Projects / Issues<br>• Figma (UI/UX)<br>• Swagger (`/api/docs`) | ออกแบบ User Story, Mockup หน้าจอ, วาง API Contract |
| **2. CODE** | พัฒนาโปรแกรม & คุมเวอร์ชัน | • Flutter (Dart) - Client<br>• NestJS (TypeScript) - Server<br>• Git & GitHub | เขียนโค้ดตาม Clean Architecture, แยก Feature Branch |
| **3. BUILD** | คอมไพล์ & ตรวจสอบรูปแบบ | • GitHub Actions<br>• `dart format` / `flutter pub get`<br>• `npm ci` / `npm run build` | ตรวจ Syntax, Clean Install Dependencies, เช็ค Formatting |
| **4. TEST** | ทดสอบความถูกต้อง & ความปลอดภัย | • `flutter test --coverage`<br>• Jest (`npm run test`)<br>• **Gitleaks** (Secret Scan)<br>• `npm audit` (SCA) | รัน Unit/Widget Test, สแกนรหัสผ่าน/Token รั่วไหล, ตรวจ CVEs |
| **5. RELEASE** | สร้างและแพ็ก Artifacts | • Git Tag (Semantic Versioning)<br>• GitHub Releases<br>• Docker Hub / GHCR | Build ไฟล์ `.apk` สำหรับแอป, Tagging Docker Image |
| **6. DEPLOY** | นำระบบขึ้นสภาพแวดล้อมจริง | • Docker Compose<br>• Firebase App Distribution (UAT)<br>• TypeORM Migration | แจก APK ให้ Tester ทดสอบ (UAT), รัน DB Migration, Deploy Cloud |
| **7. OPERATE** | ดูแลความเสถียร & เฝ้าระวัง | • Docker Restart Policies / Healthcheck<br>• NestJS Logging System<br>• Swagger UI | ตรวจสอบ Uptime ของ Container, ดู Exception Logs, เช็ค API Health |

---

## 📑 เนื้อหาและบทพูดแบบสไลด์ต่อสไลด์ (Slide-by-Slide Details)

### Slide 1: หน้าปก (Title Slide)
* **หัวข้อ:** DevOps Lifecycle & CI/CD Pipeline for InternFinder Mobile Platform
* **ผู้จัดทำ:** ทีมพัฒนา InternFinder
* **เทคโนโลยี:** Flutter, NestJS, GitHub Actions, Gitleaks, Docker
* **บทพูดแนะนำ:**
  > "สวัสดีครับ วันนี้พวกเราจะมานำเสนอ CI/CD Pipeline และ DevOps Lifecycle ของโปรเจกต์ InternFinder ตั้งแต่ขั้นตอนการวางแผนโค้ด การทดสอบความปลอดภัยอัตโนมัติ ไปจนถึงการส่งมอบขึ้น Production ภายในเวลา 10 นาทีครับ"

---

### Slide 2: วงจร DevOps Lifecycle (Overview Flow)
* **ไดอะแกรม Flow:**
  ```
  PLAN ➔ CODE ➔ BUILD ➔ TEST ➔ RELEASE ➔ DEPLOY ➔ OPERATE
  ```
* **ประเด็นสำคัญ:**
  * CI (Continuous Integration): ครอบคลุม Plan, Code, Build, Test (และ Security)
  * CD (Continuous Delivery/Deployment): ครอบคลุม Release, Deploy และขยายผลสู่ Operate
* **บทพูดแนะนำ:**
  > "โปรเจกต์ของเรานำวงจร DevOps มาจับครบทั้ง 7 ขั้นตอน โดยแบ่งเป็น 2 เส้นทางคู่ขนานคือ Mobile Client (Flutter) และ Backend API (NestJS) เพื่อให้การพัฒนาเป็นระบบอัตโนมัติตั้งแต่เริ่มเขียนโค้ดจนถึงมือผู้ใช้งานจริง"

---

### Slide 3: Stage 1 & 2 — PLAN & CODE
* **1. PLAN (การวางแผน):**
  * ใช้ **GitHub Projects & Issues** จัดการ Kanban Board แบ่ง Task ให้สมาชิกในทีม
  * ออกแบบ UI ด้วย **Figma** และทำ API Contract ล่วงหน้าด้วย **Swagger (`/api/docs`)**
* **2. CODE (การพัฒนา):**
  * สถาปัตยกรรม: Flutter แยก Presentation/Domain/Data และ NestJS แยก Controller/Service/Repository
  * **Git Branching Strategy:** ใช้ Feature-Branch Workflow (`feat/...` ➔ `develop` ➔ `main`) เพื่อไม่ให้กระทบโค้ดหลัก
* **บทพูดแนะนำ:**
  > "เราเริ่มจาก Plan ด้วยการระบุ API Contract บน Swagger และ Task บน GitHub Projects จากนั้นฝั่ง Code เราบังคับใช้ Feature Branch เพื่อแยกงานกันทำอย่างอิสระ ก่อนจะส่งโค้ดเข้าสู่ระบบอัตโนมัติผ่าน Pull Request"

---

### Slide 4: Stage 3 & 4 — BUILD, TEST & SECURITY (CI Gate)
* **3. BUILD (คอมไพล์ & ความเรียบร้อย):**
  * Client: `dart format --set-exit-if-changed .` บังคับ Code Format ตรงกันทั้งทีม + `flutter pub get`
  * Server: `npm ci` (ติดตั้งแบบล็อกเวอร์ชันแม่นยำ) + `npm run lint` + `npm run build`
* **4. TEST & DEVSECOPS (ทดสอบและตรวจความปลอดภัย):**
  * **Automated Testing:** `flutter test --coverage` และ Jest `npm run test`
  * **Secret Scanning (Gitleaks):** ตรวจจับรหัสผ่าน, API Token ที่อาจเผลอ Commit
  * **Dependency Audit (`npm audit`):** คัดกรอง Library ภายนอกที่มีช่องโหว่ CVEs
* **บทพูดแนะนำ:**
  > "ในด่าน Build และ Test เรายึดหลัก DevSecOps โดยนอกจากจะรัน Unit Test และ Lint แล้ว เรายังฝัง Gitleaks เพื่อสแกนหา Secret หลุด และใช้ npm audit ตรวจสอบช่องโหว่ของ Third-party Packages ทันที"

---

### Slide 5: Stage 5 & 6 — RELEASE, UAT & DEPLOY (CD Gate)
* **5. RELEASE (การแพ็กเกจ):**
  * ตัดเวอร์ชันอัตโนมัติด้วย **Semantic Versioning** (`v1.0.0`)
  * สร้าง GitHub Release พร้อมแนบไฟล์ติดตั้ง
  * Build และ Push Docker Image ไปยัง Container Registry
* **6. DEPLOY & UAT (การนำขึ้นระบบ):**
  * **UAT Track (ทดสอบโดยผู้ใช้):** ส่งไฟล์ APK ผ่าน **Firebase App Distribution** ให้ Product Owner / Tester ทดลองเล่นบนเครื่องจริง พร้อม Staging Backend
  * **Production Deploy:** ใช้ **Docker Compose** รัน Container บน Server
  * **Database Safety:** รัน Migration อัตโนมัติ (`npm run migration:run`) ที่มีทั้ง Up และ Down script ป้องกันข้อมูลพัง
* **บทพูดแนะนำ:**
  > "เมื่อผ่าน CI แล้ว ระบบจะเข้าสู่ Release โดยสร้าง Docker Image และไฟล์ APK จากนั้นเข้าสู่ UAT ส่งให้ Tester ทดลองเล่นผ่าน Firebase App Distribution และเมื่อทุกฝ่าย Approve จึง Deploy ขึ้น Production Server พร้อมรัน Database Migration อัตโนมัติ"

---

### Slide 6: Stage 7 — OPERATE & MONITOR
* **การดูแลระบบเมื่อเปิดใช้งานจริง:**
  * **Container Healthcheck:** ตั้ง Docker restart policies (`restart: unless-stopped`) เมื่อเกิด Crash
  * **Centralized Logging:** เก็บ Log ข้อผิดพลาดของ NestJS Server เพื่อวิเคราะห์ย้อนหลัง
  * **API Monitoring:** ใช้ Swagger UI (`/api/docs`) ตรวจสอบสถานะการเชื่อมต่อ Endpoint
* **บทพูดแนะนำ:**
  > "หลัง Deploy เรามีด่าน Operate คอย Monitor เซิร์ฟเวอร์ผ่าน Docker Healthcheck และ NestJS Logger เพื่อตรวจจับความผิดปกติแบบ Real-time และแก้ไขปัญหาได้ทันที"

---

### Slide 7: Pull Request Flow & Quality Gate (จุดเน้นสำคัญ)
* **กลไกการเปิด Pull Request (PR):**
  1. นักพัฒนาเปิด PR จาก Feature Branch ไปยัง `develop`
  2. GitHub Actions ถูกกระตุ้นให้รัน Workflow อัตโนมัติ 4 Jobs
  3. **Quality Gate Rule:** ต้องผ่านการตรวจสอบครบทุกข้อ:
     * 🟢 Gitleaks Secret Scan ผ่าน
     * 🟢 Server Lint, Test & Build ผ่าน
     * 🟢 Client Format, Analyze & Test ผ่าน
     * 🟢 Code Review ผ่านการอนุมัติจากเพื่อนร่วมทีม
  4. **ถ้ามีข้อใดข้อหนึ่งไม่ผ่าน ➔ ปุ่ม 'Merge' จะถูกล็อกปิด (Disabled) ทันที!**
* **บทพูดแนะนำ:**
  > "เราผูก CI เข้ากับ Branch Protection บน GitHub นักพัฒนาไม่สามารถกด Merge โค้ดเองได้จนกว่าไฟตรวจทุกดวงจะเป็นสีเขียว นี่คือ Quality Gate ที่รับประกันว่าโค้ดที่เข้า Branch หลักจะไม่พังแน่นอน"

---

### Slide 8: ผลลัพธ์การรันจริง: Fail-Fast Mechanism (พังแล้วหยุดเลยไหม?)
* **ตอบคำถามเชิงลึก: "ถ้าพังแล้วต่อไปไหม หรือว่าหยุดเลย?"**
  * **คำตอบ: "หยุดทำงานทันที (Fail-Fast & Stop Immediately)"**
  * ถ้า Build พัง, Test ตก หรือ Gitleaks เจอคีย์รั่ว ➔ **Pipeline จะตัดจบและแจ้งเตือนทันที**
  * **เหตุผล:**
    1. ป้องกันไม่ให้โค้ดที่มีช่องโหว่หลุดไปขั้นตอน Release/Deploy
    2. ไม่สิ้นเปลืองเวลาและทรัพยากรเครื่อง Cloud Runner
* **หลักฐานการรันจริง (จาก Pull Request #65 ของโปรเจกต์):**
  * **กรณี FAIL ❌ (ดักจับได้):** `flutter analyze` จับได้ว่าโค้ดผิด Formatting Rules ➔ Pipeline สั่งตัดจบ ล็อกปุ่ม Merge ทันที
  * **กรณี PASS ✅ (แก้ไขแล้ว):** `Gitleaks` (5s), `npm audit` (6s), `Server CI` (22s) ➔ ผ่านฉลุย ขึ้นไฟเขียวครบทุกจุด
* **บทพูดแนะนำ:**
  > "ระบบของเราใช้กลไก Fail-Fast คือถ้าพังที่จุดไหน จะ 'หยุดทันที' ไม่ให้ไปต่อ เช่น ถ้า Gitleaks เจอ Secret รั่ว ระบบจะบล็อกทันที ไม่เสียเวลารันไปจนถึง Deploy ซึ่งเราได้ทดสอบจริงใน PR #65 ของโปรเจกต์แล้ว พบว่าระบบสามารถดักจับและขึ้นไฟเขียวได้อย่างถูกต้องครบถ้วน"

---

### Slide 9: สรุปคุณค่าที่ทีมได้รับ (Key Takeaways) & Q&A
* **สิ่งที่ทีมได้รับ (Impact & Value):**
  * **Zero Leaks:** ไร้ปัญหากุญแจความลับหลุดสู่สาธารณะด้วย Gitleaks
  * **High Reliability:** โค้ดทุกบรรทัดผ่าน Unit Test & UAT ก่อนถึงมือผู้ใช้
  * **Fast Delivery:** ประหยัดเวลา Manual Build/Deploy ส่งมอบงานได้ถี่และมั่นใจขึ้น
* **ช่องทางตรวจเช็ค:** GitHub Repository Pull Request & Actions
* **เปิดรับคำถาม (Q&A)**
