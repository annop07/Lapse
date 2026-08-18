/// ช่องพิมพ์ของระบบนี้
///
/// วาดเองเพราะ `TextField` ของ Material มาพร้อมเส้นใต้ ป้ายลอย และสีของตัวเอง
/// ซึ่งไม่มีอันไหนอยู่ในดีไซน์ซิสเต็มนี้เลย
///
/// รวมไว้ที่เดียวหลังจากเขียนซ้ำมาสามที่ และครั้งหนึ่งเคยลืมบอก iOS
/// ว่าให้ใช้คีย์บอร์ดสีอะไร ทำให้คีย์บอร์ดขึ้นสว่างบนแอปธีมมืด
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../tokens/lapse_theme.dart';
import '../../tokens/lapse_tokens.dart';

class LapseTextField extends StatefulWidget {
  const LapseTextField({
    required this.controller,
    required this.placeholder,
    this.focusNode,
    this.keyboardType,
    this.formatters,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    super.key,
  });

  final TextEditingController controller;
  final String placeholder;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLines;

  @override
  State<LapseTextField> createState() => _LapseTextFieldState();
}

class _LapseTextFieldState extends State<LapseTextField> {
  FocusNode? _owned;

  FocusNode get _focus => widget.focusNode ?? (_owned ??= FocusNode());

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LapseTheme.of(context);
    final colors = theme.colors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focus.requestFocus,
      child: Stack(
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) => value.text.isEmpty
                ? Text(
                    widget.placeholder,
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
            onSubmitted: widget.onSubmitted,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.formatters,
            cursorColor: colors.ink,
            backgroundCursorColor: colors.inkFaint,
            selectionColor: colors.rule,
            textHeightBehavior: lapseTextHeightBehavior,
            keyboardAppearance:
                theme.isDark ? Brightness.dark : Brightness.light,
            style: lapseTextStyle(LapseType.body, color: colors.ink),
          ),
        ],
      ),
    );
  }
}
