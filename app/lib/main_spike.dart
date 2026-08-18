/// แอปทดสอบสามข้อจาก §6.5 — ของทิ้ง ไม่ใช่ส่วนหนึ่งของผลิตภัณฑ์
///
/// `flutter run -t lib/main_spike.dart`
///
/// S1 เรนเดอร์ข้อความไทยจริงด้วยฟอนต์จริง
/// S2 ตารางกำแพง 7px ที่ DPR ของเครื่อง
/// S3 จับเวลาแล้วแยกจอล็อกออกจากการสลับแอป — ต้องรันบน iPhone จริงเท่านั้น
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'session/focus_session.dart';
import 'session/screen_lock.dart';
import 'session/session_lifecycle.dart';
import 'tokens/lapse_theme.dart';
import 'tokens/lapse_tokens.dart';
import 'ui/wall/wall_grid.dart';

void main() => runApp(const SpikeApp());

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final colors = dark ? LapseColors.dark : LapseColors.light;
    return LapseTheme(
      colors: colors,
      isDark: dark,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(color: colors.surface, child: const _SpikePage()),
      ),
    );
  }
}

class _SpikePage extends StatelessWidget {
  const _SpikePage();

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);
    final inset = MediaQuery.paddingOf(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        LapseSpace.gutter,
        inset.top + LapseSpace.s7,
        LapseSpace.gutter,
        inset.bottom + LapseSpace.s7,
      ),
      children: [
        _Head('S1 · ข้อความไทย', colors),
        const _ThaiSample(),
        SizedBox(height: LapseSpace.s9),
        _Head('S2 · ตารางกำแพง', colors),
        const _WallSample(),
        SizedBox(height: LapseSpace.s9),
        _Head('S3 · จับเวลาและ lifecycle', colors),
        const _LifecycleSample(),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text, this.colors);

  final String text;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: LapseSpace.s5),
        child: Text(
          text.toUpperCase(),
          style: lapseTextStyle(LapseType.micro, color: colors.inkMuted),
        ),
      );
}

/// S1 — สระบนซ้อนวรรณยุกต์คือจุดที่ฟอนต์ไทยพังบ่อยที่สุด
class _ThaiSample extends StatelessWidget {
  const _ThaiSample();

  static const _samples = [
    'เช้าสมาธิดีมาก บ่ายไม่ไหวเลย พรุ่งนี้ย้ายฟิสิกส์มาไว้เช้า',
    'ผู้ใหญ่ที่เกี่ยวข้องนั้นก็ยังไม่ได้ตั้งใจอ่านหนังสือเท่าที่ควรจะเป็น',
    'ตื่นเต้นจนนอนไม่หลับ ทั้งๆ ที่อ่านไปแล้วสี่ชั่วโมงครึ่ง',
    'ที่ยังจำได้คือเรื่องคลื่นนิ่ง แต่เรื่องโพลาไรเซชันลืมหมดแล้ว',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in _samples)
          Padding(
            padding: EdgeInsets.only(bottom: LapseSpace.s4),
            child: Text(
              s,
              textHeightBehavior: lapseTextHeightBehavior,
              style: lapseTextStyle(LapseType.body, color: colors.ink),
            ),
          ),
        Divider(colors.rule),
        Text(
          'ตรวจ: สระบนชนวรรณยุกต์ไหม · บรรทัดซ้อนกันไหม · ตัดคำถูกไหม',
          style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
        ),
      ],
    );
  }
}

/// S2 — 53 คอลัมน์ × 7 แถว ที่ DPR จริงของเครื่อง
class _WallSample extends StatelessWidget {
  const _WallSample();

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);

    // ไล่ระดับแบบวนซ้ำ เพื่อให้เห็นทั้งห้าโทนติดกันและจับความเพี้ยนของระยะได้
    final levels = List<int?>.generate(371, (i) => (i * 7 + i ~/ 7) % 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: WallGrid(
            levels: levels,
            ramp: colors.wall,
            outline: colors.ink,
          ),
        ),
        SizedBox(height: LapseSpace.s4),
        Text(
          'DPR $dpr · 371 ช่อง · ช่อง ${kWallCell.toInt()}px เว้น ${kWallGap.toInt()}px',
          style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
        ),
        Text(
          'ตรวจ: ขอบคมเท่ากันทุกช่องไหม · ระยะห่างเท่ากันตลอดแถวไหม',
          style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
        ),
      ],
    );
  }
}

/// S3 — ต้องรันบน iPhone จริงที่ตั้งรหัสผ่านไว้ simulator ทดสอบข้อนี้ไม่ได้
class _LifecycleSample extends StatefulWidget {
  const _LifecycleSample();

  @override
  State<_LifecycleSample> createState() => _LifecycleSampleState();
}

