/// จุดเริ่มของแอป
///
/// ประกอบหน้า `day` กับ `focus` เข้าด้วยกัน และเป็นที่อยู่ของการส่งต่อไปที่บันทึก
/// หลังจบ session ซึ่งเป็นกลไกที่แยก Lapse ออกจากคู่แข่ง (§4.3)
library;

import 'package:flutter/widgets.dart';

import 'data/meta_store.dart';
import 'store/lapse_store.dart';
import 'tokens/lapse_theme.dart';
import 'tokens/lapse_tokens.dart';
import 'ui/day/day_screen.dart';
import 'ui/focus/focus_screen.dart';
import 'ui/wall/wall_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LapseStore.open();
  runApp(LapseApp(store: store));
}

class LapseApp extends StatelessWidget {
  const LapseApp({required this.store, super.key});

  final LapseStore store;

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
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: clampTextScaler(MediaQuery.textScalerOf(context)),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: _Root(store: store),
              ),
            ),
          );
        },
      );
}

class _Root extends StatefulWidget {
  const _Root({required this.store});

  final LapseStore store;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  final _journal = TextEditingController();
  final _journalFocus = FocusNode();
  final _dayKey = GlobalKey<DayScreenState>();

  /// รายการที่กำลังโฟกัสอยู่ · null แปลว่าอยู่หน้าวัน
  int? _focusedLine;

  String _placeholder = kJournalPlaceholder;
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
    if (_placeholder != kJournalPlaceholder) {
      setState(() => _placeholder = kJournalPlaceholder);
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_onDayMaybeChanged);
    _journal.dispose();
    _journalFocus.dispose();
    super.dispose();
  }

  void _startFocus(int lineIndex) => setState(() => _focusedLine = lineIndex);

  /// จบ session แล้วส่งต่อไปที่บันทึก — หกขั้นตามสเปก §4.3
  Future<void> _finishFocus(int minutes) async {
    final store = widget.store;
    final lineIndex = _focusedLine;
    setState(() => _focusedLine = null);

    await store.markFirstFocusDone();
    if (lineIndex == null || minutes <= 0) return;

    final lines = store.day.lines.toList();
    final what = lineIndex < lines.length ? lines[lineIndex].text : '';

    // 1 บวกเวลาเข้ารายการ
    await store.addMinutes(lineIndex, minutes);

    // 2 แสดง toast
    _showToast('+ $minutes นาที');

    // 3 ถ้ามีข้อความเดิมอยู่แล้วให้ขึ้นบรรทัดใหม่ก่อน
    if (_journal.text.isNotEmpty && !_journal.text.endsWith('\n')) {
      _journal.text = '${_journal.text}\n';
      await store.setJournal(_journal.text);
    }

    // 4 เปลี่ยน placeholder เป็นคำถามชวนทบทวน
    setState(() {
      _placeholder = what.isEmpty
          ? 'จำอะไรได้บ้าง — เขียนมั่วๆ ก็ได้'
          : 'จำอะไรได้บ้างจาก “$what” — เขียนมั่วๆ ก็ได้';
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

  void _openWall() => setState(() => _wallOpen = true);
  void _closeWall() => setState(() => _wallOpen = false);

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final lines = store.day.lines.toList();
    final focused = _focusedLine;

    return Stack(
      children: [
        DayScreen(
          key: _dayKey,
          store: store,
          journalController: _journal,
          journalFocus: _journalFocus,
          journalPlaceholder: _placeholder,
          onStartFocus: _startFocus,
          onOpenWall: _openWall,
        ),
        if (_wallOpen)
          WallScreen(store: store, onClose: _closeWall),
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
