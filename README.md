# CapCut-style Web Video Editor

ไฟล์หลัก (เวอร์ชั่นล่าสุดที่ใช้งาน): **`capcut_editor.html`**

## โครงสร้าง
- `capcut_editor.html` — เวอร์ชั่นปัจจุบัน (canonical) ที่แก้ไขล่าสุด
- `history/` — สำเนาทุกเวอร์ชั่นเก่า (v1 → v4(2)) เก็บไว้กันหาย
- `serve.ps1` — เปิดเว็บเซิร์ฟเวอร์ทดสอบบน localhost

## รันบน localhost
```powershell
powershell -ExecutionPolicy Bypass -File serve.ps1 -Port 8093
```
แล้วเปิด: http://localhost:8093/capcut_editor.html

## ย้อนกลับเวอร์ชั่นเก่า (git)
```powershell
git log --oneline                              # ดูประวัติทุกเวอร์ชั่น
git checkout <commit-id> -- capcut_editor.html # ดึงไฟล์ของ commit นั้นกลับมา
git stash                                       # พักงานปัจจุบัน (ถ้าต้องการ)
```
หรือเปิดไฟล์เวอร์ชั่นเก่าตรง ๆ จากโฟลเดอร์ `history/`

## ประวัติการแก้ (เริ่มจาก v4(2))
- แก้ play/export ไม่มีเสียง
- แก้ split แล้วคลิปด้านหลังไม่มีภาพ + แก้ export คลิปบน auto track ดำ/เงียบ
- เพิ่มปุ่ม Redo (Ctrl+Shift+Z / Ctrl+Y)
- เพิ่มปุ่มลบไฟล์ใน media list
- ปรับ subtitle ให้แม่นขึ้น (เลือกโมเดล tiny/base/small + word-level timestamps)
