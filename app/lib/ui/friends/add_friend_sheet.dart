/// เพิ่มเพื่อน (§4.6)
///
/// เป็น sheet ไม่ใช่หน้าเต็ม เพราะเป็นสิ่งที่ผู้ใช้ทำนานๆ ครั้ง
/// และไม่ควรพาเขาออกจากที่ที่เขาอยู่
///
/// **ไม่มีระบบค้นหาคนที่อาจรู้จัก** ตามที่สเปกห้ามไว้ตรงๆ
/// ต้องรู้ชื่อเขามาก่อนถึงจะเพิ่มได้ ซึ่งเป็นสิ่งที่ทำให้มันเป็นวงเพื่อนจริง
library;

import 'package:flutter/widgets.dart';

import '../../data/lapse_server.dart';
import '../../tokens/lapse_theme.dart';
import '../../tokens/lapse_tokens.dart';
import '../common/text_field.dart';

class AddFriendSheet extends StatefulWidget {
  const AddFriendSheet({
    required this.server,
    required this.onClose,
    required this.onAdded,
    super.key,
  });

  final LapseServer server;
  final VoidCallback onClose;
  final VoidCallback onAdded;

  @override
  State<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<AddFriendSheet> {
  final _handle = TextEditingController(text: '@');
  final _focus = FocusNode();
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _handle.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final problem = await widget.server.addFriend(_handle.text);
      if (!mounted) return;
      if (problem == null) {
        widget.onAdded();
        widget.onClose();
        return;
      }
      setState(() => _message = problem);
    } on Object catch (e) {
      if (mounted) setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);
    final inset = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      children: [
        // แตะพื้นที่มืดข้างบนเพื่อปิด
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              border: Border(
                top: BorderSide(
                  color: colors.rule,
                  width: LapseBorder.hairline,
                ),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              LapseSpace.gutter,
              LapseSpace.s7,
              LapseSpace.gutter,
              inset.bottom + keyboard + LapseSpace.s7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'เพิ่มเพื่อน',
                  style: lapseTextStyle(LapseType.title, color: colors.ink),
                ),
                SizedBox(height: LapseSpace.s3),
                Text(
                  'เห็นได้แค่เวลาต่อวัน สิ่งที่เขาเขียนเป็นของเขา',
                  style: lapseTextStyle(
                    LapseType.caption,
                    color: colors.inkMuted,
                  ),
                ),
                SizedBox(height: LapseSpace.s7),
                LapseTextField(
                  controller: _handle,
                  focusNode: _focus,
                  placeholder: '@ชื่อของเขา',
                  onSubmitted: (_) => _add(),
                ),
                SizedBox(height: LapseSpace.s4),
                Container(height: LapseBorder.hairline, color: colors.rule),
                if (_message != null) ...[
                  SizedBox(height: LapseSpace.s5),
                  Text(
                    _message!,
                    style: lapseTextStyle(
                      LapseType.caption,
                      color: colors.ink2,
                    ),
                  ),
                ],
                SizedBox(height: LapseSpace.s5),
                Row(
                  children: [
                    _Action(
                      label: _busy ? 'กำลังเพิ่ม' : 'เพิ่ม',
                      enabled: !_busy,
                      onTap: _add,
                      colors: colors,
                    ),
                    SizedBox(width: LapseSpace.s8),
                    _Action(
                      label: 'ปิด',
                      enabled: !_busy,
                      onTap: widget.onClose,
                      colors: colors,
                      quiet: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.colors,
    this.quiet = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final LapseColors colors;
  final bool quiet;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: LapseSpace.touch,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: lapseTextStyle(
                LapseType.body,
                color: !enabled
                    ? colors.inkFaint
                    : quiet
                        ? colors.inkMuted
                        : colors.ink,
              ),
            ),
          ),
        ),
      );
}
