/// จุดเริ่มของแอป
///
/// ยังเป็นโครงเปล่าใน Phase 0 — หน้าจอจริงมาใน Phase 4
/// สิ่งที่ยืนยันตอนนี้คือแอปขึ้นด้วยสีจากโทเคนและฟอนต์ที่ฝังไว้ ไม่ใช่ของ Material
library;

import 'package:flutter/widgets.dart';

import 'tokens/lapse_theme.dart';
import 'tokens/lapse_tokens.dart';

void main() => runApp(const LapseApp());

class LapseApp extends StatelessWidget {
  const LapseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final colors = platformDark ? LapseColors.dark : LapseColors.light;

    return LapseTheme(
      colors: colors,
      isDark: platformDark,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: clampTextScaler(MediaQuery.textScalerOf(context)),
        ),
        child: Container(
          color: colors.surface,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: _Placeholder(),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final colors = LapseTheme.colorsOf(context);
    return Center(
      child: Text(
        'lapse',
        style: lapseTextStyle(LapseType.display, color: colors.ink2),
      ),
    );
  }
}
