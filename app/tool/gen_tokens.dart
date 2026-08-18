/// สร้าง `lib/tokens/lapse_tokens.dart` จาก `docs/lapse-tokens.json`
///
/// รันด้วย `dart run tool/gen_tokens.dart` จากโฟลเดอร์ `app/`
///
/// มีสคริปต์นี้เพราะ CLAUDE.md บอกว่าสีทุกค่ามาจากโทเคน ถ้าพิมพ์ค่าลง Dart ด้วยมือ
/// อีกสองสัปดาห์ไฟล์สองฝั่งจะเพี้ยนจากกันโดยไม่มีใครรู้ตัว
library;

import 'dart:convert';
import 'dart:io';

const _source = '../docs/lapse-tokens.json';
const _target = 'lib/tokens/lapse_tokens.dart';

void main() {
  final file = File(_source);
  if (!file.existsSync()) {
    stderr.writeln('หาไฟล์โทเคนไม่เจอ: $_source');
    exit(1);
  }

  final t = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final out = StringBuffer()
    ..writeln('// สร้างอัตโนมัติจาก $_source — ห้ามแก้ไฟล์นี้ด้วยมือ')
    ..writeln('// แก้ที่ JSON แล้วรัน `dart run tool/gen_tokens.dart`')
    ..writeln('//')
    ..writeln('// โทเคนชุด ${t['name']} v${t['version']}')
    ..writeln()
    ..writeln("// animation.dart ให้ทั้ง Color และ Cubic")
    ..writeln("import 'package:flutter/animation.dart';")
    ..writeln()
    ..write(_colors(t['color'] as Map<String, dynamic>))
    ..write(_type(t['type'] as Map<String, dynamic>))
    ..write(_space(t['space'] as Map<String, dynamic>))
    ..write(_radius(t['radius'] as Map<String, dynamic>))
    ..write(_border(t['border'] as Map<String, dynamic>))
    ..write(_motion(t['motion'] as Map<String, dynamic>));

  final target = File(_target)..parent.createSync(recursive: true);
  target.writeAsStringSync(out.toString());
  stdout.writeln('เขียน $_target แล้ว');
}

String _hex(String css) => '0xFF${css.substring(1).toUpperCase()}';

const _roles = [
  ('surface', 'พื้นหลังหลัก — กระดาษ'),
  ('surfaceRaised', 'แผ่นที่ยกขึ้นมา ใช้น้อยมาก'),
  ('ink', 'ข้อความหลัก'),
  ('ink2', 'ข้อความรอง'),
  ('inkMuted', 'คำอธิบาย/placeholder'),
  ('inkFaint', 'ห้ามใช้กับข้อความ — ใช้กับเครื่องหมายเท่านั้น'),
  ('rule', 'เส้นคั่น 1px'),
  ('ruleSoft', 'พื้นตอน hover / กำลังกดค้าง'),
  ('void_', 'จอโฟกัส — ดำสนิทเท่านั้น'),
  ('danger', 'การทำลายข้อมูลเท่านั้น'),
];

String _key(String field) => field == 'void_' ? 'void' : field;

String _colorSet(Map<String, dynamic> set) {
  final b = StringBuffer('LapseColors(\n');
  for (final (field, _) in _roles) {
    b.writeln('    $field: Color(${_hex(set[_key(field)] as String)}),');
  }
  final wall = (set['wall'] as List).cast<String>();
  b.writeln('    wall: <Color>[');
  for (final c in wall) {
    b.writeln('      Color(${_hex(c)}),');
  }
  b.writeln('    ],');
  b.write('  )');
  return b.toString();
}

String _colors(Map<String, dynamic> color) {
  final b = StringBuffer()
    ..writeln('/// สีทั้งระบบ — เป็น role ไม่ใช่ hex ดิบ สลับธีมที่เดียวจบ')
    ..writeln('///')
    ..writeln('/// ไม่มีสีแบรนด์ในระบบนี้ · สีเดียวที่มีคือ [danger]')
    ..writeln('/// ซึ่งสงวนไว้ให้การลบข้อมูลถาวรเท่านั้น')
    ..writeln('class LapseColors {')
    ..writeln('  const LapseColors({');
  for (final (field, _) in _roles) {
    b.writeln('    required this.$field,');
  }
  b
    ..writeln('    required this.wall,')
    ..writeln('  });')
    ..writeln();
  for (final (field, note) in _roles) {
    b
      ..writeln('  /// $note')
      ..writeln('  final Color $field;')
      ..writeln();
  }
  b
    ..writeln('  /// ไล่โทนของกำแพง 5 ขั้น อ่อน→เข้ม · ดัชนีคือระดับจาก `wallLevel`')
    ..writeln('  final List<Color> wall;')
    ..writeln()
    ..writeln('  static const light = ${_colorSet(color['light'] as Map<String, dynamic>)};')
    ..writeln()
    ..writeln('  static const dark = ${_colorSet(color['dark'] as Map<String, dynamic>)};')
    ..writeln('}')
    ..writeln();
  return b.toString();
}

