/// เดินวงจรจริงของแอปด้วยการแตะและกดค้างจริงบนเครื่อง
///
/// รันด้วย `flutter test integration_test/daily_loop_test.dart -d <device>`
///
/// ชุดนี้มีไว้แทนสิ่งที่ widget test ตอบไม่ได้: การกดค้างที่แข่งกับการเลื่อนจอ
/// การเปลี่ยนหน้าจริง และการที่แอปอ่านเขียนไฟล์ในเครื่องจริง
/// เทสต์ชุดเดียวกันนี้เอาไปรันบน iPhone จริงได้ทันทีโดยไม่ต้องแก้อะไร
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lapse/main.dart' as app;
import 'package:lapse/ui/day/day_screen.dart';
import 'package:lapse/ui/day/line_row.dart';
import 'package:lapse/ui/focus/focus_screen.dart';
import 'package:lapse/ui/onboarding/onboarding_screen.dart';
import 'package:lapse/ui/settings/settings_screen.dart';
import 'package:lapse/ui/wall/wall_screen.dart';
import 'package:path_provider/path_provider.dart';

/// ปล่อยให้เฟรมเดินไปสักพักโดยไม่ใช้ pumpAndSettle
///
/// pumpAndSettle รอจนไม่มีแอนิเมชันเหลือ ซึ่งบนแอปจริงที่มีตัวจับเวลาเดินอยู่
/// อาจไม่มีวันเกิดขึ้น
Future<void> settle(WidgetTester tester, [int frames = 20]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> wipe() async {
  final docs = await getApplicationDocumentsDirectory();
  final root = Directory('${docs.path}/lapse');
  if (await root.exists()) await root.delete(recursive: true);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(wipe);

  testWidgets('เปิดครั้งแรกแล้วเขียนบรรทัดแรกจนเข้าหน้าวัน', (tester) async {
    app.main();
    await settle(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, 'อ่านเลข บทที่ 4');
    await settle(tester);
    await tester.tap(find.text('ต่อไป'));
    await settle(tester);

    expect(find.byType(DayScreen), findsOneWidget);
    expect(find.byType(LineRow), findsOneWidget);
    expect(find.text('อ่านเลข บทที่ 4'), findsWidgets);
  });

  testWidgets('กดค้างที่บรรทัดแล้วเข้าจอโฟกัส แตะดูเวลา แล้วกดค้างจบ',
      (tester) async {
    app.main();
    await settle(tester);
    await tester.enterText(find.byType(EditableText).first, 'ท่องศัพท์');
    await settle(tester);
    await tester.tap(find.text('ต่อไป'));
    await settle(tester);

    // กดค้าง 560ms ที่แถว
    final row = tester.getCenter(find.byType(LineRow));
    final hold = await tester.startGesture(row);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await hold.up();
    await settle(tester);

    expect(find.byType(FocusScreen), findsOneWidget);

    // แตะหนึ่งครั้งเพื่อดูเวลา — ต้องไม่จบ session
    await tester.tapAt(tester.getCenter(find.byType(FocusScreen)));
    await settle(tester);
    expect(find.byType(FocusScreen), findsOneWidget);

    // กดค้าง 720ms เพื่อจบ
    final end = await tester.startGesture(
      tester.getCenter(find.byType(FocusScreen)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await end.up();
    await settle(tester);

    expect(find.byType(FocusScreen), findsNothing);
    expect(find.byType(DayScreen), findsOneWidget);
  });

  testWidgets('จบ session ที่นับได้แล้วเด้งลงช่องบันทึกพร้อมคำถาม',
      (tester) async {
    app.main();
    await settle(tester);
    await tester.enterText(find.byType(EditableText).first, 'อ่านเลข');
    await settle(tester);
    await tester.tap(find.text('ต่อไป'));
    await settle(tester);

    final hold = await tester.startGesture(
      tester.getCenter(find.byType(LineRow)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await hold.up();
    await settle(tester);
    expect(find.byType(FocusScreen), findsOneWidget);

    // เวลาต้องเดินจริง 1 นาที ไม่มีทางลัด เพราะ §2.3 ทิ้ง session ที่สั้นกว่านั้น
    // และนี่คือกลไกที่แยกผลิตภัณฑ์นี้ออกจากคู่แข่ง จึงคุ้มที่จะรอ
    final until = DateTime.now().add(const Duration(seconds: 62));
    while (DateTime.now().isBefore(until)) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    final end = await tester.startGesture(
      tester.getCenter(find.byType(FocusScreen)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await end.up();
    // toast อยู่แค่ 2200ms ต้องตรวจก่อนที่มันจะจางไป
    await settle(tester, 12);

    expect(find.byType(FocusScreen), findsNothing);

    // เวลาถูกบวกเข้ารายการ
    expect(find.text('0:01'), findsWidgets);

    // toast บอกข้อเท็จจริง ไม่ใช่คำชม
    expect(find.text('+ 1 นาที'), findsOneWidget);

    // รอให้เลื่อนลงและไฮไลต์เสร็จ
    await settle(tester, 40);

    // placeholder เปลี่ยนเป็นคำถามชวนทบทวน
    expect(
      find.text('จำอะไรได้บ้างจาก “อ่านเลข” — เขียนมั่วๆ ก็ได้'),
      findsOneWidget,
    );

    // เคอร์เซอร์อยู่ในช่องบันทึกแล้ว พิมพ์ได้ทันทีโดยไม่ต้องแตะ
    await tester.enterText(
      find.byType(EditableText).last,
      'จำได้แค่สูตรอนุพันธ์',
    );
    await settle(tester);

    final docs = await getApplicationDocumentsDirectory();
    final today = DateTime.now();
    final name = '${today.year}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final file = File('${docs.path}/lapse/days/$name.md');
    final text = await file.readAsString();

    expect(text, contains('- [ ] อ่านเลข [0:01]'));
    expect(text, contains('---'));
    expect(text, contains('จำได้แค่สูตรอนุพันธ์'));
  });

  testWidgets('ปัดเปลี่ยนวัน และห้ามไปวันอนาคต', (tester) async {
    app.main();
    await settle(tester);
    await tester.enterText(find.byType(EditableText).first, 'สรุปฟิสิกส์');
    await settle(tester);
    await tester.tap(find.text('ต่อไป'));
    await settle(tester);

    final today = DateTime.now();
    expect(find.text('${today.day} ${_month(today.month)}'), findsOneWidget);

    // ปัดขวาเพื่อถอยไปเมื่อวาน
    await tester.fling(find.byType(DayScreen), const Offset(300, 0), 800);
    await settle(tester);

    final yesterday = today.subtract(const Duration(days: 1));
    expect(
      find.text('${yesterday.day} ${_month(yesterday.month)}'),
      findsOneWidget,
    );

    // ปัดซ้ายกลับมาวันนี้
    await tester.fling(find.byType(DayScreen), const Offset(-300, 0), 800);
    await settle(tester);
    expect(find.text('${today.day} ${_month(today.month)}'), findsOneWidget);

    // ปัดซ้ายอีกครั้งต้องไปไหนไม่ได้
    await tester.fling(find.byType(DayScreen), const Offset(-300, 0), 800);
    await settle(tester);
    expect(find.text('${today.day} ${_month(today.month)}'), findsOneWidget);
  });

  testWidgets('เปิดกำแพงและหน้าตั้งค่าจากหน้าวัน', (tester) async {
    app.main();
    await settle(tester);
    await tester.enterText(find.byType(EditableText).first, 'อ่านสังคม');
    await settle(tester);
    await tester.tap(find.text('ต่อไป'));
    await settle(tester);

    await tester.tap(find.text('กำแพง'));
    await settle(tester);
    expect(find.byType(WallScreen), findsOneWidget);
    expect(find.text('ไม่มีอันดับ — เรียงตามลำดับที่เพิ่ม'), findsOneWidget);

    await tester.tap(find.text('‹ วัน'));
    await settle(tester);
    expect(find.byType(WallScreen), findsNothing);

    await tester.tap(find.text('LAPSE'));
    await settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('สลับธีมแล้วสีพื้นเปลี่ยนจริง', (tester) async {
    app.main();
    await settle(tester);
    await tester.enterText(find.byType(EditableText).first, 'ทบทวนเลข');
    await settle(tester);
    await tester.tap(find.text('ต่อไป'));
    await settle(tester);
    await tester.tap(find.text('LAPSE'));
    await settle(tester);

    Color background() {
      final box = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(ColoredBox),
        ).first,
      );
      return box.color;
    }

    await tester.tap(find.text('สว่าง'));
    await settle(tester);
    final light = background();

    await tester.tap(find.text('มืด'));
    await settle(tester);
    expect(background(), isNot(light));
  });

  testWidgets('ลบข้อมูลทั้งหมดต้องยืนยันก่อน', (tester) async {
    app.main();
    await settle(tester);
    await tester.enterText(find.byType(EditableText).first, 'ทำข้อสอบเก่า');
    await settle(tester);
    await tester.tap(find.text('ต่อไป'));
    await settle(tester);
    await tester.tap(find.text('LAPSE'));
    await settle(tester);

    await tester.tap(find.text('ลบข้อมูลทั้งหมด'));
    await settle(tester);
    expect(find.text('ลบทุกอย่างถาวร กู้คืนไม่ได้'), findsOneWidget);

    // เปลี่ยนใจได้
    await tester.tap(find.text('ไม่ลบ'));
    await settle(tester);
    expect(find.text('ลบทุกอย่างถาวร กู้คืนไม่ได้'), findsNothing);

    await tester.tap(find.text('ลบข้อมูลทั้งหมด'));
    await settle(tester);
    await tester.tap(find.text('ลบเลย'));
    await settle(tester);

    final docs = await getApplicationDocumentsDirectory();
    final days = Directory('${docs.path}/lapse/days');
    expect(await days.list().isEmpty, isTrue);
  });
}

const _months = [
  'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
  'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
];

String _month(int m) => _months[m - 1];
