/// ข้อความทั้งหมดที่ผู้ใช้เห็น สองภาษา
///
/// ไทยเป็นภาษาตั้งต้นเพราะตลาดแรกคือไทย อังกฤษมีไว้เพราะสเปกตั้งใจขยายออก
/// ต่างประเทศตั้งแต่ต้น และไม่มีอะไรเฉพาะไทยเหลืออยู่ในผลิตภัณฑ์แล้ว
///
/// **ข้อความอังกฤษเป็นตัวพิมพ์เล็กทั้งหมด** ตามกฎน้ำเสียงใน CLAUDE.md
/// ไม่ใช่ความผิดพลาดในการพิมพ์ · ตัวใหญ่ต้นประโยคทำให้เสียงดังกว่าที่ควร
/// สำหรับแอปที่ทั้งตัวพยายามเงียบ
library;

import 'package:flutter/widgets.dart';

enum Language {
  /// ตามภาษาของเครื่อง
  auto,
  thai,
  english,
}

/// เลือกชุดข้อความจากค่าที่ผู้ใช้ตั้งไว้และภาษาของเครื่อง
Strings stringsFor(Language choice, Locale deviceLocale) => switch (choice) {
      Language.thai => const ThaiStrings(),
      Language.english => const EnglishStrings(),
      Language.auto => deviceLocale.languageCode == 'th'
          ? const ThaiStrings()
          : const EnglishStrings(),
    };

abstract class Strings {
  const Strings();

  bool get isThai;

  // ---- หน้าวัน ----
  String get wallLink;
  String get newLine;
  String get holdHint;
  String get journalPlaceholder;

  /// placeholder หลังจบ session — ชื่อรายการอยู่ในเครื่องหมายคำพูด
  String recallFrom(String what);
  String get recallAnything;

  // ---- จอโฟกัส ----
  String get untitled;
  String get focusHint;

  // ---- กำแพง ----
  String get backToDay;
  String get backToWall;
  String get backToSettings;
  String get less;
  String get more;
  String get notRead;
  String get noRanking;
  String get addFriend;
  String get you;
  String summary(int hours, int days, int year);
  String hoursInYear(int hours, int year);

  // ---- แบ่งปัน ----
  String get share;
  String get preparing;
  String get thisYear;

  // ---- ตั้งค่า ----
  String get theme;
  String get themeAuto;
  String get themeLight;
  String get themeDark;
  String get language;
  String get languageAuto;
  String get languageThai;
  String get languageEnglish;
  String get handleLabel;
  String get handlePlaceholder;
  String get handleUnset;
  String get yourData;
  String get exportAll;
  String get exportNote;
  String get deleteAll;
  String get deleteConfirm;
  String get deleteYes;
  String get deleteNo;
  String get about;
  String get accountSection;
  String get accountEntry;
  String get accountEntryNote;

  // ---- บัญชี ----
  String get signIn;
  String get signInNote;
  String get email;
  String get sendCode;
  String get sending;
  String codeSentTo(String email);
  String get codePlaceholder;
  String get verify;
  String get verifying;
  String get resend;
  String get account;
  String get handleForFriends;
  String get saveHandle;
  String get saving;
  String get saved;
  String get signOut;
  String get signOutNote;

  // ---- เพิ่มเพื่อน ----
  String get addFriendTitle;
  String get addFriendNote;
  String get friendHandlePlaceholder;
  String get add;
  String get adding;
  String get close;

  // ---- เปิดครั้งแรก ----
  String get onboardTitle;
  String get onboardNote;
  String get onboardExample;
  String get next;
}

class ThaiStrings extends Strings {
  const ThaiStrings();

  @override
  bool get isThai => true;

  @override
  String get wallLink => 'กำแพง';
  @override
  String get newLine => '+ บรรทัดใหม่';
  @override
  String get holdHint => 'กดค้างที่บรรทัดเพื่อเริ่ม';
  @override
  String get journalPlaceholder => 'วันนี้เป็นยังไงบ้าง';
  @override
  String recallFrom(String what) => 'จำอะไรได้บ้างจาก “$what” — เขียนมั่วๆ ก็ได้';
  @override
  String get recallAnything => 'จำอะไรได้บ้าง — เขียนมั่วๆ ก็ได้';

  @override
  String get untitled => 'ไม่มีชื่อ';
  @override
  String get focusHint => 'แตะเพื่อดูเวลา\nกดค้างเพื่อจบ';

