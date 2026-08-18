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

  int get columns => (levels.length / kWallRows).ceil();

  static double gridWidth(int columns) =>
      columns * kWallCell + (columns - 1) * kWallGap;

  static double gridHeight() =>
      kWallRows * kWallCell + (kWallRows - 1) * kWallGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final radius = Radius.circular(LapseRadius.cell);

    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      if (level == null) continue;

      final column = i ~/ kWallRows;
      final row = i % kWallRows;

      final left = snapToPixel(column * (kWallCell + kWallGap), devicePixelRatio);
      final top = snapToPixel(row * (kWallCell + kWallGap), devicePixelRatio);
      final rect = Rect.fromLTRB(
        left,
        top,
        snapToPixel(left + kWallCell, devicePixelRatio),
        snapToPixel(top + kWallCell, devicePixelRatio),
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
    super.key,
  });

  final List<int?> levels;
  final List<Color> ramp;
  final Color outline;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    final painter = WallGridPainter(
      levels: levels,
      ramp: ramp,
      outline: outline,
      selected: selected,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    return CustomPaint(
      size: Size(
        WallGridPainter.gridWidth(painter.columns),
        WallGridPainter.gridHeight(),
      ),
      painter: painter,
    );
  }
}
