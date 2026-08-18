import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/ui/wall/wall_grid.dart';

void main() {
  group('snapToPixel', () {
    test('DPR 1 ปัดเป็นจำนวนเต็ม', () {
      expect(snapToPixel(12.4, 1), 12);
      expect(snapToPixel(12.6, 1), 13);
    });

    test('DPR 2 ปัดเป็นครึ่งพิกเซล', () {
      expect(snapToPixel(12.4, 2), 12.5);
      expect(snapToPixel(12.1, 2), 12.0);
    });

    test('DPR 3 ปัดเป็นหนึ่งในสาม', () {
      expect(snapToPixel(12.4, 3), closeTo(12.3333, 0.0001));
      // 12.5 × 3 = 37.5 ปัดขึ้นเป็น 38 จึงได้ 12.667 ไม่ใช่ 12.5
      expect(snapToPixel(12.5, 3), closeTo(12.6667, 0.0001));
    });

    test('ค่าที่ลงตัวอยู่แล้วไม่ถูกขยับ', () {
      for (final dpr in [1.0, 2.0, 3.0]) {
        expect(snapToPixel(9.0, dpr), 9.0);
        expect(snapToPixel(0.0, dpr), 0.0);
      }
    });

    test('ทุกช่องในทั้งปีตกบนเส้นพิกเซลจริง', () {
      // นี่คือสิ่งที่ S2 ต้องพิสูจน์ — คอลัมน์ที่ 40 ต้องคมเท่าคอลัมน์แรก
      for (final dpr in [2.0, 3.0]) {
        for (var column = 0; column < 53; column++) {
          final x = snapToPixel(column * (kWallCell + kWallGap), dpr);
          final physical = x * dpr;
          expect(
            physical,
            closeTo(physical.roundToDouble(), 1e-9),
            reason: 'คอลัมน์ $column ที่ DPR $dpr ตกกลางพิกเซล',
          );
        }
      }
    });
  });

  group('เรขาคณิตของตาราง', () {
    test('ขนาดของทั้งปี', () {
      // 53 คอลัมน์ = 53 ช่อง + 52 ช่องว่าง
      expect(WallGridPainter.gridWidth(53), 53 * 7 + 52 * 2);
      expect(WallGridPainter.gridHeight(), 7 * 7 + 6 * 2);
    });

    test('จำนวนคอลัมน์ปัดขึ้นเสมอ', () {
      WallGridPainter painter(int days) => WallGridPainter(
            levels: List<int?>.filled(days, 0),
            ramp: const [],
            devicePixelRatio: 3,
          );

      expect(painter(7).columns, 1);
      expect(painter(8).columns, 2);
      expect(painter(365).columns, 53);
      expect(painter(371).columns, 53);
    });
  });
}
