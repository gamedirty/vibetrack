import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/haptic_event.dart';
import '../models/haptic_pattern.dart';
import '../models/analysis_mode.dart';
import '../models/analysis_params.dart';
import '../models/device_profile.dart';
import '../services/audio_analyzer.dart';
import '../services/haptic_engine.dart';
import '../services/pattern_storage.dart';
import '../services/audio_player_service.dart';

/// 应用状态枚举
enum AppStatus {
  idle,
  loading,
  analyzing,
  ready,
  playing,
  error,
}

/// 应用全局状态管理
class AppState extends ChangeNotifier {
  // 服务实例
  final AudioAnalyzer _analyzer = AudioAnalyzer.instance;
  final HapticEngine _hapticEngine = HapticEngine.instance;
  final PatternStorage _storage = PatternStorage.instance;
  final AudioPlayerService _audioPlayer = AudioPlayerService.instance;

  // 状态
  AppStatus _status = AppStatus.idle;
  String? _errorMessage;

  // 当前音频
  String? _currentFilePath;
  String? _currentFileName;
  int _audioDurationMs = 0;

  // 分析结果
  AudioAnalysisResult? _analysisResult;
  List<HapticEvent> _hapticEvents = [];

  // 分析参数
  AnalysisParams _analysisParams = const AnalysisParams();

  // 设备配置
  DeviceProfile _deviceProfile = const DeviceProfile();

  // 播放状态
  bool _isPlaying = false;
  int _playbackPositionMs = 0;

  // 当前编辑的Pattern
  HapticPattern? _currentPattern;

  // Getters
  AppStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get currentFilePath => _currentFilePath;
  String? get currentFileName => _currentFileName;
  int get audioDurationMs => _audioDurationMs;
  AudioAnalysisResult? get analysisResult => _analysisResult;
  List<HapticEvent> get hapticEvents => _hapticEvents;
  AnalysisParams get analysisParams => _analysisParams;
  DeviceProfile get deviceProfile => _deviceProfile;
  bool get isPlaying => _isPlaying;
  int get playbackPositionMs => _playbackPositionMs;
  HapticPattern? get currentPattern => _currentPattern;
  List<HapticPattern> get savedPatterns => _storage.patterns;

  /// 初始化
  Future<void> initialize() async {
    _status = AppStatus.loading;
    notifyListeners();

    try {
      await _hapticEngine.initialize();
      _deviceProfile = _hapticEngine.deviceProfile;
      await _storage.initialize();
      _status = AppStatus.idle;
    } catch (e) {
      _status = AppStatus.error;
      _errorMessage = '初始化失败: $e';
    }
    notifyListeners();
  }