  @override
  String get backToDay => '‹ วัน';
  @override
  String get backToWall => '‹ กำแพง';
  @override
  String get backToSettings => '‹ ตั้งค่า';
  @override
  String get less => 'น้อย';
  @override
  String get more => 'มาก';
  @override
  String get notRead => 'ไม่ได้อ่าน';
  @override
  String get noRanking => 'ไม่มีอันดับ — เรียงตามลำดับที่เพิ่ม';
  @override
  String get addFriend => '+ เพิ่มเพื่อน';
  @override
  String get you => 'คุณ';
  @override
  String summary(int hours, int days, int year) =>
      '$hours ชั่วโมง · $days วัน ในปี $year';
  @override
  String hoursInYear(int hours, int year) => '$hours ชั่วโมง ในปี $year';

  @override
  String get share => 'แบ่งปัน';
  @override
  String get preparing => 'กำลังเตรียม';
  @override
  String get thisYear => 'ปีนี้';

  @override
  String get theme => 'ธีม';
  @override
  String get themeAuto => 'ตามระบบ';
  @override
  String get themeLight => 'สว่าง';
  @override
  String get themeDark => 'มืด';
  @override
  String get language => 'ภาษา';
  @override
  String get languageAuto => 'ตามระบบ';
  @override
  String get languageThai => 'ไทย';
  @override
  String get languageEnglish => 'english';
  @override
  String get handleLabel => 'ชื่อผู้ใช้';
  @override
  String get handlePlaceholder => '@ชื่อของคุณ';
  @override
  String get handleUnset => '@ยังไม่ได้ตั้ง';
  @override
  String get yourData => 'ข้อมูลของคุณ';
  @override
  String get exportAll => 'ส่งออกทั้งหมด';
  @override
  String get exportNote => 'ไฟล์ข้อความล้วน อ่านได้ด้วยตาเปล่า ฟรีเสมอ';
  @override
  String get deleteAll => 'ลบข้อมูลทั้งหมด';
  @override
  String get deleteConfirm => 'ลบทุกอย่างถาวร กู้คืนไม่ได้';
  @override
  String get deleteYes => 'ลบเลย';
  @override
  String get deleteNo => 'ไม่ลบ';
  @override
  String get about => 'lapse · หนึ่งวัน หนึ่งหน้า';
  @override
  String get accountSection => 'บัญชีและซิงก์';
  @override
  String get accountEntry => 'บัญชี';
  @override
  String get accountEntryNote => 'เข้าสู่ระบบเพื่อซิงก์ข้ามเครื่องและเพิ่มเพื่อน';

  @override
  String get signIn => 'เข้าสู่ระบบ';
  @override
  String get signInNote => 'ซิงก์ข้อมูลข้ามเครื่อง ไม่เข้าสู่ระบบก็ใช้ได้ตามปกติ';
  @override
  String get email => 'อีเมล';
  @override
  String get sendCode => 'ส่งรหัสไปที่อีเมล';
  @override
  String get sending => 'กำลังส่ง';
  @override
  String codeSentTo(String email) => 'ส่งรหัสหกหลักไปที่ $email แล้ว';
  @override
  String get codePlaceholder => 'รหัสหกหลัก';
  @override
  String get verify => 'ยืนยัน';
  @override
  String get verifying => 'กำลังตรวจ';
  @override
  String get resend => 'ส่งรหัสใหม่';
  @override
  String get account => 'บัญชี';
  @override
  String get handleForFriends =>
      'เพื่อนใช้ชื่อนี้หาคุณเจอ · ตัวอักษรเล็ก ตัวเลข หรือขีดล่าง';
  @override
  String get saveHandle => 'บันทึกชื่อ';
  @override
  String get saving => 'กำลังบันทึก';
  @override
  String get saved => 'บันทึกแล้ว';
  @override
  String get signOut => 'ออกจากระบบ';
  @override
  String get signOutNote => 'ข้อมูลในเครื่องยังอยู่ครบหลังออกจากระบบ';

  @override
  String get addFriendTitle => 'เพิ่มเพื่อน';
  @override
  String get addFriendNote => 'เห็นได้แค่เวลาต่อวัน สิ่งที่เขาเขียนเป็นของเขา';
  @override
  String get friendHandlePlaceholder => '@ชื่อของเขา';
  @override
  String get add => 'เพิ่ม';
  @override
  String get adding => 'กำลังเพิ่ม';
  @override
  String get close => 'ปิด';

  @override
  String get onboardTitle => 'วันนี้จะทำอะไร';
  @override
  String get onboardNote => 'เขียนสักบรรทัด แก้ทีหลังได้';
  @override
  String get onboardExample => 'อ่านเลข บทที่ 4';
  @override
  String get next => 'ต่อไป';
}

