# คู่มือ Android Release Signing — BS-Mobile

คู่มือนี้อธิบายการตั้งค่า keystore, `key.properties`, และขั้นตอน build release สำหรับ Android  
**ไฟล์ลับและรหัสผ่านไม่ commit ใน git**

---

## สารบัญ

1. [ภาพรวม](#ภาพรวม)
2. [ความหมายของแต่ละค่าใน keyproperties](#ความหมายของแต่ละค่าใน-keyproperties)
3. [ไฟล์ที่เกี่ยวข้อง](#ไฟล์ที่เกี่ยวข้อง)
4. [Setup ครั้งแรก (dev ที่ build release)](#setup-ครั้งแรก-dev-ที่-build-release)
5. [Build release](#build-release)
6. [เปลี่ยนรหัสผ่าน keystore](#เปลี่ยนรหัสผ่าน-keystore)
7. [สร้าง keystore ใหม่](#สร้าง-keystore-ใหม่)
8. [ตรวจสอบ keystore](#ตรวจสอบ-keystore)
9. [แก้ปัญหาที่พบบ่อย](#แก้ปัญหาที่พบบ่อย)
10. [Checklist ก่อนส่ง build](#checklist-ก่อนส่ง-build)
11. [หมายเหตุสำหรับทีม](#หมายเหตุสำหรับทีม)

---

## ภาพรวม

Android release build ต้อง **เซ็น (sign)** ด้วย keystore กลางของทีม  
Gradle อ่านค่าจาก `android/key.properties` แล้วใช้ใน `android/app/build.gradle` (`signingConfigs.release`)

```
android/bs-mobile-release.keystore   ← ไฟล์กุญแจ (ไม่ commit)
android/key.properties               ← รหัส + path (ไม่ commit)
android/key.properties.example       ← template (commit ได้)
android/app/build.gradle             ← อ่าน key.properties ตอน build
```

ถ้า **ไม่มี** `key.properties` → release build จะ fallback ไป **debug signing** (ใช้ dev ทั่วไปได้ แต่ไม่ใช่ production)

---

## ความหมายของแต่ละค่าใน key.properties

ตัวอย่าง (`android/key.properties.example`):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=bs-mobile-release
storeFile=../bs-mobile-release.keystore
```

| ค่า             | ความหมาย                                                     | เปลี่ยนเองได้ไหม                                                           |
| --------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------- |
| `storePassword` | รหัสเปิดไฟล์ keystore                                        | ได้ — ต้องใช้ `keytool` เปลี่ยนในไฟล์ keystore ด้วย (แก้แค่ใน file ไม่ได้) |
| `keyPassword`   | รหัสของ key ภายใน keystore                                   | ได้ — keystore แบบ PKCS12 มักใช้รหัสเดียวกับ `storePassword`               |
| `keyAlias`      | **ชื่อ** key ข้างใน keystore (ไม่ใช่รหัสผ่าน)                | ไม่ควรเปลี่ยนเอง — ต้องตรงกับตอนสร้าง keystore                             |
| `storeFile`     | **path** ไปยังไฟล์ `.keystore` (relative จาก `android/app/`) | เปลี่ยนได้ถ้าย้ายไฟล์ keystore                                             |

### ทำไม `storeFile` ถึงเป็น `../bs-mobile-release.keystore`?

`build.gradle` อยู่ที่ `android/app/` — path `../` จึงชี้ไปที่ `android/bs-mobile-release.keystore`

---

## ไฟล์ที่เกี่ยวข้อง

| ไฟล์                                 | commit ใน git | หมายเหตุ                                |
| ------------------------------------ | ------------- | --------------------------------------- |
| `android/key.properties.example`     | ✅            | template — แจกทีมได้                    |
| `android/key.properties`             | ❌            | รหัสผ่านจริง                            |
| `android/bs-mobile-release.keystore` | ❌            | keystore release                        |
| `android/.keystore-credentials.txt`  | ❌            | บันทึก alias/password ในเครื่อง (ถ้ามี) |

`android/.gitignore` กันแล้ว: `key.properties`, `**/*.keystore`, `**/*.jks`, `.keystore-credentials.txt`

---

## Setup ครั้งแรก (dev ที่ build release)

### 1. รับไฟล์จากผู้ดูแล keystore / vault ทีม

- `bs-mobile-release.keystore`
- รหัสผ่าน (`storePassword` / `keyPassword`)
- ยืนยัน `keyAlias=bs-mobile-release`

### 2. วาง keystore

```
android/bs-mobile-release.keystore
```

### 3. สร้าง key.properties

**Linux / macOS / Git Bash:**

```bash
cp android/key.properties.example android/key.properties
```

**Windows (PowerShell):**

```powershell
Copy-Item android\key.properties.example android\key.properties
```

### 4. แก้ android/key.properties

```properties
storePassword=<รหัสจาก vault>
keyPassword=<รหัสจาก vault>
keyAlias=bs-mobile-release
storeFile=../bs-mobile-release.keystore
```

> keystore แบบ PKCS12: ใส่รหัสเดียวกันทั้ง `storePassword` และ `keyPassword`

### 5. ทดสอบ build (รันเอง)

```bash
flutter build apk --release
```

ผลลัพธ์: `build/app/outputs/flutter-apk/app-release.apk`

---

## Build release

### เวอร์ชันแอพ

กำหนดใน `pubspec.yaml`:

```yaml
version: 1.0.0+1
#        │ │ │  └── buildNumber (versionCode บน Android) — เพิ่มทุกครั้งก่อนส่ง store
#        └─┴─┴──── versionName (แสดงให้ user)
```

### คำสั่ง

```bash
# APK — แจกติดตั้งตรง / ทดสอบ
flutter build apk --release

# App Bundle — แนะนำสำหรับ Google Play
flutter build appbundle --release
```

---

## เปลี่ยนรหัสผ่าน keystore

### สิ่งสำคัญ

**แก้แค่ใน `key.properties` อย่างเดียวไม่ได้** — รหัสใน file ต้องตรงกับรหัสในไฟล์ `.keystore`  
ถ้าไม่ตรง build จะ error เช่น `keystore password was incorrect`

### กรณี build ครั้งแรก (ยังไม่ขึ้น Play Store / ยังไม่มี user)

เลือก **อย่างใดอย่างหนึ่ง**:

#### ทาง A: เปลี่ยนรหัส keystore เดิม (แนะนำ)

ใช้ `keytool` เปลี่ยนรหัสในไฟล์ keystore ก่อน แล้วค่อยแก้ `key.properties`

**Windows (PowerShell):**

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -storepasswd `
  -keystore android\bs-mobile-release.keystore
```

คำสั่งจะถาม:

1. รหัสเดิม (ปัจจุบันใน keystore)
2. รหัสใหม่ (เช่น `P@ssw0rd`)
3. ยืนยันรหัสใหม่

จากนั้นแก้ `android/key.properties`:

```properties
storePassword=P@ssw0rd
keyPassword=P@ssw0rd
keyAlias=bs-mobile-release
storeFile=../bs-mobile-release.keystore
```

`keyAlias` และ `storeFile` **ไม่ต้องเปลี่ยน**

**Linux / macOS:**

```bash
keytool -storepasswd -keystore android/bs-mobile-release.keystore
```

#### ทาง B: สร้าง keystore ใหม่พร้อมรหัสที่ต้องการ

ใช้ได้เฉพาะเมื่อ **ยังไม่เคยส่ง build ที่ผูกกับ key เก่า** — ดู [สร้าง keystore ใหม่](#สร้าง-keystore-ใหม่)

### กรณีขึ้น Play Store แล้ว

- เปลี่ยนรหัสใน keystore **เดิม** ได้ (`keytool -storepasswd`) — ยังเป็น key เดิม อัปเดตแอปได้ต่อ
- **ห้าม** สร้าง keystore ใหม่แทน — จะอัปเดตแอปบน Play Store ไม่ได้ (ยกเว้น enroll App Signing ใหม่)

### หลังเปลี่ยนรหัส — สิ่งที่ต้องทำ

| รายการ                                     | ต้องทำ |
| ------------------------------------------ | ------ |
| แก้ `android/key.properties`               | ✅     |
| อัปเดต vault / `.keystore-credentials.txt` | ✅     |
| แจ้งทีมที่ build release                   | ✅     |
| แก้ `build.gradle`                         | ❌     |
| ถอนแอปก่อนติดตั้ง (build ครั้งแรก)         | ❌     |

---

## สร้าง keystore ใหม่

**เฉพาะผู้ดูแล keystore / ครั้งแรกของโปรเจกต์**

### Windows

ตัวอย่าง DN ด้านล่างเป็น placeholder — เปลี่ยนเป็นข้อมูลขององค์กรก่อนรัน

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v `
  -keystore android\bs-mobile-release.keystore `
  -alias bs-mobile-release `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -storepass "รหัสที่ต้องการ" `
  -dname "CN=BS-Mobile, OU=Mobile, O=ExampleOrg, L=Bangkok, ST=Bangkok, C=TH"
```

> ถ้าไม่ใส่ `-storepass` คำสั่งจะถามรหัสแบบ interactive

### Linux / macOS

ตัวอย่าง DN ด้านล่างเป็น placeholder — เปลี่ยนเป็นข้อมูลขององค์กรก่อนรัน

```bash
keytool -genkeypair -v \
  -keystore android/bs-mobile-release.keystore \
  -alias bs-mobile-release \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=BS-Mobile, OU=Mobile, O=ExampleOrg, L=Bangkok, ST=Bangkok, C=TH"
```

### หลังสร้าง

1. สร้าง `android/key.properties` จาก example
2. บันทึก alias + รหัสใน vault ปลอดภัย
3. **backup** ไฟล์ keystore — ถ้าเสียจะอัปเดตแอปบน Play Store ไม่ได้
4. แจก keystore + รหัสให้ทุกคนที่ build release

---

## ตรวจสอบ keystore

ดู alias และข้อมูล certificate:

**Windows:**

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v `
  -keystore android\bs-mobile-release.keystore
```

**Linux / macOS:**

```bash
keytool -list -v -keystore android/bs-mobile-release.keystore
```

ตรวจว่า alias ตรงกับ `keyAlias` ใน `key.properties` (`bs-mobile-release`)

---

## แก้ปัญหาที่พบบ่อย

| อาการ                                                     | สาเหตุที่พบบ่อย                            | แก้ไข                                                                              |
| --------------------------------------------------------- | ------------------------------------------ | ---------------------------------------------------------------------------------- |
| `keystore password was incorrect`                         | รหัสใน `key.properties` ไม่ตรงกับ keystore | ใช้ `keytool -storepasswd` หรือแก้ `key.properties` ให้ตรงรหัสจริง                 |
| `Failed to read key ... from store`                       | `keyAlias` ผิด                             | รัน `keytool -list` ดู alias ที่ถูก                                                |
| `Keystore file not found`                                 | `storeFile` path ผิด                       | ต้องเป็น `../bs-mobile-release.keystore` (relative จาก `android/app/`)             |
| ติดตั้ง APK ไม่ได้ / `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | แอปเก่าเซ็นด้วย key อื่น                   | ถอนแอปเก่าก่อนติดตั้ง build ใหม่                                                   |
| Release build แต่เซ็นด้วย debug key                       | ไม่มี `key.properties`                     | สร้าง `key.properties` ตาม [Setup ครั้งแรก](#setup-ครั้งแรก-dev-ที่-build-release) |

---

## Checklist ก่อนส่ง build

- [ ] มี `android/bs-mobile-release.keystore` ในเครื่อง
- [ ] มี `android/key.properties` รหัสถูกต้อง
- [ ] เพิ่ม `buildNumber` ใน `pubspec.yaml` (`x.y.z+N`)
- [ ] `flutter build apk --release` หรือ `appbundle` ผ่าน
- [ ] ไม่ commit `key.properties`, `*.keystore`, รหัสผ่าน
- [ ] backup keystore อยู่ใน vault

---

## หมายเหตุสำหรับทีม

1. **Backup keystore** — เก็บไฟล์ + รหัสใน password manager / encrypted vault
2. **แจก keystore** — ส่งให้ทุกคนที่ build release เท่านั้น (ช่องทางปลอดภัย)
3. **เปลี่ยน release key** — อุปกรณ์ที่ติดแอป build เก่า (key อื่น) ต้อง **ถอนการติดตั้งก่อน** ติดตั้งครั้งแรกหลังเปลี่ยน key
4. **ห้าม commit** credentials ลง git — ใช้ `key.properties.example` เป็น template

---

## อ้างอิงในโปรเจกต์

- `android/app/build.gradle` — `signingConfigs.release`
- `android/key.properties.example` — template
- [Flutter: Build and release an Android app](https://docs.flutter.dev/deployment/android)
