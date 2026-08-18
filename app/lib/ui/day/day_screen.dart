/// หน้าวัน — หน้าแรกและหน้าที่ผู้ใช้อยู่นานที่สุด (§4.1)
///
/// ทั้งวันอยู่ในหน้าเดียว: สิ่งที่ตั้งใจจะทำ เวลาที่ใช้ไปจริง และสิ่งที่คิดหลังอ่านจบ
/// ผู้ใช้ไม่เคยต้องกดบันทึก แผนของตอนเช้ากลายเป็นบันทึกของตอนเย็นเอง
library;

import 'package:flutter/widgets.dart';

import '../../model/duration_fmt.dart';
import '../../model/thai_date.dart';
import '../../store/lapse_store.dart';
import '../../tokens/lapse_theme.dart';
import '../../tokens/lapse_tokens.dart';
import 'line_row.dart';

/// ค่าเริ่มต้นของ placeholder ในช่องบันทึก (§4.3)
const kJournalPlaceholder = 'วันนี้เป็นยังไงบ้าง';

class DayScreen extends StatefulWidget {
  const DayScreen({
    required this.store,
    required this.onStartFocus,
    required this.onOpenWall,
    required this.onOpenSettings,
    this.journalFocus,
    this.journalController,
    this.journalPlaceholder = kJournalPlaceholder,
    super.key,
  });

  final LapseStore store;

  /// กดค้างที่แถวแล้วเข้าหน้าโฟกัส
  final void Function(int lineIndex) onStartFocus;

  final VoidCallback onOpenWall;
  final VoidCallback onOpenSettings;

  /// หน้าโฟกัสส่งกลับมาเพื่อเด้งเคอร์เซอร์เข้าช่องบันทึก (§4.3)
  final FocusNode? journalFocus;
  final TextEditingController? journalController;

  /// เปลี่ยนเป็นคำถามชวนทบทวนหลังจบ session แล้วกลับเป็นค่าเริ่มต้นเมื่อเปลี่ยนวัน
  final String journalPlaceholder;

  @override
  State<DayScreen> createState() => DayScreenState();
}

class DayScreenState extends State<DayScreen> {
  final _rowControllers = <int, TextEditingController>{};
  final _rowFocus = <int, FocusNode>{};
  final _scroll = ScrollController();

  late final TextEditingController _journal =
      widget.journalController ?? TextEditingController();
  late final FocusNode _journalFocus = widget.journalFocus ?? FocusNode();

  DateTime? _syncedDate;

