# ASD Clear Materials

ปลั๊กอิน SketchUp สำหรับล้างสี/วัสดุ (material) ให้กลับเป็น **Default (ไร้สี)** — ใช้ได้ทั้งกับส่วนที่เลือกและทั้งโมเดล รวมถึงกลุ่มและคอมโพเนนต์ที่ซ้อนอยู่ข้างใน

## คำสั่ง

- **ล้างสีส่วนที่เลือก (รวมด้านในกลุ่ม/คอมโพเนนต์)** — ไล่เข้าไปถึง definition ข้างในทั้งหมด
- **ล้างสีส่วนที่เลือก (เฉพาะชั้นนอก)** — แตะเฉพาะชิ้นที่เลือก ไม่ลงไปข้างใน
- **ล้างสีทั้งโมเดล** — พร้อมถามว่าจะ purge วัสดุที่ไม่ได้ใช้ออกจาก In Model ด้วยหรือไม่
- **ลบวัสดุที่ไม่ได้ใช้ (Purge Materials)** — ลบวัสดุที่ไม่มีชิ้นงานอ้างถึง

เข้าถึงได้จากเมนู `Extensions > ASD Clear Materials`, toolbar และ right-click context menu (`ASD: ล้างสีเป็น Default`)

## พฤติกรรม

- ล้าง material ของ `Face` ทั้งหน้าและหลัง (front/back), `Edge`, `Group` และ `ComponentInstance`
- โหมด recursive ไล่เข้าไปใน definition ของทุก group/component โดยประมวลผลแต่ละ definition ครั้งเดียว
- ทุกคำสั่งเป็น **undo step เดียว** — กด Ctrl+Z คืนได้ทั้งครั้ง
- แสดงสรุปจำนวนชิ้นงานที่ถูกล้างหลังทำงานเสร็จ และแจ้งเตือนถ้าไม่ได้เลือกอะไรไว้

## ติดตั้ง

1. ดาวน์โหลด `ASD_Clear_Materials_v1.0.0.rbz` จากหน้า Releases
2. เปิด SketchUp → `Window > Extension Manager` → `Install Extension`
3. เลือกไฟล์ `.rbz` แล้วรีสตาร์ต SketchUp

## โครงสร้างโปรเจกต์

```
src/asd_clear_materials.rb          loader + ลงทะเบียน extension
src/asd_clear_materials/main.rb     logic ทั้งหมด (191 บรรทัด)
src/asd_clear_materials/icons/      ไอคอน toolbar ขนาด 24/32 px
test/mock_test.rb                   เทสต์ด้วย SketchUp API mock รันนอก SketchUp
dist/                               ไฟล์ .rbz ที่ build แล้ว (ไม่อยู่ใน git)
```

ไฟล์ `.rbz` คือ zip ของเนื้อหาใน `src/` (loader อยู่ระดับบนสุดของ archive)

## พัฒนา

```bash
ruby test/mock_test.rb     # ต้องมี Ruby ในเครื่อง dev; SketchUp ฝั่งผู้ใช้ใช้ Ruby 2.7
```

## เวอร์ชัน

- **1.0.0** — ล้างสีแบบเลือก/ทั้งโมเดล, recursive เข้าไปใน group และ component, purge วัสดุ, undo step เดียว

© 2026 ASD
