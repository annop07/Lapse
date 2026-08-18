/// กำแพง — ตารางสะสมรายปี หนึ่งช่อง = หนึ่งวัน (§4.4)
///
/// หน้านี้คือสิ่งที่ทำให้คนกลับมาเปิดแอป และตั้งใจให้ไม่มีอันดับ ไม่มีการเปรียบเทียบ
/// วันว่างคือข้อเท็จจริง ไม่ใช่ความล้มเหลว จึงไม่มีสีแดงและไม่มีคำทวง
library;

import 'package:flutter/widgets.dart';

import '../../model/day.dart';
import '../../model/duration_fmt.dart';
import '../../model/thai_date.dart';
import '../../model/wall_level.dart';
import '../../store/lapse_store.dart';
import '../../tokens/lapse_theme.dart';
import '../../tokens/lapse_tokens.dart';
import 'wall_grid.dart';

class WallScreen extends StatefulWidget {
  const WallScreen({required this.store, required this.onClose, super.key});

  final LapseStore store;
  final VoidCallback onClose;

  @override
  State<WallScreen> createState() => _WallScreenState();
}

class _WallScreenState extends State<WallScreen> {
  Map<String, int> _minutes = const {};
  DateTime? _selected;
  Day? _selectedDay;

  int get _year => DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final minutes = await widget.store.minutesByDate();
    if (mounted) setState(() => _minutes = minutes);
  }

  /// ทุกวันของปีนี้ เรียงเป็นคอลัมน์ละสัปดาห์ เริ่มจากวันอาทิตย์
  ///
  /// ช่องก่อนวันที่ 1 มกราคม และหลังวันสุดท้ายของปีเป็น `null` คือไม่มีอยู่จริง
  List<int?> _levels() {
    final first = DateTime(_year, 1, 1);
    final last = DateTime(_year, 12, 31);
    final lead = sundayFirstWeekday(first);

    final cells = <int?>[...List<int?>.filled(lead, null)];
    for (var d = first;
        !d.isAfter(last);
        d = d.add(const Duration(days: 1))) {
      cells.add(wallLevel(_minutes[dateKey(d)] ?? 0));
    }
    while (cells.length % kWallRows != 0) {
      cells.add(null);
    }
    return cells;
  }

  DateTime? _dateAt(int index) {
    final first = DateTime(_year, 1, 1);
    final offset = index - sundayFirstWeekday(first);
    if (offset < 0) return null;
    final date = first.add(Duration(days: offset));
    return date.year == _year ? date : null;
  }

  Future<void> _select(DateTime date) async {
    setState(() {
      _selected = date;
      _selectedDay = null;
    });
    // กำแพงของตัวเองแสดงรายการของวันนั้นด้วย ไม่ใช่แค่เวลา
    final day = await widget.store.dayAt(date);
    if (mounted && _selected == date) setState(() => _selectedDay = day);
  }

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);
    final inset = MediaQuery.paddingOf(context);
    final levels = _levels();

    final totalMinutes = _minutes.values.fold(0, (a, b) => a + b);
    final daysWithTime = _minutes.length;

    return ColoredBox(
      color: colors.surface,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          LapseSpace.gutter,
          inset.top + LapseSpace.s5,
          LapseSpace.gutter,
          inset.bottom + LapseSpace.s8,
        ),
        children: [
          _Header(
            handle: widget.store.meta.handle,
            year: _year,
            totalMinutes: totalMinutes,
            daysWithTime: daysWithTime,
            onClose: widget.onClose,
            colors: colors,
          ),
          SizedBox(height: LapseSpace.s8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MonthLabels(year: _year, colors: colors),
                SizedBox(height: LapseSpace.s2),
                _TappableGrid(
                  levels: levels,
                  ramp: colors.wall,
                  onTapCell: (index) {
                    final date = _dateAt(index);
                    if (date != null) _select(date);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: LapseSpace.s6),
          _Legend(colors: colors),
          SizedBox(height: LapseSpace.s8),
          if (_selected != null)
            _Detail(
              date: _selected!,
              minutes: _minutes[dateKey(_selected!)] ?? 0,
              day: _selectedDay,
              colors: colors,
            ),
          SizedBox(height: LapseSpace.s8),
          _Friends(handle: widget.store.meta.handle, colors: colors),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.handle,
    required this.year,
    required this.totalMinutes,
    required this.daysWithTime,
    required this.onClose,
    required this.colors,
  });

  final String handle;
  final int year;
  final int totalMinutes;
  final int daysWithTime;
  final VoidCallback onClose;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: LapseSpace.touch,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '‹ วัน',
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
          Text(
            handle.isEmpty ? 'กำแพง' : handle,
            style: lapseTextStyle(LapseType.title, color: colors.ink),
          ),
          SizedBox(height: LapseSpace.s2),
          Text(
            '${totalMinutes ~/ 60} ชั่วโมง · $daysWithTime วัน ในปี $year',
            style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
          ),
        ],
      );
}

