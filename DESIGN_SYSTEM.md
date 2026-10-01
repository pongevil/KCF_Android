# BS-Mobile Design System

เอกสาร **Theme & Visual Spec** สำหรับ SA / Designer / AI ใช้ gen หน้าจอ mockup  
ไม่ใช่คู่มือ implementation — รายละเอียดโค้ดดูใน [README.md](README.md)

**Default brand:** Fresh Green (อ้างอิง Freshket) · รองรับ **4 สีแบรนด์** + **Light / Dark**

---

## สารบัญ

1. [ภาพรวมสำหรับ AI](#1-ภาพรวมสำหรับ-ai)
2. [Color Palettes](#2-color-palettes)
3. [สีสถานะ (Status)](#3-สีสถานะ-status)
4. [พื้นหลัง & ข้อความ (Light / Dark)](#4-พื้นหลัง--ข้อความ-light--dark)
5. [Gradients](#5-gradients)
6. [Typography](#6-typography)
7. [Components (หน้าตา)](#7-components-หน้าตา)
8. [Spacing & Shape](#8-spacing--shape)
9. [Checklist ก่อนส่ง mockup](#9-checklist-ก่อนส่ง-mockup)
10. [Prompt ตัวอย่างสำหรับ AI](#10-prompt-ตัวอย่างสำหรับ-ai)

---

## 1. ภาพรวมสำหรับ AI

เมื่อ gen หน้าจอ BS-Mobile ให้ยึดหลักนี้:

- สไตล์: **modern, clean, mobile-first**, flat + gradient จุดเน้น
- Card: **มุมโค้ง, ไม่มี elevation หนัก**, border บาง
- ปุ่มหลัก: สี **primary** ของ palette ที่เลือก, มุมโค้ง ~12px, สูง ~54px
- Header หน้า Home: **gradient โค้งล่าง** (radius 40px)
- สีสถานะ: ใช้ชุด success / warning / error / info **คงที่** ทุก palette
- รองรับ **Light mode เป็นหลัก** — ถ้าไม่ระบุให้ใช้ Light + Fresh Green
- หน้ากล้อง / QR: พื้นดำได้ (ยกเว้นจาก theme ปกติ)

ผู้ใช้เปลี่ยน **สีแบรนด์ 4 แบบ** และ **Dark mode** ได้จาก Drawer หลัง login

### Mockup กับ implementation (สำคัญ)

- Mockup ที่ SA ส่ง = **reference snapshot** มักเป็น **Fresh Green + Light**
- ออกแบบด้วย **ชื่อ role** (`Primary`, `Surface`, `Error`) ไม่ lock hex ทุก layer ถ้าไม่จำเป็น
- Dev implement ด้วย semantic token — เมื่อ user เปลี่ยน palette สี brand **เปลี่ยนตาม** (ไม่ใช่ bug)
- ฟอร์ม WMS ใช้ **neutral surface** — brand ใช้ที่ header / CTA / hero เท่านั้น

---

## 2. Color Palettes

เลือก 1 palette ต่อ mockup (default = **Fresh Green**)

### Fresh Green _(default)_

| Token            | Hex       | ใช้เมื่อ                    |
| ---------------- | --------- | --------------------------- |
| Primary          | `#00CE7C` | ปุ่มหลัก, accent, link      |
| Primary Light    | `#ECFB56` | gradient อ่อน, inbound card |
| Primary Dark     | `#008065` | header, drawer (light)      |
| Accent (text)    | `#1D4849` | ข้อความหลัก (light mode)    |
| Decorative       | `#DAF7E9` | พื้นตกแต่ง, border อ่อน     |
| Secondary Accent | `#FF6600` | outbound / ส้ม              |

### Ocean Blue

| Token            | Hex       |
| ---------------- | --------- |
| Primary          | `#0EA5E9` |
| Primary Light    | `#7DD3FC` |
| Primary Dark     | `#0369A1` |
| Accent           | `#0C4A6E` |
| Decorative       | `#E0F2FE` |
| Secondary Accent | `#0284C7` |

### Royal Purple

| Token            | Hex       |
| ---------------- | --------- |
| Primary          | `#8B5CF6` |
| Primary Light    | `#C4B5FD` |
| Primary Dark     | `#6D28D9` |
| Accent           | `#4C1D95` |
| Decorative       | `#EDE9FE` |
| Secondary Accent | `#A855F7` |

### Sunset Orange

| Token            | Hex       |
| ---------------- | --------- |
| Primary          | `#F97316` |
| Primary Light    | `#FDBA74` |
| Primary Dark     | `#C2410C` |
| Accent           | `#7C2D12` |
| Decorative       | `#FFEDD5` |
| Secondary Accent | `#EA580C` |

---

## 3. สีสถานะ (Status)

ใช้ชุดนี้เท่านั้น — **ไม่เปลี่ยนตาม palette**

| สถานะ   | Hex       | ใช้เมื่อ             |
| ------- | --------- | -------------------- |
| Success | `#22C55E` | สำเร็จ, ยืนยัน, ผ่าน |
| Warning | `#FF6600` | เตือน, รอดำเนินการ   |
| Error   | `#EF4444` | ผิดพลาด, ปฏิเสธ      |
| Info    | `#06B6D4` | แจ้งข้อมูล           |

ปุ่มตามบทบาท:

| ปุ่ม     | สีพื้น                               | ข้อความ |
| -------- | ------------------------------------ | ------- |
| Primary  | Primary ของ palette                  | ขาว     |
| Success  | `#22C55E`                            | ขาว     |
| Danger   | `#EF4444`                            | ขาว     |
| Warning  | `#FF6600`                            | ขาว     |
| Disabled | `#F4F7F6` (light) / `#2A2A2A` (dark) | จาง 38% |

---

## 4. พื้นหลัง & ข้อความ (Light / Dark)

### Light Mode

| Role             | Hex                                             | ใช้เมื่อ             |
| ---------------- | ----------------------------------------------- | -------------------- |
| Page background  | `#F4F7F6`                                       | พื้นหลังหน้าหลัก     |
| Surface / Card   | `#FFFFFF`                                       | การ์ด, sheet, input  |
| Text หลัก        | สี Accent ของ palette (Fresh Green = `#1D4849`) | หัวข้อ, body         |
| Text รอง         | `#536E6F`                                       | label, hint, caption |
| Border / Divider | `#E8ECEB`                                       | เส้นแบ่ง, ขอบการ์ด   |
| Scaffold         | `#FFFFFF`                                       | —                    |

### Dark Mode

| Role             | Hex                   | ใช้เมื่อ     |
| ---------------- | --------------------- | ------------ |
| Page background  | `#0A0A0A` – `#121212` | พื้นหลัง     |
| Surface / Card   | `#1E1E1E`             | การ์ด, sheet |
| Text หลัก        | `#F4F7F6`             | หัวข้อ, body |
| Text รอง         | `#A0B3B2`             | label, hint  |
| Border / Divider | `#333333`             | เส้นแบ่ง     |
| Elevated surface | `#2A2A2A`             | พื้นยกชั้น   |

---

## 5. Gradients

### Fresh Green — Light mode

| ชื่อ          | สี                    | ใช้ที่                |
| ------------- | --------------------- | --------------------- |
| Primary       | `#00CE7C` → `#008065` | AppBar เขียว, loading |
| Header        | `#008065` → `#1D4849` | Home header โค้งล่าง  |
| Inbound card  | `#ECFB56` → `#00CE7C` | เมนูรับเข้า           |
| Outbound card | ส้มอ่อน → `#FF6600`   | เมนูจ่ายออก           |

### Dark mode

- Header / menu cards → โทนเข้ม blend กับ primary (ไม่ใช่สีสดแบบ light)
- Header มักเป็น `#1A1A1A` → `#121212`

### AppBar แบบในแอพ

| แบบ       | หน้าตา                                     |
| --------- | ------------------------------------------ |
| Surface   | พื้นขาว/เทา + เส้นล่างบาง                  |
| Green     | gradient Primary                           |
| Orange    | gradient Outbound (ส้ม)                    |
| Pink/Teal | gradient Header (`primaryDark` → `accent`) |

---

## 6. Typography

| Style     | ขนาด | น้ำหนัก  | ใช้เมื่อ          |
| --------- | ---- | -------- | ----------------- |
| Heading L | 28px | Bold     | ชื่อหน้า          |
| Heading M | 22px | Bold     | หัว section       |
| Heading S | 18px | SemiBold | หัวการ์ด          |
| Body L    | 16px | Regular  | เนื้อหาหลัก       |
| Body M    | 14px | Regular  | เนื้อหารอง        |
| Caption   | 12px | Regular  | badge, label เล็ก |

**Font ในแอพ:** Noto Sans Thai (หลัก) + Noto Sans (Latin fallback) — จาก `assets/fonts/`

สีข้อความ: หลักตามตาราง Light/Dark ด้านบน, รองใช้ `#536E6F` / `#A0B3B2`

---

## 7. Components (หน้าตา)

อธิบาย visual — ไม่ใช่ชื่อ class ในโค้ด

### ปุ่ม (Button)

- มุมโค้ง ~12px, สูงมาตรฐาน ~54px
- มีไอคอนซ้ายได้
- กดแล้วยุบเล็กน้อย (micro-interaction)
- แบบ: Primary · Success · Danger · Warning · Disabled

### Text Field

- label ด้านบน, border โค้ง ~12px
- รองรับ: password (toggle แสดงรหัส), date picker, validation error สีแดง
- hint สี `#536E6F`

### การ์ด (Card)

- พื้น surface, มุมโค้ง **16–20px**
- elevation ต่ำมาก / เงาเบา 4%
- ขอบบาง `#E8ECEB` (light)
- หัวการ์ดมี icon + title ได้
- **Neutral card (ฟอร์ม / config):** พื้น `surface` + ขอบ `outlineVariant` — **ห้ามทา primary tint** ทั้งการ์ด
- Icon box ใน header ใช้ `surfaceContainerHighest` + ไอคอน `onSurfaceVariant`

### Brand vs Neutral surfaces

| ประเภท | ใช้เมื่อ | สี |
|--------|----------|-----|
| **Brand** | Header Home, Hero menu, Drawer header, Primary CTA, AI gradient button | gradient / `primary` |
| **Neutral** | Form card, Info box, Config, Settings, Login | `surface` + `outlineVariant` |
| **Text on brand** | ข้อความบน gradient | `barContentColor` / `onPrimary` |
| **Body text** | เนื้อหาทั่วไป | `onSurface` `#2D3436` (light) + `onSurfaceVariant` รอง |

### Info Box

- กล่องข้อมูลโทนกลาง (พื้น/ขอบจาก `outlineVariant` โปร่งใส)
- ใช้สี semantic (`success` / `warning` / `error`) เฉพาะเมื่อสื่อสถานะชัดเจน

### เมนูการ์ด (Home)

- **Hero card ใหญ่:** gradient ตาม inbound/outbound, ไอคอน + title + subtitle
- **Menu card ปกติ:** พื้น surface, ไอคอน, badge ตัวเลขได้

### App Bar

- สูง ~68px (มี subtitle ~78px)
- แบบ gradient หรือ surface เรียบ
- ปุ่ม back / action มุมโค้ง 14px

### Loading

- หุ่นยนต์ (robot mascot) + Lottie หรือ shimmer skeleton
- overlay มืดครึ่งจอเมื่อ loading เต็มหน้า

### Toast / Alert

- success = เขียว · warning = ส้ม · error = แดง · info = ฟ้า
- แสดงด้านบน, หายอัตโนมัติ ~3 วินาที

### Drawer

- Header: พื้น `primaryDark` (light) หรือ `#1A1A1A` (dark)
- มี avatar + ชื่อ user
- รายการเมนู + ตัวเลือก **Dark mode** และ **เปลี่ยนสีธีม 4 แบบ**

### Dropdown

- แบบธรรมดา, ค้นหาใน list, modal เต็มจอ, หรือโหลดแบบ paging

### หน้า Login

- การ์ดกลางจอโค้งมน, animation เบา
- logo ด้านบน, ช่อง username / password, ปุ่ม primary เต็มความกว้าง

---

## 8. Spacing & Shape

| Token       | ค่า  | ใช้เมื่อ     |
| ----------- | ---- | ------------ |
| radius-sm   | 8px  | chip, badge  |
| radius-md   | 12px | ปุ่ม, input  |
| radius-lg   | 16px | การ์ด        |
| radius-xl   | 20px | การ์ดใหญ่    |
| radius-2xl  | 24px | bottom sheet |
| radius-full | pill | avatar, tag  |

**Spacing แนะนำ:** 4 · 8 · 12 · 16 · 24 · 32 px

**Home header:** โค้งล่างซ้าย-ขวา **40px**

---

## 9. Checklist ก่อนส่ง mockup

- [ ] ระบุ **Reference: Fresh Green + Light** (ถ้าไม่ระบุ = default นี้)
- [ ] ระบุ palette ถ้าไม่ใช่ Fresh Green
- [ ] ใช้ชื่อ role (`Primary`, `Surface`, `Success`) ใน Figma ไม่ lock hex ทุก element
- [ ] ข้อความหลัก / รอง ใช้สีถูก role
- [ ] ปุ่มหลักใช้ Primary ของ palette
- [ ] สถานะใช้ success / warning / error / info เท่านั้น
- [ ] การ์ดมุมโค้ง 16–20px, ไม่เงาหนัก
- [ ] Header Home ใช้ gradient + โค้งล่าง 40px
- [ ] เมนู action ใช้ gradient inbound (เขียว) / outbound (ส้ม)
- [ ] ไม่ hardcode สีนอก palette โดยไม่จำเป็น

---

## 10. Prompt ตัวอย่างสำหรับ AI

คัดลอกปรับใช้กับ ChatGPT / Figma AI / v0 ฯลฯ

```text
ออกแบบหน้าจอ mobile app BS-Mobile (Flutter warehouse app)

Reference theme: Fresh Green · Light mode
(แอพรองรับ 4 palette + dark — dev ใช้ semantic token ไม่ copy hex)

Theme:
- Palette: Fresh Green (primary #00CE7C, accent text #1D4849)
- Mode: Light
- Page bg #F4F7F6, cards #FFFFFF radius 20px, subtle border #E8ECEB
- Header gradient #008065 → #1D4849, bottom curve radius 40px
- Font: Noto Sans Thai + Noto Sans — Heading 22px Bold, body 16px

Components ที่มีในระบบ:
- Primary button สูง 54px, radius 12px, สี #00CE7C
- Text field มี label + hint สี #536E6F
- Status: success #22C55E, warning #FF6600, error #EF4444
- Hero menu cards ใช้ gradient เขียว (inbound) หรือส้ม (outbound)

หน้าที่ต้องการ: [อธิบายหน้าจอ]
ฟิลด์ / ปุ่ม: [รายการ]
```

---

## เอกสารอื่น (สำหรับ Dev)

- [README.md](README.md) — overview, conventions
- [docs/SHARED_WIDGETS.md](docs/SHARED_WIDGETS.md) — widget catalog สำหรับ implement
- [docs/LOCALE.md](docs/LOCALE.md) — ข้อความหลายภาษา `context.tr()`
