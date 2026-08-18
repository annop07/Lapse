import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/data/day_file.dart';
import 'package:lapse/model/day.dart';

final _d = DateTime(2026, 8, 18);

void main() {
  group('parse', () {
    test('ตัวอย่างในสเปก §2.2', () {
      const src = '''
- [x] อ่านเลข บทที่ 4 [1:47:00]
- [x] ท่องศัพท์ 50 คำ [0:32:00]
- [ ] สรุปฟิสิกส์

---
เช้าสมาธิดีมาก บ่ายไม่ไหวเลย
พรุ่งนี้ย้ายฟิสิกส์มาไว้เช้า
''';
      final day = parseDayFile(_d, src);

      expect(day.lines.toList(), [
        const Line(text: 'อ่านเลข บทที่ 4', done: true, seconds: 6420),
        const Line(text: 'ท่องศัพท์ 50 คำ', done: true, seconds: 1920),
        const Line(text: 'สรุปฟิสิกส์'),
      ]);
      expect(day.journal,
          'เช้าสมาธิดีมาก บ่ายไม่ไหวเลย\nพรุ่งนี้ย้ายฟิสิกส์มาไว้เช้า');
      expect(day.totalSeconds, 8340);
    });

    test('ไฟล์ว่างได้วันเปล่า', () {
      expect(parseDayFile(_d, '').entries, isEmpty);
      expect(parseDayFile(_d, '\n').entries, isEmpty);
      expect(parseDayFile(_d, '').isEmpty, isTrue);
    });

    test('ไฟล์ที่มีแต่ journal', () {
      final day = parseDayFile(_d, '---\nวันนี้ไม่ได้อ่านอะไรเลย\n');
      expect(day.entries, isEmpty);
      expect(day.journal, 'วันนี้ไม่ได้อ่านอะไรเลย');
      expect(day.isEmpty, isFalse);
    });

    test('ไฟล์ที่มีแต่รายการ ไม่มีเส้นคั่น', () {
      final day = parseDayFile(_d, '- [ ] สรุปฟิสิกส์\n');
      expect(day.journal, isEmpty);
      expect(day.lines.single.text, 'สรุปฟิสิกส์');
    });

    test('รายการที่ยังไม่เสร็จแต่มีเวลาแล้ว', () {
      final day = parseDayFile(_d, '- [ ] อ่านเลข [0:12:34]\n');
      expect(day.lines.single,
          const Line(text: 'อ่านเลข', done: false, seconds: 754));
    });

    test('อ่านไฟล์รูปแบบเดิมที่ไม่มีวินาทีได้ถูกต้อง', () {
      // ไฟล์ที่ผู้ใช้มีอยู่ก่อนเปลี่ยนหน่วยต้องไม่เพี้ยน
      final day = parseDayFile(_d, '- [x] อ่านเลข [1:47]\n');
      expect(day.lines.single.seconds, 6420);
    });

    test('เขียนกลับเป็นรูปแบบใหม่เสมอ', () {
      final day = parseDayFile(_d, '- [x] อ่านเลข [1:47]\n');
      expect(serializeDayFile(day), '- [x] อ่านเลข [1:47:00]\n');
    });

    test('รับ CRLF', () {
      final day = parseDayFile(_d, '- [x] a [1:00]\r\n\r\n---\r\nบันทึก\r\n');
      expect(day.lines.single.seconds, 3600);
      expect(day.journal, 'บันทึก');
    });

    test('ยอมรับ [X] ตัวใหญ่ตอนอ่าน', () {
      expect(parseDayFile(_d, '- [X] a\n').lines.single.done, isTrue);
    });

    test('ชั่วโมงหลายหลัก', () {
      expect(parseDayFile(_d, '- [x] a [12:05:09]\n').lines.single.seconds, 43509);
    });

    test('เวลาจับเฉพาะที่ท้ายบรรทัด', () {
      final day = parseDayFile(_d, '- [ ] อ่าน [1:47:00] ต่อจากเมื่อวาน\n');
      expect(day.lines.single.seconds, 0);
      expect(day.lines.single.text, 'อ่าน [1:47:00] ต่อจากเมื่อวาน');
    });

    test('นาทีเกิน 59 ไม่ใช่เวลา', () {
      final day = parseDayFile(_d, '- [ ] อ่านหน้า [1:99]\n');
      expect(day.lines.single.seconds, 0);
      expect(day.lines.single.text, 'อ่านหน้า [1:99]');
    });

    test('บรรทัดที่ parse ไม่ออกต้องไม่หาย', () {
      const src = '# หัวข้อที่ผู้ใช้เขียนเอง\n- [x] a\n* ไม่ใช่รูปแบบเรา\n';
      final day = parseDayFile(_d, src);
      expect(day.entries.length, 3);
      expect(day.entries[0], const RawLine('# หัวข้อที่ผู้ใช้เขียนเอง'));
      expect(day.entries[2], const RawLine('* ไม่ใช่รูปแบบเรา'));
      expect(serializeDayFile(day), src);
    });

    test('--- ตัวที่สองเป็นข้อความใน journal', () {
      final day = parseDayFile(_d, '- [x] a\n\n---\nบรรทัดแรก\n---\nบรรทัดสาม\n');
      expect(day.journal, 'บรรทัดแรก\n---\nบรรทัดสาม');
    });

    test('รักษาช่องว่างใน journal ไว้ตามที่ผู้ใช้พิมพ์', () {
      final day = parseDayFile(_d, '---\n\n  เว้นบรรทัดแล้วย่อหน้า\n');
      expect(day.journal, '\n  เว้นบรรทัดแล้วย่อหน้า');
    });
  });

  group('serialize', () {
    test('เขียนกลับได้เหมือนตัวอย่างในสเปก', () {
      final day = Day(
        date: _d,
        entries: const [
          Line(text: 'อ่านเลข บทที่ 4', done: true, seconds: 6420),
          Line(text: 'ท่องศัพท์ 50 คำ', done: true, seconds: 1920),
          Line(text: 'สรุปฟิสิกส์'),
        ],
        journal: 'เช้าสมาธิดีมาก บ่ายไม่ไหวเลย',
      );
      expect(serializeDayFile(day), '''
- [x] อ่านเลข บทที่ 4 [1:47:00]
- [x] ท่องศัพท์ 50 คำ [0:32:00]
- [ ] สรุปฟิสิกส์

---
เช้าสมาธิดีมาก บ่ายไม่ไหวเลย
''');
    });

    test('บรรทัดที่มีเวลาแต่ยังไม่มีชื่อ', () {
      final day = Day(date: _d, entries: const [Line(text: '', seconds: 3600)]);
      expect(serializeDayFile(day), '- [ ] [1:00:00]\n');
    });

    test('journal ที่มีแต่ช่องว่างไม่ทำให้เกิดเส้นคั่น', () {
      final day = Day(date: _d, entries: const [Line(text: 'a')], journal: '  \n ');
      expect(serializeDayFile(day), '- [ ] a\n');
    });
  });

  group('round trip', () {
    const samples = [
      '- [x] อ่านเลข บทที่ 4 [1:47:00]\n- [ ] สรุปฟิสิกส์\n\n---\nบันทึกของวัน\n',
      '- [ ] a\n',
      '---\nมีแต่บันทึก\n',
      '# ของผู้ใช้\n- [x] b [0:05:00]\n\n---\nบรรทัดแรก\n---\nบรรทัดสาม\n',
      '- [ ] [2:30:15]\n',
    ];

    for (var i = 0; i < samples.length; i++) {
      test('ตัวอย่างที่ $i กลับไปกลับมาแล้วเหมือนเดิม', () {
        final once = parseDayFile(_d, samples[i]);
        final text = serializeDayFile(once);
        expect(text, samples[i]);
        expect(serializeDayFile(parseDayFile(_d, text)), text);
      });
    }
  });

  group('Day', () {
    test('isEmpty ไม่สนใจบรรทัดว่าง', () {
      final day = Day(
        date: _d,
        entries: const [RawLine(''), Line(text: '   ')],
        journal: '  ',
      );
      expect(day.isEmpty, isTrue);
    });

    test('pruned ตัดบรรทัดเปล่า แต่เก็บบรรทัดที่มีเวลา', () {
      final day = Day(
        date: _d,
        entries: const [
          Line(text: 'a'),
          Line(text: ''),
          Line(text: '', seconds: 1800),
        ],
      );
      final kept = day.pruned().entries;
      expect(kept.length, 2);
      expect((kept[1] as Line).seconds, 1800);
    });

    test('totalMinutes รวมเฉพาะรายการ', () {
      final day = Day(date: _d, entries: const [
        Line(text: 'a', seconds: 6420),
        RawLine('ข้อความอื่น'),
        Line(text: 'b', seconds: 1920),
      ]);
      expect(day.totalSeconds, 8340);
    });
  });

  group('dateKey', () {
    test('เขียนและอ่านกลับ', () {
      expect(dateKey(DateTime(2026, 1, 1)), '2026-01-01');
      expect(dateKey(DateTime(2026, 8, 18)), '2026-08-18');
      expect(parseDateKey('2026-08-18'), DateTime(2026, 8, 18));
    });

    test('ปฏิเสธรูปแบบและวันที่ที่ไม่มีจริง', () {
      expect(parseDateKey('2026-8-18'), isNull);
      expect(parseDateKey('2026-13-01'), isNull);
      expect(parseDateKey('2026-02-31'), isNull);
      expect(parseDateKey('meta.json'), isNull);
    });
  });
}
