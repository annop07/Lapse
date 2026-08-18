import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/model/duration_fmt.dart';
import 'package:lapse/model/wall_level.dart';

void main() {
  test('ขอบของแต่ละระดับตรงกับ §2.7', () {
    expect(wallLevel(0), 0);
    expect(wallLevel(1), 1);
    expect(wallLevel(59), 1);
    expect(wallLevel(60), 2);
    expect(wallLevel(149), 2);
    expect(wallLevel(150), 3);
    expect(wallLevel(259), 3);
    expect(wallLevel(260), 4);
    expect(wallLevel(2000), 4);
  });

  test('เวลาติดลบถือเป็นศูนย์', () {
    expect(wallLevel(-5), 0);
  });

  test('formatHm', () {
    expect(formatHm(0), '0:00');
    expect(formatHm(32), '0:32');
    expect(formatHm(107), '1:47');
    expect(formatHm(725), '12:05');
  });

  test('formatThai', () {
    expect(formatThai(0), '0 นาที');
    expect(formatThai(45), '45 นาที');
    expect(formatThai(120), '2 ชั่วโมง');
    expect(formatThai(160), '2 ชั่วโมง 40 นาที');
  });
}
