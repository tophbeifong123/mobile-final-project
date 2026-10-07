# งานประจำของสภาพผลิต

ค่าชื่อมาจากผลของ `infra/bootstrap.ps1` แทนที่ resource group, ชื่อแอป และชื่อ vault ด้านล่างถ้าเปลี่ยนจากค่าเริ่มต้น

## สำรอง PostgreSQL ก่อนรุ่นที่แตะ schema

Flexible Server สำรองให้อยู่แล้ว 7 วัน คำสั่งนี้สั่งจุดสำรองเพิ่มก่อน deploy

```powershell
az postgres flexible-server backup create `
  --resource-group internfinder-prod `
  --name (az postgres flexible-server list --resource-group internfinder-prod --query "[0].name" --output tsv) `
  --backup-name ("predeploy-" + (Get-Date -Format yyyyMMddHHmm))
```

ถ้าต้องดึงไฟล์มาที่เครื่อง ให้เปิด firewall ชั่วคราวเฉพาะ IP นั้น แล้วใช้ `pg_dump` กับโฮสต์จาก output `postgresHost` ผู้ใช้คือ `internfinder` รหัสอยู่ใน Key Vault ชื่อ `database-password` ปิดกฎ firewall ทันทีหลังดึงเสร็จ

## ดู log สด

```powershell
az containerapp logs show `
  --name internfinder-api `
  --resource-group internfinder-prod `
  --follow
```

## ย้อน revision

โหมด Single จะสร้าง revision ใหม่จากอิมเมจเก่า แล้วเลิกใช้ revision ปัจจุบัน

จาก GitHub Actions เปิด workflow `Deploy API` แล้วใส่ `revision_name` หรือ `image_tag` อย่างใดอย่างหนึ่ง

จากเครื่อง

```powershell
$image = az containerapp revision show `
  --name internfinder-api `
  --resource-group internfinder-prod `
  --revision "<revision-name>" `
  --query "properties.template.containers[0].image" `
  --output tsv

az containerapp update `
  --name internfinder-api `
  --resource-group internfinder-prod `
  --image $image
```

ดูชื่อ revision

```powershell
az containerapp revision list `
  --name internfinder-api `
  --resource-group internfinder-prod `
  --query "[].name" `
  --output tsv
```

## ตรวจเพดาน log

```powershell
az monitor log-analytics workspace show `
  --resource-group internfinder-prod `
  --workspace-name internfinder-logs `
  --query "{retention:retentionInDays, dailyCap:workspaceCapping.dailyQuotaGb}"
```

ค่าที่ต้องเห็นคือ retention 30 และ daily cap 0.5

## ใส่ secret เพิ่มหลัง bootstrap

ใช้เมื่อ role ของ Key Vault ยังไม่ทัน propagate ตอนรันสคริปต์ครั้งแรก หรือเมื่อจะเปลี่ยน DSN และรหัส SMTP

```powershell
az keyvault secret set --vault-name <key-vault-name> --name sentry-dsn --value "<dsn>"
az keyvault secret set --vault-name <key-vault-name> --name smtp-password --value "<smtp-password>"
```

จากนั้นปล่อย revision ใหม่จาก workflow ของ `main` เพื่อให้แอปอ่านค่าล่าสุด ค่า `disabled` หมายถึงยังไม่ส่ง Sentry และยังไม่ใช้รหัส SMTP
