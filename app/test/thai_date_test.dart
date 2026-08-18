import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/model/thai_date.dart';

void main() {
  test('หัววันตรงกับโปรโตไทป์', () {
    final d = DateTime(2026, 8, 18);
    expect(thaiDayAndMonth(d), '18 สิงหาคม');
    expect(thaiWeekdayAndYear(d), 'อังคาร · 2026');
  });

  test('อาทิตย์เป็นแถวแรกของกำแพง', () {
    expect(sundayFirstWeekday(DateTime(2026, 8, 16)), 0); // อาทิตย์
    expect(sundayFirstWeekday(DateTime(2026, 8, 17)), 1); // จันทร์
    expect(sundayFirstWeekday(DateTime(2026, 8, 22)), 6); // เสาร์
  });

  test('ชื่อวันครบทั้งเจ็ด', () {
    final names = <String>{};
    for (var i = 16; i <= 22; i++) {
      names.add(thaiWeekday(DateTime(2026, 8, i)));
    }
    expect(names, {
      'อาทิตย์', 'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์',
    });
  });

  test('ชื่อเดือนย่อครบสิบสอง', () {
    expect(thaiMonthShort(1), 'ม.ค.');
    expect(thaiMonthShort(8), 'ส.ค.');
    expect(thaiMonthShort(12), 'ธ.ค.');
  });

  test('ปีเป็นคริสต์ศักราช ไม่ใช่พุทธศักราช', () {
    expect(thaiWeekdayAndYear(DateTime(2026, 1, 1)), contains('2026'));
  });
}
