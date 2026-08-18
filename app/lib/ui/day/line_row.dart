/// หนึ่งแถวในหน้าวัน — เป็นทั้ง todo, ตัวจับเวลา และบันทึกในตัวเดียว (§9)
///
/// สถานะที่ต้องรองรับ: ปกติ · กำลังกดค้าง · ทำแล้ว · กำลังแก้ข้อความ
///
/// ช่องติ๊กวาดเองด้วย `CustomPaint` ไม่ใช้ `Checkbox` ของ Material
/// พื้นที่กดจริงของมันคือ 44px แม้รูปที่เห็นจะเล็กกว่ามาก
library;

import 'package:flutter/widgets.dart';

import '../../model/duration_fmt.dart';
import '../../tokens/lapse_theme.dart';
import '../../tokens/lapse_tokens.dart';
import '../common/hold_detector.dart';

const double _boxSize = 15;

class LineRow extends StatelessWidget {
  const LineRow({
    required this.text,
    required this.done,
    required this.seconds,
    required this.controller,
    required this.focusNode,
    required this.onToggle,
    required this.onTextChanged,
    required this.onHold,
    super.key,
  });

  final String text;
  final bool done;
  final int seconds;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onToggle;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onHold;

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);

    return HoldDetector(
      duration: LapseMotion.hold,
      // กดค้างตอนกำลังแก้ข้อความบรรทัดนี้อยู่ต้องไม่ทำงาน (§4.1)
      enabled: !focusNode.hasFocus,
      onComplete: onHold,
      builder: (context, progress) => Stack(
        children: [
          // แถบที่ไหลจากซ้ายไปขวาระหว่างกดค้าง ต้อง linear เสมอ
          // เพราะมันคือมาตรวัดเวลาจริง ไม่ใช่การตกแต่ง
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.ruleSoft,
                  borderRadius: BorderRadius.circular(LapseRadius.row),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Box(done: done, onTap: onToggle, colors: colors),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: LapseSpace.s3),
                  child: EditableText(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onTextChanged,
                    maxLines: null,
                    cursorColor: colors.ink,
                    backgroundCursorColor: colors.inkFaint,
                    selectionColor: colors.rule,
                    // ถ้าไม่บอก iOS ว่าใช้คีย์บอร์ดแบบไหน มันจะขึ้นสว่างเสมอแม้แอปจะเป็นธีมมืด
                    keyboardAppearance: LapseTheme.of(context).isDark
                        ? Brightness.dark
                        : Brightness.light,
                    textHeightBehavior: lapseTextHeightBehavior,
                    style: lapseTextStyle(
                      LapseType.body,
                      color: done ? colors.ink2 : colors.ink,
                    ),
                  ),
                ),
              ),
              _Time(seconds: seconds, colors: colors),
            ],
          ),
        ],
      ),
    );
  }
}

/// ช่องติ๊ก — เส้น 1.5px ไม่มีพื้นทึบ ไม่มีเครื่องหมายถูกสำเร็จรูป
class _Box extends StatelessWidget {
  const _Box({required this.done, required this.onTap, required this.colors});

  final bool done;
  final VoidCallback onTap;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          // สิ่งที่เห็นคือ 15px แต่พื้นที่กดคือ 44px ตามที่สเปกกำหนด
          width: LapseSpace.touch,
          height: LapseSpace.touch,
          child: Center(
            child: CustomPaint(
              size: const Size.square(_boxSize),
              painter: _BoxPainter(done: done, colors: colors),
            ),
          ),
        ),
      );
}

class _BoxPainter extends CustomPainter {
  _BoxPainter({required this.done, required this.colors});

  final bool done;
  final LapseColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = LapseBorder.stroke / 2;
    final box = RRect.fromRectAndRadius(
      Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset),
      Radius.circular(LapseRadius.box),
    );

    // ช่องที่ติ๊กแล้วถมทึบ ช่องว่างเป็นเส้นเปล่า
    // นี่ไม่ขัดกฎ "ไม่มีปุ่มพื้นสีทึบ" เพราะกฎนั้นพูดถึงปุ่ม ไม่ใช่ช่องติ๊ก
    if (done) {
      canvas.drawRRect(box, Paint()..color = colors.ink);
    } else {
      canvas.drawRRect(
        box,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = LapseBorder.stroke
          ..color = colors.inkMuted,
      );
      return;
    }

    // เครื่องหมายถูกวาดเอง สองเส้นตรง ไม่ใช้ไอคอนสำเร็จรูป
    final tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.square
      ..color = colors.surface;

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.26, size.height * 0.52)
        ..lineTo(size.width * 0.44, size.height * 0.70)
        ..lineTo(size.width * 0.76, size.height * 0.32),
      tick,
    );
  }

  @override
  bool shouldRepaint(_BoxPainter old) =>
      old.done != done || old.colors != colors;
}

/// เวลาสะสมของแถว — mono เพราะเป็นสิ่งที่เครื่องใส่ ไม่ใช่สิ่งที่มนุษย์พิมพ์
class _Time extends StatelessWidget {
  const _Time({required this.seconds, required this.colors});

  final int seconds;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: LapseSpace.s4,
          top: LapseSpace.s4,
        ),
        child: Text(
          seconds > 0 ? formatHms(seconds) : '—',
          style: lapseTextStyle(
            LapseType.mono,
            color: seconds > 0 ? colors.ink2 : colors.inkFaint,
          ),
        ),
      );
}
