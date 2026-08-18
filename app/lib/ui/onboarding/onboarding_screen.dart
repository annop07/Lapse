/// เปิดครั้งแรก — สามจังหวะเท่านั้น (§4.9)
///
/// 1. เขียนสิ่งที่จะทำวันนี้หนึ่งบรรทัด
/// 2. กดค้างที่บรรทัดนั้นแล้วเข้าโหมดโฟกัสจริง
/// 3. เห็นช่องแรกบนกำแพงติดขึ้นมา
///
/// ไม่มีสไลด์อธิบายฟีเจอร์ · ไม่ขอสิทธิ์แจ้งเตือนเพราะไม่มีการแจ้งเตือน ·
/// ไม่บังคับสมัครสมาชิก
///
/// จังหวะที่ 2 และ 3 ไม่ใช่หน้าจอของตัวเอง มันคือหน้า `day` กับหน้า `wall` จริงๆ
/// หน้านี้จึงมีแค่จังหวะแรกกับคำใบ้ที่ค้างอยู่จนกว่าผู้ใช้จะทำสำเร็จ
library;

import 'package:flutter/widgets.dart';

import '../../tokens/lapse_theme.dart';
import '../../tokens/lapse_tokens.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onWrote, super.key});

  /// เขียนบรรทัดแรกเสร็จแล้ว — ส่งข้อความกลับไปให้ store สร้างรายการจริง
  final void Function(String text) onWrote;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // เคอร์เซอร์อยู่ในช่องตั้งแต่วินาทีแรก ไม่ต้องหาว่าจะเริ่มตรงไหน
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onWrote(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);
    final inset = MediaQuery.paddingOf(context);
    // ต้องเผื่อความสูงคีย์บอร์ดด้วย ไม่ใช่แค่ safe area
    // ไม่งั้นปุ่มต่อไปจะอยู่ใต้คีย์บอร์ดที่เด้งขึ้นมาเองตั้งแต่วินาทีแรก
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return ColoredBox(
      color: colors.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          LapseSpace.gutter,
          inset.top + LapseSpace.s10,
          LapseSpace.gutter,
          inset.bottom + keyboard + LapseSpace.s7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'วันนี้จะทำอะไร',
              style: lapseTextStyle(LapseType.title, color: colors.ink),
            ),
            SizedBox(height: LapseSpace.s3),
            Text(
              'เขียนสักบรรทัด แก้ทีหลังได้',
              style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
            ),
            SizedBox(height: LapseSpace.s8),
            Stack(
              children: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) => value.text.isEmpty
                      ? Text(
                          'อ่านเลข บทที่ 4',
                          style: lapseTextStyle(
                            LapseType.body,
                            color: colors.inkFaint,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                EditableText(
                  controller: _controller,
                  focusNode: _focus,
                  onSubmitted: (_) => _submit(),
                  maxLines: 1,
                  cursorColor: colors.ink,
                  backgroundCursorColor: colors.inkFaint,
                  selectionColor: colors.rule,
                  textHeightBehavior: lapseTextHeightBehavior,
                  style: lapseTextStyle(LapseType.body, color: colors.ink),
                ),
              ],
            ),
            SizedBox(height: LapseSpace.s4),
            Container(height: LapseBorder.hairline, color: colors.rule),
            const Spacer(),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => GestureDetector(
                onTap: value.text.trim().isEmpty ? null : _submit,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: LapseSpace.touch,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ต่อไป',
                      style: lapseTextStyle(
                        LapseType.body,
                        color: value.text.trim().isEmpty
                            ? colors.inkFaint
                            : colors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
