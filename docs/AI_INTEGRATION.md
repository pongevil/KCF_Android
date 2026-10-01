# AI Integration (BS-Mobile)

Mobile เรียก AI ผ่าน **gateway URL เดิม** (`AppStorage.getApi()`) — ไม่ต้องตั้งค่า AI URL แยกในแอพ  
OpenRouter API key อยู่ฝั่ง server เท่านั้น

---

## Architecture

```
AiChatSheet (UI)
    → AiChatBloc
    → AiChatRepository
    → ApiClient.post('ai/chat', timeoutSec: 90)
    → Gateway (JWT Bearer เดียวกับ login)

AiActionCoordinator (presentation)
    → navigate / camera / SnackBar side effects
```

UI side effects ของ AI อยู่ที่ [`AiActionCoordinator`](../lib/src/features/ai/presentation/ai_action_coordinator.dart) — ไม่ได้อยู่ใน `core/`

---

## Files

| Path | Role |
|------|------|
| `lib/src/core/ai/ai_config.dart` | Endpoint path + timeout |
| `lib/src/core/ai/models/` | Request/response models |
| `lib/src/core/ai/ai_action.dart` | Decision type enum |
| `lib/src/features/ai/presentation/ai_action_coordinator.dart` | Navigate / scanner / SnackBar |
| `lib/src/features/ai/repository/ai_chat_repository.dart` | POST chat / confirm / reject / suggestions |
| `lib/src/features/ai/presentation/bloc/` | `ai_chat_bloc` + events + state |
| `lib/src/features/ai/presentation/widgets/ai_chat_sheet.dart` | Bottom sheet UI + `showAiChatSheet()` |
| `lib/src/features/ai/presentation/widgets/ai_suggestion_chips.dart` | Quick-pick suggestion chips |

Registered in `lib/src/app/app.dart` as global `AiChatBloc`.

---

## Endpoints

| Endpoint | Path | Purpose |
|----------|------|---------|
| Chat | `ai/chat` | ส่งข้อความ / รับคำตอบ |
| Confirm | `ai/confirm` | ยืนยัน CRUD proposal |
| Reject | `ai/reject` | ปฏิเสธ CRUD proposal |
| Suggestions | `ai/suggestions` | คำถามแนะนำตาม `process` |

| Item | Value |
|------|-------|
| Base URL | `AppStorage.getApi()` (Config URL page) |
| Auth | Bearer JWT (auto via `ApiClient`) |
| Timeout | 90 seconds (`AiConfig.receiveTimeoutSec`) |
| Default process constant | `AiConfig.defaultMobileHomeProcess` = `/master/warehouse` |
| Home FAB process (current) | `/master/item` in `home_page.dart` |

---

## Chat request

```json
{
  "process": "/master/item",
  "user_message": "hi",
  "user_id": "mobile1",
  "user_name": "Mo mobile1",
  "conversation_history": []
}
```

| Field | Source |
|-------|--------|
| `process` | หน้าปัจจุบัน (Home ใช้ `/master/item`) |
| `user_message` | ข้อความที่ผู้ใช้พิมพ์ล่าสุด |
| `user_id` | `AppStorage.getUserId()` |
| `user_name` | `AppStorage.getUsername()` |
| `conversation_history` | ข้อความก่อนหน้า (ไม่รวม `user_message` ปัจจุบัน) |

ดูรายละเอียด response / proposal ในโค้ด `lib/src/core/ai/models/`.
