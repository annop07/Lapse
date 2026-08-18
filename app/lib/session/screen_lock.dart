/// สะพานไปหาสัญญาณ "จอถูกล็อก" ของฝั่งเนทีฟ (§2.4)
///
/// `AppLifecycleState` อย่างเดียวตอบไม่ได้ว่าแอปหลุดโฟกัสเพราะอะไร
/// ทั้งการล็อกจอและการสลับไปแอปอื่นให้ `inactive` → `hidden` → `paused` เหมือนกันเป๊ะ
/// ฝั่ง iOS จึงต้องดัก `protectedDataWillBecomeUnavailable` แยกให้
library;

import 'package:flutter/services.dart';

/// ช่วงเวลาที่จอถูกล็อกครั้งล่าสุด หน่วยเป็น epoch milliseconds
///
/// [end] เป็น null แปลว่ายังล็อกอยู่
class LockWindow {
  const LockWindow({this.start, this.end});

  final int? start;
  final int? end;

  /// จอถูกล็อกคาบเกี่ยวกับช่วงที่แอปหลุดโฟกัสไปหรือเปล่า
  ///
  /// เผื่อ [slack] ไว้เพราะสัญญาณล็อกจออาจมาถึงก่อนหรือหลัง lifecycle เล็กน้อย
  bool overlaps(int pausedAtMs, {int slack = 2000}) {
    final s = start;
    if (s == null) return false;
    return s >= pausedAtMs - slack;
  }
}

abstract class ScreenLock {
  /// เครื่องนี้ตั้งรหัสผ่านไว้ไหม
  ///
  /// ถ้าไม่ได้ตั้ง data protection จะไม่ทำงานและสัญญาณล็อกจอจะไม่ยิงเลย
  /// กรณีนั้นเราแยกสองสถานการณ์ไม่ออก และเลือกทางที่ปลอดภัยกว่าคือ "หยุดนับ"
  Future<bool> hasPasscode();

  Future<LockWindow> lastLockWindow();
}

class PlatformScreenLock implements ScreenLock {
  const PlatformScreenLock();

  static const _channel = MethodChannel('app.lapse/screen_lock');

  @override
  Future<bool> hasPasscode() async =>
      await _channel.invokeMethod<bool>('hasPasscode') ?? false;

  @override
  Future<LockWindow> lastLockWindow() async {
    final raw = await _channel.invokeMapMethod<String, Object?>('lastLockWindow');
    if (raw == null) return const LockWindow();
    return LockWindow(start: raw['start'] as int?, end: raw['end'] as int?);
  }
}

/// ใช้บนแพลตฟอร์มที่ยังไม่มีสะพาน — ถือว่าไม่เคยมีการล็อกจอ
class NoScreenLock implements ScreenLock {
  const NoScreenLock();

  @override
  Future<bool> hasPasscode() async => false;

  @override
  Future<LockWindow> lastLockWindow() async => const LockWindow();
}
