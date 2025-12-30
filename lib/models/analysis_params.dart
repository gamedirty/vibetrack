import 'analysis_mode.dart';

/// 音频分析参数
class AnalysisParams {
  /// 分析模式
  final AnalysisMode mode;

  /// 灵敏度阈值 (0.0 - 1.0)，越低越敏感
  final double threshold;

  /// 最小事件间隔（毫秒）
  final int minIntervalMs;

  /// 全局增益 (0.5 - 2.0)
  final double globalGain;

  /// 默认震动时长（毫秒）
  final int defaultDurationMs;

  const AnalysisParams({
    this.mode = AnalysisMode.hybrid,
    this.threshold = 0.3,
    this.minIntervalMs = 100,
    this.globalGain = 1.0,
    this.defaultDurationMs = 40,
  });

  AnalysisParams copyWith({
    AnalysisMode? mode,
    double? threshold,
    int? minIntervalMs,
    double? globalGain,
    int? defaultDurationMs,
  }) {
    return AnalysisParams(
      mode: mode ?? this.mode,
      threshold: threshold ?? this.threshold,
      minIntervalMs: minIntervalMs ?? this.minIntervalMs,
      globalGain: globalGain ?? this.globalGain,
      defaultDurationMs: defaultDurationMs ?? this.defaultDurationMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'threshold': threshold,
      'minIntervalMs': minIntervalMs,
      'globalGain': globalGain,
      'defaultDurationMs': defaultDurationMs,
    };
  }

  factory AnalysisParams.fromJson(Map<String, dynamic> json) {
    return AnalysisParams(
      mode: AnalysisMode.fromString(json['mode'] as String? ?? 'hybrid'),
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.3,
      minIntervalMs: json['minIntervalMs'] as int? ?? 100,
      globalGain: (json['globalGain'] as num?)?.toDouble() ?? 1.0,
      defaultDurationMs: json['defaultDurationMs'] as int? ?? 40,
    );
  }
}

