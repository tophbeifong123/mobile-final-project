# กู้คืนรหัสผ่านด้วยอีเมลที่ใช้สมัคร

จากหน้า Login กด **ลืมรหัสผ่าน?**, กรอกอีเมลบัญชี, เปิดลิงก์ในอีเมล แล้วกรอกและยืนยันรหัสผ่านใหม่ จากนั้นเข้าสู่ระบบตามปกติ ใช้ได้ทั้ง Student และ Company

ส่งลิงก์ไปยังอีเมลที่บันทึกไว้ตอนสมัคร ไม่จำกัดโดเมน เช่น Gmail, Outlook, PSU หรืออีเมลองค์กรอื่น ตรวจรูปแบบอีเมล ตัดช่องว่างหัวท้าย และปรับเป็นตัวพิมพ์เล็กก่อนค้นหาบัญชี ทั้งนักศึกษาและบริษัทใช้ได้เหมือนกัน อีเมลรูปแบบถูกต้องได้รับคำตอบเดียวกันไม่ว่ามีบัญชีหรือไม่ โดยส่งอีเมลเฉพาะบัญชีที่มีอยู่

รีเซ็ตเฉพาะรหัสผ่านของบัญชี InternFinder ที่สมัครด้วยอีเมล/รหัสผ่าน ไม่เปลี่ยนรหัสผ่านของผู้ให้บริการอีเมล และไม่ต้องใช้ Google Login ผู้ใช้ต้องเปิดลิงก์ที่ส่งไปยังกล่องจดหมายของตนเอง

บัญชีผู้ส่งของแอปแยกจากอีเมลผู้รับ ต้องตั้ง SMTP สำหรับผู้ส่งจึงจะส่งลิงก์จริงได้ ตัวอย่างด้านล่างใช้ Gmail เป็นผู้ส่ง และส่งไปยังอีเมลที่ใช้สมัครของทุกโดเมนได้ การตั้ง Gmail SMTP ไม่เกี่ยวกับการเปิดใช้งาน Google Login ในแอป

## ตัวอย่างตั้งค่า Gmail ของผู้ส่ง

1. เปิดการยืนยันแบบ 2 ขั้นตอนของบัญชี Gmail ผู้ส่ง
2. สร้าง App Password สำหรับ InternFinder ที่ https://myaccount.google.com/apppasswords (https://support.google.com/mail/answer/185833)
3. ใส่ค่าต่อไปนี้ใน `server/.env` ซึ่งถูก gitignore ไว้แล้ว:

```dotenv
APP_WEB_URL=http://localhost:8080
SMTP_HOST=smtp.gmail.com
SMTP_PORT=465
SMTP_SECURE=true
SMTP_REQUIRE_TLS=true
SMTP_USER=your-address@gmail.com
SMTP_PASSWORD=your-16-character-app-password
SMTP_FROM=InternFinder <your-address@gmail.com>
```

ใช้ App Password ไม่ใช่รหัสผ่านเข้าสู่ระบบ Google ปกติ ใส่รหัสโดยไม่มีช่องว่าง อย่าใส่ SMTP credentials ใน Flutter, dart-define, source code หรือ git

`APP_WEB_URL` ต้องเป็นที่อยู่เว็บ Flutter ที่ผู้รับเปิดได้ หากใช้งานนอกเครื่องพัฒนาให้ใช้โดเมน HTTPS ที่ deploy แล้ว ระบบสร้างเส้นทาง `/#/reset-password?token=...` อัตโนมัติ ไม่อิง Host header ของคำขอ

ในเครื่องพัฒนาให้ใช้ `http://localhost:8080` ตรงกับคำสั่ง Flutter ด้านล่าง หากเปลี่ยน hostname หรือ port ต้องเปลี่ยน `APP_WEB_URL` ตามและ restart API จากนั้นขอลิงก์ใหม่ ลิงก์ในอีเมลเดิมจะไม่เปลี่ยนตามการตั้งค่า และ `localhost` ใช้ได้เฉพาะเมื่อเปิดอีเมลบนเครื่องที่รัน Flutter อยู่

บัญชี Google Workspace หรือบัญชีที่เปิด Advanced Protection อาจไม่อนุญาต App Password ให้ใช้ SMTP ที่ผู้ดูแลอนุญาตแทน ตัวส่งรองรับ SMTP มาตรฐาน

## เริ่มระบบ

เปิด PostgreSQL ตามค่าที่ตั้งใน `.env` แล้วรัน:

```powershell
cd server
npm install --legacy-peer-deps
npm run migration:run
npm run start:dev
```

