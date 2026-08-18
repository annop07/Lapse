import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/ui/common/hold_detector.dart';

const _hold = Duration(milliseconds: 560);
const _holdPast = Duration(milliseconds: 561);

/// เลย 560ms ไปหนึ่งมิลลิวินาที
///
/// `_InterpolationSimulation.isDone` ใช้เงื่อนไข `t > duration` แบบเข้ม
/// การ pump ที่ 560ms พอดีจึงได้ค่า 1.0 แต่สถานะยังไม่เป็น completed
/// ในแอปจริงไม่เจอเพราะเฟรมถัดไปตกที่ราว 565ms อยู่แล้ว

void main() {
  late int completed;
  late int cancelled;
  late double lastProgress;

  Widget subject({bool enabled = true, HoldHaptic haptic = HoldHaptic.none}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: HoldDetector(
          duration: _hold,
          enabled: enabled,
          haptic: haptic,
          onComplete: () => completed++,
          onCancel: () => cancelled++,
          builder: (context, progress) {
            lastProgress = progress;
            return const SizedBox(width: 200, height: 44);
          },
        ),
      ),
    );
  }

  setUp(() {
    completed = 0;
    cancelled = 0;
    lastProgress = -1;
  });

  testWidgets('กดค้างครบ 560ms แล้วทำงานหนึ่งครั้ง', (tester) async {
    await tester.pumpWidget(subject());
    final gesture = await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    // ticker เริ่มเดินที่เฟรมถัดไป ต้องปล่อยหนึ่งเฟรมก่อนจับเวลา
    await tester.pump();

    await tester.pump(_holdPast);
    expect(completed, 1);

    await gesture.up();
    await tester.pump();
    expect(completed, 1);
  });

  testWidgets('ปล่อยก่อนครบแล้วไม่ทำงาน', (tester) async {
    await tester.pumpWidget(subject());
    final gesture = await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    // ticker เริ่มเดินที่เฟรมถัดไป ต้องปล่อยหนึ่งเฟรมก่อนจับเวลา
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pump();

    expect(completed, 0);
    expect(cancelled, 1);
  });

  testWidgets('ขยับนิ้วเกิน 8px แล้วยกเลิกทันที', (tester) async {
    await tester.pumpWidget(subject());
    final gesture = await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    // ticker เริ่มเดินที่เฟรมถัดไป ต้องปล่อยหนึ่งเฟรมก่อนจับเวลา
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();
    expect(cancelled, 1);

    await tester.pump(_holdPast);
    expect(completed, 0);
  });

  testWidgets('ขยับนิดเดียวยังนับว่ากดค้างอยู่', (tester) async {
    await tester.pumpWidget(subject());
    final gesture = await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    // ticker เริ่มเดินที่เฟรมถัดไป ต้องปล่อยหนึ่งเฟรมก่อนจับเวลา
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveBy(const Offset(5, 0));
    await tester.pump(_holdPast);

    expect(cancelled, 0);
    expect(completed, 1);
  });

  testWidgets('ความคืบหน้าเดินแบบ linear', (tester) async {
    await tester.pumpWidget(subject());
    await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    // ticker เริ่มเดินที่เฟรมถัดไป ต้องปล่อยหนึ่งเฟรมก่อนจับเวลา
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 140));
    expect(lastProgress, closeTo(0.25, 0.02));

    await tester.pump(const Duration(milliseconds: 140));
    expect(lastProgress, closeTo(0.50, 0.02));

    await tester.pump(const Duration(milliseconds: 140));
    expect(lastProgress, closeTo(0.75, 0.02));
  });

  testWidgets('ความคืบหน้ากลับไปศูนย์หลังทำงานเสร็จ', (tester) async {
    await tester.pumpWidget(subject());
    await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    // ticker เริ่มเดินที่เฟรมถัดไป ต้องปล่อยหนึ่งเฟรมก่อนจับเวลา
    await tester.pump();

    await tester.pump(_holdPast);
    await tester.pump();
    expect(lastProgress, 0);
  });

  testWidgets('ปิดไว้แล้วกดค้างไม่ทำอะไร', (tester) async {
    await tester.pumpWidget(subject(enabled: false));
    await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    // ticker เริ่มเดินที่เฟรมถัดไป ต้องปล่อยหนึ่งเฟรมก่อนจับเวลา
    await tester.pump();

    await tester.pump(_holdPast);
    expect(completed, 0);
    expect(lastProgress, 0);
  });

  testWidgets('ครบเวลาแล้วต้องสั่นด้วย ไม่ใช่แค่ภาพ', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(subject(haptic: HoldHaptic.medium));
    await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    // ticker เริ่มเดินที่เฟรมถัดไป ต้องปล่อยหนึ่งเฟรมก่อนจับเวลา
    await tester.pump();
    await tester.pump(_holdPast);

    expect(calls, ['HapticFeedbackType.mediumImpact']);
  });
}
