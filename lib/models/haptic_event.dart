/// 触觉事件 - 基础单元
class HapticEvent {
  /// 相对音频起点的时间（毫秒）
  final int timeMs;

  /// 震动持续时长（毫秒）
  final int durationMs;

  /// 震动强度 1-255
  final int amplitude;

  const HapticEvent({
    required this.timeMs,
    required this.durationMs,
    required this.amplitude,
  });

  HapticEvent copyWith({
    int? timeMs,
    int? durationMs,
    int? amplitude,
  }) {
    return HapticEvent(
      timeMs: timeMs ?? this.timeMs,
      durationMs: durationMs ?? this.durationMs,
      amplitude: amplitude ?? this.amplitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeMs': timeMs,
      'durationMs': durationMs,
      'amplitude': amplitude,
    };
  }

  factory HapticEvent.fromJson(Map<String, dynamic> json) {
    return HapticEvent(
      timeMs: json['timeMs'] as int,
      durationMs: json['durationMs'] as int,
      amplitude: json['amplitude'] as int,
    );
  }

  @override
  String toString() {
    return 'HapticEvent(time: ${timeMs}ms, duration: ${durationMs}ms, amp: $amplitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HapticEvent &&
        other.timeMs == timeMs &&
        other.durationMs == durationMs &&
        other.amplitude == amplitude;
  }

  @override
  int get hashCode => timeMs.hashCode ^ durationMs.hashCode ^ amplitude.hashCode;
}