/// ป้ายเดือนเหนือตาราง
///
/// สเปก §4.4 บอกให้ข้ามป้ายที่ห่างจากป้ายก่อนหน้าน้อยกว่า 3 คอลัมน์
/// แต่กฎนั้นตั้งอยู่บนสมมติฐานว่าป้ายแคบ · สามคอลัมน์กว้าง 27px ขณะที่ `เม.ย.`
/// ที่ระยะห่างตัวอักษรของสเกล micro กว้างราว 40px ป้ายจึงยังชนกันอยู่ดี
///
/// เราวัดความกว้างจริงของแต่ละป้ายแทน แล้ววางเฉพาะป้ายที่ไม่ทับป้ายก่อนหน้า
/// วิธีนี้ถูกต้องไม่ว่าจะภาษาไหนหรือผู้ใช้ตั้งขนาดตัวอักษรไว้เท่าไร
class _MonthLabels extends StatelessWidget {
  const _MonthLabels({required this.year, required this.colors});

  final int year;
  final LapseColors colors;

  static const _minGap = 6.0;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(year, 1, 1);
    final lead = sundayFirstWeekday(first);
    final style = lapseTextStyle(LapseType.micro, color: colors.inkMuted);
    final scaler = MediaQuery.textScalerOf(context);

    final placed = <(double, String)>[];
    var lastRight = double.negativeInfinity;

    for (var month = 1; month <= 12; month++) {
      final label = thaiMonthShort(month);
      final column =
          (lead + DateTime(year, month, 1).difference(first).inDays) ~/
              kWallRows;
      final left = column * (kWallCell + kWallGap);
      if (left < lastRight + _minGap) continue;

      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();

      placed.add((left, label));
      lastRight = left + painter.width;
    }

    final columns = ((lead + 365) / kWallRows).ceil();
    return SizedBox(
      width: WallGridPainter.gridWidth(columns),
      height: LapseType.micro.size * LapseType.micro.height + LapseSpace.s1,
      child: Stack(
        children: [
          for (final (left, label) in placed)
            Positioned(left: left, child: Text(label, style: style)),
        ],
      ),
    );
  }
}

class _TappableGrid extends StatelessWidget {
  const _TappableGrid({
    required this.levels,
    required this.ramp,
    required this.onTapCell,
  });

  final List<int?> levels;
  final List<Color> ramp;
  final ValueChanged<int> onTapCell;

  @override
  Widget build(BuildContext context) {
    final columns = (levels.length / kWallRows).ceil();
    return GestureDetector(
      onTapUp: (details) {
        final step = kWallCell + kWallGap;
        final column = details.localPosition.dx ~/ step;
        final row = details.localPosition.dy ~/ step;
        final index = column * kWallRows + row;
        if (index >= 0 && index < levels.length) onTapCell(index);
      },
      child: SizedBox(
        width: WallGridPainter.gridWidth(columns),
        height: WallGridPainter.gridHeight(),
        child: WallGrid(levels: levels, ramp: ramp),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.colors});

  final LapseColors colors;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text('น้อย',
              style: lapseTextStyle(LapseType.caption, color: colors.inkMuted)),
          SizedBox(width: LapseSpace.s3),
          for (final color in colors.wall)
            Padding(
              padding: EdgeInsets.only(right: kWallGap),
              child: Container(
                width: kWallCell,
                height: kWallCell,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(LapseRadius.cell),
                ),
              ),
            ),
          SizedBox(width: LapseSpace.s2),
          Text('มาก',
              style: lapseTextStyle(LapseType.caption, color: colors.inkMuted)),
        ],
      );
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.date,
    required this.minutes,
    required this.day,
    required this.colors,
  });

  final DateTime date;
  final int minutes;
  final Day? day;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) {
    final lines = day?.lines.toList() ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: LapseBorder.hairline,
          color: colors.rule,
          margin: EdgeInsets.only(bottom: LapseSpace.s5),
        ),
        Row(
          children: [
            Text(
              '${thaiDayAndMonth(date)} ${date.year}',
              style: lapseTextStyle(LapseType.label, color: colors.ink),
            ),
            const Spacer(),
            Text(
              minutes > 0 ? formatThai(minutes) : 'ไม่ได้อ่าน',
              style: lapseTextStyle(LapseType.label, color: colors.ink2),
            ),
          ],
        ),
        for (final line in lines)
          Padding(
            padding: EdgeInsets.only(top: LapseSpace.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    line.text,
                    style: lapseTextStyle(
                      LapseType.body,
                      color: line.done ? colors.ink2 : colors.ink,
                    ),
                    textHeightBehavior: lapseTextHeightBehavior,
                  ),
                ),
                if (line.minutes > 0)
                  Text(
                    formatHm(line.minutes),
                    style: lapseTextStyle(
                      LapseType.mono,
                      color: colors.ink2,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// รายชื่อเพื่อน — v0 มีแค่ตัวเอง แต่คำแถลงจุดยืนต้องอยู่ตั้งแต่แรก
class _Friends extends StatelessWidget {
  const _Friends({required this.handle, required this.colors});

  final String handle;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: LapseBorder.hairline,
            color: colors.rule,
            margin: EdgeInsets.only(bottom: LapseSpace.s5),
          ),
          Text(
            'ไม่มีอันดับ — เรียงตามลำดับที่เพิ่ม',
            style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
          ),
          SizedBox(height: LapseSpace.s4),
          Text(
            handle.isEmpty ? 'คุณ' : '$handle (คุณ)',
            style: lapseTextStyle(LapseType.body, color: colors.ink),
          ),
        ],
      );
}
