# SonarQube — BS-Mobile

คู่มือรัน **SonarQube Scanner** สำหรับวิเคราะห์โค้ด Dart ใน `lib/`  
ไม่ scan native (`android/`, `ios/`) หรือ generated files

---

## สารบัญ

1. [ภาพรวม](#ภาพรวม)
2. [สิ่งที่ต้องมี](#สิ่งที่ต้องมี)
3. [รันคำสั่ง (Windows)](#รันคำสั่ง-windows)
4. [รันคำสั่ง (macOS / Linux)](#รันคำสั่ง-macos--linux)
5. [พารามิเตอร์ที่ใช้](#พารามิเตอร์ที่ใช้)
6. [Token — อย่า commit](#token--อย่า-commit)
7. [ดูผลบน SonarQube](#ดูผลบน-sonarqube)
8. [แก้ปัญหาที่พบบ่อย](#แก้ปัญหาที่พบบ่อย)

---

## ภาพรวม

```
โปรเจกต์ BS-Mobile (lib/)
        │
        ▼
  sonar-scanner (local)
        │
        ▼
  SonarQube Server
  http://10.10.60.67/sonarqube
```

- **scan เฉพาะ** `lib/` — โค้ด Flutter/Dart หลัก
- **ไม่ scan** `android/`, `ios/`, `build/`, `.dart_tool/`, ไฟล์ generated (`*.g.dart`, `*.freezed.dart`)

---

## สิ่งที่ต้องมี

1. **SonarQube Server** ทีมเข้าถึงได้ — `http://10.10.60.67/sonarqube`
2. **SonarScanner** ติดตั้งบนเครื่องที่รัน
   - ดาวน์โหลด: [SonarScanner CLI](https://docs.sonarsource.com/sonarqube/latest/analyzing-source-code/scanners/sonarscanner/)
3. **Project** ลงทะเบียนบน SonarQube แล้ว — `projectKey` ต้องตรงกับที่ตั้งใน server (ตัวอย่างด้านล่างใช้ `BS-Mobile`)
4. **User Token** จาก SonarQube → My Account → Security → Generate Tokens

แนะนำรันก่อน scan:

```bash
flutter pub get
flutter analyze
flutter test
```

---

## รันคำสั่ง (Windows)

รันที่ **root โปรเจกต์** (`BS-Mobile/`) — โฟลเดอร์ที่มี `pubspec.yaml`

```powershell
cd D:\developer\mobile\BS-Mobile

sonar-scanner.bat `
  -D"sonar.projectKey=BS-Mobile" `
  -D"sonar.sources=lib" `
  -D"sonar.host.url=http://10.10.60.67/sonarqube" `
  -D"sonar.token=sqp_ed0614c861f88217f417e490d3d32825967903f2" `
  -D"sonar.exclusions=android/**,ios/**,build/**,.dart_tool/**,**/*.g.dart,**/*.freezed.dart"
```

แบบบรรทัดเดียว (copy ง่าย):

```powershell
sonar-scanner.bat -D"sonar.projectKey=BS-Mobile" -D"sonar.sources=lib" -D"sonar.host.url=http://10.10.60.67/sonarqube" -D"sonar.token=<YOUR_TOKEN>" -D"sonar.exclusions=android/**,ios/**,build/**,.dart_tool/**,**/*.g.dart,**/*.freezed.dart"
```

---

## รันคำสั่ง (macOS / Linux)

```bash
cd /path/to/BS-Mobile

sonar-scanner \
  -Dsonar.projectKey=BS-Mobile \
  -Dsonar.sources=lib \
  -Dsonar.host.url=http://10.10.60.67/sonarqube \
  -Dsonar.token=<YOUR_TOKEN> \
  -Dsonar.exclusions=android/**,ios/**,build/**,.dart_tool/**,**/*.g.dart,**/*.freezed.dart
```

---

## พารามิเตอร์ที่ใช้

| พารามิเตอร์        | ค่า                            | ความหมาย                                              |
| ------------------ | ------------------------------ | ----------------------------------------------------- |
| `sonar.projectKey` | `BS-Mobile`                    | ชื่อโปรเจกต์บน SonarQube (ต้องสร้างไว้บน server ก่อน) |
| `sonar.sources`    | `lib`                          | โฟลเดอร์ที่ให้ scan                                   |
| `sonar.host.url`   | `http://10.10.60.67/sonarqube` | URL ของ SonarQube server                              |
| `sonar.token`      | token ของ user                 | ยืนยันตัวตน — **ห้าม commit**                         |
| `sonar.exclusions` | ดูด้านล่าง                     | ข้าม path ที่ไม่ต้องการวิเคราะห์                      |

**Exclusions:**

```
android/**
ios/**
build/**
.dart_tool/**
**/*.g.dart
**/*.freezed.dart
```

ถ้าทีมสร้าง project ใหม่ชื่อ `BS-Mobile` บน SonarQube ให้เปลี่ยน `sonar.projectKey` ให้ตรงกับที่ลงทะเบียน

---

## Token — อย่า commit

- **ห้าม** ใส่ token จริงใน git, README หรือ script ที่ commit
- ใช้ placeholder `<YOUR_TOKEN>` แล้วแทนตอนรัน หรือใช้ environment variable

**Windows (PowerShell):**

```powershell
$env:SONAR_TOKEN = "your-token-here"

sonar-scanner.bat `
  -D"sonar.projectKey=BS-Mobile" `
  -D"sonar.sources=lib" `
  -D"sonar.host.url=http://10.10.60.67/sonarqube" `
  -D"sonar.token=$env:SONAR_TOKEN" `
  -D"sonar.exclusions=android/**,ios/**,build/**,.dart_tool/**,**/*.g.dart,**/*.freezed.dart"
```

**macOS / Linux:**

```bash
export SONAR_TOKEN="your-token-here"

sonar-scanner \
  -Dsonar.projectKey=BS-Mobile \
  -Dsonar.sources=lib \
  -Dsonar.host.url=http://10.10.60.67/sonarqube \
  -Dsonar.token=$SONAR_TOKEN \
  -Dsonar.exclusions=android/**,ios/**,build/**,.dart_tool/**,**/*.g.dart,**/*.freezed.dart
```

---

## ดูผลบน SonarQube

1. เปิด `http://10.10.60.67/sonarqube`
2. เข้าโปรเจกต์ `BS-Mobile` (หรือ project key ที่ตั้งไว้)
3. ดู Issues, Code Smells, Duplications ฯลฯ

---

## แก้ปัญหาที่พบบ่อย

| ปัญหา                     | แนวทาง                                                       |
| ------------------------- | ------------------------------------------------------------ |
| `sonar-scanner` ไม่รู้จัก | ติดตั้ง SonarScanner และเพิ่ม `bin` ใน PATH                  |
| 401 / 403                 | ตรวจ token หมดอายุหรือสิทธิ์ user                            |
| Project not found         | สร้าง project บน SonarQube ให้ `projectKey` ตรงกับคำสั่ง     |
| ไม่เห็นไฟล์ Dart          | ตรวจว่ารันที่ root โปรเจกต์ และ `sonar.sources=lib`          |
| scan ช้า / ไฟล์เยอะ       | ตรวจ `sonar.exclusions` ว่าข้าม `build/`, `.dart_tool/` แล้ว |

---

## หมายเหตุสำหรับทีม

- รัน scan ก่อน merge PR หรือตามรอบที่ทีมกำหนด
- แก้ issue ระดับ Blocker/Critical ก่อน release ตามนโยบายทีม
- ถ้าต้องการ scan `test/` ด้วย ให้เพิ่ม `sonar.tests=test` ในอนาคต (ยังไม่จำเป็นในรอบนี้)
