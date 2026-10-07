# Deploy เซิร์ฟเวอร์บน Azure for Students

สภาพผลิตมีชุดเดียวใน resource group `internfinder-prod` GitHub Actions ปล่อยอิมเมจเมื่อโค้ดเข้า `main` เท่านั้น `develop` รัน lint, test และสแกนอิมเมจ แต่ไม่ถูก deploy

PostgreSQL Flexible Server รุ่น Burstable `B1ms` เป็นค่าใช้จ่ายหลัก ประมาณ 12 ถึง 15 ดอลลาร์สหรัฐต่อเดือนจากเครดิตนักเรียน Container Apps แบบ consumption, Container Registry รุ่น Basic และ Storage แบบ LRS อยู่ในชั้นที่ถูกกว่า Redis ไม่ถูกสร้างเพราะโปรเซสที่รันจริงไม่ได้ใช้ อย่าเพิ่มสภาพทดสอบอีกชุดบน Azure

## วงจร

1. Pull request และ `develop` ผ่าน `.github/workflows/server-ci.yml` คือ lint, test, build อิมเมจ แล้ว Trivy สแกนอิมเมจโดยไม่ push
2. พุชเข้า `main` ที่แตะ `server/`, `infra/` หรือ workflow ของ CD จะเรียง Lint, Test, สแกน dependency, build อิมเมจ, สแกนอิมเมจ, push เข้า registry แล้วอัปเดต Container App
3. Container App ใช้ revision แบบ Single และ replica เดียว migration ใน entrypoint จึงไม่ชนกับ revision เก่า
4. กดรัน workflow `Deploy API` เองได้ ใส่ `image_tag` หรือ `revision_name` เพื่อย้อนกลับโดยไม่ build ใหม่

## สิ่งที่ถูกสร้าง

`infra/main.bicep` สร้าง Log Analytics, Container Apps Environment, registry รุ่น Basic, Storage พร้อม container `internfinder`, PostgreSQL 16, Key Vault, user-assigned managed identity และ Container App

Log Analytics เก็บ 30 วันและหยุดรับ log เมื่อถึง 0.5 GB ในวันนั้น

```bicep
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
    workspaceCapping: { dailyQuotaGb: json('0.5') }
  }
}
```

`json('0.5')` คือค่า 0.5 GB ตัวคอมไพเลอร์ของ Bicep อ่านเลข `0.5` ที่ขึ้นต้นด้วยศูนย์เป็นตัวเลขศูนย์ตามด้วยชื่อพร็อพเพอร์ตี้ จึงต้องส่งเศษผ่าน `json`

รหัสฐานข้อมูล, `JWT_SECRET`, `SENTRY_DSN` และ `SMTP_PASSWORD` ถูกเก็บใน Key Vault สภาพแวดล้อมของ Container Apps บน subscription นี้อยู่ในโหมด Express ซึ่งอ้างอิง Key Vault จากแอปโดยตรงไม่ได้ ดังนั้นตอนปล่อยแอป สคริปต์คัดลอกค่าเหล่านั้นเข้า secret ของ Container App ไม่มี storage key ในตัวแปรสภาพแวดล้อม ไฟล์ใช้ `DefaultAzureCredential` กับ Blob

`DATABASE_SSL=true` ทำให้ TypeORM เชื่อใบรับรอง DigiCert Global Root CA และ DigiCert Global Root G2 พร้อมกัน เพราะ Flexible Server ใช้สาย G2 เครื่องพัฒนาไม่ตั้งค่านี้

## ครั้งแรก

ติดตั้ง Azure CLI แล้วเลือก subscription ของ Azure for Students

```powershell
az login
az account set --subscription "<subscription-id>"
.\infra\bootstrap.ps1
```

สคริปต์ลองภูมิภาคที่นโยบายของ Azure for Students เปิดให้ คือ `eastasia`, `koreacentral`, `japanwest`, `malaysiawest` แล้วจึง `indonesiacentral` ถ้ารายการล้มเพราะโควตาหรือภูมิภาคที่ไม่ได้รับอนุญาต และ resource group ยังว่าง จะลบแล้วลองภูมิภาคถัดไป รหัสผ่านถูกสุ่มแล้วเก็บใน Key Vault เท่านั้น ผลลัพธ์ที่พิมพ์คือค่าที่ต้องใส่เป็น GitHub Actions secret

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_REGISTRY_NAME`
- `AZURE_RESOURCE_GROUP`
- `AZURE_CONTAINER_APP_NAME`

สร้าง GitHub Environment ชื่อ `production` แล้วใส่ secret ชุดนี้ OIDC ถูกผูกกับสาขา `main` และ environment `production` ไม่มี client secret

ถ้าจะให้ Azure Monitor ยิง Discord ให้ตั้ง `DISCORD_WEBHOOK_URL` ก่อนรัน bootstrap `SENTRY_DSN` และ `SMTP_PASSWORD` ตั้งเป็นตัวแปรสภาพแวดล้อมของเครื่องก่อนรันได้ ถ้าไม่ตั้ง สคริปต์เก็บค่า `disabled` ซึ่งแอปจะไม่ส่ง Sentry และจะไม่พยายามเข้า SMTP จนกว่าจะมี `SMTP_USER`

อิมเมจตัวแรกเป็น placeholder อ่านพอร์ตไม่ตรงกับ API จริง revision นี้จะไม่ผ่าน readiness จนกว่า workflow ของ `main` จะใส่ภาพของเซิร์ฟเวอร์

## Sentry

เซิร์ฟเวอร์เริ่มเมื่อมี DSN

```ts
import * as Sentry from '@sentry/nestjs';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1,
  integrations: [Sentry.nestIntegration()],
});
```

แอปมือถือรับ DSN ตอน build ไม่เขียนลงซอร์ส

```powershell
flutter run --dart-define=SENTRY_DSN=https://examplePublicKey@o0.ingest.sentry.io/0
```

## เฝ้าจากภายนอก

ใช้ Better Stack ชั้นฟรี หรือ Uptime Kuma บนเครื่องที่มีอยู่แล้ว ยิง `https://<container-app-fqdn>/api/health/ready` ทุก 1 นาที แล้วแจ้ง Discord ช่องเดียวกับ action group อย่ารันตัวตรวจนี้เป็นคอนเทนเนอร์บน Azure เพราะจะกินเครดิตเพิ่ม

คิวรี error 15 นาทีล่าสุดใน Log Analytics

```kusto
ContainerAppConsoleLogs_CL
| where TimeGenerated > ago(15m)
| where Log_s has '"level":"error"'
| project TimeGenerated, Log_s
```

ชื่อคอลัมน์ของ Container Apps อาจเป็น `Log_s` หรือ `Log` ตามเวอร์ชันของตาราง ถ้าคิวรีแรกว่าง ให้เปิดตาราง `ContainerAppConsoleLogs_CL` แล้วเลือกคอลัมน์ข้อความจริง
