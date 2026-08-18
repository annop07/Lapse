/// การนับเวลาของ session หนึ่งครั้ง (§2.4)
///
/// สองกฎที่ห้ามพลาด
///
/// 1. **เวลาคำนวณจากผลต่างของ timestamp ไม่ใช่การนับ tick**
///    ถ้านับ tick แล้วจอดับสิบนาที เวลาจะหายไปทั้งสิบนาที (§6.5 ข้อ 3)
/// 2. **จอล็อกเอง = นับต่อ · สลับไปแอปอื่น = หยุดนับ**
///    ผลคือตัวเลขที่ได้เป็น "เวลาที่ไม่ได้ใช้มือถือทำอย่างอื่น" อยู่แล้วโดยธรรมชาติ
///
/// คลาสนี้ไม่รู้จัก Flutter และรับนาฬิกาเข้ามา เพื่อให้ทดสอบกฎข้างบนได้
/// โดยไม่ต้องรอสิบนาทีจริงๆ
library;

class FocusSession {
  FocusSession({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  Duration _banked = Duration.zero;
  DateTime? _runningSince;

  bool get isRunning => _runningSince != null;

  /// เวลาที่สะสมได้ถึงตอนนี้ · อ่านได้ตลอดโดยไม่กระทบการนับ
  ///
  /// การแตะจอเพื่อดูเวลาจึงไม่หยุดนับ ตามตารางใน §2.4
  Duration get elapsed {
    final since = _runningSince;
    if (since == null) return _banked;
    return _banked + _clock().difference(since);
  }

  /// เวลาที่จะถูกบวกเข้ารายการจริงๆ หน่วยวินาที
  ///
  /// **ปัดลง** โดยตั้งใจ ตัวเลขบนกำแพงต้องไม่เคยมากกว่าเวลาที่ใช้ไปจริง
  /// เพราะทั้งผลิตภัณฑ์วางอยู่บนความน่าเชื่อถือของตัวเลขนั้น (§8 ข้อ 1)
  int get seconds => elapsed.inSeconds;

  /// นับทุกวินาที ไม่ทิ้งอะไรเลย
  ///
  /// สเปก §2.3 เดิมทิ้ง session ที่สั้นกว่าหนึ่งนาที เพราะตอนนั้นหน่วยเป็นนาที
  /// 30 วินาทีจึงปัดเป็นศูนย์และไม่มีความหมายที่จะเก็บ พอนับวินาทีได้แล้ว
  /// เหตุผลนั้นหมดไป · การกดค้าง 560ms กับ 720ms ยังกันการเริ่มจบโดยบังเอิญอยู่
  bool get countsAtAll => seconds >= 1;

  void start() {
    _banked = Duration.zero;
    _runningSince = _clock();
  }

  /// ผู้ใช้สลับไปแอปอื่น — หยุดนับ
  void pause() {
    final since = _runningSince;
    if (since == null) return;
    _banked += _clock().difference(since);
    _runningSince = null;
  }

  /// กลับเข้ามาในแอป — นับต่อจากเดิม
  void resume() {
    if (_runningSince != null) return;
    _runningSince = _clock();
  }

  /// คืนเวลาที่ถูกหักไปตอน [pause] กลับเข้า session
  ///
  /// ใช้ตอนที่รู้ทีหลังว่าช่วงที่แอปหลุดโฟกัสไปนั้นคือ "จอล็อกเอง" ไม่ใช่ "สลับแอป"
  /// เราตัดสินตอนกลับเข้าแอปแทนที่จะตัดสินตอนออก เพราะลำดับการยิงสัญญาณของ iOS
  /// ระหว่าง lifecycle กับ protectedData ไม่ได้รับประกันว่าอันไหนมาก่อน
  void credit(Duration gap) {
    if (gap <= Duration.zero) return;
    _banked += gap;
  }

  /// กดค้างจนครบเพื่อจบ · คืนจำนวนวินาทีที่จะบวกเข้ารายการ
  int stop() {
    pause();
    final result = countsAtAll ? seconds : 0;
    _banked = Duration.zero;
    return result;
  }
}
