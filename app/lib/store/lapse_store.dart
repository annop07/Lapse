/// สถานะทั้งแอปอยู่ในคลาสเดียว
///
/// §6.4 บอกให้ใช้ state management ที่เบาที่สุดที่พอใช้ แอปนี้มีหน้าหลักสามหน้า
/// และข้อมูลก้อนเดียว `ChangeNotifier` จึงพอแล้ว ไม่ต้องลงแพ็กเกจเพิ่ม
///
/// ทุกการแก้ไขเขียนลงไฟล์ทันที ไม่มีปุ่มบันทึกในแอปนี้ — แผนของตอนเช้า
/// กลายเป็นบันทึกของตอนเย็นโดยที่ผู้ใช้ไม่เคยต้องกดอะไร
library;

import 'dart:io';

import 'package:flutter/widgets.dart';

import '../data/day_repository.dart';
import '../data/meta_store.dart';
import '../model/day.dart';

class LapseStore extends ChangeNotifier {
  LapseStore._(this._days, this._metaFile, this._meta, this._day);

  final DayRepository _days;
  final MetaStore _metaFile;

  Meta _meta;
  Day _day;

  Meta get meta => _meta;
  Day get day => _day;
  DateTime get cursor => _day.date;

  /// วันนี้ตามเขตเวลาของเครื่อง — คำนวณใหม่ทุกครั้งเพราะแอปอาจเปิดค้างข้ามคืน
  DateTime get today => dateOnly(DateTime.now());

  /// ห้ามเลื่อนไปวันอนาคต (§4.1)
  bool get canGoForward => cursor.isBefore(today);

  static Future<LapseStore> open() async =>
      _from(await DayRepository.open());

  /// ใช้ในเทสต์ — ชี้ไปโฟลเดอร์ชั่วคราวแทนโฟลเดอร์เอกสารจริง
  static Future<LapseStore> openAt(Directory root) async =>
      _from(await DayRepository.openAt(root));

  static Future<LapseStore> _from(DayRepository days) async {
    final metaFile = MetaStore(File('${days.root.path}/meta.json'));
    final meta = await metaFile.load();
    final day = await days.load(dateOnly(DateTime.now()));
    return LapseStore._(days, metaFile, meta, day);
  }

  Future<void> goTo(DateTime date) async {
    final target = dateOnly(date);
    if (target.isAfter(today)) return;
    _day = await _days.load(target);
    notifyListeners();
  }

  Future<void> goBackOneDay() =>
      goTo(cursor.subtract(const Duration(days: 1)));

  Future<void> goForwardOneDay() async {
    if (!canGoForward) return;
    await goTo(cursor.add(const Duration(days: 1)));
  }

  /// อ่านไฟล์ของวันปัจจุบันใหม่ เผื่อถูกแก้จากข้างนอกระหว่างที่แอปหลับ
  Future<void> reload() async {
    _days.forgetCache();
    _day = await _days.load(cursor);
    notifyListeners();
  }

  // ---- การแก้ไขรายการ ----

  /// เพิ่มบรรทัดว่างท้ายรายการ แล้วคืนลำดับของมันเพื่อให้หน้าจอโฟกัสเคอร์เซอร์ต่อ
  ///
  /// ยังไม่เขียนลงไฟล์ เพราะบรรทัดว่างไม่ควรถูกบันทึก จนกว่าจะมีชื่อหรือมีเวลา
  int addLine() {
    _day = _day.copyWith(entries: [..._day.entries, const Line(text: '')]);
    notifyListeners();
    return _day.lines.length - 1;
  }

  Future<void> setLineText(int lineIndex, String text) =>
      _updateLine(lineIndex, (line) => line.copyWith(text: text));

  Future<void> toggleLine(int lineIndex) =>
      _updateLine(lineIndex, (line) => line.copyWith(done: !line.done));

  /// บวกเวลาที่เพิ่งโฟกัสเข้ารายการ (§4.3 ขั้นที่ 1)
  Future<void> addMinutes(int lineIndex, int minutes) {
    if (minutes <= 0) return Future.value();
    return _updateLine(
      lineIndex,
      (line) => line.copyWith(minutes: line.minutes + minutes),
    );
  }

  Future<void> removeLine(int lineIndex) {
    final at = _day.entryIndexOfLine(lineIndex);
    if (at < 0) return Future.value();
    final entries = [..._day.entries]..removeAt(at);
    return _commit(_day.copyWith(entries: entries));
  }

  Future<void> _updateLine(int lineIndex, Line Function(Line) change) {
    final at = _day.entryIndexOfLine(lineIndex);
    if (at < 0) return Future.value();
    final entries = [..._day.entries];
    entries[at] = change(entries[at] as Line);
    return _commit(_day.copyWith(entries: entries));
  }

  Future<void> setJournal(String text) =>
      _commit(_day.copyWith(journal: text));

  Future<void> _commit(Day next) async {
    _day = next;
    notifyListeners();
    // เขียนทับด้วยผลของ pruned ที่ repository คืนกลับมาไม่ได้
    // เพราะผู้ใช้อาจกำลังพิมพ์อยู่ในบรรทัดว่างที่ pruned จะตัดทิ้ง
    await _days.save(next);
  }

  // ---- กำแพง ----

  Future<Map<String, int>> minutesByDate() => _days.minutesByDate();

  /// อ่านวันหนึ่งโดยไม่ย้ายวันที่กำลังดูอยู่
  ///
  /// แผงรายละเอียดของกำแพงใช้ตัวนี้ การแตะดูวันเก่าไม่ควรพาผู้ใช้ออกจากวันนี้
  Future<Day> dayAt(DateTime date) => _days.load(dateOnly(date));

  // ---- meta ----

  Future<void> setTheme(ThemeChoice choice) =>
      _saveMeta(_meta.copyWith(theme: choice));

  Future<void> setHandle(String handle) =>
      _saveMeta(_meta.copyWith(handle: handle));

  Future<void> markOnboarded() => _meta.hasOnboarded
      ? Future.value()
      : _saveMeta(_meta.copyWith(onboardedAt: today));

  /// จบ session แรกในชีวิตแล้ว — หลังจากนี้คำใบ้ในหน้าโฟกัสค่อยหรี่ถาวร (§4.2)
  Future<void> markFirstFocusDone() => _meta.hasFinishedFirstFocus
      ? Future.value()
      : _saveMeta(_meta.copyWith(firstFocusDoneAt: today));

  Future<void> _saveMeta(Meta next) async {
    _meta = next;
    notifyListeners();
    await _metaFile.save(next);
  }

  Future<void> deleteEverything() async {
    await _days.deleteEverything();
    _meta = const Meta();
    await _metaFile.save(_meta);
    _day = Day(date: today);
    notifyListeners();
  }
}
