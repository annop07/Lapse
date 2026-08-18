/// ตั้งค่า — ธีม · handle · export · ลบข้อมูล · เกี่ยวกับ (§4.7)
///
/// ไม่มีอะไรมากกว่านี้ ทุกอย่างที่จะเพิ่มต้องแลกด้วยการเอาอย่างอื่นออก
library;

import 'package:flutter/widgets.dart';

import '../../i18n/strings.dart';

import '../../data/meta_store.dart';
import '../../store/lapse_store.dart';
import '../../tokens/lapse_theme.dart';
import '../../tokens/lapse_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.store,
    required this.onClose,
    required this.onExport,
    this.onOpenAccount,
    super.key,
  });

  final LapseStore store;
  final VoidCallback onClose;

  /// ส่งโฟลเดอร์ทั้งก้อนออกไป — ฟรีเสมอ เป็นคำสัญญาของแบรนด์
  final Future<void> Function() onExport;

  /// null เมื่อต่อเซิร์ฟเวอร์ไม่ได้ · แอปยังใช้ได้ครบโดยไม่มีบัญชี
  final VoidCallback? onOpenAccount;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _handle =
      TextEditingController(text: widget.store.meta.handle);
  bool _confirmingDelete = false;

  @override
  void dispose() {
    _handle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);
    final inset = MediaQuery.paddingOf(context);
    final meta = widget.store.meta;
    final strings = LapseStrings.of(context);

    return ColoredBox(
      color: colors.surface,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          LapseSpace.gutter,
          inset.top + LapseSpace.s5,
          LapseSpace.gutter,
          inset.bottom + MediaQuery.viewInsetsOf(context).bottom + LapseSpace.s8,
        ),
        children: [
          _BackLink(onTap: widget.onClose, colors: colors),
          SizedBox(height: LapseSpace.s5),
          _SectionLabel(strings.theme, colors: colors),
          _Choices<ThemeChoice>(
            value: meta.theme,
            options: {
              ThemeChoice.auto: strings.themeAuto,
              ThemeChoice.light: strings.themeLight,
              ThemeChoice.dark: strings.themeDark,
            },
            onChanged: widget.store.setTheme,
            colors: colors,
          ),
          _Divider(colors: colors),
          _SectionLabel(strings.language, colors: colors),
          _Choices<Language>(
            value: meta.language,
            options: {
              Language.auto: strings.languageAuto,
              Language.thai: strings.languageThai,
              Language.english: strings.languageEnglish,
            },
            onChanged: widget.store.setLanguage,
            colors: colors,
          ),
          _Divider(colors: colors),
          _SectionLabel(strings.handleLabel, colors: colors),
          _HandleField(
            controller: _handle,
            onChanged: widget.store.setHandle,
            colors: colors,
          ),
          if (widget.onOpenAccount != null) ...[
            _Divider(colors: colors),
            _SectionLabel(strings.accountSection, colors: colors),
            _TextAction(
              label: strings.accountEntry,
              note: strings.accountEntryNote,
              onTap: () async => widget.onOpenAccount!(),
              colors: colors,
            ),
          ],
          _Divider(colors: colors),
          _SectionLabel(strings.yourData, colors: colors),
          _TextAction(
            label: strings.exportAll,
            note: strings.exportNote,
            onTap: widget.onExport,
            colors: colors,
          ),
          SizedBox(height: LapseSpace.s5),
          if (!_confirmingDelete)
            _TextAction(
              label: strings.deleteAll,
              onTap: () async =>
                  setState(() => _confirmingDelete = true),
              colors: colors,
              danger: true,
            )
          else
            _ConfirmDelete(
              strings: strings,
              onCancel: () => setState(() => _confirmingDelete = false),
              onConfirm: () async {
                await widget.store.deleteEverything();
                if (mounted) setState(() => _confirmingDelete = false);
                _handle.text = '';
              },
              colors: colors,
            ),
          _Divider(colors: colors),
          Text(
            strings.about,
            style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.onTap, required this.colors});

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
              LapseStrings.of(context).backToDay,
              style: lapseTextStyle(LapseType.label, color: colors.inkMuted),
            ),
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.colors});

  final String text;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: LapseSpace.s4),
        child: Text(
          text,
          style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider({required this.colors});

  final LapseColors colors;

  @override
  Widget build(BuildContext context) => Container(
        height: LapseBorder.hairline,
        color: colors.rule,
        margin: EdgeInsets.symmetric(vertical: LapseSpace.s7),
      );
}

