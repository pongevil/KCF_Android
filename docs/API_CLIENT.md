# ApiClient (BS-Mobile)

HTTP client กลาง — ไฟล์ต้นทาง: [`lib/src/core/network/api_client.dart`](../lib/src/core/network/api_client.dart)

Repository เท่านั้นที่เรียก `ApiClient` โดยตรง (feature ห้าม import `dio`)

---

## Setup

| Item     | Source                                                                        |
| -------- | ----------------------------------------------------------------------------- |
| Base URL | `AppStorage.getApi()` (หน้า Config URL) — gateway                             |
| Auth     | Bearer JWT จาก `AppStorage.getToken()` เมื่อ `useAuth: true`                  |
| Headers  | `Content-Type`, `Accept`, `X-Client-IP`, `X-Client-Device`, `X-Client-Locale` |
| Timeout  | connect 50s / receive 30s (ปรับได้ด้วย `timeoutSec`)                          |

ลงทะเบียน DI ใน `lib/src/app/app.dart` เป็น singleton `ApiClient`

---

## Gateway vs localhost (`USE_LOCAL_API`)

แอปคุยกับ **gateway** (auth / menu / version) และอาจคุยกับ **local API** (feature เฉพาะ) ตอนพัฒนา

| Flag | วิธีตั้ง | ความหมาย |
|------|----------|----------|
| `USE_LOCAL_API` | `--dart-define=USE_LOCAL_API=true\|false` | `true` = API ทั่วไปไป localhost; gateway-only ยังใช้ `AppStorage.getApi()` |
| default | `true` | โหมด dev — build จริงควรส่ง `USE_LOCAL_API=false` |

```bash
# Dev (default) — localhost สำหรับ API ที่ไม่ใช่ gateway
flutter run --dart-define=USE_LOCAL_API=true

# Production / ทดสอบกับ gateway ทั้งหมด
flutter run --dart-define=USE_LOCAL_API=false
```

| เมื่อ | Base URL |
|------|----------|
| `isRunLocalhost == false` | gateway เสมอ (`AppStorage.getApi()`) |
| `isRunLocalhost == true` และ path เป็น gateway-only | gateway |
| `isRunLocalhost == true` และ path อื่น | `http://10.0.2.2:5087/` (Android emulator → host) |

**Gateway-only path segments** (อยู่นใน `_gatewayOnlyPathSegments`):

`login`, `logout`, `refreshToken`, `refresh`, `menu`, `CheckVersion`

ตัวอย่าง:

| Call | `USE_LOCAL_API=true` |
|------|----------------------|
| `post('login', …)` | → gateway |
| `get('menu', …)` | → gateway |
| `post('ai/chat', …)` | → `http://10.0.2.2:5087/ai/chat` |
| token refresh ใน `AuthInterceptor` | → gateway เสมอ |

> Device จริง / iOS simulator: เปลี่ยน `_localhostBaseUrl` เป็น LAN IP ของเครื่อง เช่น `http://192.168.1.10:5087/`

เพิ่ม gateway-only path: แก้ set ใน `api_client.dart` แล้วอัปเดตตารางนี้

---

## Methods

| Method     | Signature                                                      | Notes                           |
| ---------- | -------------------------------------------------------------- | ------------------------------- |
| `get`      | `get(path, {queryParameters, useAuth, showAlert, timeoutSec})` | รองรับ query string แยกจาก path |
| `post`     | `post(path, {data, useAuth, showAlert, timeoutSec})`           | body เป็น JSON                  |
| `put`      | `put(path, {data, useAuth})`                                   |                                 |
| `delete`   | `delete(path, {data, useAuth})`                                |                                 |
| `download` | `download(path, savePath, {...})`                              | บันทึกไฟล์ลงเครื่อง             |

---

## GET + queryParameters

ใช้พารามิเตอร์ `queryParameters` แทนการต่อ `?key=value` ใน path เอง

- key และ value ถูก encode ด้วย `Uri.encodeComponent`
- ค่า `null` จะไม่ถูกส่ง
- ถ้า `path` มี `?` อยู่แล้ว จะต่อด้วย `&`

```dart
// แนะนำ
final response = await _client.get(
  'menu',
  queryParameters: {'platform': 'MOBILE'},
);

// แทนที่แบบเก่า
// await _client.get('menu?platform=MOBILE');

// หลายพารามิเตอร์ + ค่าที่มีอักขระพิเศษ
final response = await _client.get(
  'search',
  queryParameters: {
    'q': 'กรุงเทพ & ปริมณฑล',
    'page': 1,
    'active': true,
  },
);
// → search?q=%E0%B8%81%E0%B8%A3%E0%B8%B8%E0%B8%87%E0%B9%80%E0%B8%97%E0%B8%9E%20%26%20%E0%B8%9B%E0%B8%A3%E0%B8%B4%E0%B8%A1%E0%B8%93%E0%B8%91%E0%B8%A5&page=1&active=true
```

Helper สำหรับ encode อย่างเดียว (เช่น unit test):

```dart
ApiClient.encodeQueryString({'a': 'b c', 'x': null}); // "a=b%20c"
```

---

## Error handling

- HTTP status ≠ 200 → `AppException` (ข้อความจาก `ApiErrorMapper`)
- `DioException` → map เป็นข้อความ user-facing; แสดง alert เมื่อ `showAlert: true`
- status 200 → `AppStorage.setNetwork(true)`

---

## ตัวอย่างในโปรเจกต์

| Repository                   | การเรียก                                                             |
| ---------------------------- | -------------------------------------------------------------------- |
| `home_repository.dart`       | `get('menu?platform=MOBILE')` — สามารถย้ายเป็น `queryParameters` ได้ |
| `version_repository.dart`    | `get('/Mobile/AppVersion/CheckVersion?version=...')`                 |
| `config_url_repository.dart` | `get('${url}test', useAuth: false)`                                  |
| `ai_chat_repository.dart`    | `post('ai/chat', data: ..., timeoutSec: 90)`                         |

---

  /// กฎสำหรับ AI / contributor

1. เพิ่ม endpoint ใหม่ใน **Repository** ของ feature ไม่ใช่ใน widget หรือ BLoC
2. GET ที่มี query ให้ใช้ `queryParameters` ไม่ฝัง string ใน path
3. ไม่สร้าง `Dio()` ใหม่ใน feature — ใช้ `ApiClient` ที่ inject
4. endpoint path เป็น relative (ไม่ใส่ base URL) เช่น `'menu'`, `'ai/chat'`
5. endpoint auth/menu/version ต้องอยู่ใน `_gatewayOnlyPathSegments` ถ้าต้องการให้ไม่ไป localhost
6. build จริง / CI: ส่ง `--dart-define=USE_LOCAL_API=false`
