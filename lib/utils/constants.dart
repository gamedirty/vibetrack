import 'package:flutter/material.dart';

/// 应用颜色常量
class AppColors {
  // 主题色 - 深邃紫色与橙色渐变
  static const Color primary = Color(0xFF6B4EE6);
  static const Color primaryDark = Color(0xFF4A2FC4);
  static const Color accent = Color(0xFFFF7043);
  static const Color accentLight = Color(0xFFFFAB91);

  // 背景色
  static const Color backgroundDark = Color(0xFF0D0D1A);
  static const Color backgroundCard = Color(0xFF1A1A2E);
  static const Color backgroundElevated = Color(0xFF252542);

  // 文字颜色
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted = Color(0xFF6E6E8A);

  // 功能色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);

  // 波形颜色
  static const Color waveformFill = Color(0xFF6B4EE6);
  static const Color waveformLine = Color(0xFFFF7043);
  static const Color hapticEvent = Color(0xFFFFD54F);
  static const Color hapticEventSelected = Color(0xFFFFE082);

  // 渐变
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6B4EE6), Color(0xFF9C7CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF7043), Color(0xFFFFAB91)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D0D1A), Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// 应用文字样式
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

/// 应用间距常量
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// 应用圆角常量
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 100;
}

/// 分析参数默认值
class AnalysisDefaults {
  static const double minThreshold = 0.1;
  static const double maxThreshold = 0.8;
  static const double defaultThreshold = 0.3;

  static const int minInterval = 50;
  static const int maxInterval = 500;
  static const int defaultInterval = 100;

  static const double minGain = 0.5;
  static const double maxGain = 2.0;
  static const double defaultGain = 1.0;

  static const int previewDurationMs = 5000;
}

/// 时间格式化工具
class TimeFormatter {
  static String formatMs(int ms) {
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    final millis = (ms % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(2, '0')}';
  }

  static String formatMsShort(int ms) {
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 支持的音频格式
class SupportedFormats {
  static const List<String> extensions = [
    'mp3',
    'aac',
    'm4a',
    'wav',
    'flac',
    'ogg',
  ];

  static bool isSupported(String path) {
    final ext = path.split('.').last.toLowerCase();
    return extensions.contains(ext);
  }
}

