import 'package:flutter/material.dart';

/// Mountain palette — forest-pine primary, warm-bark secondary, sandstone
/// tertiary, beige neutrals. The slate scale below is retained as a
/// neutral-grey fallback for widget chrome that pre-dates the warm
/// palette refresh; new surfaces should prefer [stone*] or the named
/// nature tones.
class AppColors {
  const AppColors._();

  // Brand — forest pine
  static const primary = Color(0xFF2F5D3A); // deep forest green
  static const primaryDark = Color(0xFF1F4429); // evergreen
  static const primaryLight = Color(0xFF5C7A4F); // mossy

  // Secondary — warm earth / bark
  static const secondary = Color(0xFF8B5E3C); // saddle brown
  static const secondaryLight = Color(0xFFA0825F); // warm earth

  // Tertiary — sandstone / sun-bleached rock
  static const tertiary = Color(0xFFC2A878);

  // Surfaces — soft warm whites
  static const surface = Color(0xFFFAFAF7);
  static const background = Color(0xFFF4F2EC);

  // Foregrounds
  static const onPrimary = Color(0xFFFFFFFF);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF2A2520); // warm near-black
  static const onBackground = Color(0xFF2A2520);

  // Status
  static const error = Color(0xFFB23A3A); // brick red, warm-toned
  static const onError = Color(0xFFFFFFFF);
  static const success = Color(0xFF4F7A4D); // leaf green

  // Stone scale — beige-leaning warm neutrals (preferred for new chrome)
  static const stone50 = Color(0xFFFAF8F2);
  static const stone100 = Color(0xFFF1ECDF);
  static const stone200 = Color(0xFFE3DBC8);
  static const stone300 = Color(0xFFCABFA4);
  static const stone400 = Color(0xFFA89A7A);
  static const stone500 = Color(0xFF7A6F58); // warm dark grey-brown
  static const stone600 = Color(0xFF5C5343); // deeper warm dark

  // Slate scale — retained for backwards compatibility with iter 1–4
  // widget chrome; do not introduce new references in new code.
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);

  // Sunrise over-the-summit — used by the SOS countdown gradient.
  // Amber→brick still works against the new forest/earth palette.
  static const gradientSunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8A33D), Color(0xFFB23A3A)],
  );
}
