import 'haptic_event.dart';
import 'analysis_mode.dart';

/// 触觉模式 - 完整的震动作品
class HapticPattern {
  /// 唯一标识符
  final String id;

  /// 作品标题
  final String title;

  /// 源音频时长（毫秒）
  final int sourceDurationMs;

  /// 分析模式
  final AnalysisMode analysisMode;

  /// 震动事件列表
  final List<HapticEvent> events;

  /// 创建时间
  final DateTime createdAt;

  /// 最后修改时间
  final DateTime modifiedAt;

  /// 源文件名（仅用于显示，不存储路径）
  final String? sourceFileName;

  const HapticPattern({
    required this.id,
    required this.title,
    required this.sourceDurationMs,
    required this.analysisMode,
    required this.events,
    required this.createdAt,
    required this.modifiedAt,
    this.sourceFileName,
  });

  HapticPattern copyWith({
    String? id,
    String? title,
    int? sourceDurationMs,
    AnalysisMode? analysisMode,
    List<HapticEvent>? events,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? sourceFileName,
  }) {
    return HapticPattern(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
      analysisMode: analysisMode ?? this.analysisMode,
      events: events ?? this.events,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      sourceFileName: sourceFileName ?? this.sourceFileName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'source': {
        'durationMs': sourceDurationMs,
        'analysisMode': analysisMode.name,
        'fileName': sourceFileName,
      },
      'events': events.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  factory HapticPattern.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as Map<String, dynamic>;
    return HapticPattern(
      id: json['id'] as String,
      title: json['title'] as String,
      sourceDurationMs: source['durationMs'] as int,
      analysisMode: AnalysisMode.fromString(source['analysisMode'] as String),
      events: (json['events'] as List)
          .map((e) => HapticEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      sourceFileName: source['fileName'] as String?,
    );
  }

  /// 导出为分享用的JSON（不包含私有信息）
  String toExportJson() {
    final exportData = {
      'id': id,
      'title': title,
      'source': {
        'durationMs': sourceDurationMs,
        'analysisMode': analysisMode.name,
      },
      'events': events.map((e) => e.toJson()).toList(),
    };
    return _prettyJson(exportData);
  }

  String _prettyJson(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    _writeJson(buffer, data, 0);
    return buffer.toString();
  }

  void _writeJson(StringBuffer buffer, dynamic data, int indent) {
    final indentStr = '  ' * indent;
    if (data is Map<String, dynamic>) {
      buffer.writeln('{');
      final entries = data.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        buffer.write('$indentStr  "${entries[i].key}": ');
        _writeJson(buffer, entries[i].value, indent + 1);
        if (i < entries.length - 1) buffer.write(',');
        buffer.writeln();
      }
      buffer.write('$indentStr}');
    } else if (data is List) {
      if (data.isEmpty) {
        buffer.write('[]');
      } else if (data.first is Map) {
        buffer.writeln('[');
        for (var i = 0; i < data.length; i++) {
          buffer.write('$indentStr  ');
          _writeJson(buffer, data[i], indent + 1);
          if (i < data.length - 1) buffer.write(',');
          buffer.writeln();
        }
        buffer.write('$indentStr]');
      } else {
        buffer.write('[${data.join(', ')}]');
      }
    } else if (data is String) {
      buffer.write('"$data"');
    } else {
      buffer.write(data);
    }
  }

  @override
  String toString() {
    return 'HapticPattern(id: $id, title: $title, events: ${events.length})';
  }
}

