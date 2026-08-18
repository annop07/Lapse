/// ตัวติดต่อเซิร์ฟเวอร์ — เข้าสู่ระบบ โปรไฟล์ และเพื่อน
///
/// รวมไว้คลาสเดียวเพราะทั้งสามเรื่องพันกันอยู่แล้ว และแอปนี้ยึดหลักว่า
/// ใช้สิ่งที่เบาที่สุดที่พอใช้ การแตกเป็นสามคลาสจะได้ชั้นนามธรรมที่ไม่มีใครใช้
///
/// การเข้าสู่ระบบใช้รหัสหกหลักทางอีเมล ไม่ใช่รหัสผ่าน
/// เพราะรหัสผ่านต้องมีหน้าตั้งรหัส หน้าลืมรหัส และหน้าเปลี่ยนรหัส
/// ซึ่งเป็นสามหน้าที่สเปกไม่ได้ขอ และผู้ใช้ต้องจำอะไรเพิ่มอีกหนึ่งอย่าง
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// เพื่อนหนึ่งคนพร้อมเวลาของเขา
class Friend {
  const Friend({required this.id, required this.handle, required this.seconds});

  final String id;
  final String handle;

  /// วินาทีต่อวัน — สิ่งเดียวที่เราเห็นของเขา
  final Map<String, int> seconds;
}

class LapseServer {
  LapseServer(this._client);

  final SupabaseClient _client;

  static Future<LapseServer> start() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    return LapseServer(Supabase.instance.client);
  }

  Session? get session => _client.auth.currentSession;
  String? get userId => _client.auth.currentUser?.id;
  String? get email => _client.auth.currentUser?.email;
  bool get signedIn => session != null;

  Stream<AuthState> get changes => _client.auth.onAuthStateChange;

  // ---- เข้าสู่ระบบ ----

  /// ส่งรหัสหกหลักไปที่อีเมล · สมัครให้เองถ้ายังไม่มีบัญชี
  Future<void> sendCode(String email) =>
      _client.auth.signInWithOtp(email: email.trim());

  /// ยืนยันรหัสที่ผู้ใช้พิมพ์
  Future<void> verifyCode(String email, String code) async {
    await _client.auth.verifyOTP(
      type: OtpType.email,
      email: email.trim(),
      token: code.trim(),
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  // ---- โปรไฟล์ ----

  /// handle ต้องเป็น `@` ตามด้วยตัวเล็ก ตัวเลข หรือขีดล่าง 2–20 ตัว
  ///
  /// กฎเดียวกับที่ฐานข้อมูลบังคับไว้ · เช็คที่นี่ด้วยเพื่อบอกผู้ใช้ก่อนยิงไป
  static final _handlePattern = RegExp(r'^@[a-z0-9_]{2,20}$');

  static bool isValidHandle(String handle) =>
      _handlePattern.hasMatch(handle.trim());

  /// จอง handle ของตัวเอง · คืนข้อความบอกเหตุถ้าไม่สำเร็จ
  Future<String?> claimHandle(String handle) async {
    final id = userId;
    if (id == null) return 'ยังไม่ได้เข้าสู่ระบบ';

    final value = handle.trim().toLowerCase();
    if (!isValidHandle(value)) {
      return 'ใช้ @ ตามด้วยตัวอักษรเล็ก ตัวเลข หรือขีดล่าง 2–20 ตัว';
    }

    try {
      await _client.from('profiles').upsert({'id': id, 'handle': value});
      return null;
    } on PostgrestException catch (e) {
      // 23505 คือ unique violation · handle ซ้ำกับคนอื่น
      if (e.code == '23505') return 'ชื่อนี้มีคนใช้แล้ว';
      return e.message;
    }
  }

  Future<String?> myHandle() async {
    final id = userId;
    if (id == null) return null;
    final row = await _client
        .from('profiles')
        .select('handle')
        .eq('id', id)
        .maybeSingle();
    return row?['handle'] as String?;
  }

  // ---- เพื่อน ----

  /// เพิ่มเพื่อนด้วย handle · คืนข้อความบอกเหตุถ้าไม่สำเร็จ
  Future<String?> addFriend(String handle) async {
    final id = userId;
    if (id == null) return 'ยังไม่ได้เข้าสู่ระบบ';

    final value = handle.trim().toLowerCase();
    if (!isValidHandle(value)) return 'รูปแบบชื่อไม่ถูกต้อง';

    final row = await _client
        .from('profiles')
        .select('id')
        .eq('handle', value)
        .maybeSingle();
    if (row == null) return 'ไม่พบ $value';

    final friendId = row['id'] as String;
    if (friendId == id) return 'นี่คือชื่อของคุณเอง';

    try {
      await _client.from('friends').insert({
        'user_id': id,
        'friend_id': friendId,
      });
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '23505') return 'เพิ่มไปแล้ว';
      // ทริกเกอร์จำกัด 30 คนส่งข้อความไทยกลับมาตรงๆ
      return e.message;
    }
  }

  Future<void> removeFriend(String friendId) async {
    final id = userId;
    if (id == null) return;
    await _client
        .from('friends')
        .delete()
        .eq('user_id', id)
        .eq('friend_id', friendId);
  }

  /// เพื่อนทั้งหมด **เรียงตามลำดับที่เพิ่ม** ห้ามเรียงตามเวลา (§4.4)
  Future<List<Friend>> friends() async {
    final id = userId;
    if (id == null) return const [];

    final edges = await _client
        .from('friends')
        .select('friend_id, created_at, profiles!friends_friend_id_fkey(handle)')
        .eq('user_id', id)
        .order('created_at');

    final result = <Friend>[];
    for (final edge in edges as List) {
      final friendId = edge['friend_id'] as String;
      final profile = edge['profiles'] as Map<String, dynamic>?;

      final rows = await _client
          .from('day_totals')
          .select('day, seconds')
          .eq('user_id', friendId);

      result.add(Friend(
        id: friendId,
        handle: profile?['handle'] as String? ?? '@?',
        seconds: {
          for (final r in rows as List)
            r['day'] as String: (r['seconds'] as num).toInt(),
        },
      ));
    }
    return result;
  }
}