class _LifecycleSampleState extends State<_LifecycleSample>
    with WidgetsBindingObserver {
  final _session = FocusSession();
  final _lock = const PlatformScreenLock();
  late final SessionLifecycle _lifecycle =
      SessionLifecycle(session: _session, screenLock: _lock);

  final _log = <String>[];
  File? _logFile;
  String _passcode = 'ยังไม่ได้ถาม';

  @override
  void initState() {
    super.initState();
    _lifecycle.attach();
    WidgetsBinding.instance.addObserver(this);
    _session.start();
    _openLogFile();
    _note('เริ่ม session');
    _askPasscode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycle.detach();
    super.dispose();
  }

  /// เขียน log ลงไฟล์ด้วย เพราะการเชื่อมต่อดีบักหลุดตอนจอดับ
  ///
  /// ไฟล์นี้อ่านย้อนหลังได้แม้สายจะขาดไปแล้ว ซึ่งเป็นกรณีที่เกิดขึ้นจริง
  /// ตอนทดสอบผ่านการเชื่อมต่อไร้สาย
  Future<void> _openLogFile() async {
    final docs = await getApplicationDocumentsDirectory();
    _logFile = File('${docs.path}/spike.log');
    await _logFile!.writeAsString(
      '--- เริ่มรอบใหม่ ---\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<void> _askPasscode() async {
    try {
      final has = await _lock.hasPasscode();
      setState(() => _passcode = has ? 'ตั้งรหัสผ่านไว้' : 'ไม่ได้ตั้งรหัสผ่าน');
    } on Object catch (e) {
      setState(() => _passcode = 'ถามไม่ได้: $e');
    }
  }

  void _note(String line) {
    // พิมพ์ออก console ด้วย เพราะบนเครื่องจริงการอ่าน log ง่ายกว่าถ่ายภาพหน้าจอ
    debugPrint('SPIKE $line');
    final stamp = DateTime.now().toIso8601String().substring(11, 19);
    _logFile?.writeAsStringSync('$stamp  $line\n', mode: FileMode.append, flush: true);
    _log.insert(0, line);
    if (_log.length > 14) _log.removeLast();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _note('lifecycle → ${state.name}');
    if (state == AppLifecycleState.resumed) _reportWindow();
  }

  Future<void> _reportWindow() async {
    final w = await _lock.lastLockWindow();
    final now = DateTime.now().millisecondsSinceEpoch;
    _note('ช่วงล็อกล่าสุด start=${w.start} end=${w.end}');
    if (w.start != null) {
      _note('ล็อกเมื่อ ${(now - w.start!) ~/ 1000} วินาทีที่แล้ว');
    }
    _note('เวลาสะสมทันทีที่กลับมา ${_session.elapsed.inSeconds} วินาที');

    // SessionLifecycle คืนเวลาให้แบบ async เพราะต้องถามฝั่งเนทีฟก่อน
    // ถ้าอ่านทันทีจะได้ค่าก่อนการคืนเวลา ซึ่งทำให้แยกไม่ออกว่าไม่คืน
    // หรือแค่ยังไม่ทันคืน จึงต้องอ่านซ้ำหลังทุกอย่างนิ่งแล้ว
    await Future<void>.delayed(const Duration(seconds: 3));
    _note('เวลาสะสมหลังนิ่งแล้ว ${_session.elapsed.inSeconds} วินาที');
  }

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _note('เวลาสะสม ${_session.elapsed.inSeconds} วินาที'),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: LapseSpace.s5),
            color: colors.ruleSoft,
            child: Text(
              'แตะเพื่อบันทึกเวลาปัจจุบัน',
              textAlign: TextAlign.center,
              style: lapseTextStyle(LapseType.label, color: colors.ink2),
            ),
          ),
        ),
        SizedBox(height: LapseSpace.s4),
        Text('รหัสผ่านเครื่อง: $_passcode',
            style: lapseTextStyle(LapseType.caption, color: colors.ink2)),
        Divider(colors.rule),
        for (final line in _log)
          Text(line,
              style: lapseTextStyle(LapseType.caption, color: colors.ink2)),
        Divider(colors.rule),
        Text(
          'ตรวจบน iPhone จริง: ล็อกจอ 10 นาที เวลาต้องเดินต่อ · '
          'สลับแอป 3 นาที เวลาต้องไม่เพิ่ม',
          style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
        ),
      ],
    );
  }
}

/// เส้นคั่น 1px — ระบบนี้ไม่มีเงา ระดับชั้นสร้างด้วยเส้นเท่านั้น
class Divider extends StatelessWidget {
  const Divider(this.color, {super.key});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: LapseBorder.hairline,
        margin: EdgeInsets.symmetric(vertical: LapseSpace.s5),
        color: color,
      );
}
