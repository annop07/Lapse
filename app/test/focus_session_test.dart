import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/session/focus_session.dart';

/// นาฬิกาปลอมที่เดินเมื่อเราสั่งเท่านั้น
class _Clock {
  DateTime now = DateTime(2026, 8, 18, 9, 0);
  void tick(Duration d) => now = now.add(d);
}

void main() {
  late _Clock clock;
  late FocusSession session;

  setUp(() {
    clock = _Clock();
    session = FocusSession(clock: () => clock.now);
  });

  test('นับจากผลต่างเวลา ไม่ใช่จำนวนครั้งที่ถูกเรียก', () {
    session.start();
    clock.tick(const Duration(minutes: 47));
    expect(session.minutes, 47);
  });

  test('แตะจอดูเวลาไม่หยุดนับ', () {
    session.start();
    clock.tick(const Duration(minutes: 10));
    expect(session.elapsed, const Duration(minutes: 10));

    clock.tick(const Duration(minutes: 5));
    expect(session.elapsed, const Duration(minutes: 15));
    expect(session.isRunning, isTrue);
  });

  test('จอล็อกเองแล้วนับต่อ — ไม่มีใครเรียก pause', () {
    session.start();
    clock.tick(const Duration(minutes: 10));
    expect(session.minutes, 10);
  });

  test('สลับไปแอปอื่นแล้วเวลาไม่เดิน', () {
    session.start();
    clock.tick(const Duration(minutes: 3));

    session.pause();
    clock.tick(const Duration(minutes: 30));
    expect(session.elapsed, const Duration(minutes: 3));

    session.resume();
    clock.tick(const Duration(minutes: 2));
    expect(session.elapsed, const Duration(minutes: 5));
  });

  test('resume ซ้ำไม่ทำให้เวลาเดินสองเท่า', () {
    session.start();
    session.resume();
    session.resume();
    clock.tick(const Duration(minutes: 4));
    expect(session.minutes, 4);
  });

  test('session ต่ำกว่าหนึ่งนาทีถูกทิ้ง', () {
    session.start();
    clock.tick(const Duration(seconds: 59));
    expect(session.countsAtAll, isFalse);
    expect(session.stop(), 0);
  });

  test('หนึ่งนาทีพอดีนับ', () {
    session.start();
    clock.tick(const Duration(seconds: 60));
    expect(session.stop(), 1);
  });

  test('ปัดลงเสมอ เวลาที่บันทึกต้องไม่มากกว่าที่ใช้จริง', () {
    session.start();
    clock.tick(const Duration(seconds: 119));
    expect(session.stop(), 1);
  });

  test('stop แล้วเริ่มใหม่ได้ ไม่มีเวลาค้างจากรอบก่อน', () {
    session.start();
    clock.tick(const Duration(minutes: 20));
    expect(session.stop(), 20);

    session.start();
    clock.tick(const Duration(minutes: 3));
    expect(session.stop(), 3);
  });

  test('กรณีจริงจาก §6.5 ข้อ 3 — ล็อกจอทิ้งไว้สิบนาที', () {
    session.start();
    clock.tick(const Duration(minutes: 2));
    // จอดับเอง ไม่มีการเรียก pause เพราะไม่ใช่การสลับแอป
    clock.tick(const Duration(minutes: 10));
    session.resume(); // ปลดล็อกกลับมา ยังนับอยู่ resume จึงไม่เปลี่ยนอะไร
    clock.tick(const Duration(minutes: 1));
    expect(session.stop(), 13);
  });
}
