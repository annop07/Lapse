import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/data/meta_store.dart';
import 'package:lapse/i18n/strings.dart';

void main() {
  late Directory tmp;
  late MetaStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('lapse_meta');
    store = MetaStore(File('${tmp.path}/meta.json'));
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('ยังไม่มีไฟล์ได้ค่าเริ่มต้น', () async {
    final meta = await store.load();
    expect(meta.handle, isEmpty);
    expect(meta.theme, ThemeChoice.auto);
    expect(meta.hasOnboarded, isFalse);
    expect(meta.hasFinishedFirstFocus, isFalse);
  });

  test('เขียนแล้วอ่านกลับ', () async {
    await store.save(Meta(
      handle: '@jan',
      theme: ThemeChoice.dark,
      createdAt: DateTime(2026, 1, 1),
      onboardedAt: DateTime(2026, 1, 1),
    ));

    final meta = await store.load();
    expect(meta.handle, '@jan');
    expect(meta.theme, ThemeChoice.dark);
    expect(meta.createdAt, DateTime(2026, 1, 1));
    expect(meta.hasOnboarded, isTrue);
    expect(meta.hasFinishedFirstFocus, isFalse);
  });

  test('รูปแบบบนดิสก์ตรงกับ §2.5 และอ่านออกด้วยตาเปล่า', () async {
    await store.save(Meta(
      handle: '@jan',
      friends: const ['@ploy', '@nine'],
      createdAt: DateTime(2026, 1, 1),
    ));

    expect(await store.file.readAsString(), '''
{
  "handle": "@jan",
  "friends": [
    "@ploy",
    "@nine"
  ],
  "theme": "auto",
  "language": "auto",
  "createdAt": "2026-01-01"
}
''');
  });

  test('ภาษาที่เลือกถูกเขียนและอ่านกลับ', () async {
    await store.save(const Meta(language: Language.english));
    expect((await store.load()).language, Language.english);
  });

  test('ไฟล์เก่าที่ไม่มีคีย์ภาษาได้ค่าตามระบบ', () async {
    await store.file.writeAsString('{"handle":"@jan","theme":"dark"}');
    expect((await store.load()).language, Language.auto);
  });

  test('ไฟล์พังไม่ทำให้เปิดแอปไม่ขึ้น', () async {
    await store.file.writeAsString('{ นี่ไม่ใช่ json');
    expect((await store.load()).theme, ThemeChoice.auto);
  });

  test('เก็บรายชื่อเพื่อนที่มีอยู่แล้วไว้ แม้ v0 จะยังไม่ใช้', () async {
    await store.file.writeAsString('{"friends":["@ploy"],"handle":"@jan"}');
    final meta = await store.load();
    expect(meta.friends, ['@ploy']);
  });
}
