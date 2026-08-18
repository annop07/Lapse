/// จุดเริ่มของแอป
///
/// ประกอบหน้า `day` กับ `focus` เข้าด้วยกัน และเป็นที่อยู่ของการส่งต่อไปที่บันทึก
/// หลังจบ session ซึ่งเป็นกลไกที่แยก Lapse ออกจากคู่แข่ง (§4.3)
library;

import 'package:flutter/widgets.dart';

import 'data/lapse_server.dart';
import 'data/meta_store.dart';
import 'i18n/strings.dart';
import 'model/duration_fmt.dart';
import 'store/lapse_store.dart';
import 'tokens/lapse_theme.dart';
import 'tokens/lapse_tokens.dart';
import 'ui/account/account_screen.dart';
import 'ui/day/day_screen.dart';
import 'ui/friends/add_friend_sheet.dart';
import 'ui/focus/focus_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/share/share_screen.dart';
import 'ui/wall/wall_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LapseStore.open();
  // เซิร์ฟเวอร์ต่อไม่ติดก็ต้องใช้แอปได้ตามปกติ ข้อมูลอยู่ในเครื่องอยู่แล้ว
  LapseServer? server;
  try {
    server = await LapseServer.start();
  } on Object catch (_) {
    server = null;
  }
  runApp(LapseApp(store: store, server: server));
}

class LapseApp extends StatelessWidget {
  const LapseApp({required this.store, this.server, super.key});

  final LapseStore store;
  final LapseServer? server;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final platformDark =
              MediaQuery.platformBrightnessOf(context) == Brightness.dark;
          final isDark = switch (store.meta.theme) {
            ThemeChoice.light => false,
            ThemeChoice.dark => true,
            ThemeChoice.auto => platformDark,
          };

          return LapseTheme(
            colors: isDark ? LapseColors.dark : LapseColors.light,
            isDark: isDark,
            child: LapseStrings(
              strings: stringsFor(
                store.meta.language,
                // ภาษาของเครื่อง ไม่ใช่ของแอป — ใช้ตอนผู้ใช้เลือก "ตามระบบ"
                WidgetsBinding.instance.platformDispatcher.locale,
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: clampTextScaler(MediaQuery.textScalerOf(context)),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: _Root(store: store, server: server),
                ),
              ),
            ),
          );
        },
      );
}

class _Root extends StatefulWidget {
  const _Root({required this.store, this.server});

  final LapseStore store;
  final LapseServer? server;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  final _journal = TextEditingController();
  final _journalFocus = FocusNode();
  final _dayKey = GlobalKey<DayScreenState>();

  /// รายการที่กำลังโฟกัสอยู่ · null แปลว่าอยู่หน้าวัน
  int? _focusedLine;

  String? _placeholder;

  Strings get _strings => LapseStrings.of(context);
  String? _toast;

  DateTime? _seenDate;

  @override
  void initState() {
    super.initState();
    _seenDate = widget.store.cursor;
    widget.store.addListener(_onDayMaybeChanged);
  }

