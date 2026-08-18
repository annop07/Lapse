/// บัญชีและซิงก์ (§4.8)
///
/// สเปกเดิมรวมหน้าขายของไว้ในนี้ด้วย รอบนี้ยังไม่มีการเก็บเงิน
/// จึงเหลือแค่สถานะซิงก์ การเข้าสู่ระบบ และชื่อผู้ใช้
///
/// เข้าสู่ระบบด้วยรหัสหกหลักทางอีเมล ไม่ใช่รหัสผ่าน
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../data/lapse_server.dart';
import '../../store/lapse_store.dart';
import '../../tokens/lapse_theme.dart';
import '../../tokens/lapse_tokens.dart';
import '../common/text_field.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    required this.store,
    required this.server,
    required this.onClose,
    super.key,
  });

  final LapseStore store;
  final LapseServer server;
  final VoidCallback onClose;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _handle = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _handle.text = widget.store.meta.handle;
    _loadHandle();
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _handle.dispose();
    super.dispose();
  }

  Future<void> _loadHandle() async {
    if (!widget.server.signedIn) return;
    final handle = await widget.server.myHandle();
    if (handle != null && mounted) {
      _handle.text = handle;
      await widget.store.setHandle(handle);
    }
  }

  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final problem = await action();
      if (mounted) setState(() => _message = problem);
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
          _Back(onTap: widget.onClose, colors: colors),
          SizedBox(height: LapseSpace.s5),
          if (widget.server.signedIn)
            ..._signedIn(colors)
          else
            ..._signedOut(colors),
          if (_message != null) ...[
            SizedBox(height: LapseSpace.s6),
            Text(
              _message!,
              style: lapseTextStyle(LapseType.caption, color: colors.ink2),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _signedOut(LapseColors colors) => [
        _Label('เข้าสู่ระบบ', colors: colors),
        Text(
          'ซิงก์ข้อมูลข้ามเครื่อง ไม่เข้าสู่ระบบก็ใช้ได้ตามปกติ',
          style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
        ),
        SizedBox(height: LapseSpace.s6),
        LapseTextField(
          controller: _email,
          placeholder: 'อีเมล',
          keyboardType: TextInputType.emailAddress,
        ),
        _Rule(colors: colors),
        if (!_codeSent)
          _Action(
            label: _busy ? 'กำลังส่ง' : 'ส่งรหัสไปที่อีเมล',
            enabled: !_busy && _email.text.contains('@'),
            onTap: () => _run(() async {
              await widget.server.sendCode(_email.text);
              setState(() => _codeSent = true);
              return 'ส่งรหัสหกหลักไปที่ ${_email.text.trim()} แล้ว';
            }),
            colors: colors,
          )
        else ...[
          LapseTextField(
            controller: _code,
            placeholder: 'รหัสหกหลัก',
            keyboardType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          _Rule(colors: colors),
          _Action(
            label: _busy ? 'กำลังตรวจ' : 'ยืนยัน',
            enabled: !_busy && _code.text.length == 6,
            onTap: () => _run(() async {
              await widget.server.verifyCode(_email.text, _code.text);
              await _loadHandle();
              setState(() => _codeSent = false);
              return null;
            }),
            colors: colors,
          ),
          _Action(
            label: 'ส่งรหัสใหม่',
            enabled: !_busy,
            onTap: () => _run(() async {
              await widget.server.sendCode(_email.text);
              return 'ส่งรหัสใหม่แล้ว';
            }),
            colors: colors,
            quiet: true,
          ),
        ],
      ];

  List<Widget> _signedIn(LapseColors colors) => [
        _Label('บัญชี', colors: colors),
        Text(
          widget.server.email ?? '',
          style: lapseTextStyle(LapseType.body, color: colors.ink),
        ),
        _Rule(colors: colors),
        _Label('ชื่อผู้ใช้', colors: colors),
        Text(
          'เพื่อนใช้ชื่อนี้หาคุณเจอ · ตัวอักษรเล็ก ตัวเลข หรือขีดล่าง',
          style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
        ),
        SizedBox(height: LapseSpace.s4),
        LapseTextField(controller: _handle, placeholder: '@ชื่อของคุณ'),
        _Action(
          label: _busy ? 'กำลังบันทึก' : 'บันทึกชื่อ',
          enabled: !_busy,
          onTap: () => _run(() async {
            final problem = await widget.server.claimHandle(_handle.text);
            if (problem == null) {
              await widget.store.setHandle(_handle.text.trim().toLowerCase());
              return 'บันทึกแล้ว';
            }
            return problem;
          }),
          colors: colors,
        ),
        _Rule(colors: colors),
        _Action(
          label: 'ออกจากระบบ',
          enabled: !_busy,
          onTap: () => _run(() async {
            await widget.server.signOut();
            setState(() {});
            return null;
          }),
          colors: colors,
        ),
        SizedBox(height: LapseSpace.s3),
        Text(
          'ข้อมูลในเครื่องยังอยู่ครบหลังออกจากระบบ',
          style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
        ),
      ];
}

class _Back extends StatelessWidget {
  const _Back({required this.onTap, required this.colors});

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
              '‹ ตั้งค่า',
              style: lapseTextStyle(LapseType.label, color: colors.inkMuted),
            ),
          ),
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.colors});

  final String text;
  final LapseColors colors;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: LapseSpace.s3),
        child: Text(
          text,
          style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
        ),
      );
}

class _Rule extends StatelessWidget {
  const _Rule({required this.colors});

  final LapseColors colors;

  @override
  Widget build(BuildContext context) => Container(
        height: LapseBorder.hairline,
        color: colors.rule,
        margin: EdgeInsets.symmetric(vertical: LapseSpace.s6),
      );
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
