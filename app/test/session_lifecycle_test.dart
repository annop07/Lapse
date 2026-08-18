import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/session/focus_session.dart';
import 'package:lapse/session/screen_lock.dart';
import 'package:lapse/session/session_lifecycle.dart';

class _Clock {
  DateTime now = DateTime(2026, 8, 18, 9, 0);
  void tick(Duration d) => now = now.add(d);
}

class _FakeLock implements ScreenLock {
  bool passcode = true;
  LockWindow window = const LockWindow();

  @override
  Future<bool> hasPasscode() async => passcode;

  @override
  Future<LockWindow> lastLockWindow() async => window;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Clock clock;
  late FocusSession session;
  late _FakeLock lock;
  late SessionLifecycle lifecycle;

  setUp(() {
    clock = _Clock();
    session = FocusSession(clock: () => clock.now);
    lock = _FakeLock();
    lifecycle = SessionLifecycle(
      session: session,
      screenLock: lock,
      clock: () => clock.now,
    );
  });

  group('LockWindow', () {
    test('ไม่เคยล็อกเลยแปลว่าไม่ใช่การล็อกจอ', () {
      expect(const LockWindow().overlaps(1000), isFalse);
    });

    test('ล็อกหลังจากแอปหลุดโฟกัสถือว่าใช่', () {
      expect(const LockWindow(start: 5000).overlaps(4000), isTrue);
    });

    test('ล็อกก่อนหน้านั้นนานแล้วไม่เกี่ยวกัน', () {
      expect(const LockWindow(start: 1000).overlaps(60000), isFalse);
    });

    test('เผื่อความคลาดเคลื่อนของลำดับสัญญาณไว้สองวินาที', () {
      // สัญญาณล็อกจอมาถึงก่อน lifecycle เล็กน้อย ยังต้องนับว่าใช่
      expect(const LockWindow(start: 9000).overlaps(10000), isTrue);
      expect(const LockWindow(start: 7000).overlaps(10000), isFalse);
    });
  });

  group('กฎ §2.4', () {
    test('ล็อกจอสิบนาทีแล้วเวลาเดินต่อ', () async {
      session.start();
      clock.tick(const Duration(minutes: 2));

      lifecycle.didChangeAppLifecycleState(AppLifecycleState.paused);
      lock.window = LockWindow(start: clock.now.millisecondsSinceEpoch);
      clock.tick(const Duration(minutes: 10));

      lifecycle.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      clock.tick(const Duration(minutes: 1));
      expect(session.stop(), 13 * 60);
    });

    test('สลับไปแอปอื่นสามนาทีแล้วเวลาไม่เพิ่ม', () async {
      session.start();
      clock.tick(const Duration(minutes: 5));

      lifecycle.didChangeAppLifecycleState(AppLifecycleState.paused);
      clock.tick(const Duration(minutes: 3));

      lifecycle.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      clock.tick(const Duration(minutes: 2));
      expect(session.stop(), 7 * 60);
    });

    test('เครื่องไม่มีรหัสผ่านถือว่าเป็นการสลับแอปเสมอ', () async {
      lock.passcode = false;
      session.start();
      clock.tick(const Duration(minutes: 1));

      lifecycle.didChangeAppLifecycleState(AppLifecycleState.paused);
      lock.window = LockWindow(start: clock.now.millisecondsSinceEpoch);
      clock.tick(const Duration(minutes: 30));

      lifecycle.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(session.stop(), 60);
    });

    test('ลำดับที่ iOS ส่งจริงตอนสลับแอป', () async {
      // ลำดับนี้บันทึกมาจากการรันจริง ไม่ได้เดา
      // จุดสำคัญคือ hidden มาสองครั้ง และครั้งที่สองมาตอนกลับเข้าแอป
      session.start();
      clock.tick(const Duration(seconds: 11));

      lifecycle.didChangeAppLifecycleState(AppLifecycleState.inactive);
      lifecycle.didChangeAppLifecycleState(AppLifecycleState.hidden);
      lifecycle.didChangeAppLifecycleState(AppLifecycleState.paused);

      clock.tick(const Duration(seconds: 30));

      lifecycle.didChangeAppLifecycleState(AppLifecycleState.hidden);
      lifecycle.didChangeAppLifecycleState(AppLifecycleState.inactive);
      lifecycle.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(session.elapsed, const Duration(seconds: 11));
    });

    test('inactive อย่างเดียวไม่หยุดนับ', () {
      session.start();
      lifecycle.didChangeAppLifecycleState(AppLifecycleState.inactive);
      clock.tick(const Duration(minutes: 4));
      expect(session.seconds, 4 * 60);
    });

    test('ไม่ได้อยู่ใน session แล้วสลับแอปไม่ทำอะไร', () async {
      lifecycle.didChangeAppLifecycleState(AppLifecycleState.paused);
      lifecycle.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(session.isRunning, isFalse);
      expect(session.seconds, 0);
    });
  });
}