จากอีกเทอร์มินัล:

```powershell
cd client
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 8080
```

หลังเปลี่ยนค่า SMTP ให้ restart backend ผู้รับต้องใช้อีเมลบัญชีที่สมัครใน InternFinder อยู่แล้ว หากยังไม่มี SMTP credentials ฟังก์ชันจะตอบ 503 แทนการแสดงว่าระบบพร้อมส่ง

## สัญญา API และการป้องกัน

- `POST /api/auth/forgot-password` รับ `{email}` ทุกโดเมน รูปแบบไม่ถูกต้องคืน 400 รูปแบบถูกต้องคืน 200 `{message}` แบบเดียวกันเมื่อมี/ไม่มีบัญชี ไม่คืน token หรือ reset URL ทาง API
- `POST /api/auth/reset-password` รับ `{token,password}` คืน 200 `{message}` หรือ 400 เมื่อลิงก์หมดอายุ/ถูกใช้แล้ว หากรหัสใหม่ซ้ำกับรหัสเดิมคืน 409 พร้อม `code: PASSWORD_REUSE` ลิงก์ยังใช้ได้จนหมดอายุสำหรับกรอกรหัสใหม่อีกครั้ง
- ไม่ตรวจโดเมนตอนใช้ลิงก์หรือใน transaction ลิงก์ที่ยังไม่หมดอายุและยังไม่ถูกใช้ของบัญชีทุกโดเมนใช้ได้ ตรวจว่าบัญชียังมีอยู่และล็อก user ก่อน token เช่นเดิม
- ลิงก์สุ่ม 32 bytes, เก็บเฉพาะ SHA-256, อายุ 15 นาที และใช้ได้ครั้งเดียว ขอลิงก์ใหม่หลัง cooldown จะยกเลิกลิงก์เดิม
- รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสเดิม อย่างน้อย 8 Unicode code points มี A–Z, a–z, ตัวเลข 0–9 และอักขระพิเศษ ASCII อย่างน้อยประเภทละ 1 ตัว และไม่เกิน 72 UTF-8 bytes ตามขีดจำกัด bcrypt เปรียบเทียบกับ hash ของรหัสปัจจุบันขณะล็อกแถวบัญชี เพื่อกันการเปลี่ยนพร้อมกัน
- จำกัดคำขอ 10 ครั้งต่อ IP/endpoint ใน 5 นาที และส่งลิงก์ใหม่ให้บัญชีหนึ่งไม่เกินครั้งละ 60 วินาที
- รีเซ็ตสำเร็จยกเลิก access/refresh sessions เดิมทั้งหมด และส่งอีเมลแจ้งว่ารหัสผ่านถูกเปลี่ยน โดยไม่ส่งรหัสผ่าน
- การส่งอีเมลทำแยกจากเวลาตอบ API เพื่อไม่เผยว่าบัญชีมีอยู่หรือไม่ หาก SMTP ส่งไม่สำเร็จจะบันทึก error โดยไม่เปิดเผยอีเมล/token และลบลิงก์ที่ส่งไม่สำเร็จ
- ตัวจำกัด IP ใช้หน่วยความจำของ API หนึ่ง process; หาก deploy หลาย instance ให้เพิ่ม shared rate limit ที่ proxy/Redis

Swagger ของทั้งสองเส้นทางอยู่ที่ `/api/docs` Migration `1791072000000` มีทั้ง `up` และ `down`

## ทดสอบแบบ end-to-end ในเครื่อง

กำหนด `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_NAME` และ `JWT_SECRET` ให้ชี้ฐานข้อมูลทดสอบแบบแยกเฉพาะ ห้ามใช้ฐานข้อมูลจริง หลัง build และ migrate ฐานข้อมูลทดสอบแล้ว รัน `node --test test/password-recovery.integration.mjs` จาก `server` การทดสอบจับ SMTP บน loopback เท่านั้น ไม่ส่งอีเมลจริง และลบเฉพาะบัญชีทดสอบ UUID ที่ตัวเองสร้าง ครอบคลุมนักศึกษา Gmail, บริษัท Outlook, ลิงก์ของโดเมนอื่น, คำตอบที่ไม่เผยว่ามีบัญชี, อีเมลผิดรูปแบบ, รีเซ็ตพร้อมกัน, token หมดอายุ/ใช้ซ้ำ, session เดิม, rate limit และ migration rollback เทสหน่วยยังตรวจว่าอีเมล PSU ทั้งสองโดเมนใช้ได้ตามเดิม
