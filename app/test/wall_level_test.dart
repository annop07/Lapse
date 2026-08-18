import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/model/duration_fmt.dart';
import 'package:lapse/model/wall_level.dart';

void main() {
  test('ขอบของแต่ละระดับยังเป็นนาทีเหมือนเดิม แม้จะรับค่าเป็นวินาที', () {
    expect(wallLevel(0), 0);
    expect(wallLevel(1), 1);
    expect(wallLevel(59 * 60 + 59), 1);
    expect(wallLevel(60 * 60), 2);
    expect(wallLevel(149 * 60 + 59), 2);
    expect(wallLevel(150 * 60), 3);
    expect(wallLevel(259 * 60 + 59), 3);
    expect(wallLevel(260 * 60), 4);
  });

  test('ไม่กี่วินาทีก็ยังนับเป็นระดับหนึ่ง ไม่ใช่ศูนย์', () {
    expect(wallLevel(5), 1);
  });

  test('เวลาติดลบถือเป็นศูนย์', () {
    expect(wallLevel(-5), 0);
  });

  test('formatHms', () {
    expect(formatHms(0), '0:00:00');
    expect(formatHms(45), '0:00:45');
    expect(formatHms(1920), '0:32:00');
    expect(formatHms(6443), '1:47:23');
    expect(formatHms(43509), '12:05:09');
  });

  test('formatThai ละเอียดถึงวินาทีเฉพาะตอนที่ยังไม่ถึงนาที', () {
    expect(formatThai(0), '0 วินาที');
    expect(formatThai(45), '45 วินาที');
    expect(formatThai(60), '1 นาที');
    expect(formatThai(45 * 60), '45 นาที');
    expect(formatThai(120 * 60), '2 ชั่วโมง');
    expect(formatThai(160 * 60), '2 ชั่วโมง 40 นาที');
  });
}
