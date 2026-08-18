/// การ์ดแชร์ — สัดส่วน 9:16 สำหรับลงสตอรี่ (§4.5)
///
/// สเปกบอกว่านี่คือช่องทางหาผู้ใช้หลัก มันจึงต้องสวยพอที่คนอยากโพสต์เอง
/// โดยไม่ต้องมีใครขอ
///
/// บนการ์ดมีสี่อย่าง: กำแพงปีนี้ · handle · ชั่วโมงรวม · wordmark เล็กๆ
/// **ไม่มี** อันดับ การเปรียบเทียบ หรือคำโฆษณา ตามที่สเปกห้ามไว้ตรงๆ
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../i18n/strings.dart';
import 'package:share_plus/share_plus.dart';

import '../../model/day.dart';
import '../../model/thai_date.dart';
import '../../model/wall_level.dart';
import '../../store/lapse_store.dart';
import '../../tokens/lapse_theme.dart';
import '../../tokens/lapse_tokens.dart';
import '../wall/wall_grid.dart';

/// ขนาดการ์ดในหน่วยตรรกะ · ส่งออกที่ 3 เท่าจะได้ 1080×1920 พอดีกับสตอรี่
const _cardWidth = 360.0;
const _cardHeight = 640.0;

/// ระยะขอบด้านในของการ์ด
const _cardPadding = 30.0;

/// สัดส่วนช่องว่างต่อขนาดช่อง — ตามโทเคนเดิมคือ 2 ต่อ 7
const _gapRatio = 2 / 7;

/// ขนาดช่องบนการ์ดคำนวณจากความกว้างที่เหลือ ไม่ใช่ค่าตายตัว
///
/// ทั้งปีมี 53 คอลัมน์ ถ้ากำหนดขนาดเองแล้วเดาผิด กำแพงจะล้นขอบการ์ด
/// ซึ่งเกิดขึ้นจริงมาแล้วรอบหนึ่ง
double _cellFor(int columns) {
  const available = _cardWidth - _cardPadding * 2;
  return available / (columns + _gapRatio * (columns - 1));
}

class ShareScreen extends StatefulWidget {
  const ShareScreen({required this.store, required this.onClose, super.key});

  final LapseStore store;
  final VoidCallback onClose;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _cardKey = GlobalKey();
  Map<String, int> _seconds = const {};
  bool _busy = false;

  int get _year => DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seconds = await widget.store.secondsByDate();
    if (mounted) setState(() => _seconds = seconds);
  }

  List<int?> _levels() {
    final first = DateTime(_year, 1, 1);
    final last = DateTime(_year, 12, 31);
    final cells = <int?>[
      ...List<int?>.filled(sundayFirstWeekday(first), null),
    ];
    for (var d = first; !d.isAfter(last); d = d.add(const Duration(days: 1))) {
      cells.add(wallLevel(_seconds[dateKey(d)] ?? 0));
    }
    while (cells.length % kWallRows != 0) {
      cells.add(null);
    }
    return cells;
  }

  /// วาดการ์ดเป็นภาพแล้วเปิดแผงแบ่งปันของระบบ
  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return;

      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;

      final bytes = data.buffer.asUint8List();
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(bytes),
              name: 'lapse-$_year.png',
              mimeType: 'image/png',
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);
    final inset = MediaQuery.paddingOf(context);
    final totalHours = _seconds.values.fold(0, (a, b) => a + b) ~/ 3600;
    final strings = LapseStrings.of(context);

    return ColoredBox(
      color: colors.surface,
      child: Column(
        children: [
          SizedBox(height: inset.top),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: LapseSpace.gutter),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onClose,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: LapseSpace.touch,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        LapseStrings.of(context).backToWall,
                        style: lapseTextStyle(
                          LapseType.label,
                          color: colors.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _Card(
                    handle: widget.store.meta.handle,
                    year: _year,
                    hours: totalHours,
                    levels: _levels(),
                    colors: colors,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _share,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                LapseSpace.gutter,
                LapseSpace.s5,
                LapseSpace.gutter,
                inset.bottom + LapseSpace.s7,
              ),
              child: Text(
                _busy ? strings.preparing : strings.share,
                style: lapseTextStyle(
                  LapseType.body,
                  color: _busy ? colors.inkMuted : colors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ตัวการ์ดจริงที่ถูกวาดเป็นภาพ
///
/// แยกออกมาเป็น widget ของตัวเองเพราะมันต้องถูกเรนเดอร์ที่ขนาดคงที่เสมอ
/// ไม่ว่าจอของเครื่องจะกว้างแค่ไหน ภาพที่ออกไปจึงเหมือนกันทุกเครื่อง
class _Card extends StatelessWidget {
  const _Card({
    required this.handle,
    required this.year,
    required this.hours,
    required this.levels,
    required this.colors,
  });

  final String handle;
  final int year;
  final int hours;
  final List<int?> levels;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) {
    final columns = (levels.length / kWallRows).ceil();
    final cell = _cellFor(columns);
    final gap = cell * _gapRatio;
    return Container(
      width: _cardWidth,
      height: _cardHeight,
      decoration: BoxDecoration(
        // แผ่นที่ยกขึ้นมาบวกเส้นขอบ เพื่อให้อ่านออกว่านี่คือการ์ด ไม่ใช่พื้นจอ
        // ระบบนี้ไม่มีเงา ระดับชั้นจึงสร้างด้วยเส้นกับพื้นผิวเท่านั้น
        color: colors.surfaceRaised,
        border: Border.all(
          color: colors.rule,
          width: LapseBorder.hairline,
        ),
      ),
      padding: const EdgeInsets.all(_cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            handle.isEmpty ? LapseStrings.of(context).thisYear : handle,
            style: lapseTextStyle(LapseType.title, color: colors.ink),
          ),
          SizedBox(height: LapseSpace.s7),
          SizedBox(
            width: WallGridPainter.gridWidth(
              columns,
              cell: cell,
              gap: gap,
            ),
            height: WallGridPainter.gridHeight(cell: cell, gap: gap),
            child: WallGrid(
              levels: levels,
              ramp: colors.wall,
              outline: colors.ink,
              cell: cell,
              gap: gap,
            ),
          ),
          SizedBox(height: LapseSpace.s6),
          Text(
            LapseStrings.of(context).hoursInYear(hours, year),
            style: lapseTextStyle(LapseType.mono, color: colors.ink2),
          ),
          const Spacer(),
          Container(
            height: LapseBorder.hairline,
            color: colors.rule,
            margin: EdgeInsets.only(bottom: LapseSpace.s5),
          ),
          Text(
            'LAPSE',
            style: lapseTextStyle(LapseType.micro, color: colors.inkFaint),
          ),
        ],
      ),
    );
  }
}