String _type(Map<String, dynamic> type) {
  final families = type['families'] as Map<String, dynamic>;
  final scale = type['scale'] as Map<String, dynamic>;
  final weights = type['weights'] as Map<String, dynamic>;

  final b = StringBuffer()
    ..writeln('/// สอง family เท่านั้น และห้ามสลับกัน')
    ..writeln('///')
    ..writeln('/// - [mono] คือสิ่งที่ **เครื่อง** ใส่ — เวลา วันที่ ตัวเลข handle ป้าย')
    ..writeln('/// - [sans] คือสิ่งที่ **มนุษย์** พิมพ์ — ชื่องาน journal')
    ..writeln('enum LapseFontFamily {')
    ..writeln("  mono('${families['mono']}'),")
    ..writeln("  sans('${families['sans']}');")
    ..writeln()
    ..writeln('  const LapseFontFamily(this.name);')
    ..writeln('  final String name;')
    ..writeln('}')
    ..writeln()
    ..writeln('/// สามน้ำหนัก ไม่มีตัวหนา — เน้นด้วยขนาดและพื้นที่ว่างแทน')
    ..writeln('class LapseWeight {')
    ..writeln('  const LapseWeight._();')
    ..writeln('  static const light = ${weights['light']};')
    ..writeln('  static const regular = ${weights['regular']};')
    ..writeln('  static const medium = ${weights['medium']};')
    ..writeln('}')
    ..writeln()
    ..writeln('class LapseTypeScale {')
    ..writeln('  const LapseTypeScale({')
    ..writeln('    required this.size,')
    ..writeln('    required this.height,')
    ..writeln('    required this.trackingEm,')
    ..writeln('    required this.family,')
    ..writeln('    this.uppercase = false,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final double size;')
    ..writeln()
    ..writeln('  /// ตัวคูณระยะบรรทัด — ของข้อความไทยห้ามต่ำกว่า 1.8')
    ..writeln('  final double height;')
    ..writeln()
    ..writeln('  /// letter-spacing หน่วย em ตามที่โทเคนเขียนไว้')
    ..writeln('  final double trackingEm;')
    ..writeln()
    ..writeln('  final LapseFontFamily family;')
    ..writeln('  final bool uppercase;')
    ..writeln()
    ..writeln('  /// Flutter คิด letterSpacing เป็นพิกเซล ไม่ใช่ em')
    ..writeln('  double get letterSpacing => trackingEm * size;')
    ..writeln('}')
    ..writeln()
    ..writeln('/// สเกลตัวอักษรทั้งเจ็ดขั้น')
    ..writeln('class LapseType {')
    ..writeln('  const LapseType._();');

  for (final entry in scale.entries) {
    final v = entry.value as Map<String, dynamic>;
    final tracking = (v['tracking'] as String).replaceAll('em', '');
    final upper = v['transform'] == 'uppercase';
    b
      ..writeln()
      ..writeln('  static const ${entry.key} = LapseTypeScale(')
      ..writeln('    size: ${(v['size'] as num).toDouble()},')
      ..writeln('    height: ${(v['lineHeight'] as num).toDouble()},')
      ..writeln('    trackingEm: ${double.parse(tracking)},')
      ..writeln('    family: LapseFontFamily.${v['family']},')
      ..writeln(upper ? '    uppercase: true,' : '')
      ..writeln('  );');
  }
  b
    ..writeln('}')
    ..writeln();
  return b.toString().replaceAll('\n\n  );', '\n  );');
}

String _space(Map<String, dynamic> space) {
  final scale = (space['scale'] as List).cast<num>();
  final b = StringBuffer()
    ..writeln('/// ระยะทั้งหมด ฐาน ${space['base']}px')
    ..writeln('class LapseSpace {')
    ..writeln('  const LapseSpace._();');
  for (var i = 0; i < scale.length; i++) {
    b.writeln('  static const s${i + 1} = ${scale[i].toDouble()};');
  }
  b
    ..writeln()
    ..writeln('  /// ระยะขอบจอ')
    ..writeln('  static const gutter = ${(space['gutter'] as num).toDouble()};')
    ..writeln()
    ..writeln('  /// พื้นที่กดขั้นต่ำ แม้สิ่งที่มองเห็นจะเล็กกว่า')
    ..writeln('  static const touch = ${(space['minTouchTarget'] as num).toDouble()};')
    ..writeln('}')
    ..writeln();
  return b.toString();
}

String _radius(Map<String, dynamic> radius) {
  final b = StringBuffer()
    ..writeln('class LapseRadius {')
    ..writeln('  const LapseRadius._();');
  for (final e in radius.entries) {
    b.writeln('  static const ${e.key} = ${(e.value as num).toDouble()};');
  }
  b
    ..writeln('}')
    ..writeln();
  return b.toString();
}

String _border(Map<String, dynamic> border) {
  final b = StringBuffer()
    ..writeln('class LapseBorder {')
    ..writeln('  const LapseBorder._();');
  for (final e in border.entries) {
    b.writeln('  static const ${e.key} = ${(e.value as num).toDouble()};');
  }
  b
    ..writeln('}')
    ..writeln();
  return b.toString();
}

String _motion(Map<String, dynamic> motion) {
  final d = motion['duration'] as Map<String, dynamic>;
  final e = motion['easing'] as Map<String, dynamic>;
  final cubic = RegExp(r'cubic-bezier\(([^)]*)\)')
      .firstMatch(e['out'] as String)!
      .group(1)!
      .split(',')
      .map((s) => double.parse(s.trim()))
      .toList();

  final b = StringBuffer()
    ..writeln('/// จังหวะทั้งหมดของแอป')
    ..writeln('class LapseMotion {')
    ..writeln('  const LapseMotion._();');
  for (final entry in d.entries) {
    b.writeln(
        '  static const ${entry.key} = Duration(milliseconds: ${entry.value});');
  }
  b
    ..writeln()
    ..writeln('  /// ใช้กับการเคลื่อนไหวทั่วไป')
    ..writeln('  static const out = Cubic(${cubic.join(', ')});')
    ..writeln('}')
    ..writeln()
    ..writeln('/// ระบบนี้ไม่มีเงา ระดับชั้นสร้างด้วยเส้นและพื้นเท่านั้น')
    ..writeln('const lapseHasShadow = false;');
  return b.toString();
}
