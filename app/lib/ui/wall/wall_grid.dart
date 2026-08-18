/// ตารางกำแพง — คอลัมน์ละสัปดาห์ 7 แถว เริ่มจากวันอาทิตย์ (§4.4)
///
/// §4.4 กำหนดช่อง 7px เว้น 2px ซึ่งยืมมาจากกราฟ contributions ของ GitHub
/// ที่ออกแบบมาสำหรับจอกว้างกับเมาส์ บนมือถือขนาดนั้นเล็กเกินกว่าจะแตะให้ตรงวัน
/// และขัดกับกฎพื้นที่กดขั้นต่ำ 44px ของสเปกเอง
///
/// จึงขยายเป็นช่อง 14px เว้น 3px ตามที่เจ้าของผลิตภัณฑ์ตัดสินใจหลังลองใช้จริง
/// ทั้งปียังอยู่ครบ แต่เห็นทีละราว 20 สัปดาห์แล้วเลื่อนย้อนดูได้
///
/// ปัญหาที่ต้องระวังคือความคม ตัวเลขพวกนี้เล็กมากเมื่อเทียบกับพิกเซลจริง
/// ถ้าปล่อยให้ Flutter ปัดพิกัดเอง ขอบจะเบลอไม่เท่ากันในแต่ละคอลัมน์
/// เราจึงปัดพิกัดเข้าเส้นพิกเซลจริงของเครื่องก่อนวาดทุกครั้ง
library;

import 'package:flutter/widgets.dart';

import '../../tokens/lapse_tokens.dart';

/// ปัดพิกัดเข้าเส้นพิกเซลจริงของเครื่อง
///
/// ช่อง 7px ที่ DPR 3 กินพื้นที่ 21 พิกเซลจริงพอดี แต่ระยะสะสมของคอลัมน์ที่ 40
/// อาจตกลงกลางพิกเซล ทำให้ขอบช่องนั้นเบลอกว่าเพื่อน การปัดก่อนวาดทำให้ทุกช่อง
/// คมเท่ากันแทนที่จะคมบ้างเบลอบ้างแล้วแต่ตำแหน่ง
double snapToPixel(double value, double devicePixelRatio) =>
    (value * devicePixelRatio).roundToDouble() / devicePixelRatio;

const double kWallCell = 14;
const double kWallGap = 3;
const int kWallRows = 7;

class WallGridPainter extends CustomPainter {
  WallGridPainter({
    required this.levels,
    required this.ramp,
    required this.devicePixelRatio,
    required this.outline,
    this.selected,
    this.cell = kWallCell,
    this.gap = kWallGap,
  });

  /// ระดับ 0–4 ของแต่ละวัน เรียงตามเวลา · `null` คือช่องที่ไม่มีอยู่จริงในปีนั้น
  final List<int?> levels;

  /// ไล่โทน 5 ขั้นจากโทเคน
  final List<Color> ramp;

  final double devicePixelRatio;

  /// สีของกรอบช่องที่เลือกอยู่
  final Color outline;

  /// ดัชนีของช่องที่เลือกอยู่ · null = ยังไม่ได้เลือก
  final int? selected;

  /// การ์ดแชร์วาดเล็กกว่านี้ได้ เพราะเป็นภาพ ไม่ใช่พื้นที่ที่ต้องกด
  final double cell;
  final double gap;

  int get columns => (levels.length / kWallRows).ceil();

  static double gridWidth(int columns,
          {double cell = kWallCell, double gap = kWallGap}) =>
      columns * cell + (columns - 1) * gap;

  static double gridHeight({double cell = kWallCell, double gap = kWallGap}) =>
      kWallRows * cell + (kWallRows - 1) * gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    // รัศมีต้องได้สัดส่วนกับช่อง ไม่งั้นช่องเล็กๆ บนการ์ดแชร์จะกลายเป็นวงกลม
    final radius = Radius.circular(
      LapseRadius.cell < cell * 0.3 ? LapseRadius.cell : cell * 0.3,
    );

    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      if (level == null) continue;

      final column = i ~/ kWallRows;
      final row = i % kWallRows;

      final left = snapToPixel(column * (cell + gap), devicePixelRatio);
      final top = snapToPixel(row * (cell + gap), devicePixelRatio);
      final rect = Rect.fromLTRB(
        left,
        top,
        snapToPixel(left + cell, devicePixelRatio),
        snapToPixel(top + cell, devicePixelRatio),
      );

      paint.color = ramp[level.clamp(0, ramp.length - 1)];
      final rounded = RRect.fromRectAndRadius(rect, radius);
      canvas.drawRRect(rounded, paint);

      // กรอบรอบช่องที่เลือก เพื่อให้เห็นว่ากดโดนวันไหน
      if (i != selected) continue;
      canvas.drawRRect(
        rounded.inflate(LapseBorder.stroke),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = LapseBorder.stroke
          ..color = outline,
      );
    }
  }

  @override
  bool shouldRepaint(WallGridPainter old) =>
      old.devicePixelRatio != devicePixelRatio ||
      old.ramp != ramp ||
      old.selected != selected ||
      old.outline != outline ||
      !identical(old.levels, levels);
}

class WallGrid extends StatelessWidget {
  const WallGrid({
    required this.levels,
    required this.ramp,
    required this.outline,
    this.selected,
    this.cell = kWallCell,
    this.gap = kWallGap,
    super.key,
  });

  final List<int?> levels;
  final List<Color> ramp;
  final Color outline;
  final int? selected;
  final double cell;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final painter = WallGridPainter(
      levels: levels,
      ramp: ramp,
      outline: outline,
      selected: selected,
      cell: cell,
      gap: gap,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    return CustomPaint(
      size: Size(
        WallGridPainter.gridWidth(painter.columns, cell: cell, gap: gap),
        WallGridPainter.gridHeight(cell: cell, gap: gap),
      ),
      painter: painter,
    );
  }
}
