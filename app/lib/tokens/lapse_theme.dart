/// ธีมของแอป — ไม่ผ่าน `ThemeData` ของ Material เลยแม้แต่ค่าเดียว
///
/// §6.4 ห้ามพึ่งสีจาก Material และ §5 บอกว่าสีทุกค่าต้องมาจากโทเคน
/// ไฟล์นี้คือทางเดียวที่คอมโพเนนต์จะได้สีและตัวอักษร
library;

import 'package:flutter/widgets.dart';

import 'lapse_tokens.dart';

/// ส่งชุดสีลงไปทั้งต้นไม้
class LapseTheme extends InheritedWidget {
  const LapseTheme({
    required this.colors,
    required this.isDark,
    required super.child,
    super.key,
  });

  final LapseColors colors;
  final bool isDark;

  static LapseTheme of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<LapseTheme>();
    assert(theme != null, 'ไม่มี LapseTheme อยู่เหนือ widget นี้');
    return theme!;
  }

  /// ทางลัดที่ใช้บ่อยที่สุด
  static LapseColors colorsOf(BuildContext context) => of(context).colors;

  @override
  bool updateShouldNotify(LapseTheme old) =>
      old.isDark != isDark || old.colors != colors;
}

/// สร้าง [TextStyle] จากสเกลในโทเคน
///
/// เรียกผ่านฟังก์ชันนี้เท่านั้น อย่าประกอบ [TextStyle] เองในคอมโพเนนต์
/// เพราะจะหลุด family หรือระยะบรรทัดโดยไม่รู้ตัว
TextStyle lapseTextStyle(
  LapseTypeScale scale, {
  required Color color,
  int weight = LapseWeight.regular,
}) =>
    TextStyle(
      fontFamily: scale.family.name,
      fontSize: scale.size,
      height: scale.height,
      letterSpacing: scale.letterSpacing,
      fontWeight: _weight(weight),
      color: color,
      // สระบนกับวรรณยุกต์ของไทยต้องการที่ว่างเหนือบรรทัด การกระจายระยะบรรทัด
      // แบบเท่ากันหัวท้ายทำให้ตัวอักษรไม่ถูกดันชิดขอบบน
      leadingDistribution: TextLeadingDistribution.even,
    );

/// ตัดการตัดขอบระยะบรรทัดของบรรทัดแรกและบรรทัดสุดท้ายออก
///
/// จำเป็นสำหรับข้อความไทย ไม่งั้นสระบนของบรรทัดแรกจะโดนตัด
const lapseTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: true,
  applyHeightToLastDescent: true,
  leadingDistribution: TextLeadingDistribution.even,
);

FontWeight _weight(int w) => FontWeight.values[(w ~/ 100) - 1];

/// ตัวคูณขนาดตัวอักษรของระบบที่เรายอมรับ
///
/// สเปกกำหนดขนาดเป็น px ตายตัว แต่การเมินการตั้งค่าของผู้ใช้ทั้งหมดคือปัญหา
/// การเข้าถึงจริง · เกิน 1.3 แล้วตารางกำแพงกับแถวรายการจะพัง จึงหนีบไว้เท่านี้
/// (ตัวเลขนี้ยังไม่ถูกยืนยันด้วยตาบนเครื่องจริง — ดู Phase 7)
const lapseMinTextScale = 1.0;
const lapseMaxTextScale = 1.3;

TextScaler clampTextScaler(TextScaler scaler) => switch (scaler) {
      TextScaler.noScaling => TextScaler.noScaling,
      _ => scaler.clamp(
          minScaleFactor: lapseMinTextScale,
          maxScaleFactor: lapseMaxTextScale,
        ),
    };