/// ตัวพิมพ์เล็กทั้งหมดโดยตั้งใจ ดูหมายเหตุบนสุดของไฟล์
class EnglishStrings extends Strings {
  const EnglishStrings();

  @override
  bool get isThai => false;

  @override
  String get wallLink => 'wall';
  @override
  String get newLine => '+ new line';
  @override
  String get holdHint => 'hold a line to start';
  @override
  String get journalPlaceholder => 'how was today';
  @override
  String recallFrom(String what) =>
      'what do you remember from “$what” — scribble is fine';
  @override
  String get recallAnything => 'what do you remember — scribble is fine';

  @override
  String get untitled => 'untitled';
  @override
  String get focusHint => 'tap to see the time\nhold to finish';

  @override
  String get backToDay => '‹ day';
  @override
  String get backToWall => '‹ wall';
  @override
  String get backToSettings => '‹ settings';
  @override
  String get less => 'less';
  @override
  String get more => 'more';
  @override
  String get notRead => 'nothing';
  @override
  String get noRanking => 'no ranking — ordered by when you added them';
  @override
  String get addFriend => '+ add friend';
  @override
  String get you => 'you';
  @override
  String summary(int hours, int days, int year) =>
      '$hours hours · $days days in $year';
  @override
  String hoursInYear(int hours, int year) => '$hours hours in $year';

  @override
  String get share => 'share';
  @override
  String get preparing => 'preparing';
  @override
  String get thisYear => 'this year';

  @override
  String get theme => 'theme';
  @override
  String get themeAuto => 'system';
  @override
  String get themeLight => 'light';
  @override
  String get themeDark => 'dark';
  @override
  String get language => 'language';
  @override
  String get languageAuto => 'system';
  @override
  String get languageThai => 'ไทย';
  @override
  String get languageEnglish => 'english';
  @override
  String get handleLabel => 'handle';
  @override
  String get handlePlaceholder => '@yourname';
  @override
  String get handleUnset => '@not set';
  @override
  String get yourData => 'your data';
  @override
  String get exportAll => 'export everything';
  @override
  String get exportNote => 'plain text you can read with your eyes · always free';
  @override
  String get deleteAll => 'delete everything';
  @override
  String get deleteConfirm => 'deletes everything for good';
  @override
  String get deleteYes => 'delete';
  @override
  String get deleteNo => 'keep';
  @override
  String get about => 'lapse · one day, one page';
  @override
  String get accountSection => 'account and sync';
  @override
  String get accountEntry => 'account';
  @override
  String get accountEntryNote => 'sign in to sync across devices and add friends';

  @override
  String get signIn => 'sign in';
  @override
  String get signInNote => 'syncs across devices · works fine without it';
  @override
  String get email => 'email';
  @override
  String get sendCode => 'send a code to my email';
  @override
  String get sending => 'sending';
  @override
  String codeSentTo(String email) => 'sent a six digit code to $email';
  @override
  String get codePlaceholder => 'six digit code';
  @override
  String get verify => 'verify';
  @override
  String get verifying => 'checking';
  @override
  String get resend => 'send another code';
  @override
  String get account => 'account';
  @override
  String get handleForFriends =>
      'friends find you by this · lowercase, digits or underscore';
  @override
  String get saveHandle => 'save handle';
  @override
  String get saving => 'saving';
  @override
  String get saved => 'saved';
  @override
  String get signOut => 'sign out';
  @override
  String get signOutNote => 'everything on this device stays after signing out';

  @override
  String get addFriendTitle => 'add friend';
  @override
  String get addFriendNote =>
      'you only see time per day · what they write stays theirs';
  @override
  String get friendHandlePlaceholder => '@their name';
  @override
  String get add => 'add';
  @override
  String get adding => 'adding';
  @override
  String get close => 'close';

  @override
  String get onboardTitle => 'what will you do today';
  @override
  String get onboardNote => 'write one line · you can change it later';
  @override
  String get onboardExample => 'maths, chapter 4';
  @override
  String get next => 'next';
}

/// ส่งชุดข้อความลงไปทั้งต้นไม้ เหมือนที่ `LapseTheme` ส่งสี
class LapseStrings extends InheritedWidget {
  const LapseStrings({
    required this.strings,
    required super.child,
    super.key,
  });

  final Strings strings;

  static Strings of(BuildContext context) {
    final found = context.dependOnInheritedWidgetOfExactType<LapseStrings>();
    assert(found != null, 'ไม่มี LapseStrings อยู่เหนือ widget นี้');
    return found!.strings;
  }

  @override
  bool updateShouldNotify(LapseStrings old) => old.strings != strings;
}
