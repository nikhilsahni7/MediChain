# Keep Razorpay classes
-keep class com.razorpay.** {*;}
-keepclassmembers class com.razorpay.** {*;}

# Keep WebView JS interface
-keepattributes JavascriptInterface
-keep public class * extends android.webkit.WebViewClient
-keepclassmembers class * extends android.webkit.WebViewClient {
    <methods>;
}

# Keep missing ProGuard annotation classes referenced by Razorpay
-dontwarn proguard.annotation.**
-keep public class proguard.annotation.** { *; }

# Keep Google Pay classes used by Razorpay
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** {*;}

# Additional Google Pay related classes
-keep class com.google.android.gms.wallet.** { *; }
-dontwarn com.google.android.gms.wallet.**
-keep class com.google.android.gms.** { *; }

# Play Core library classes
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Specific Play Core classes from missing_rules.txt
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep other necessary classes
-keep class androidx.lifecycle.** { *; }
-keep class androidx.annotation.** { *; }

# Don't shrink or obfuscate these packages
-dontwarn retrofit.**
-keep class retrofit.** { *; }
-keepattributes Signature
-keepattributes Exceptions
-dontwarn okio.**
-dontwarn com.squareup.okhttp.**
