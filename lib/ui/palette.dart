import 'package:flutter/material.dart';

/// Brand palette: herb greens that flow into a saturated blue (same tones as the heart icon,
/// see tools/make_icons.mjs).
abstract final class Palette {
  static const herbPale = Color(0xFFE4F2D5);
  static const herbLight = Color(0xFFB2DE84);
  static const herb = Color(0xFF5E9E3A);
  static const herbDeep = Color(0xFF3E7F2C);
  static const blue = Color(0xFF2F6BEA);
  static const blueDeep = Color(0xFF0B2A86);

  /// Main accent gradient: herb green → saturated blue.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [herbDeep, herb, blue, blueDeep],
    stops: [0, 0.3, 0.75, 1],
  );

  static const _heatStops = [herbPale, herbLight, herb, blue, blueDeep];

  /// Heatmap color for t in [0, 1]: pale herb → green → saturated blue.
  static Color heat(double t) {
    final x = t.clamp(0.0, 1.0) * (_heatStops.length - 1);
    final i = x.floor().clamp(0, _heatStops.length - 2);
    return Color.lerp(_heatStops[i], _heatStops[i + 1], x - i)!;
  }

  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: herb,
      brightness: brightness,
      primary: dark ? herbLight : herbDeep,
      tertiary: dark ? const Color(0xFF9DB8FF) : blue,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? scheme.surfaceContainerHighest : blueDeep,
        contentTextStyle: TextStyle(color: dark ? scheme.onSurface : Colors.white),
        actionTextColor: herbLight,
      ),
    );
  }
}

/// A large rounded button filled with the brand gradient.
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.onPressed, required this.icon, required this.label});

  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final scheme = Theme.of(context).colorScheme;
    final fg = enabled ? Colors.white : scheme.onSurface.withValues(alpha: 0.38);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? Palette.brandGradient : null,
        color: enabled ? null : scheme.onSurface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
        boxShadow: enabled
            ? [BoxShadow(color: Palette.blue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: SizedBox(
            height: 56,
            child: IconTheme.merge(
              data: IconThemeData(color: fg),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(width: 8),
                    Flexible(child: label),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The heart logo (rendered from tools/icon.svg by tools/make_icons.mjs).
class HeartLogo extends StatelessWidget {
  const HeartLogo({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/logo.png', width: size, height: size, filterQuality: FilterQuality.medium);
}