  /// ไฮไลต์ช่องบันทึกสั้นๆ เพื่อบอกว่าเคอร์เซอร์ย้ายมาที่นี่แล้ว (§4.3 ขั้นที่ 3)
  bool _journalLit = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    _syncFromStore();
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    for (final c in _rowControllers.values) {
      c.dispose();
    }
    for (final f in _rowFocus.values) {
      f.dispose();
    }
    _scroll.dispose();
    if (widget.journalController == null) _journal.dispose();
    if (widget.journalFocus == null) _journalFocus.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    _syncFromStore();
    if (mounted) setState(() {});
  }

  /// ดึงข้อความจาก store เข้า controller เฉพาะตอนที่มันต่างจริงๆ
  ///
  /// ถ้าเขียนทับทุกครั้งที่ store แจ้งเตือน เคอร์เซอร์ของผู้ใช้จะกระโดดกลับไปต้นบรรทัด
  /// ทุกตัวอักษรที่พิมพ์
  void _syncFromStore() {
    final day = widget.store.day;
    _syncedDate = day.date;

    final lines = day.lines.toList();
    for (var i = 0; i < lines.length; i++) {
      final controller = _rowControllers.putIfAbsent(i, TextEditingController.new);
      _rowFocus.putIfAbsent(i, FocusNode.new);
      if (controller.text != lines[i].text) controller.text = lines[i].text;
    }

    // เก็บกวาด controller ของแถวที่หายไปแล้ว
    for (final key in _rowControllers.keys.toList()) {
      if (key < lines.length) continue;
      _rowControllers.remove(key)?.dispose();
      _rowFocus.remove(key)?.dispose();
    }

    if (_journal.text != day.journal) _journal.text = day.journal;
  }

  /// เลื่อนลงไปที่ช่องบันทึกแล้วไฮไลต์ไว้ 1.4 วินาที
  ///
  /// เรียกจากข้างนอกตอนจบ session ผ่าน [GlobalKey]
  Future<void> revealJournal() async {
    if (_scroll.hasClients) {
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: LapseMotion.base,
        curve: LapseMotion.out,
      );
    }
    if (!mounted) return;
    setState(() => _journalLit = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _journalLit = false);
  }

  Future<void> _addLine() async {
    final at = widget.store.addLine();
    // รอให้แถวถูกสร้างก่อนค่อยโฟกัสเคอร์เซอร์เข้าไป
    await Future<void>.delayed(Duration.zero);
    _rowFocus[at]?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);
    final store = widget.store;
    final day = store.day;
    final lines = day.lines.toList();
    final inset = MediaQuery.paddingOf(context);

    return GestureDetector(
      // ปัดซ้ายขวาเปลี่ยนวัน (§4.1)
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 200) store.goBackOneDay();
        if (v < -200) store.goForwardOneDay();
      },
      child: ColoredBox(
        color: colors.surface,
        // ไม่ได้ใช้ Scaffold จึงไม่มี resizeToAvoidBottomInset มาให้
        // ต้องย่อเนื้อหาขึ้นเหนือคีย์บอร์ดเอง ไม่งั้นมันจะทับสิ่งที่กำลังพิมพ์
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
          children: [
            SizedBox(height: inset.top),
            _TopBar(
              onOpenWall: widget.onOpenWall,
              onOpenSettings: widget.onOpenSettings,
              colors: colors,
            ),
            _DateHeader(store: store, colors: colors),
            Expanded(
              child: CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverPadding(
                    padding:
                        EdgeInsets.symmetric(horizontal: LapseSpace.gutter),
                    sliver: SliverList.list(
                      children: [
                        for (var i = 0; i < lines.length; i++)
                          LineRow(
                            key: ValueKey('$_syncedDate-$i'),
                            text: lines[i].text,
                            done: lines[i].done,
                            minutes: lines[i].minutes,
                            controller: _rowControllers[i]!,
                            focusNode: _rowFocus[i]!,
                            onToggle: () => store.toggleLine(i),
                            onTextChanged: (text) => store.setLineText(i, text),
                            onHold: () => widget.onStartFocus(i),
                          ),
                        _AddLineButton(onTap: _addLine, colors: colors),
                        _Rule(colors: colors),
                      ],
                    ),
                  ),
                  // ช่องบันทึกกินพื้นที่ที่เหลือทั้งหมดของจอ แล้วโตต่อได้ถ้าเขียนยาว
                  SliverPadding(
                    padding:
                        EdgeInsets.symmetric(horizontal: LapseSpace.gutter),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: _Journal(
                        controller: _journal,
                        focusNode: _journalFocus,
                        onChanged: store.setJournal,
                        placeholder: widget.journalPlaceholder,
                        lit: _journalLit,
                        colors: colors,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _BottomBar(
              minutes: day.totalMinutes,
              colors: colors,
              bottomInset: inset.bottom,
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onOpenWall,
    required this.onOpenSettings,
    required this.colors,
  });

  final VoidCallback onOpenWall;
  final VoidCallback onOpenSettings;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: LapseSpace.gutter),
        child: Row(
          children: [
            // wordmark เป็นทางเข้าหน้าตั้งค่า ไม่ต้องมีไอคอนเฟืองมาเพิ่มความรก
            GestureDetector(
              onTap: onOpenSettings,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: LapseSpace.touch,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'LAPSE',
                    style: lapseTextStyle(
                      LapseType.micro,
                      color: colors.inkFaint,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            // ลิงก์ไปกำแพงต้องไม่ดึงสายตา — micro และจาง
            GestureDetector(
              onTap: onOpenWall,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: LapseSpace.touch,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'กำแพง',
                    style: lapseTextStyle(
                      LapseType.micro,
                      color: colors.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.store, required this.colors});

  final LapseStore store;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) {
    final date = store.cursor;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        LapseSpace.gutter,
        LapseSpace.s5,
        LapseSpace.gutter,
        LapseSpace.s7,
      ),
      child: Row(
        children: [
          _Arrow(
            glyph: '‹',
            enabled: true,
            onTap: store.goBackOneDay,
            colors: colors,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  thaiDayAndMonth(date),
                  style: lapseTextStyle(LapseType.title, color: colors.ink),
                ),
                Text(
                  thaiWeekdayAndYear(date),
                  style: lapseTextStyle(
                    LapseType.caption,
                    color: colors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          // `›` ตายเมื่ออยู่ที่วันนี้ — ห้ามเลื่อนไปวันอนาคต
          _Arrow(
            glyph: '›',
            enabled: store.canGoForward,
            onTap: store.goForwardOneDay,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.glyph,
    required this.enabled,
    required this.onTap,
    required this.colors,
  });

  final String glyph;
  final bool enabled;
  final VoidCallback onTap;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: LapseSpace.touch,
          height: LapseSpace.touch,
          child: Center(
            child: Text(
              glyph,
              style: lapseTextStyle(
                LapseType.title,
                color: enabled ? colors.ink2 : colors.inkFaint,
              ),
            ),
          ),
        ),
      );
}

class _AddLineButton extends StatelessWidget {
  const _AddLineButton({required this.onTap, required this.colors});

  final VoidCallback onTap;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: LapseSpace.touch,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '+ บรรทัดใหม่',
              style: lapseTextStyle(LapseType.label, color: colors.inkMuted),
            ),
          ),
        ),
      );
}

/// เส้นคั่นระหว่างรายการกับบันทึก — ตรงกับ `---` ในไฟล์
class _Rule extends StatelessWidget {
  const _Rule({required this.colors});

  final LapseColors colors;

  @override
  Widget build(BuildContext context) => Container(
        height: LapseBorder.hairline,
        margin: EdgeInsets.symmetric(vertical: LapseSpace.s6),
        color: colors.rule,
      );
}

class _Journal extends StatelessWidget {
  const _Journal({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.placeholder,
    required this.lit,
    required this.colors,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final bool lit;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) {
    final style = lapseTextStyle(LapseType.body, color: colors.ink);

    return GestureDetector(
      // แตะตรงไหนของพื้นที่ที่เหลือก็เริ่มพิมพ์ได้ ไม่ต้องเล็งบรรทัดเล็กๆ
      behavior: HitTestBehavior.opaque,
      onTap: focusNode.requestFocus,
      child: AnimatedContainer(
        duration: LapseMotion.base,
        curve: LapseMotion.out,
        // ไฮไลต์เป็นพื้นจางๆ ไม่ใช่กรอบหรือเงา
        color: lit ? colors.ruleSoft : null,
        padding: EdgeInsets.symmetric(vertical: LapseSpace.s2),
        child: Align(
        alignment: Alignment.topLeft,
        child: Stack(
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => value.text.isEmpty
                  ? Text(
                      placeholder,
                      textHeightBehavior: lapseTextHeightBehavior,
                      style: lapseTextStyle(
                        LapseType.body,
                        color: colors.inkMuted,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            EditableText(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              maxLines: null,
              cursorColor: colors.ink,
              backgroundCursorColor: colors.inkFaint,
              selectionColor: colors.rule,
              textHeightBehavior: lapseTextHeightBehavior,
              style: style,
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.minutes,
    required this.colors,
    required this.bottomInset,
  });

  final int minutes;
  final LapseColors colors;
  final double bottomInset;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          LapseSpace.gutter,
          LapseSpace.s4,
          LapseSpace.gutter,
          bottomInset + LapseSpace.s4,
        ),
        child: Row(
          children: [
            Text(
              'กดค้างที่บรรทัดเพื่อเริ่ม',
              style: lapseTextStyle(LapseType.micro, color: colors.inkFaint),
            ),
            const Spacer(),
            Text(
              minutes > 0 ? formatHm(minutes) : '—',
              style: lapseTextStyle(
                LapseType.mono,
                color: minutes > 0 ? colors.ink2 : colors.inkFaint,
              ),
            ),
          ],
        ),
      );
}
