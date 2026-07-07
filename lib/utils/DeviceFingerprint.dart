// lib/utils/DeviceFingerprint.dart
// 🆕 توليد بصمة جهاز ثابتة (Device Fingerprint) تُستخدم في الباك إند لمنع
// حصول أكتر من حساب على مكافأة الترحيب من نفس الجهاز الفعلي.
//
// بتتحسب مرة واحدة بس وتتخزن محليًا (SharedPreferences)، وبعد كده بترجع
// نفس القيمة طول عمر تثبيت التطبيق حتى لو المستخدم عمل logout/login بحسابات
// مختلفة — وده بالظبط الهدف منها.
//
// ⚠️ ملحوظة مهمة: مكتبة device_info_plus بقى من v4.0.0 بترجع دايماً null
// لو استخدمنا AndroidDeviceInfo.id على أساس إنه "Android ID" — القيمة دي
// اتشالت من المكتبة نفسها. فلاستخراج Android ID الحقيقي (Settings.Secure.ANDROID_ID)
// لازم نستخدم باكدج مخصصة لكده (android_id)، ونسيب device_info_plus
// لـ iOS بس (identifierForVendor).

import 'dart:io';
import 'dart:math';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:nb_utils/nb_utils.dart';

const String _kDeviceFingerprintPrefKey = 'twomenu_device_fingerprint';

Future<String> getDeviceFingerprint() async {
  // ✅ أول حاجة نتأكد منها: هل محسوبة ومخزّنة قبل كده؟
  final cached = getStringAsync(_kDeviceFingerprintPrefKey);
  if (cached.isNotEmpty) return cached;

  String fingerprint = '';
  try {
    if (Platform.isAndroid) {
      // ✅ Android ID: ثابت طول عمر تثبيت التطبيق على نفس الجهاز بنفس
      // توقيع الـ APK، وبيتغيّر بس مع Factory Reset — كافي جدًا لغرضنا هنا.
      const androidIdPlugin = AndroidId();
      final id = await androidIdPlugin.getId();
      if (id != null && id.isNotEmpty) {
        fingerprint = 'android_$id';
      }
    } else if (Platform.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;
      // ✅ identifierForVendor: ثابت طالما فيه تطبيق واحد على الأقل
      // بنفس الناشر مثبّت على الجهاز.
      final vendorId = info.identifierForVendor ?? '';
      if (vendorId.isNotEmpty) {
        fingerprint = 'ios_$vendorId';
      }
    }
  } catch (e) {
    fingerprint = '';
  }

  // ✅ Fallback نادر جداً: لو النظام رفض يديّنا معرّف لأي سبب، نولّد معرّف
  // عشوائي ونثبّته محليًا بدل ما نسيب بصمة الجهاز فاضية بالكامل.
  if (fingerprint.isEmpty) {
    final rnd = Random.secure();
    final randomPart = List.generate(32, (_) => rnd.nextInt(16).toRadixString(16)).join();
    fingerprint = 'fallback_$randomPart';
  }

  await setValue(_kDeviceFingerprintPrefKey, fingerprint);
  return fingerprint;
}