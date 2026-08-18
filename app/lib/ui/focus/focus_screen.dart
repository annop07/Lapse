/// จอโฟกัส — ดำสนิทเต็มจอ (§4.2)
///
/// ไม่มีตัวเลขนับ ไม่มีวงกลม ไม่มีแถบความคืบหน้า ต้องแตะถึงจะเห็นเวลา
/// แล้วมันจะจางหายไปเอง จอนี้ตั้งใจให้ไม่มีอะไรให้ดู
///
/// พื้นหลังต้องเป็น `#000000` ไม่ใช่เทาเข้ม เพราะบน OLED สีดำสนิทคือพิกเซลที่ดับจริง
library;

import 'package:flutter/widgets.dart';

import '../../model/duration_fmt.dart';
import '../../session/focus_session.dart';
import '../../session/session_lifecycle.dart';
import '../../tokens/lapse_theme.dart';
import '../../tokens/lapse_tokens.dart';
import '../common/hold_detector.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({
    required this.what,
    required this.isFirstEver,
    required this.onFinish,
    super.key,
  });

  /// ชื่อรายการที่กำลังทำ
  final String what;

  /// ครั้งแรกในชีวิตที่เข้าหน้านี้ — คำใบ้ต้องคอนทราสต์ปกติและไม่จางหาย
  ///
  /// คำใบ้ปกติมีคอนทราสต์ราว 1.6:1 ซึ่งต่ำกว่ามาตรฐานมากโดยตั้งใจ
  /// ถ้าปล่อยให้จางตั้งแต่ครั้งแรก ผู้ใช้จะหาทางออกจากจอนี้ไม่เจอ
  final bool isFirstEver;

  /// คืนจำนวนนาทีที่จะบวกเข้ารายการ · 0 แปลว่า session สั้นเกินกว่าจะนับ
  final void Function(int minutes) onFinish;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

/// จอนี้ดำเสมอไม่ว่าผู้ใช้จะตั้งธีมไหน สีของข้อความบนนั้นจึงมาจากชุดมืดเสมอ
/// ไม่ใช่จากธีมปัจจุบัน — และยังคงเป็นค่าจากโทเคน ไม่ใช่ hex ที่พิมพ์เอง
const _onVoid = LapseColors.dark;

/// เส้นที่ไหลตอนกดค้างเพื่อจบ สเปก §4.2 กำหนดไว้ที่ 2px ตรงๆ
/// หนากว่า hairline เพราะต้องเห็นได้บนพื้นดำสนิท
const double _endBarHeight = 2;

class _FocusScreenState extends State<FocusScreen> {
  final _session = FocusSession();
  late final SessionLifecycle _lifecycle = SessionLifecycle(session: _session);

  /// คำใบ้กับชื่อรายการจางหายไปพร้อมกันใน 2.6 วินาที
  bool _settled = false;

  /// เวลาที่โผล่มาตอนแตะ แล้วจางหายใน 1.8 วินาที
  bool _peeking = false;
  int _peekToken = 0;

  @override
  void initState() {
    super.initState();
    _lifecycle.attach();
    _session.start();
    if (!widget.isFirstEver) {
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _settled = true);
      });
    }
  }

  @override
  void dispose() {
    _lifecycle.detach();
    super.dispose();
  }

  void _peek() {
    final token = ++_peekToken;
    setState(() => _peeking = true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && token == _peekToken) setState(() => _peeking = false);
    });
  }

  void _finish() => widget.onFinish(_session.stop());

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);
    final faded = _settled && !widget.isFirstEver;

    return HoldDetector(
      // จบใช้ 720ms นานกว่าตอนเริ่มโดยตั้งใจ กันการจบ session โดยบังเอิญ
      duration: LapseMotion.end,
      haptic: HoldHaptic.light,
      onComplete: _finish,
      // ปล่อยนิ้วก่อนครบ = แตะเพื่อดูเวลา
      onCancel: _peek,
      builder: (context, progress) => ColoredBox(
        color: colors.void_,
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(LapseSpace.gutter),
                      child: _Fading(
                        faded: faded,
                        child: Text(
                          widget.what.isEmpty ? 'ไม่มีชื่อ' : widget.what,
                          textAlign: TextAlign.center,
                          textHeightBehavior: lapseTextHeightBehavior,
                          style: lapseTextStyle(
                            LapseType.body,
                            color: _onVoid.inkMuted,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: _peeking ? 1 : 0,
                          duration: LapseMotion.base,
                          curve: LapseMotion.out,
                          child: Text(
                            formatHm(_session.elapsed.inMinutes),
                            style: lapseTextStyle(
                              LapseType.display,
                              color: _onVoid.ink2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(LapseSpace.gutter),
                      child: _Fading(
                        faded: faded,
                        child: Text(
                          'แตะเพื่อดูเวลา\nกดค้างเพื่อจบ',
                          textAlign: TextAlign.center,
                          textHeightBehavior: lapseTextHeightBehavior,
                          style: lapseTextStyle(
                            LapseType.caption,
                            color: widget.isFirstEver
                                ? _onVoid.ink2
                                : _onVoid.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // เส้น 2px ที่ขอบล่างระหว่างกดค้างเพื่อจบ
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                height: _endBarHeight,
                width: MediaQuery.sizeOf(context).width * progress,
                color: _onVoid.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// จางหายไปเฉยๆ ไม่มีการเลื่อน ไม่มีการย่อขยาย
class _Fading extends StatelessWidget {
  const _Fading({required this.faded, required this.child});

  final bool faded;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: faded ? 0 : 1,
        duration: LapseMotion.fade,
        curve: LapseMotion.out,
        child: child,
      );
}
