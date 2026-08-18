/// การจัดรูปเวลา — หน่วยของทั้งแอปคือ "นาที" (§2.3)
library;

/// `107` → `1:47` · ใช้ทั้งในไฟล์ `[h:mm]` และบนหน้าจอ
///
/// ชั่วโมงไม่เติมศูนย์ข้างหน้า นาทีเติมเสมอ — ตรงกับตัวอย่างในสเปก §2.2
String formatHm(int minutes) {
  final m = minutes < 0 ? 0 : minutes;
  return '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';
}

/// `160` → `2 ชั่วโมง 40 นาที` · ใช้ในแผงรายละเอียดของกำแพง
String formatThai(int minutes) {
  final m = minutes < 0 ? 0 : minutes;
  final h = m ~/ 60;
  final rest = m % 60;
  if (h == 0) return '$rest นาที';
  if (rest == 0) return '$h ชั่วโมง';
  return '$h ชั่วโมง $rest นาที';
}
