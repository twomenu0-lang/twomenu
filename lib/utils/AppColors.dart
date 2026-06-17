import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
/// Brand Colors — الهوية البصرية الجديدة (Two Menu Premium UI)
/// ─────────────────────────────────────────────────────────────
/// ملاحظة: دول constants جديدة بجانب الموجودين في Colors.dart
/// (مش بدلاء لـ primaryColor الحالي حتى لا نكسر الشاشات الأخرى)

const Color kBrandPrimary = Color(0xFF343892);
const Color kBrandSecondary = Color(0xFFF6C657);
const Color kBrandBackground = Color(0xFFFFFFFF);

/// درجات مساعدة
const Color kBrandPrimaryLight = Color(0xFFEDEEF8); // primary بشفافية خفيفة كخلفية للأيقونات
const Color kTextMuted = Color(0xFF9098B1);

/// ─────────────────────────────────────────────────────────────
/// Radius
/// ─────────────────────────────────────────────────────────────
const double kAppBarRadius = 24.0;
const double kBottomNavRadius = 30.0;
const double kCardRadius = 18.0;
const double kBannerRadius = 20.0;
const double kPillRadius = 24.0;

/// ─────────────────────────────────────────────────────────────
/// Animation
/// ─────────────────────────────────────────────────────────────
const Duration kAnimDuration = Duration(milliseconds: 250);

/// ─────────────────────────────────────────────────────────────
/// Shadows
/// ─────────────────────────────────────────────────────────────
List<BoxShadow> kFloatingShadow({double opacity = 0.08, double blur = 20, Offset offset = const Offset(0, 8)}) {
  return [
    BoxShadow(
      color: kBrandPrimary.withOpacity(opacity),
      blurRadius: blur,
      offset: offset,
    ),
  ];
}

/// ─────────────────────────────────────────────────────────────
/// Gradients
/// ─────────────────────────────────────────────────────────────

/// خط متدرج (Accent line) تحت الـ AppBar
LinearGradient kAccentLineGradient = LinearGradient(
  colors: [kBrandSecondary, kBrandPrimary.withOpacity(0.05)],
  begin: Alignment.centerRight,
  end: Alignment.centerLeft,
);

/// تدرج زجاجي فوق صور الـ Hero Banner
LinearGradient kGlassOverlayGradient = LinearGradient(
  colors: [
    Colors.white.withOpacity(0.0),
    Colors.white.withOpacity(0.55),
  ],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
