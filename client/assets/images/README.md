# UI Assets / Images

โฟลเดอร์สำหรับเก็บไฟล์รูปภาพต่างๆ ที่ใช้ในส่วนของ User Interface (UI) เช่น:
- ภาพประกอบ (Illustrations)
- ภาพ Banner / Background
- ไอคอนพิเศษหรือโลโก้แอป (App Logo / Branding)
- ภาพตัวอย่างหรือภาพจำลอง (Placeholders / Mockups)

---

### โครงสร้างที่แนะนำ (Recommended Structure)

```text
client/assets/images/
├── icons/          # ไอคอนพิเศษ หรือกราฟิกขนาดเล็ก
├── illustrations/  # ภาพเวกเตอร์หรือภาพประกอบหน้าจอ (Empty state, onboarding, etc.)
└── placeholders/   # รูป mock สำหรับแสดงผลตอนยังไม่มีข้อมูลจริง (Company logo placeholder, avatar)
```

---

### วิธีเรียกใช้งานใน Flutter (Usage in Code)

กำหนด path ในโค้ดหรือเรียกผ่าน `client/lib/core/constants/app_assets.dart`:

```dart
Image.asset('assets/images/your_image.png')
```
