# Flutter Stripe - Push Provisioning (optional feature, safe to ignore)
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.pushProvisioning.** { *; }

# React Native Stripe SDK (مضمّن في flutter_stripe)
-dontwarn com.reactnativestripesdk.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# General
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception