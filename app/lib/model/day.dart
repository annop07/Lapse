/// โมเดลของ "หนึ่งวัน" — ตรงกับไฟล์ `days/YYYY-MM-DD.md` หนึ่งไฟล์ (§2.1)
///
/// ไฟล์คือ source of truth ไม่ใช่ตาราง DB คลาสในนี้จึงเป็นแค่ภาพของไฟล์
/// ในหน่วยความจำ และต้องเขียนกลับออกไปให้เหมือนเดิมได้เสมอ
library;

/// สิ่งที่อยู่เหนือเส้นคั่นในไฟล์รายวัน
///
/// มีสองแบบเท่านั้น: [Line] ที่เรารู้จัก กับ [RawLine] ที่เราไม่รู้จักแต่ต้องเก็บไว้
sealed class DayEntry {
  const DayEntry();
}

/// รายการหนึ่งบรรทัด — เป็นทั้ง todo, ตัวจับเวลา และบันทึกในตัวเดียว (§9)
final class Line extends DayEntry {
  const Line({required this.text, this.done = false, this.minutes = 0});

  final String text;
  final bool done;

  /// เวลาโฟกัสสะสมของบรรทัดนี้ หน่วยเป็น "นาที" (§2.3) · 0 = ยังไม่มีเวลา
  final int minutes;

  bool get isBlank => text.trim().isEmpty && minutes == 0;

  Line copyWith({String? text, bool? done, int? minutes}) => Line(
        text: text ?? this.text,
        done: done ?? this.done,
        minutes: minutes ?? this.minutes,
      );

  @override
  bool operator ==(Object other) =>
      other is Line &&
      other.text == text &&
      other.done == done &&
      other.minutes == minutes;

  @override
  int get hashCode => Object.hash(text, done, minutes);

  @override
  String toString() => 'Line(${done ? "x" : " "}, "$text", $minutes)';
}

/// บรรทัดที่ parse ไม่ออก — เก็บไว้ดิบๆ ห้ามทิ้ง
///
/// หลักการข้อ 4 บอกว่าข้อมูลเป็นของผู้ใช้ และไฟล์ต้องแก้ด้วย text editor ได้
/// ถ้าผู้ใช้เขียนอะไรที่เราไม่เข้าใจแล้วเราลบทิ้ง นั่นคือการทำลายข้อมูลของเขา
final class RawLine extends DayEntry {
  const RawLine(this.text);

  final String text;

  bool get isBlank => text.trim().isEmpty;

  @override
  bool operator ==(Object other) => other is RawLine && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'RawLine("$text")';
}

/// หนึ่งวัน = หนึ่งหน้า = หนึ่งไฟล์
class Day {
  Day({required DateTime date, List<DayEntry>? entries, this.journal = ''})
      : date = dateOnly(date),
        entries = List.unmodifiable(entries ?? const <DayEntry>[]);

  final DateTime date;
  final List<DayEntry> entries;

  /// ทุกอย่างใต้เส้น `---` เก็บดิบตามที่ผู้ใช้พิมพ์ ไม่ตัดช่องว่าง
  final String journal;

  /// เฉพาะรายการที่เรารู้จัก เรียงตามลำดับในไฟล์
  Iterable<Line> get lines => entries.whereType<Line>();

  /// เวลารวมของวัน หน่วยนาที — แสดงที่แถบล่างของหน้า `day` (§4.1)
  int get totalMinutes => lines.fold(0, (sum, l) => sum + l.minutes);

  /// วันที่ไม่มีอะไรเลย — ไฟล์แบบนี้ห้ามถูกสร้าง และถ้ามีอยู่ต้องถูกลบ (§2.1)
  bool get isEmpty =>
      journal.trim().isEmpty &&
      entries.every((e) => switch (e) {
            Line l => l.isBlank,
            RawLine r => r.isBlank,
          });

  /// ตำแหน่งใน [entries] ของรายการลำดับที่ [lineIndex]
  ///
  /// หน้าจอแสดงเฉพาะ [lines] แต่ [RawLine] ยังนั่งแทรกอยู่ในไฟล์ตามเดิม
  /// การแก้รายการจึงต้องแปลงลำดับที่ผู้ใช้เห็นกลับเป็นตำแหน่งจริงก่อนเสมอ
  /// คืน -1 ถ้าไม่มีรายการลำดับนั้น
  int entryIndexOfLine(int lineIndex) {
    var seen = 0;
    for (var i = 0; i < entries.length; i++) {
      if (entries[i] is! Line) continue;
      if (seen == lineIndex) return i;
      seen++;
    }
    return -1;
  }

  /// ตัดบรรทัดว่างที่ไม่มีทั้งชื่อและเวลาออก ก่อนเขียนลงไฟล์
  ///
  /// หน้า `day` สร้างบรรทัดว่างทันทีที่กด `+` ถ้าผู้ใช้ไม่พิมพ์อะไรแล้วเปลี่ยนวัน
  /// เราไม่ควรทิ้ง `- [ ]` เปล่าๆ ไว้ในไฟล์ · บรรทัดที่ไม่มีชื่อแต่ **มีเวลา** ต้องเก็บไว้
  /// เพราะการทิ้งมันคือการทำเวลาของผู้ใช้หาย
  Day pruned() => copyWith(
        entries: entries.where((e) => e is! Line || !e.isBlank).toList(),
      );

  Day copyWith({DateTime? date, List<DayEntry>? entries, String? journal}) =>
      Day(
        date: date ?? this.date,
        entries: entries ?? this.entries,
        journal: journal ?? this.journal,
      );

  @override
  String toString() =>
      'Day(${dateKey(date)}, ${entries.length} entries, ${totalMinutes}m)';
}

/// ตัดเวลาออกจาก [DateTime] เหลือแค่วัน ตามเขตเวลาของเครื่อง
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// `2026-08-18` — ทั้งชื่อไฟล์และคีย์ของดัชนีใช้รูปนี้
String dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// อ่านคีย์วันที่กลับเป็น [DateTime] · คืน null ถ้ารูปแบบไม่ตรง
DateTime? parseDateKey(String key) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
  if (m == null) return null;
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  final parsed = DateTime(y, mo, d);
  // ปัดวันที่ที่ไม่มีอยู่จริง เช่น 2026-02-31 ซึ่ง DateTime จะเลื่อนให้เอง
  if (parsed.month != mo || parsed.day != d) return null;
  return parsed;
}
