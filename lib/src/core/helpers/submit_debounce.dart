/// กันเหตุการณ์ Enter/submit ยิงซ้ำ
///
/// บน hardware keyboard / barcode scanner (PDA) ปุ่ม Enter ตัวเดียวมักถูกส่ง
/// ทั้ง raw key event และ IME action ทำให้ `onSubmitted` / `onFieldSubmitted`
/// ถูกเรียกสองครั้ง หรือ cascade ไปยัง field ถัดไปที่เพิ่งได้ focus ภายในเฟรม
/// เดียวกัน. helper นี้เก็บเวลา submit ครั้งล่าสุดแบบ global แล้วปฏิเสธ submit
/// ที่เกิดถี่เกิน [window] เพื่อให้ Enter ตัวเดียวถูกประมวลผลเพียงครั้งเดียว
class SubmitDebounce {
  const SubmitDebounce._();

  /// ช่วงเวลาที่ถือว่าเป็น submit ซ้ำ (เผื่อ cascade ข้าม field ในเฟรมเดียวกัน)
  static const Duration window = Duration(milliseconds: 250);

  static int _lastSubmitMs = 0;

  /// คืน `true` ถ้าควรประมวลผล submit นี้ (ไม่ใช่ตัวซ้ำ)
  static bool shouldHandle() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSubmitMs < window.inMilliseconds) {
      return false;
    }
    _lastSubmitMs = now;
    return true;
  }
}
