/// ผูก [FocusSession] เข้ากับวงจรชีวิตของแอปตามกฎใน §2.4
///
/// | เหตุการณ์ | นับต่อ? |
/// |---|---|
/// | แตะจอเพื่อดูเวลา | นับต่อ |
/// | จอล็อกเอง | **นับต่อ** |
/// | สลับไปแอปอื่น | **หยุดนับ** |
///
/// จุดสำคัญของไฟล์นี้: **เราไม่ตัดสินตอนแอปหลุดโฟกัส แต่ตัดสินตอนกลับเข้ามา**
/// เพราะ iOS ไม่รับประกันว่าสัญญาณล็อกจอกับ lifecycle อันไหนจะมาก่อน
/// ตอนออกเราหักเวลาไว้ก่อนเสมอ แล้วค่อยคืนให้ถ้ารู้ว่าเป็นการล็อกจอ
library;

import 'package:flutter/widgets.dart';

import 'focus_session.dart';
import 'screen_lock.dart';

class SessionLifecycle with WidgetsBindingObserver {
  SessionLifecycle({
    required this.session,
    ScreenLock? screenLock,
    DateTime Function()? clock,
  })  : _lock = screenLock ?? const PlatformScreenLock(),
        _clock = clock ?? DateTime.now;

  final FocusSession session;
  final ScreenLock _lock;
  final DateTime Function() _clock;

  DateTime? _leftAt;

  void attach() => WidgetsBinding.instance.addObserver(this);
  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _onLeft();
      case AppLifecycleState.resumed:
        _onReturned();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // `inactive` เกิดตอนลากศูนย์ควบคุมลงมาด้วย ซึ่งยังไม่ใช่การออกจากแอป
        break;
    }
  }

  void _onLeft() {
    // การ์ดบรรทัดนี้รับน้ำหนักจริง ไม่ใช่การกันเหนียว
    //
    // ลำดับที่ iOS ส่งจริงตอนสลับแอปคือ
    //   ขาออก  inactive → hidden → paused
    //   ขากลับ hidden → inactive → resumed
    //
    // `hidden` มาสองครั้ง และครั้งที่สองมาตอนกำลังกลับเข้าแอป
    // ถ้าไม่เช็กว่ายังนับอยู่ไหม ครั้งที่สองจะเขียนทับ [_leftAt]
    // ด้วยเวลาปัจจุบัน แล้วช่วงที่หายไปจะถูกคิดเป็นศูนย์
    if (!session.isRunning) return;
    _leftAt = _clock();
    session.pause();
  }

  Future<void> _onReturned() async {
    final leftAt = _leftAt;
    _leftAt = null;
    if (leftAt == null) return;

    final gap = _clock().difference(leftAt);
    if (await _wasScreenLock(leftAt)) session.credit(gap);
    session.resume();
  }

  /// ช่วงที่หายไปนั้นเกิดจากการล็อกจอหรือเปล่า
  ///
  /// เครื่องที่ไม่ได้ตั้งรหัสผ่านตอบคำถามนี้ไม่ได้เลย กรณีนั้นเลือก "ไม่ใช่"
  /// เพราะกำแพงที่ตัวเลขเชื่อถือไม่ได้คือกำแพงที่ไม่มีความหมาย (§8 ข้อ 1)
  Future<bool> _wasScreenLock(DateTime leftAt) async {
    if (!await _lock.hasPasscode()) return false;
    final window = await _lock.lastLockWindow();
    return window.overlaps(leftAt.millisecondsSinceEpoch);
  }
}
