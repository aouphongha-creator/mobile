# JORNY OG

แอปวางแผนการเดินทางและบันทึกค่าใช้จ่าย พัฒนาด้วย Flutter
รายวิชา Mobile Application Design and Development

## ฟีเจอร์

- **Home** — รายการทริปพร้อมสถานะ (กำลังเดินทาง / วางแผน / จบแล้ว), เพิ่ม แก้ไข และลบทริป
- **Detail** — แผนรายวัน (Day 1, 2, 3 …), เพิ่ม แก้ไข และลบสถานที่, สภาพอากาศ, สรุปงบประมาณ, อัตราแลกเปลี่ยน
- **History** — ประวัติค่าใช้จ่ายแยกตามวัน, กรองตามหมวดหมู่และวัน, แปลงสกุลเงินเป็นบาทอัตโนมัติ

## External APIs

- [OpenWeatherMap](https://openweathermap.org/api) — สภาพอากาศ (ใส่ API key ตอนรัน)
- [Open-Meteo](https://open-meteo.com/) — สภาพอากาศสำรอง ไม่ต้องใช้ key
- [ExchangeRate-API](https://www.exchangerate-api.com/) — อัตราแลกเปลี่ยน
- [Supabase](https://supabase.com/) — ฐานข้อมูล (ไม่ต้องล็อกอิน ทุกเครื่องใช้ข้อมูลชุดเดียวกัน)

## ตั้งค่า Supabase

1. เปิด SQL Editor ใน Supabase แล้วรันไฟล์ [`supabase/schema.sql`](supabase/schema.sql)
2. ใส่ Project URL ใน `lib/app/supabase_config.dart` (ถ้าเว้นว่าง แอปจะเก็บข้อมูลในเครื่องแทน)

## วิธีรัน

```bash
flutter pub get
flutter run                                   # ใช้ Open-Meteo
flutter run --dart-define=OWM_API_KEY=<key>   # ใช้ OpenWeatherMap
flutter run -d chrome                         # รันบนเว็บ
```

## ผู้จัดทำ

| ชื่อ-นามสกุล | รหัสนิสิต |
|---|---|
| ธัญวรรณ บูรณะกิจ | 6721652251 |
| ภัทรชนน พงษ์หา | 6721652498 |
