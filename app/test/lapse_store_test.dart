import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/data/meta_store.dart';
import 'package:lapse/model/day.dart';
import 'package:lapse/store/lapse_store.dart';

void main() {
  late Directory tmp;
  late LapseStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('lapse_store');
    store = await LapseStore.openAt(tmp);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  File fileFor(DateTime d) => File('${tmp.path}/days/${dateKey(d)}.md');

  test('เปิดมาที่วันนี้', () {
    expect(store.cursor, dateOnly(DateTime.now()));
  });

  test('ห้ามเลื่อนไปวันอนาคต', () async {
    expect(store.canGoForward, isFalse);

    await store.goForwardOneDay();
    expect(store.cursor, dateOnly(DateTime.now()));

    await store.goTo(DateTime.now().add(const Duration(days: 3)));
    expect(store.cursor, dateOnly(DateTime.now()));
  });

  test('ถอยหลังได้ไม่จำกัด แล้วเดินหน้ากลับมาได้', () async {
    await store.goBackOneDay();
    expect(store.canGoForward, isTrue);

    await store.goForwardOneDay();
    expect(store.cursor, dateOnly(DateTime.now()));
  });

  test('บรรทัดว่างยังไม่ถูกเขียนลงไฟล์', () async {
    store.addLine();
    expect(store.day.lines.length, 1);
    expect(await fileFor(store.cursor).exists(), isFalse);
  });

  test('พอมีชื่อแล้วไฟล์ถึงเกิด', () async {
    final at = store.addLine();
    await store.setLineText(at, 'อ่านเลข');

    expect(await fileFor(store.cursor).readAsString(), '- [ ] อ่านเลข\n');
  });

  test('ติ๊กแล้วสถานะสลับและถูกบันทึก', () async {
    final at = store.addLine();
    await store.setLineText(at, 'อ่านเลข');
    await store.toggleLine(at);

    expect(store.day.lines.single.done, isTrue);
    expect(await fileFor(store.cursor).readAsString(), '- [x] อ่านเลข\n');
  });

  test('เวลาที่โฟกัสได้ถูกบวกสะสม', () async {
    final at = store.addLine();
    await store.setLineText(at, 'อ่านเลข');
    await store.addSeconds(at, 2820);
    await store.addSeconds(at, 3600);

    expect(store.day.lines.single.seconds, 6420);
    expect(await fileFor(store.cursor).readAsString(),
        '- [ ] อ่านเลข [1:47:00]\n');
  });

  test('บวกเวลาศูนย์หรือติดลบไม่ทำอะไร', () async {
    final at = store.addLine();
    await store.setLineText(at, 'อ่านเลข');
    await store.addSeconds(at, 0);
    await store.addSeconds(at, -5);

    expect(store.day.lines.single.seconds, 0);
  });

  test('journal ถูกบันทึกและอยู่ใต้เส้นคั่น', () async {
    final at = store.addLine();
    await store.setLineText(at, 'อ่านเลข');
    await store.setJournal('เช้าสมาธิดี');

    expect(await fileFor(store.cursor).readAsString(),
        '- [ ] อ่านเลข\n\n---\nเช้าสมาธิดี\n');
  });

  test('แก้รายการได้ถูกตัวแม้จะมีบรรทัดแปลกปนอยู่', () async {
    final date = dateOnly(DateTime.now());
    await fileFor(date).parent.create(recursive: true);
    await fileFor(date).writeAsString(
      '# ของผู้ใช้\n- [ ] หนึ่ง\n* แปลก\n- [ ] สอง\n',
    );
    await store.reload();

    await store.setLineText(1, 'สองแก้แล้ว');

    final onDisk = await fileFor(date).readAsString();
    expect(onDisk, '# ของผู้ใช้\n- [ ] หนึ่ง\n* แปลก\n- [ ] สองแก้แล้ว\n');
  });

  test('ลบรายการแล้วบรรทัดอื่นยังอยู่ครบ', () async {
    final a = store.addLine();
    await store.setLineText(a, 'หนึ่ง');
    final b = store.addLine();
    await store.setLineText(b, 'สอง');

    await store.removeLine(0);
    expect(store.day.lines.single.text, 'สอง');
  });

  test('meta ถูกเขียนและอ่านกลับได้', () async {
    await store.setHandle('@jan');
    await store.setTheme(ThemeChoice.dark);
    await store.markFirstFocusDone();

    final reopened = await LapseStore.openAt(tmp);
    expect(reopened.meta.handle, '@jan');
    expect(reopened.meta.theme, ThemeChoice.dark);
    expect(reopened.meta.hasFinishedFirstFocus, isTrue);
  });

  test('ลบข้อมูลทั้งหมดแล้วเหลือวันเปล่า', () async {
    final at = store.addLine();
    await store.setLineText(at, 'อ่านเลข');
    await store.setHandle('@jan');

    await store.deleteEverything();

    expect(store.day.isEmpty, isTrue);
    expect(store.meta.handle, isEmpty);
    expect(await store.secondsByDate(), isEmpty);
  });

  test('minutesByDate เห็นวันที่มีเวลาเท่านั้น', () async {
    final at = store.addLine();
    await store.setLineText(at, 'อ่านเลข');
    await store.addSeconds(at, 5400);

    expect(await store.secondsByDate(), {dateKey(store.cursor): 5400});
  });
}
