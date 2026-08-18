/// ส่งออกข้อมูลทั้งหมด — ฟรีเสมอ (§4.7)
///
/// นี่คือคำสัญญาของแบรนด์ ไม่ใช่ฟีเจอร์ระดับพรีเมียม ถ้าวันหนึ่งมันถูกคิดเงิน
/// หลักการข้อ 4 ก็พังทั้งข้อ
///
/// นอกจากปุ่มนี้แล้ว โฟลเดอร์ `lapse/` ยังเปิดจากแอป Files ได้โดยตรง
/// (`UIFileSharingEnabled` ใน Info.plist) ผู้ใช้จึงไม่เคยถูกขังอยู่กับแอปนี้
library;

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class Exporter {
  const Exporter(this.root);

  /// โฟลเดอร์ `lapse/` ทั้งก้อน
  final Directory root;

  /// รวมทุกไฟล์เป็น zip แล้วเปิดแผงแบ่งปันของระบบ
  ///
  /// ชื่อไฟล์ผูกกับวันที่ เพื่อให้ผู้ใช้ที่ส่งออกหลายครั้งแยกออกว่าอันไหนใหม่กว่า
  Future<void> share({DateTime? now}) async {
    final archive = Archive();

    await for (final entity in root.list(recursive: true)) {
      if (entity is! File) continue;
      final bytes = await entity.readAsBytes();
      final name = entity.path.substring(root.parent.path.length + 1);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    if (archive.isEmpty) return;

    final stamp = _stamp(now ?? DateTime.now());
    final zip = File('${(await getTemporaryDirectory()).path}/lapse-$stamp.zip');
    await zip.writeAsBytes(ZipEncoder().encode(archive), flush: true);

    await SharePlus.instance.share(ShareParams(files: [XFile(zip.path)]));
  }

  static String _stamp(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
