import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/sync/sync_plan.dart';

void main() {
  SyncAction plan({String? local, String? remote, String? base}) =>
      planDay(SyncInput(local: local, remote: remote, lastSynced: base));

  group('ไม่ต้องทำอะไร', () {
    test('สองฝั่งเหมือนกัน', () {
      expect(plan(local: 'a', remote: 'a', base: 'a'), SyncAction.none);
    });

    test('ไม่มีทั้งสองฝั่ง', () {
      expect(plan(), SyncAction.none);
    });
  });

  group('ส่งขึ้น', () {
    test('วันใหม่ที่ยังไม่เคยส่ง', () {
      expect(plan(local: 'a'), SyncAction.pushLocal);
    });

    test('แก้บนเครื่องนี้ เซิร์ฟเวอร์ไม่ขยับ', () {
      expect(plan(local: 'b', remote: 'a', base: 'a'), SyncAction.pushLocal);
    });

    test('ลบวันทิ้งบนเครื่องนี้ เซิร์ฟเวอร์ไม่ขยับ', () {
      expect(plan(remote: 'a', base: 'a'), SyncAction.pushLocal);
    });
  });

  group('เอาของเซิร์ฟเวอร์มา', () {
    test('เครื่องอื่นเขียนวันที่เครื่องนี้ไม่มี', () {
      expect(plan(remote: 'a'), SyncAction.takeRemote);
    });

    test('เซิร์ฟเวอร์ขยับ เครื่องนี้ไม่ได้แตะ', () {
      expect(plan(local: 'a', remote: 'b', base: 'a'), SyncAction.takeRemote);
    });
  });

  group('ชนกัน — ห้าม merge ห้ามทิ้งฝั่งใดฝั่งหนึ่ง', () {
    test('สองเครื่องแก้วันเดียวกันคนละทาง', () {
      expect(plan(local: 'b', remote: 'c', base: 'a'), SyncAction.conflict);
    });

    test('สองเครื่องเขียนวันเดียวกันโดยไม่เคยซิงก์', () {
      expect(plan(local: 'a', remote: 'b'), SyncAction.conflict);
    });

    test('ลบบนเครื่องนี้ แต่เซิร์ฟเวอร์แก้ไปแล้ว', () {
      // กรณีนี้อันตรายที่สุด ถ้าให้การลบชนะ งานที่เครื่องอื่นเขียนจะหายเงียบๆ
      expect(plan(remote: 'b', base: 'a'), SyncAction.conflict);
    });
  });

  test('ชื่อไฟล์ของฝั่งที่ชนต้องไม่ถูกอ่านเป็นวัน', () {
    expect(conflictFileName('2026-08-18'), '2026-08-18 (conflict).md');
  });
}
