import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/i18n/strings.dart';
import 'package:lapse/model/thai_date.dart';

void main() {
  const th = Locale('th');
  const en = Locale('en');

  group('เลือกภาษา', () {
    test('เลือกเองชนะภาษาของเครื่องเสมอ', () {
      expect(stringsFor(Language.english, th).isThai, isFalse);
      expect(stringsFor(Language.thai, en).isThai, isTrue);
    });

    test('ตามระบบใช้ภาษาของเครื่อง', () {
      expect(stringsFor(Language.auto, th).isThai, isTrue);
      expect(stringsFor(Language.auto, en).isThai, isFalse);
    });

    test('เครื่องภาษาอื่นได้อังกฤษ ไม่ใช่ไทย', () {
      expect(stringsFor(Language.auto, const Locale('ja')).isThai, isFalse);
    });
  });

  group('วันที่', () {
    final d = DateTime(2026, 8, 19);

    test('ไทย', () {
      expect(dayAndMonth(d, thai: true), '19 สิงหาคม');
      expect(weekdayAndYear(d, thai: true), 'พุธ · 2026');
      expect(monthShort(8, thai: true), 'ส.ค.');
    });

    test('อังกฤษเป็นตัวพิมพ์เล็กทั้งหมดตามกฎน้ำเสียง', () {
      expect(dayAndMonth(d, thai: false), '19 august');
      expect(weekdayAndYear(d, thai: false), 'wednesday · 2026');
      expect(monthShort(8, thai: false), 'aug');
    });
  });

  group('ข้อความอังกฤษไม่ขึ้นต้นด้วยตัวใหญ่', () {
    test('ทุกข้อความที่เป็นอักษรละติน', () {
      const s = EnglishStrings();
      final samples = <String>[
        s.wallLink, s.newLine, s.holdHint, s.journalPlaceholder,
        s.untitled, s.less, s.more, s.notRead, s.noRanking, s.you,
        s.share, s.preparing, s.thisYear, s.theme, s.themeAuto,
        s.themeLight, s.themeDark, s.language, s.handleLabel,
        s.yourData, s.exportAll, s.exportNote, s.deleteAll,
        s.deleteConfirm, s.deleteYes, s.deleteNo, s.about,
        s.accountSection, s.accountEntry, s.accountEntryNote,
        s.signIn, s.signInNote, s.email, s.sendCode, s.sending,
        s.codePlaceholder, s.verify, s.verifying, s.resend, s.account,
        s.handleForFriends, s.saveHandle, s.saving, s.saved,
        s.signOut, s.signOutNote, s.addFriendTitle, s.addFriendNote,
        s.add, s.adding, s.close, s.onboardTitle, s.onboardNote,
        s.onboardExample, s.next,
      ];

      for (final text in samples) {
        final letters = text.replaceAll(RegExp(r'[^A-Za-z]'), '');
        expect(
          letters,
          letters.toLowerCase(),
          reason: 'มีตัวพิมพ์ใหญ่ใน "$text"',
        );
      }
    });
  });
}
