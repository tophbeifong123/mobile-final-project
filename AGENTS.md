# InternFinder — คำสั่งสำหรับ AI

อ่านเอกสารเหล่านี้ก่อนแก้พฤติกรรมของแอป

1. [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) คือขอบเขตหน้า, use case และกติกา
2. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) คือโมดูล, เส้นทาง API, Swagger และโครง Flutter
3. [docs/DATABASE.md](docs/DATABASE.md) คือ schema, unique, transaction และ lock

กฎที่ใช้ตอนแก้ไฟล์อยู่ใน `.cursor/rules/` สรุปสั้นอยู่ใน `.cursorrules`

## ขอบเขตที่ห้ามขยายเอง

- Role มี `student` กับ `company` เลือกตอนสมัครแล้วเปลี่ยนไม่ได้
- HTTP adapter คือ Express ไม่ย้ายไป Fastify
- สัญญา API คือ Swagger ที่ `/api/docs` ห้ามให้แอปเรียกเส้นทางที่ไม่มีในเอกสาร
- ไม่เพิ่มแชท, นัดสัมภาษณ์, login โซเชียล, ลืมรหัสผ่าน, ยืนยัน email, ถอนใบสมัคร, หน้าโปรไฟล์บริษัทแยก, Admin หรือ push นอกแอป

## ตอนลงมือ

- ฝั่ง `server/` ให้ controller บาง กติกาอยู่ใน service และ repository เป็น Data Mapper
- ฝั่ง `client/` ให้แยก `presentation`, `domain`, `data` และใช้ Riverpod กับ `go_router`
- เปลี่ยนตารางด้วย migration ที่มีทั้ง `up` และ `down`
