/// ตัดสินใจว่าจะทำอะไรกับแต่ละวันตอนซิงก์ (§2.6)
///
/// ไฟล์นี้เป็นฟังก์ชันบริสุทธิ์ ไม่แตะทั้งดิสก์และเครือข่าย
/// เพราะกฎการชนกันเป็นส่วนที่ผิดแล้วเจ็บที่สุด — ผิดแล้วผู้ใช้เสียงานที่เขียนไป
/// และเป็นส่วนที่ทดสอบยากที่สุดถ้าปนกับ I/O
///
/// กฎจากสเปก
///
/// > ชนกัน (conflict) → เก็บทั้งสองฝั่งเป็น `2026-08-18.md` และ
/// > `2026-08-18 (conflict).md` ห้าม merge อัตโนมัติ ห้ามทิ้งของฝั่งใดฝั่งหนึ่ง
library;

/// สิ่งที่ต้องทำกับวันหนึ่ง
enum SyncAction {
  /// ไม่ต้องทำอะไร ทั้งสองฝั่งตรงกันอยู่แล้ว
  none,

  /// เอาของเซิร์ฟเวอร์มาทับ — เครื่องนี้ไม่ได้แก้อะไรตั้งแต่ซิงก์ครั้งก่อน
  takeRemote,

  /// ส่งของเครื่องนี้ขึ้นไป — เซิร์ฟเวอร์ไม่ได้เปลี่ยนตั้งแต่ซิงก์ครั้งก่อน
  pushLocal,

  /// ทั้งสองฝั่งแก้ไปคนละทาง — เก็บทั้งคู่ ห้ามเลือกข้าง
  conflict,
}

/// สภาพของวันหนึ่งจากสามมุม
class SyncInput {
  const SyncInput({this.local, this.remote, this.lastSynced});

  /// เนื้อไฟล์บนเครื่องนี้ · null = ไม่มีไฟล์
  final String? local;

  /// เนื้อไฟล์บนเซิร์ฟเวอร์ · null = ยังไม่เคยส่งขึ้นไป
  final String? remote;

  /// เนื้อไฟล์ตอนซิงก์สำเร็จครั้งล่าสุด · null = วันนี้ยังไม่เคยซิงก์
  ///
  /// ตัวนี้คือสิ่งที่ทำให้แยก "ใครเป็นคนแก้" ออกจากกันได้
  /// ถ้าไม่มีมัน เราจะรู้แค่ว่าสองฝั่งต่างกัน แต่ไม่รู้ว่าใครขยับ
  final String? lastSynced;
}

/// ตัดสินว่าวันนี้ต้องทำอะไร
SyncAction planDay(SyncInput day) {
  final local = day.local;
  final remote = day.remote;
  final base = day.lastSynced;

  if (local == remote) return SyncAction.none;

  // มีแค่ฝั่งเดียวและยังไม่เคยซิงก์ — ไม่ใช่การชนกัน แค่ยังไม่รู้จักกัน
  if (remote == null) return SyncAction.pushLocal;
  if (local == null) {
    // เคยซิงก์แล้วแต่ตอนนี้ไม่มีไฟล์ = ผู้ใช้ลบวันนั้นทิ้งบนเครื่องนี้
    // ถ้าเซิร์ฟเวอร์ก็ไม่ได้เปลี่ยนตั้งแต่นั้น ให้การลบมีผล
    if (base != null && base == remote) return SyncAction.pushLocal;
    // เซิร์ฟเวอร์เปลี่ยนไปด้วย หรือเครื่องนี้ยังไม่เคยเห็นวันนี้เลย
    return base == null ? SyncAction.takeRemote : SyncAction.conflict;
  }

  final localMoved = local != base;
  final remoteMoved = remote != base;

  if (localMoved && remoteMoved) return SyncAction.conflict;
  if (localMoved) return SyncAction.pushLocal;
  return SyncAction.takeRemote;
}

/// ชื่อไฟล์ที่ใช้เก็บของอีกฝั่งตอนชนกัน (§2.6)
///
/// ตั้งใจให้ `parseDateKey` อ่านไม่ออก แอปจะได้ไม่นับมันเป็นวันหนึ่ง
/// มันเป็นแค่ไฟล์ที่วางไว้ให้ผู้ใช้เปิดอ่านเองแล้วตัดสินใจ
String conflictFileName(String dateKey) => '$dateKey (conflict).md';
