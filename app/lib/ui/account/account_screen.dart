/// บัญชีและซิงก์ (§4.8)
///
/// สเปกเดิมรวมหน้าขายของไว้ในนี้ด้วย รอบนี้ยังไม่มีการเก็บเงิน
/// จึงเหลือแค่สถานะซิงก์ การเข้าสู่ระบบ และชื่อผู้ใช้
///
/// เข้าสู่ระบบด้วยรหัสหกหลักทางอีเมล ไม่ใช่รหัสผ่าน
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../i18n/strings.dart';

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
          _Back(onTap: widget.onClose, colors: colors),
          SizedBox(height: LapseSpace.s5),
          if (widget.server.signedIn)
            ..._signedIn(colors, strings)
          else
            ..._signedOut(colors, strings),
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

  List<Widget> _signedOut(LapseColors colors, Strings strings) => [
        _Label(strings.signIn, colors: colors),
        Text(
          strings.signInNote,
          style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
        ),
        SizedBox(height: LapseSpace.s6),
        LapseTextField(
          controller: _email,
          placeholder: strings.email,
          keyboardType: TextInputType.emailAddress,
        ),
        _Rule(colors: colors),
        if (!_codeSent)
          _Action(
            label: _busy ? strings.sending : strings.sendCode,
            enabled: !_busy && _email.text.contains('@'),
            onTap: () => _run(() async {
              await widget.server.sendCode(_email.text);
              setState(() => _codeSent = true);
              return strings.codeSentTo(_email.text.trim());
            }),
            colors: colors,
          )
        else ...[
          LapseTextField(
            controller: _code,
            placeholder: strings.codePlaceholder,
            keyboardType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          _Rule(colors: colors),
          _Action(
            label: _busy ? strings.verifying : strings.verify,
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
            label: strings.resend,
            enabled: !_busy,
            onTap: () => _run(() async {
              await widget.server.sendCode(_email.text);
              return strings.codeSentTo(_email.text.trim());
            }),
            colors: colors,
            quiet: true,
          ),
        ],
      ];

  List<Widget> _signedIn(LapseColors colors, Strings strings) => [
        _Label(strings.account, colors: colors),
        Text(
          widget.server.email ?? '',
          style: lapseTextStyle(LapseType.body, color: colors.ink),
        ),
        _Rule(colors: colors),
        _Label(strings.handleLabel, colors: colors),
        Text(
          strings.handleForFriends,
          style: lapseTextStyle(LapseType.caption, color: colors.inkMuted),
        ),
        SizedBox(height: LapseSpace.s4),
        LapseTextField(
          controller: _handle,
          placeholder: strings.handlePlaceholder,
        ),
        _Action(
          label: _busy ? strings.saving : strings.saveHandle,
          enabled: !_busy,
          onTap: () => _run(() async {
            final problem = await widget.server.claimHandle(_handle.text);
            if (problem == null) {
              await widget.store.setHandle(_handle.text.trim().toLowerCase());
              return strings.saved;
            }
            return problem;
          }),
          colors: colors,
        ),
        _Rule(colors: colors),
        _Action(
          label: strings.signOut,
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
          strings.signOutNote,
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
              LapseStrings.of(context).backToSettings,
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
