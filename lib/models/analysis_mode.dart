/// 分析模式枚举
enum AnalysisMode {
  /// 节拍模式 - 使用能量变化峰值
  beat('Beat', '基于节拍检测，适合鼓点明显的音乐'),

  /// 能量模式 - 按能量包络定期采样
  energy('Energy', '基于能量波动，适合电子/氛围音乐'),

  /// 混合模式 - Beat决定时间点，Energy决定强度
  hybrid('Hybrid', '综合节拍与能量，推荐大多数音乐');

  final String displayName;
  final String description;

  const AnalysisMode(this.displayName, this.description);

  static AnalysisMode fromString(String value) {
    return AnalysisMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AnalysisMode.hybrid,
    );
  }
}

