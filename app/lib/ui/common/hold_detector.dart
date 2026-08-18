/// การกดค้าง — คอมโพเนนต์ที่สำคัญที่สุดในแอป
///
/// การกระทำหลักของ Lapse (เริ่มจับเวลา) ไม่ใช่ปุ่ม มันคือการกดค้าง
/// จังหวะสองค่าที่เป็นพิธีกรรมคือ 560ms ตอนเริ่ม และ 720ms ตอนจบ
/// ตอนจบนานกว่าโดยตั้งใจ เพื่อกันการจบ session โดยบังเอิญ
///
/// ทำไมไม่ใช้ `GestureDetector.onLongPress`
///
/// - ต้องรู้ความคืบหน้าเป็นเศษส่วนตลอดเวลาเพื่อวาดแถบ ซึ่ง recognizer มาตรฐานไม่บอก
/// - ต้องคุมเวลาให้ตรงกับโทเคนเป๊ะๆ ไม่ใช่ค่าของ Material
/// - ต้องยกเลิกเองที่ระยะ 8px ไม่ใช่ค่า slop ของระบบ
///
/// แถบความคืบหน้าต้องเป็น `linear` เสมอ เพราะมันคือมาตรวัดเวลาจริง
/// ไม่ใช่การตกแต่ง — ถ้าใส่ ease เข้าไป มันจะโกหกผู้ใช้เรื่องเวลาที่เหลือ
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// ขยับนิ้วเกินระยะนี้แล้วยกเลิกทันที (§4.1)
const double kHoldSlop = 8.0;

enum HoldHaptic { none, light, medium }

class HoldDetector extends StatefulWidget {
  const HoldDetector({
    required this.duration,
    required this.onComplete,
    required this.builder,
    this.enabled = true,
    this.haptic = HoldHaptic.medium,
    this.onCancel,
    super.key,
  });

  /// 560ms ตอนเริ่ม · 720ms ตอนจบ — เอาค่าจาก `LapseMotion`
  final Duration duration;

  final VoidCallback onComplete;

  /// เรียกเมื่อปล่อยก่อนครบหรือขยับนิ้วเกินระยะ
  final VoidCallback? onCancel;

  /// ความคืบหน้า 0→1 แบบ linear ส่งให้ผู้เรียกไปวาดแถบเอง
  final Widget Function(BuildContext context, double progress) builder;

  /// ปิดไว้ตอนที่การกดค้างไม่ควรทำงาน เช่นกำลังแก้ข้อความบรรทัดนั้นอยู่
  final bool enabled;

  final HoldHaptic haptic;

  @override
  State<HoldDetector> createState() => _HoldDetectorState();
}

class _HoldDetectorState extends State<HoldDetector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener(_onStatus);

  Offset? _origin;

  @override
  void didUpdateWidget(HoldDetector old) {
    super.didUpdateWidget(old);
    if (widget.duration != old.duration) _progress.duration = widget.duration;
    if (!widget.enabled) _abort();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _origin = null;
    _progress.value = 0;
    switch (widget.haptic) {
      case HoldHaptic.medium:
        HapticFeedback.mediumImpact();
      case HoldHaptic.light:
        HapticFeedback.lightImpact();
      case HoldHaptic.none:
        break;
    }
    widget.onComplete();
  }

  void _onDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _origin = event.position;
    _progress.forward(from: 0);
  }

  void _onMove(PointerMoveEvent event) {
    final origin = _origin;
    if (origin == null) return;
    if ((event.position - origin).distance > kHoldSlop) _abort();
  }

  void _onUp(PointerEvent event) {
    if (_origin == null) return;
    _abort();
  }

  void _abort() {
    if (_origin == null && _progress.value == 0) return;
    _origin = null;
    _progress
      ..stop()
      ..value = 0;
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) => widget.builder(context, _progress.value),
      ),
    );
  }
}