  /// 加载音频文件
  Future<void> loadAudioFile(String filePath, String fileName) async {
    _status = AppStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentFilePath = filePath;
      _currentFileName = fileName;

      // 获取音频时长
      final duration = await _audioPlayer.loadFile(filePath);
      _audioDurationMs = duration?.inMilliseconds ?? 0;

      _status = AppStatus.idle;
    } catch (e) {
      _status = AppStatus.error;
      _errorMessage = '加载音频失败: $e';
    }
    notifyListeners();
  }

  /// 分析音频
  Future<void> analyzeAudio() async {
    if (_currentFilePath == null) {
      _errorMessage = '请先选择音频文件';
      notifyListeners();
      return;
    }

    _status = AppStatus.analyzing;
    _errorMessage = null;
    notifyListeners();

    try {
      _analysisResult = await _analyzer.analyzeAudio(_currentFilePath!);
      _hapticEvents = _analyzer.generateHapticEvents(_analysisResult!, _analysisParams);
      _status = AppStatus.ready;
    } catch (e) {
      _status = AppStatus.error;
      _errorMessage = '分析失败: $e';
    }
    notifyListeners();
  }

  /// 更新分析参数并重新生成事件
  void updateAnalysisParams(AnalysisParams params) {
    _analysisParams = params;
    if (_analysisResult != null) {
      _hapticEvents = _analyzer.generateHapticEvents(_analysisResult!, params);
    }
    notifyListeners();
  }

  /// 更新单个参数
  void updateThreshold(double value) {
    updateAnalysisParams(_analysisParams.copyWith(threshold: value));
  }

  void updateMinInterval(int value) {
    updateAnalysisParams(_analysisParams.copyWith(minIntervalMs: value));
  }

  void updateGlobalGain(double value) {
    updateAnalysisParams(_analysisParams.copyWith(globalGain: value));
  }

  void updateAnalysisMode(AnalysisMode mode) {
    updateAnalysisParams(_analysisParams.copyWith(mode: mode));
  }

  /// 开始播放
  Future<void> startPlayback({int startFromMs = 0}) async {
    if (_hapticEvents.isEmpty) return;

    _isPlaying = true;
    _status = AppStatus.playing;
    notifyListeners();

    try {
      // 同时播放音频和震动
      await _audioPlayer.seek(Duration(milliseconds: startFromMs));
      await _audioPlayer.play();

      // 播放震动
      if (_currentPattern != null) {
        _hapticEngine.playPattern(_currentPattern!, startFromMs: startFromMs);
      } else {
        // 创建临时Pattern
        final tempPattern = HapticPattern(
          id: 'temp',
          title: 'Temp',
          sourceDurationMs: _audioDurationMs,
          analysisMode: _analysisParams.mode,
          events: _hapticEvents,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );
        _hapticEngine.playPattern(tempPattern, startFromMs: startFromMs);
      }

      // 监听位置更新
      _audioPlayer.positionStream.listen((position) {
        _playbackPositionMs = position.inMilliseconds;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = '播放失败: $e';
      _isPlaying = false;
      _status = AppStatus.ready;
    }
    notifyListeners();
  }

  /// 停止播放
  Future<void> stopPlayback() async {
    _isPlaying = false;
    _status = AppStatus.ready;
    await _audioPlayer.pause();
    await _hapticEngine.cancel();
    notifyListeners();
  }

  /// 预览指定范围
  Future<void> previewRange(int startMs, int endMs) async {
    final rangeEvents = _hapticEvents
        .where((e) => e.timeMs >= startMs && e.timeMs < endMs)
        .toList();

    if (rangeEvents.isEmpty) return;

    await _audioPlayer.seek(Duration(milliseconds: startMs));
    await _audioPlayer.play();
    await _hapticEngine.previewRange(
      events: rangeEvents,
      startMs: startMs,
      endMs: endMs,
    );

    // 预览结束后暂停
    Future.delayed(Duration(milliseconds: endMs - startMs), () {
      _audioPlayer.pause();
    });
  }

  /// 编辑事件
  void updateHapticEvent(int index, HapticEvent event) {
    if (index >= 0 && index < _hapticEvents.length) {
      _hapticEvents[index] = event;
      notifyListeners();
    }
  }

  void deleteHapticEvent(int index) {
    if (index >= 0 && index < _hapticEvents.length) {
      _hapticEvents.removeAt(index);
      notifyListeners();
    }
  }

  void addHapticEvent(HapticEvent event) {
    _hapticEvents.add(event);
    _hapticEvents.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    notifyListeners();
  }

  /// 保存Pattern
  Future<HapticPattern> saveCurrentPattern({String? title}) async {
    final pattern = HapticPattern(
      id: const Uuid().v4(),
      title: title ?? '$_currentFileName - ${_analysisParams.mode.displayName}',
      sourceDurationMs: _audioDurationMs,
      analysisMode: _analysisParams.mode,
      events: List.from(_hapticEvents),
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      sourceFileName: _currentFileName,
    );

    await _storage.savePattern(pattern);
    _currentPattern = pattern;
    notifyListeners();
    return pattern;
  }

  /// 加载Pattern
  void loadPattern(HapticPattern pattern) {
    _currentPattern = pattern;
    _hapticEvents = List.from(pattern.events);
    _audioDurationMs = pattern.sourceDurationMs;
    _analysisParams = _analysisParams.copyWith(mode: pattern.analysisMode);
    _status = AppStatus.ready;
    notifyListeners();
  }

  /// 删除Pattern
  Future<void> deletePattern(String patternId) async {
    await _storage.deletePattern(patternId);
    if (_currentPattern?.id == patternId) {
      _currentPattern = null;
    }
    notifyListeners();
  }

  /// 导出Pattern
  Future<String> exportPattern() async {
    _currentPattern ??= await saveCurrentPattern();
    return await _storage.exportPattern(_currentPattern!);
  }

  /// 执行单次震动测试
  Future<void> testVibration({int durationMs = 100, int amplitude = 255}) async {
    await _hapticEngine.vibrate(durationMs: durationMs, amplitude: amplitude);
  }

  /// 更新设备配置
  void updateDeviceProfile(DeviceProfile profile) {
    _deviceProfile = profile;
    _hapticEngine.updateDeviceProfile(profile);
    notifyListeners();
  }

  /// 清理状态
  void reset() {
    _status = AppStatus.idle;
    _errorMessage = null;
    _currentFilePath = null;
    _currentFileName = null;
    _audioDurationMs = 0;
    _analysisResult = null;
    _hapticEvents.clear();
    _currentPattern = null;
    _isPlaying = false;
    _playbackPositionMs = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _hapticEngine.dispose();
    super.dispose();
  }
}

