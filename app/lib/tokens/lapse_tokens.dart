// สร้างอัตโนมัติจาก ../docs/lapse-tokens.json — ห้ามแก้ไฟล์นี้ด้วยมือ
// แก้ที่ JSON แล้วรัน `dart run tool/gen_tokens.dart`
//
// โทเคนชุด Lapse Design Tokens v1.0.0

// animation.dart ให้ทั้ง Color และ Cubic
import 'package:flutter/animation.dart';

/// สีทั้งระบบ — เป็น role ไม่ใช่ hex ดิบ สลับธีมที่เดียวจบ
///
/// ไม่มีสีแบรนด์ในระบบนี้ · สีเดียวที่มีคือ [danger]
/// ซึ่งสงวนไว้ให้การลบข้อมูลถาวรเท่านั้น
class LapseColors {
  const LapseColors({
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.ink2,
    required this.inkMuted,
    required this.inkFaint,
    required this.rule,
    required this.ruleSoft,
    required this.void_,
    required this.danger,
    required this.wall,
  });

  /// พื้นหลังหลัก — กระดาษ
  final Color surface;

  /// แผ่นที่ยกขึ้นมา ใช้น้อยมาก
  final Color surfaceRaised;

  /// ข้อความหลัก
  final Color ink;

  /// ข้อความรอง
  final Color ink2;

  /// คำอธิบาย/placeholder
  final Color inkMuted;

  /// ห้ามใช้กับข้อความ — ใช้กับเครื่องหมายเท่านั้น
  final Color inkFaint;

  /// เส้นคั่น 1px
  final Color rule;

  /// พื้นตอน hover / กำลังกดค้าง
  final Color ruleSoft;

  /// จอโฟกัส — ดำสนิทเท่านั้น
  final Color void_;

  /// การทำลายข้อมูลเท่านั้น
  final Color danger;

  /// ไล่โทนของกำแพง 5 ขั้น อ่อน→เข้ม · ดัชนีคือระดับจาก `wallLevel`
  final List<Color> wall;

  static const light = LapseColors(
    surface: Color(0xFFF4F2ED),
    surfaceRaised: Color(0xFFFBFAF7),
    ink: Color(0xFF171614),
    ink2: Color(0xFF5C5A54),
    inkMuted: Color(0xFF8B877D),
    inkFaint: Color(0xFFCFCBC2),
    rule: Color(0xFFE3E0D8),
    ruleSoft: Color(0xFFEEEBE4),
    void_: Color(0xFF000000),
    danger: Color(0xFFA33A31),
    wall: <Color>[
      Color(0xFFE6E3DC),
      Color(0xFFC2BEB4),
      Color(0xFF918D83),
      Color(0xFF57544D),
      Color(0xFF1C1B18),
    ],
  );

  static const dark = LapseColors(
    surface: Color(0xFF151513),
    surfaceRaised: Color(0xFF1C1B19),
    ink: Color(0xFFF2F0EA),
    ink2: Color(0xFFA8A49A),
    inkMuted: Color(0xFF6B675F),
    inkFaint: Color(0xFF43413D),
    rule: Color(0xFF2B2A27),
    ruleSoft: Color(0xFF232220),
    void_: Color(0xFF000000),
    danger: Color(0xFFE07A6E),
    wall: <Color>[
      Color(0xFF242320),
      Color(0xFF454340),
      Color(0xFF6F6C65),
      Color(0xFFA8A49A),
      Color(0xFFF0EEE8),
    ],
  );
}

/// สอง family เท่านั้น และห้ามสลับกัน
///
/// - [mono] คือสิ่งที่ **เครื่อง** ใส่ — เวลา วันที่ ตัวเลข handle ป้าย
/// - [sans] คือสิ่งที่ **มนุษย์** พิมพ์ — ชื่องาน journal
enum LapseFontFamily {
  mono('IBM Plex Mono'),
  sans('IBM Plex Sans Thai');

  const LapseFontFamily(this.name);
  final String name;
}

/// สามน้ำหนัก ไม่มีตัวหนา — เน้นด้วยขนาดและพื้นที่ว่างแทน
class LapseWeight {
  const LapseWeight._();
  static const light = 300;
  static const regular = 400;
  static const medium = 500;
}

class LapseTypeScale {
  const LapseTypeScale({
    required this.size,
    required this.height,
    required this.trackingEm,
    required this.family,
    this.uppercase = false,
  });

  final double size;

  /// ตัวคูณระยะบรรทัด — ของข้อความไทยห้ามต่ำกว่า 1.8
  final double height;

  /// letter-spacing หน่วย em ตามที่โทเคนเขียนไว้
  final double trackingEm;

  final LapseFontFamily family;
  final bool uppercase;

  /// Flutter คิด letterSpacing เป็นพิกเซล ไม่ใช่ em
  double get letterSpacing => trackingEm * size;
}

/// สเกลตัวอักษรทั้งเจ็ดขั้น
class LapseType {
  const LapseType._();

  static const display = LapseTypeScale(
    size: 30.0,
    height: 1.1,
    trackingEm: 0.04,
    family: LapseFontFamily.mono,
  );

  static const title = LapseTypeScale(
    size: 21.0,
    height: 1.25,
    trackingEm: -0.01,
    family: LapseFontFamily.sans,
  );

  static const body = LapseTypeScale(
    size: 14.5,
    height: 1.85,
    trackingEm: 0.0,
    family: LapseFontFamily.sans,
  );

  static const mono = LapseTypeScale(
    size: 13.5,
    height: 1.55,
    trackingEm: 0.01,
    family: LapseFontFamily.mono,
  );

  static const label = LapseTypeScale(
    size: 12.5,
    height: 1.5,
    trackingEm: 0.02,
    family: LapseFontFamily.mono,
  );

  static const caption = LapseTypeScale(
    size: 11.0,
    height: 1.5,
    trackingEm: 0.06,
    family: LapseFontFamily.mono,
  );

  static const micro = LapseTypeScale(
    size: 10.0,
    height: 1.4,
    trackingEm: 0.16,
    family: LapseFontFamily.mono,
    uppercase: true,
  );
}

/// ระยะทั้งหมด ฐาน 4px
class LapseSpace {
  const LapseSpace._();
  static const s1 = 2.0;
  static const s2 = 4.0;
  static const s3 = 8.0;
  static const s4 = 12.0;
  static const s5 = 16.0;
  static const s6 = 20.0;
  static const s7 = 26.0;
  static const s8 = 34.0;
  static const s9 = 46.0;
  static const s10 = 64.0;

  /// ระยะขอบจอ
  static const gutter = 26.0;

  /// พื้นที่กดขั้นต่ำ แม้สิ่งที่มองเห็นจะเล็กกว่า
  static const touch = 44.0;
}

class LapseRadius {
  const LapseRadius._();
  static const cell = 2.0;
  static const box = 3.0;
  static const row = 5.0;
  static const pill = 20.0;
  static const device = 46.0;
}

class LapseBorder {
  const LapseBorder._();
  static const hairline = 1.0;
  static const stroke = 1.5;
}

/// จังหวะทั้งหมดของแอป
class LapseMotion {
  const LapseMotion._();
  static const quick = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 320);
  static const hold = Duration(milliseconds: 560);
  static const end = Duration(milliseconds: 720);
  static const fade = Duration(milliseconds: 1200);

  /// ใช้กับการเคลื่อนไหวทั่วไป
  static const out = Cubic(0.2, 0.7, 0.3, 1.0);
}

/// ระบบนี้ไม่มีเงา ระดับชั้นสร้างด้วยเส้นและพื้นเท่านั้น
const lapseHasShadow = false;
