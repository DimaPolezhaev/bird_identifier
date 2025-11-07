# ===============================
# TensorFlow Lite
# ===============================
-keep class org.tensorflow.lite.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# ===============================
# Flutter Sound
# ===============================
-keep class com.dooboolab.flutter_sound.** { *; }
-keep class com.dooboolab.flutter_sound.exceptions.** { *; }
-dontwarn com.dooboolab.flutter_sound.**

# ===============================
# File Picker
# ===============================
-keep class io.flutter.plugins.filepicker.** { *; }
-dontwarn io.flutter.plugins.filepicker.**

# ===============================
# General Flutter / Kotlin
# ===============================
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugin.**

# ===============================
# Keep all model and GPU delegate classes
# ===============================
-keep class org.tensorflow.lite.gpu.** { *; }

# ===============================
# Optional: keep annotations
# ===============================
-keepattributes *Annotation*