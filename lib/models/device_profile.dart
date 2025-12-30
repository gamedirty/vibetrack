/// 设备震动能力配置
class DeviceProfile {
  /// 最小可感知震动时长（毫秒）
  final int minPulseMs;

  /// 强度缩放因子 (0.0 - 2.0)
  final double amplitudeScale;

  /// 是否支持幅度控制
  final bool hasAmplitudeControl;

  /// 最大连续震动时长（毫秒）
  final int maxContinuousDurationMs;

  const DeviceProfile({
    this.minPulseMs = 10,
    this.amplitudeScale = 1.0,
    this.hasAmplitudeControl = true,
    this.maxContinuousDurationMs = 5000,
  });

  DeviceProfile copyWith({
    int? minPulseMs,
    double? amplitudeScale,
    bool? hasAmplitudeControl,
    int? maxContinuousDurationMs,
  }) {
    return DeviceProfile(
      minPulseMs: minPulseMs ?? this.minPulseMs,
      amplitudeScale: amplitudeScale ?? this.amplitudeScale,
      hasAmplitudeControl: hasAmplitudeControl ?? this.hasAmplitudeControl,
      maxContinuousDurationMs: maxContinuousDurationMs ?? this.maxContinuousDurationMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minPulseMs': minPulseMs,
      'amplitudeScale': amplitudeScale,
      'hasAmplitudeControl': hasAmplitudeControl,
      'maxContinuousDurationMs': maxContinuousDurationMs,
    };
  }

  factory DeviceProfile.fromJson(Map<String, dynamic> json) {
    return DeviceProfile(
      minPulseMs: json['minPulseMs'] as int? ?? 10,
      amplitudeScale: (json['amplitudeScale'] as num?)?.toDouble() ?? 1.0,
      hasAmplitudeControl: json['hasAmplitudeControl'] as bool? ?? true,
      maxContinuousDurationMs: json['maxContinuousDurationMs'] as int? ?? 5000,
    );
  }

  /// 根据设备配置调整震动强度
  int adjustAmplitude(int originalAmplitude) {
    if (!hasAmplitudeControl) return 255;
    final adjusted = (originalAmplitude * amplitudeScale).round();
    return adjusted.clamp(1, 255);
  }

  /// 根据设备配置调整震动时长
  int adjustDuration(int originalDurationMs) {
    if (originalDurationMs < minPulseMs) return minPulseMs;
    if (originalDurationMs > maxContinuousDurationMs) return maxContinuousDurationMs;
    return originalDurationMs;
  }
}

