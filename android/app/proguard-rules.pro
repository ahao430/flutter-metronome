# Flutter Soloud - 防止混淆导致 Native 崩溃
-keep class flutter.soloud.** { *; }
-keep class top.kikt.flutter_soloud.** { *; }
-keep class com.alextorq.flutter_soloud.** { *; }

# 保留 FFI 相关
-keep class dart.ffi.** { *; }
