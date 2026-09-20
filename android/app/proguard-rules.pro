# Head over Heels ProGuard Rules

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.** { *; }

# Riverpod
-keep class dev.flutter.riverpod.** { *; }
-keep class dev.flutter.riverpod.internal.** { *; }

# Freezed
-keep class **_$* { *; }
-keep class **.$* { *; }

# JSON serialization
-keep class **_$*JsonConverter { *; }

# Flame
-keep class org.flame.** { *; }
-keep class flame.** { *; }

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# OkHttp (used by just_audio)
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }

# Just Audio / Media3
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }

# Shared Preferences
-keep class androidx.preference.** { *; }

# Keep all annotations
-keepattributes *Annotation*

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
}