  /// เปลี่ยนวันแล้ว placeholder กลับเป็นค่าเริ่มต้น
  void _onDayMaybeChanged() {
    if (widget.store.cursor == _seenDate) return;
    _seenDate = widget.store.cursor;
    if (_placeholder != null) setState(() => _placeholder = null);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onDayMaybeChanged);
    _journal.dispose();
    _journalFocus.dispose();
    super.dispose();
  }

  void _startFocus(int lineIndex) {
    // ปิดคีย์บอร์ดก่อนเข้าจอโฟกัสเสมอ
    //
    // จอโฟกัสเป็นเลเยอร์ทับหน้าวัน ช่องพิมพ์ข้างล่างจึงยังถือโฟกัสอยู่
    // และคีย์บอร์ดจะค้างขึ้นมาทับจอดำ ซึ่งขัดกับทั้งหน้านั้นทั้งหน้า
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _focusedLine = lineIndex);
  }

  /// จบ session แล้วส่งต่อไปที่บันทึก — หกขั้นตามสเปก §4.3
  Future<void> _finishFocus(int seconds) async {
    final store = widget.store;
    final lineIndex = _focusedLine;
    setState(() => _focusedLine = null);

    await store.markFirstFocusDone();
    if (lineIndex == null || seconds <= 0) return;

    final lines = store.day.lines.toList();
    final what = lineIndex < lines.length ? lines[lineIndex].text : '';

    // 1 บวกเวลาเข้ารายการ
    await store.addSeconds(lineIndex, seconds);

    // 2 แสดง toast บอกข้อเท็จจริง ไม่ใช่คำชม
    _showToast('+ ${formatThai(seconds)}');

    // 3 ถ้ามีข้อความเดิมอยู่แล้วให้ขึ้นบรรทัดใหม่ก่อน
    if (_journal.text.isNotEmpty && !_journal.text.endsWith('\n')) {
      _journal.text = '${_journal.text}\n';
      await store.setJournal(_journal.text);
    }

    // 4 เปลี่ยน placeholder เป็นคำถามชวนทบทวน
    setState(() {
      _placeholder = what.isEmpty
          ? _strings.recallAnything
          : _strings.recallFrom(what);
    });

    // 5 เลื่อนลงไปที่ช่องบันทึกแล้วไฮไลต์ไว้สั้นๆ
    await _dayKey.currentState?.revealJournal();

    // 6 โฟกัสเคอร์เซอร์เข้าช่องบันทึกที่ท้ายข้อความ
    if (!mounted) return;
    _journalFocus.requestFocus();
    _journal.selection =
        TextSelection.collapsed(offset: _journal.text.length);
  }

  void _showToast(String message) {
    setState(() => _toast = message);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && _toast == message) setState(() => _toast = null);
    });
  }

  bool _wallOpen = false;

  bool _settingsOpen = false;
  bool _shareOpen = false;
  bool _accountOpen = false;
  bool _addFriendOpen = false;

  void _openWall() => setState(() => _wallOpen = true);
  void _closeWall() => setState(() => _wallOpen = false);
  void _openShare() => setState(() => _shareOpen = true);
  void _closeShare() => setState(() => _shareOpen = false);
  void _openAccount() => setState(() => _accountOpen = true);
  void _closeAccount() => setState(() => _accountOpen = false);
  void _openAddFriend() => setState(() => _addFriendOpen = true);
  void _closeAddFriend() => setState(() => _addFriendOpen = false);
  void _openSettings() => setState(() => _settingsOpen = true);
  void _closeSettings() => setState(() => _settingsOpen = false);

  /// จังหวะแรกของ onboarding — เขียนหนึ่งบรรทัดแล้วเข้าหน้าวันจริงเลย
  Future<void> _finishOnboarding(String text) async {
    final store = widget.store;
    final at = store.addLine();
    await store.setLineText(at, text);
    await store.markOnboarded();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final lines = store.day.lines.toList();
    final focused = _focusedLine;

    if (!store.meta.hasOnboarded) {
      return OnboardingScreen(onWrote: _finishOnboarding);
    }

    return Stack(
      children: [
        DayScreen(
          key: _dayKey,
          store: store,
          journalController: _journal,
          journalFocus: _journalFocus,
          journalPlaceholder: _placeholder ?? _strings.journalPlaceholder,
          onStartFocus: _startFocus,
          onOpenWall: _openWall,
          onOpenSettings: _openSettings,
        ),
        if (_wallOpen)
          WallScreen(
            store: store,
            onClose: _closeWall,
            onShare: _openShare,
            onAddFriend: widget.server == null ? null : _openAddFriend,
          ),
        if (_shareOpen) ShareScreen(store: store, onClose: _closeShare),
        if (_settingsOpen)
          SettingsScreen(
            store: store,
            onClose: _closeSettings,
            onExport: store.exporter.share,
            onOpenAccount: widget.server == null ? null : _openAccount,
          ),
        if (_accountOpen && widget.server != null)
          AccountScreen(
            store: store,
            server: widget.server!,
            onClose: _closeAccount,
          ),
        if (_addFriendOpen && widget.server != null)
          AddFriendSheet(
            server: widget.server!,
            onClose: _closeAddFriend,
            onAdded: () => setState(() {}),
          ),
        if (focused != null)
          FocusScreen(
            what: focused < lines.length ? lines[focused].text : '',
            isFirstEver: !store.meta.hasFinishedFirstFocus,
            onFinish: _finishFocus,
          ),
        if (_toast != null) _Toast(message: _toast!),
      ],
    );
  }
}

/// ข้อความบอกข้อเท็จจริงสั้นๆ ไม่ใช่การฉลอง
class _Toast extends StatelessWidget {
  const _Toast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.paddingOf(context).bottom + LapseSpace.s10,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: LapseSpace.s6,
              vertical: LapseSpace.s3,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              border: Border.all(color: colors.rule, width: LapseBorder.hairline),
              borderRadius: BorderRadius.circular(LapseRadius.pill),
            ),
            child: Text(
              message,
              style: lapseTextStyle(LapseType.label, color: colors.ink2),
            ),
          ),
        ),
      ),
    );
  }
}