/// แถวตัวเลือก — ข้อความล้วน ตัวที่เลือกอยู่เข้มกว่า ไม่มีพื้นสีทึบ
///
/// ใช้ได้ทั้งธีมและภาษา เพราะทั้งสองอย่างคือการเลือกหนึ่งจากไม่กี่ตัวเลือก
class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.value,
    required this.options,
    required this.onChanged,
    required this.colors,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (final entry in options.entries)
            GestureDetector(
              onTap: () => onChanged(entry.key),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: LapseSpace.touch,
                padding: EdgeInsets.only(right: LapseSpace.s7),
                alignment: Alignment.centerLeft,
                child: Text(
                  entry.value,
                  style: lapseTextStyle(
                    LapseType.body,
                    color: entry.key == value ? colors.ink : colors.inkMuted,
                  ),
                ),
              ),
            ),
        ],
      );
}

class _HandleField extends StatefulWidget {
  const _HandleField({
    required this.controller,
    required this.onChanged,
    required this.colors,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final LapseColors colors;

  @override
  State<_HandleField> createState() => _HandleFieldState();
}

class _HandleFieldState extends State<_HandleField> {
  // ต้องอยู่ใน state ไม่ใช่ใน build ไม่งั้นเคอร์เซอร์จะหลุดทุกตัวอักษรที่พิมพ์
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focus.requestFocus,
      child: Stack(
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) => value.text.isEmpty
                ? Text(
                    LapseStrings.of(context).handleUnset,
                    style: lapseTextStyle(
                      LapseType.body,
                      color: colors.inkMuted,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          EditableText(
            controller: widget.controller,
            focusNode: _focus,
            onChanged: widget.onChanged,
            maxLines: 1,
            cursorColor: colors.ink,
            backgroundCursorColor: colors.inkFaint,
            selectionColor: colors.rule,
            // ถ้าไม่บอก iOS ว่าใช้คีย์บอร์ดแบบไหน มันจะขึ้นสว่างเสมอแม้แอปจะเป็นธีมมืด
            keyboardAppearance: LapseTheme.of(context).isDark
                ? Brightness.dark
                : Brightness.light,
            style: lapseTextStyle(LapseType.body, color: colors.ink),
          ),
        ],
      ),
    );
  }
}

/// ปุ่มทุกตัวในระบบนี้เป็นข้อความล้วน ไม่มีพื้นสีทึบ
class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.onTap,
    required this.colors,
    this.note,
    this.danger = false,
  });

  final String label;
  final String? note;
  final Future<void> Function() onTap;
  final LapseColors colors;
  final bool danger;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: LapseSpace.touch,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: lapseTextStyle(
                    LapseType.body,
                    color: danger ? colors.danger : colors.ink,
                  ),
                ),
              ),
            ),
            if (note != null)
              Text(
                note!,
                style: lapseTextStyle(
                  LapseType.caption,
                  color: colors.inkMuted,
                ),
              ),
          ],
        ),
      );
}

/// ยืนยันการลบในที่เดิม ไม่ใช้ modal — modal ขัดจังหวะ และระบบนี้ไม่มี
class _ConfirmDelete extends StatelessWidget {
  const _ConfirmDelete({
    required this.strings,
    required this.onCancel,
    required this.onConfirm,
    required this.colors,
  });

  final Strings strings;
  final VoidCallback onCancel;
  final Future<void> Function() onConfirm;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.deleteConfirm,
            style: lapseTextStyle(LapseType.body, color: colors.ink),
          ),
          Row(
            children: [
              _TextAction(
                label: strings.deleteYes,
                onTap: onConfirm,
                colors: colors,
                danger: true,
              ),
              SizedBox(width: LapseSpace.s7),
              _TextAction(
                label: strings.deleteNo,
                onTap: () async => onCancel(),
                colors: colors,
              ),
            ],
          ),
        ],
      );
}
