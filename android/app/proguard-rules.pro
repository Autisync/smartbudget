# Flutter's own embedding classes are kept automatically by the Flutter Gradle
# plugin's bundled consumer rules. The rules below cover this app's specific
# native/reflection-based dependencies that are not otherwise auto-handled.

# SQLCipher for Android binds native methods to exact class/method signatures
# via JNI — renaming or stripping these breaks the encrypted-database open path.
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# flutter_local_notifications reflects over enum values for notification
# importance/priority; stripping them breaks scheduling on some OEM builds.
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# workmanager dispatches background work via a callback registered by class
# name, and androidx.work instantiates Worker subclasses via reflection.
-keep class dev.fluttercommunity.workmanager.** { *; }
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# Firebase Messaging/Core generally ship their own consumer rules, but keep
# the SDK defensively since a stripped model class here fails silently
# (a dropped push notification, not a crash) rather than loudly.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Sign-In / Play Services Auth.
-keep class com.google.android.gms.auth.** { *; }
-dontwarn com.google.android.gms.**

# Flutter's engine references Play Core's split-install classes for deferred
# components even though this app doesn't use dynamic feature modules —
# without this, R8 fails the build with "Missing class" errors for classes
# that are genuinely absent (no play-core dependency is declared here).
-dontwarn com.google.android.play.core.**
