# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.**

# Google Play Services
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.location.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Riverpod
-keep class com.riverpod.** { *; }
-dontwarn com.riverpod.**

# Hive
-keep class hive.** { *; }
-keep class * extends hive.HiveObject { *; }

# Dio HTTP client
-keep class dio.** { *; }
-dontwarn dio.**

# App specific models
-keep class com.stika.rider.models.** { *; }
-keep class com.stika.rider.data.** { *; }

# Serialization
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Camera
-keep class android.hardware.camera2.** { *; }

# Location services
-keep class android.location.** { *; }

# Networking
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Image processing
-keep class android.graphics.** { *; }

# General Android
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom exceptions
-keep public class * extends java.lang.Exception