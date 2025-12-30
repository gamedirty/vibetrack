import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/haptic_pattern.dart';

/// Pattern存储服务
class PatternStorage {
  static PatternStorage? _instance;
  static PatternStorage get instance => _instance ??= PatternStorage._();

  PatternStorage._();

  Directory? _storageDir;
  final List<HapticPattern> _patterns = [];

  List<HapticPattern> get patterns => List.unmodifiable(_patterns);

  /// 初始化存储
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _storageDir = Directory('${appDir.path}/patterns');
    if (!await _storageDir!.exists()) {
      await _storageDir!.create(recursive: true);
    }
    await _loadPatterns();
  }

  /// 加载所有Pattern
  Future<void> _loadPatterns() async {
    _patterns.clear();
    final files = await _storageDir!.list().toList();

    for (final file in files) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final pattern = HapticPattern.fromJson(json);
          _patterns.add(pattern);
        } catch (e) {
          // 跳过损坏的文件
          continue;
        }
      }
    }

    // 按修改时间排序
    _patterns.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
  }

  /// 保存Pattern
  Future<void> savePattern(HapticPattern pattern) async {
    final file = File('${_storageDir!.path}/${pattern.id}.json');
    final json = jsonEncode(pattern.toJson());
    await file.writeAsString(json);

    // 更新内存缓存
    final existingIndex = _patterns.indexWhere((p) => p.id == pattern.id);
    if (existingIndex >= 0) {
      _patterns[existingIndex] = pattern;
    } else {
      _patterns.insert(0, pattern);
    }
  }

  /// 删除Pattern
  Future<void> deletePattern(String patternId) async {
    final file = File('${_storageDir!.path}/$patternId.json');
    if (await file.exists()) {
      await file.delete();
    }
    _patterns.removeWhere((p) => p.id == patternId);
  }

  /// 获取Pattern
  HapticPattern? getPattern(String patternId) {
    return _patterns.firstWhere(
      (p) => p.id == patternId,
      orElse: () => throw StateError('Pattern not found: $patternId'),
    );
  }

  /// 导出Pattern到文件
  Future<String> exportPattern(HapticPattern pattern) async {
    final downloadsDir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final fileName = '${pattern.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}.json';
    final file = File('${downloadsDir.path}/$fileName');
    await file.writeAsString(pattern.toExportJson());
    return file.path;
  }

  /// 从JSON导入Pattern
  Future<HapticPattern?> importPattern(String jsonContent) async {
    try {
      final json = jsonDecode(jsonContent) as Map<String, dynamic>;
      final pattern = HapticPattern.fromJson(json);
      await savePattern(pattern);
      return pattern;
    } catch (e) {
      return null;
    }
  }

  /// 重命名Pattern
  Future<void> renamePattern(String patternId, String newTitle) async {
    final pattern = getPattern(patternId);
    if (pattern != null) {
      final updated = pattern.copyWith(
        title: newTitle,
        modifiedAt: DateTime.now(),
      );
      await savePattern(updated);
    }
  }

  void dispose() {
    _instance = null;
  }
}

