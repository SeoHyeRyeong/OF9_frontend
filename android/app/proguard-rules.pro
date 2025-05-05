# Flutter 기본 규칙
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }

# ML Kit 모든 언어 클래스 보존
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }

# 누락된 Builder 클래스 보존
-keep class com.google.mlkit.vision.text.*. { *; }

# 경고 무시
-dontwarn com.google.mlkit.vision.text.**
