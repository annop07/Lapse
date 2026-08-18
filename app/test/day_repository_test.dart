import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/data/day_repository.dart';
import 'package:lapse/model/day.dart';

void main() {
  late Directory tmp;
  late DayRepository repo;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('lapse_test');
    repo = await DayRepository.openAt(tmp);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('วันที่ยังไม่มีไฟล์คืนวันเปล่า ไม่ใช่ null', () async {
    final day = await repo.load(DateTime(2026, 8, 18));
    expect(day.isEmpty, isTrue);
    expect(await repo.fileFor(DateTime(2026, 8, 18)).exists(), isFalse);
  });

  test('เขียนแล้วอ่านกลับได้เหมือนเดิม', () async {
    final date = DateTime(2026, 8, 18);
    await repo.save(Day(
      date: date,
      entries: const [Line(text: 'อ่านเลข', done: true, minutes: 107)],
      journal: 'เช้าสมาธิดี',
    ));

    repo.forgetCache();
    final back = await repo.load(date);
    expect(back.lines.single.minutes, 107);
    expect(back.journal, 'เช้าสมาธิดี');
  });

  test('ไฟล์บนดิสก์อ่านรู้เรื่องด้วยตาเปล่า', () async {
    final date = DateTime(2026, 8, 18);
    await repo.save(Day(
      date: date,
      entries: const [Line(text: 'ท่องศัพท์ 50 คำ', done: true, minutes: 32)],
      journal: 'จำได้ครึ่งเดียว',
    ));

    expect(await repo.fileFor(date).readAsString(), '''
- [x] ท่องศัพท์ 50 คำ [0:32]

---
จำได้ครึ่งเดียว
''');
  });

  test('วันที่ไม่เหลืออะไรแล้วไม่มีไฟล์ค้างไว้', () async {
    final date = DateTime(2026, 8, 18);
    await repo.save(Day(date: date, entries: const [Line(text: 'a')]));
    expect(await repo.fileFor(date).exists(), isTrue);

    await repo.save(Day(date: date));
    expect(await repo.fileFor(date).exists(), isFalse);
  });

  test('บรรทัดเปล่าไม่ถูกเขียนลงไฟล์ แต่บรรทัดที่มีเวลาถูกเก็บไว้', () async {
    final date = DateTime(2026, 8, 18);
    await repo.save(Day(date: date, entries: const [
      Line(text: 'a'),
      Line(text: ''),
      Line(text: '', minutes: 30),
    ]));

    expect(await repo.fileFor(date).readAsString(), '- [ ] a\n- [ ] [0:30]\n');
  });

  test('แก้ไฟล์จากข้างนอกแล้วบรรทัดแปลกๆ ต้องไม่หาย', () async {
    final date = DateTime(2026, 8, 18);
    const edited = '# หมายเหตุที่พิมพ์เอง\n- [x] อ่านเลข [1:00]\n';
    await repo.fileFor(date).writeAsString(edited);

    repo.forgetCache();
    final day = await repo.load(date);
    await repo.save(day.copyWith(journal: 'เพิ่มบันทึก'));

    final onDisk = await repo.fileFor(date).readAsString();
    expect(onDisk, contains('# หมายเหตุที่พิมพ์เอง'));
    expect(onDisk, contains('- [x] อ่านเลข [1:00]'));
    expect(onDisk, contains('เพิ่มบันทึก'));
  });

  test('allDates เรียงจากเก่าไปใหม่และมองข้ามไฟล์ที่ไม่ใช่วัน', () async {
    for (final d in [DateTime(2026, 8, 18), DateTime(2026, 1, 1)]) {
      await repo.save(Day(date: d, entries: const [Line(text: 'a')]));
    }
    await File('${repo.daysDir.path}/README.md').writeAsString('ไม่ใช่วัน');
    await File('${repo.daysDir.path}/notes.txt').writeAsString('ไม่ใช่วัน');

    expect(await repo.allDates(), [DateTime(2026, 1, 1), DateTime(2026, 8, 18)]);
  });

  test('minutesByDate ข้ามวันที่ไม่มีเวลา', () async {
    await repo.save(Day(
      date: DateTime(2026, 8, 17),
      entries: const [Line(text: 'a', minutes: 107)],
    ));
    await repo.save(Day(
      date: DateTime(2026, 8, 18),
      entries: const [Line(text: 'b')],
      journal: 'อ่านไม่ลง',
    ));

    expect(await repo.minutesByDate(), {'2026-08-17': 107});
  });

  test('ลบข้อมูลทั้งหมดแล้วโครงยังอยู่', () async {
    await repo.save(Day(
      date: DateTime(2026, 8, 18),
      entries: const [Line(text: 'a')],
    ));
    await repo.deleteEverything();

    expect(await repo.allDates(), isEmpty);
    expect(await repo.daysDir.exists(), isTrue);
  });
}
