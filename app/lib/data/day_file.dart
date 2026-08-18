/// อ่าน/เขียนไฟล์รายวันตามรูปแบบใน §2.2
///
/// ทั้งไฟล์นี้เป็นฟังก์ชันบริสุทธิ์ ไม่แตะดิสก์ ไม่รู้จัก Flutter
/// เพื่อให้ทดสอบรูปแบบไฟล์ได้เต็มที่โดยไม่ต้องมีเครื่องจริง
///
/// ```markdown
/// - [x] อ่านเลข บทที่ 4 [1:47]
/// - [ ] สรุปฟิสิกส์
///
/// ---
/// เช้าสมาธิดีมาก บ่ายไม่ไหวเลย
/// ```
library;

import '../model/day.dart';
import '../model/duration_fmt.dart';

/// `- [x] ` หรือ `- [ ] ` ที่ต้นบรรทัด · ยอมรับ `X` ตัวใหญ่ตอนอ่าน
/// และยอมให้ไม่มีช่องว่างตามหลังได้ เผื่อบรรทัดที่ยังไม่มีชื่อ
final _itemPattern = RegExp(r'^- \[([ xX])\][ ]?(.*)$');

/// `[1:47]` ที่ท้ายบรรทัดเท่านั้น
///
/// ผูกกับท้ายบรรทัดโดยตั้งใจ ไม่งั้นชื่องานที่มีวงเล็บเหลี่ยมอยู่กลางประโยค
/// จะถูกกินไปเป็นเวลา
final _timePattern = RegExp(r'\s*\[(\d+):([0-5]\d)\]$');

/// เส้นคั่นระหว่างรายการกับ journal — ต้องเป็น `---` ที่ยืนอยู่บรรทัดเดียว
bool _isSeparator(String line) => line.trim() == '---';

/// แปลงเนื้อไฟล์เป็น [Day]
///
/// บรรทัดที่ไม่เข้ารูปแบบใดเลยจะกลายเป็น [RawLine] และถูกเก็บไว้เหมือนเดิม
Day parseDayFile(DateTime date, String content) {
  var text = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  // ตัดขึ้นบรรทัดใหม่ตัวสุดท้ายทิ้ง เพราะเราเติมกลับเองตอนเขียนเสมอ
  if (text.endsWith('\n')) text = text.substring(0, text.length - 1);

  if (text.isEmpty) return Day(date: date);

  final all = text.split('\n');
  final sepIndex = all.indexWhere(_isSeparator);

  // `---` ตัวแรกที่ยืนเดี่ยวคือตัวคั่น · ตัวถัดๆ ไปเป็นข้อความ journal ธรรมดา
  final head = sepIndex == -1 ? all : all.sublist(0, sepIndex);
  final journal = sepIndex == -1 ? '' : all.sublist(sepIndex + 1).join('\n');

  final entries = <DayEntry>[];
  for (final line in head) {
    final m = _itemPattern.firstMatch(line);
    if (m == null) {
      entries.add(RawLine(line));
      continue;
    }
    final done = m.group(1)!.toLowerCase() == 'x';
    var body = m.group(2)!;
    var minutes = 0;
    final t = _timePattern.firstMatch(body);
    if (t != null) {
      minutes = int.parse(t.group(1)!) * 60 + int.parse(t.group(2)!);
      body = body.substring(0, t.start);
    }
    entries.add(Line(text: body, done: done, minutes: minutes));
  }

  // ตัดบรรทัดว่างท้ายส่วนรายการทิ้ง มันเป็นแค่ช่องว่างก่อนเส้นคั่น
  while (entries.isNotEmpty &&
      entries.last is RawLine &&
      (entries.last as RawLine).isBlank) {
    entries.removeLast();
  }

  return Day(date: date, entries: entries, journal: journal);
}

/// แปลง [Day] กลับเป็นเนื้อไฟล์ · ปิดท้ายด้วยขึ้นบรรทัดใหม่เสมอ
String serializeDayFile(Day day) {
  final buf = StringBuffer();

  for (final e in day.entries) {
    buf.writeln(switch (e) {
      Line l => _renderLine(l),
      RawLine r => r.text,
    });
  }

  if (day.journal.trim().isNotEmpty) {
    if (day.entries.isNotEmpty) buf.writeln();
    buf.writeln('---');
    buf.writeln(day.journal);
  }

  return buf.toString();
}

String _renderLine(Line l) {
  final parts = <String>['- [${l.done ? 'x' : ' '}]'];
  if (l.text.isNotEmpty) parts.add(l.text);
  if (l.minutes > 0) parts.add('[${formatHm(l.minutes)}]');
  return parts.join(' ');
}
