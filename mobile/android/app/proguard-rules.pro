# R8 keep rules for the release build.
#
# Only the Java/Kotlin layer is affected here — the Dart code lives in
# libapp.so and is obfuscated by `flutter build apk --obfuscate` instead.

# ---------------------------------------------------------------- ML Kit
# google_mlkit_text_recognition ships in the APK because it is a pubspec
# dependency, even though no code calls it yet (the receipt scanner is only a
# parser so far). ML Kit resolves its model implementations reflectively, so R8
# cannot see the references and would strip them — the failure surfaces at
# runtime as a MissingPluginException or a native loader crash, not at build
# time. Keep them so the dependency stays usable when scanning is wired up.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-dontwarn com.google.mlkit.**

# Optional ML Kit language models the text recognizer declares but that are not
# bundled for a Latin-script-only build.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# -------------------------------------------------------- Flutter plugins
# flutter_secure_storage reaches androidx.security for the Keystore-backed
# EncryptedSharedPreferences implementation.
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# Tink is the crypto backend androidx.security uses, and it registers key
# managers by reflection at runtime.
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# ------------------------------------------------------------------ misc
# Keep annotations that the above rules and the Android framework depend on.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
