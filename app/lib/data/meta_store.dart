/// `meta.json` — ทุกอย่างที่ไม่ใช่เนื้อหารายวัน (§2.5)
///
/// ```json
/// {
///   "handle": "@jan",
///   "friends": [],
///   "theme": "auto",
///   "createdAt": "2026-01-01"
/// }
/// ```
///
/// v0 เพิ่มสองคีย์ที่สเปกไม่ได้เขียนไว้ คือ `onboardedAt` กับ `firstFocusDoneAt`
/// เพราะหน้า `focus` ต้องรู้ว่านี่เป็นครั้งแรกในชีวิตของผู้ใช้หรือยัง (§4.2)
/// ทั้งคู่เป็นวันที่ธรรมดา อ่านออกด้วยตาเปล่าเหมือนคีย์อื่น
library;

import 'dart:convert';

import '../i18n/strings.dart';
import 'dart:io';

enum ThemeChoice { auto, light, dark }

class Meta {
  const Meta({
    this.handle = '',
    this.friends = const [],
    this.theme = ThemeChoice.auto,
    this.language = Language.auto,
    this.createdAt,
    this.onboardedAt,
    this.firstFocusDoneAt,
  });

  final String handle;

  /// ยังไม่ถูกใช้ใน v0 แต่เก็บค่าที่อ่านมาไว้ เพื่อไม่ให้ข้อมูลหายถ้ามีอยู่แล้ว
  final List<String> friends;

  final ThemeChoice theme;

  /// ภาษาที่ผู้ใช้เลือก · auto = ตามภาษาของเครื่อง
  final Language language;
  final DateTime? createdAt;

  /// ผ่าน onboarding แล้วหรือยัง
  final DateTime? onboardedAt;

  /// จบ session แรกในชีวิตแล้วหรือยัง — ก่อนหน้านั้นคำใบ้ในหน้าโฟกัสต้องไม่จาง
  final DateTime? firstFocusDoneAt;

  bool get hasOnboarded => onboardedAt != null;
  bool get hasFinishedFirstFocus => firstFocusDoneAt != null;

  Meta copyWith({
    String? handle,
    List<String>? friends,
    ThemeChoice? theme,
    Language? language,
    DateTime? createdAt,
    DateTime? onboardedAt,
    DateTime? firstFocusDoneAt,
  }) =>
      Meta(
        handle: handle ?? this.handle,
        friends: friends ?? this.friends,
        theme: theme ?? this.theme,
        language: language ?? this.language,
        createdAt: createdAt ?? this.createdAt,
        onboardedAt: onboardedAt ?? this.onboardedAt,
        firstFocusDoneAt: firstFocusDoneAt ?? this.firstFocusDoneAt,
      );

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
        handle: json['handle'] as String? ?? '',
        friends:
            (json['friends'] as List?)?.whereType<String>().toList() ?? const [],
        theme: switch (json['theme']) {
          'light' => ThemeChoice.light,
          'dark' => ThemeChoice.dark,
          _ => ThemeChoice.auto,
        },
        language: switch (json['language']) {
          'thai' => Language.thai,
          'english' => Language.english,
          _ => Language.auto,
        },
        createdAt: _date(json['createdAt']),
        onboardedAt: _date(json['onboardedAt']),
        firstFocusDoneAt: _date(json['firstFocusDoneAt']),
      );

  Map<String, dynamic> toJson() => {
        'handle': handle,
        'friends': friends,
        'theme': theme.name,
        'language': language.name,
        if (createdAt != null) 'createdAt': _key(createdAt!),
        if (onboardedAt != null) 'onboardedAt': _key(onboardedAt!),
        if (firstFocusDoneAt != null)
          'firstFocusDoneAt': _key(firstFocusDoneAt!),
      };

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  static String _key(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class MetaStore {
  MetaStore(this.file);

  final File file;

  Future<Meta> load() async {
    if (!await file.exists()) return const Meta();
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return const Meta();
      return Meta.fromJson(raw);
    } on FormatException {
      // ไฟล์พังหรือถูกแก้มาผิด — ถอยไปใช้ค่าเริ่มต้น ดีกว่าเปิดแอปไม่ขึ้น
      // ไม่เขียนทับจนกว่าผู้ใช้จะเปลี่ยนการตั้งค่าจริงๆ
      return const Meta();
    }
  }

  Future<void> save(Meta meta) async {
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(meta.toJson())}\n',
      flush: true,
    );
    await tmp.rename(file.path);
  }
}
