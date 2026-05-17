import 'package:flutter/material.dart';

class AppTypography {
  static const String headingFamily = 'Sora';
  static const String bodyFamily = 'DM Sans';

  static TextStyle heading({
    double size = 24,
    FontWeight weight = FontWeight.w700,
  }) =>
      TextStyle(
        fontFamily: headingFamily,
        fontSize: size,
        fontWeight: weight,
        height: 1.2,
      );

  static TextStyle subheading({
    double size = 18,
    FontWeight weight = FontWeight.w600,
  }) =>
      TextStyle(
        fontFamily: headingFamily,
        fontSize: size,
        fontWeight: weight,
        height: 1.3,
      );

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
  }) =>
      TextStyle(
        fontFamily: bodyFamily,
        fontSize: size,
        fontWeight: weight,
        height: 1.5,
      );

  static TextStyle caption({
    double size = 12,
    FontWeight weight = FontWeight.w400,
  }) =>
      TextStyle(
        fontFamily: bodyFamily,
        fontSize: size,
        fontWeight: weight,
        height: 1.4,
      );

  static TextTheme buildTextTheme() => TextTheme(
        headlineLarge: heading(size: 28),
        headlineMedium: heading(size: 24),
        headlineSmall: subheading(size: 20),
        titleLarge: subheading(size: 18),
        titleMedium: subheading(size: 16),
        titleSmall: subheading(size: 14, weight: FontWeight.w600),
        bodyLarge: body(size: 16),
        bodyMedium: body(size: 14),
        bodySmall: body(size: 12),
        labelLarge: body(size: 14, weight: FontWeight.w500),
        labelMedium: caption(size: 12),
        labelSmall: caption(size: 10),
      );
}
