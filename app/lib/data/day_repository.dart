/// ที่เก็บไฟล์รายวัน — ไฟล์คือ source of truth หน่วยความจำเป็นแค่ cache (§2.1)
///
/// ```
/// <เอกสารของแอป>/lapse/
/// ├── days/
/// │   ├── 2026-01-01.md
/// │   └── 2026-08-18.md
/// └── meta.json
/// ```
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../model/day.dart';
import 'day_file.dart';

class DayRepository {
  DayRepository._(this.root);

  /// โฟลเดอร์ `lapse/` ทั้งก้อน — ตัวที่ export ออกไปทั้งดุ้น
  final Directory root;

  final Map<String, Day> _cache = {};

  Directory get daysDir => Directory('${root.path}/days');

  File fileFor(DateTime date) =>
      File('${daysDir.path}/${dateKey(date)}.md');

  /// เปิดที่เก็บในโฟลเดอร์เอกสารของแอป · สร้างโครงให้ถ้ายังไม่มี
  static Future<DayRepository> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory('${docs.path}/lapse');
    final repo = DayRepository._(root);
    await repo.daysDir.create(recursive: true);
    return repo;
  }

  /// ใช้ในเทสต์ — ชี้ไปโฟลเดอร์ชั่วคราวแทนโฟลเดอร์เอกสารจริง
  static Future<DayRepository> openAt(Directory root) async {
    final repo = DayRepository._(root);
    await repo.daysDir.create(recursive: true);
    return repo;
  }

  /// อ่านวันหนึ่ง · วันที่ไม่มีไฟล์คืน [Day] เปล่า ไม่ใช่ null
  ///
  /// "วันว่างคือข้อเท็จจริง ไม่ใช่ความล้มเหลว" — ผู้เรียกจึงไม่ต้องเช็ก null
  Future<Day> load(DateTime date) async {
    final key = dateKey(date);
    final cached = _cache[key];
    if (cached != null) return cached;

    final file = fileFor(date);
    final day = await file.exists()
        ? parseDayFile(date, await file.readAsString())
        : Day(date: date);
    _cache[key] = day;
    return day;
  }

  /// เขียนวันหนึ่งลงไฟล์ · วันที่ไม่เหลืออะไรแล้วจะถูกลบไฟล์ทิ้ง (§2.1)
  ///
  /// เขียนลงไฟล์ชั่วคราวก่อนแล้วค่อย rename ทับ เพื่อไม่ให้ไฟล์ของผู้ใช้พังกลางคัน
  Future<Day> save(Day day) async {
    final pruned = day.pruned();
    _cache[dateKey(pruned.date)] = pruned;

    final file = fileFor(pruned.date);
    if (pruned.isEmpty) {
      if (await file.exists()) await file.delete();
      return pruned;
    }

    await daysDir.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(serializeDayFile(pruned), flush: true);
    await tmp.rename(file.path);
    return pruned;
  }

  /// ลืมของที่จำไว้ ให้ครั้งต่อไปอ่านจากไฟล์ใหม่
  ///
  /// ใช้ตอนกลับเข้าแอป เพราะผู้ใช้อาจไปแก้ไฟล์จากเครื่องอื่นระหว่างนั้น
  void forgetCache() => _cache.clear();

  /// รายชื่อวันที่ทั้งหมดที่มีไฟล์อยู่จริง เรียงจากเก่าไปใหม่
  Future<List<DateTime>> allDates() async {
    if (!await daysDir.exists()) return const [];
    final dates = <DateTime>[];
    await for (final entity in daysDir.list()) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      final name = entity.uri.pathSegments.last;
      final date = parseDateKey(name.substring(0, name.length - 3));
      if (date != null) dates.add(date);
    }
    dates.sort();
    return dates;
  }

  /// นาทีต่อวันของทั้งปี — ข้อมูลที่กำแพงต้องใช้ (§4.4)
  ///
  /// อ่านทุกไฟล์ตรงๆ ไม่ผ่านฐานข้อมูล หนึ่งปีคือ 365 ไฟล์ ไฟล์ละไม่กี่ร้อยไบต์
  /// ถ้าวันหนึ่งมันช้าจริงค่อยใส่ cache ทีหลัง อย่าเดาว่ามันช้าตั้งแต่ตอนนี้
  Future<Map<String, int>> minutesByDate() async {
    final result = <String, int>{};
    for (final date in await allDates()) {
      final day = await load(date);
      final minutes = day.totalMinutes;
      if (minutes > 0) result[dateKey(date)] = minutes;
    }
    return result;
  }

  /// ลบข้อมูลทั้งหมด — เรียกจากหน้า `settings` เท่านั้น
  Future<void> deleteEverything() async {
    _cache.clear();
    if (await root.exists()) await root.delete(recursive: true);
    await daysDir.create(recursive: true);
  }
}
