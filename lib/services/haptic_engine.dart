import 'dart:async';
import 'package:flutter/services.dart';
import '../models/haptic_event.dart';
import '../models/haptic_pattern.dart';
import '../models/device_profile.dart';

/// 震动引擎 - 负责与原生平台通信执行震动
class HapticEngine {
  static const MethodChannel _channel = MethodChannel('com.iwannasee.vibetrack/haptic');

  static HapticEngine? _instance;
  static HapticEngine get instance => _instance ??= HapticEngine._();

  HapticEngine._();

  DeviceProfile _deviceProfile = const DeviceProfile();
  bool _isPlaying = false;
  Timer? _playbackTimer;
  int _currentSegmentIndex = 0;
  List<HapticEvent> _currentEvents = [];
  int _playbackStartTime = 0;
  StreamController<int>? _positionController;

  DeviceProfile get deviceProfile => _deviceProfile;
  bool get isPlaying => _isPlaying;

  /// 初始化引擎，检测设备能力
  Future<void> initialize() async {
    try {
      final result = await _channel.invokeMethod<Map>('getDeviceCapabilities');
      if (result != null) {
        _deviceProfile = DeviceProfile(
          hasAmplitudeControl: result['hasAmplitudeControl'] as bool? ?? false,
          minPulseMs: result['minPulseMs'] as int? ?? 10,
          maxContinuousDurationMs: result['maxContinuousDurationMs'] as int? ?? 5000,
        );
      }
    } on PlatformException catch (e) {
      // 设备不支持，使用默认配置
      _deviceProfile = const DeviceProfile(hasAmplitudeControl: false);
      throw HapticEngineException('初始化失败: ${e.message}');
    }
  }

  /// 更新设备配置
  void updateDeviceProfile(DeviceProfile profile) {
    _deviceProfile = profile;
  }

  /// 执行单次震动
  Future<void> vibrate({
    int durationMs = 100,
    int amplitude = 255,
  }) async {
    final adjustedDuration = _deviceProfile.adjustDuration(durationMs);
    final adjustedAmplitude = _deviceProfile.adjustAmplitude(amplitude);

    try {
      await _channel.invokeMethod('vibrate', {
        'durationMs': adjustedDuration,
        'amplitude': adjustedAmplitude,
      });
    } on PlatformException catch (e) {
      throw HapticEngineException('震动执行失败: ${e.message}');
    }
  }

  /// 执行震动波形
  Future<void> playWaveform({
    required List<int> timings,
    required List<int> amplitudes,
  }) async {
    if (timings.isEmpty || amplitudes.isEmpty) return;
    if (timings.length != amplitudes.length) {
      throw HapticEngineException('timings和amplitudes长度必须一致');
    }

    final adjustedAmplitudes = amplitudes
        .map((a) => _deviceProfile.adjustAmplitude(a))
        .toList();

    try {
      await _channel.invokeMethod('playWaveform', {
        'timings': timings,
        'amplitudes': adjustedAmplitudes,
      });
    } on PlatformException catch (e) {
      throw HapticEngineException('波形播放失败: ${e.message}');
    }
  }

  /// 停止所有震动
  Future<void> cancel() async {
    _stopPlayback();
    try {
      await _channel.invokeMethod('cancel');
    } on PlatformException catch (e) {
      throw HapticEngineException('取消震动失败: ${e.message}');
    }
  }

  /// 播放HapticPattern（分段播放）
  Stream<int> playPattern(HapticPattern pattern, {int startFromMs = 0}) {
    _stopPlayback();
    _currentEvents = pattern.events;
    _positionController = StreamController<int>.broadcast();

    _startPatternPlayback(startFromMs);

    return _positionController!.stream;
  }

  /// 预览指定时间范围的事件
  Future<void> previewRange({
    required List<HapticEvent> events,
    required int startMs,
    required int endMs,
  }) async {
    final rangeEvents = events
        .where((e) => e.timeMs >= startMs && e.timeMs < endMs)
        .toList();

    if (rangeEvents.isEmpty) return;

    await _playEventsBatch(rangeEvents, baseTimeMs: startMs);
  }

  void _startPatternPlayback(int startFromMs) {
    _isPlaying = true;
    _playbackStartTime = DateTime.now().millisecondsSinceEpoch - startFromMs;

    // 找到起始事件索引
    _currentSegmentIndex = _currentEvents.indexWhere((e) => e.timeMs >= startFromMs);
    if (_currentSegmentIndex < 0) {
      _stopPlayback();
      return;
    }

    _scheduleNextSegment();
  }

  void _scheduleNextSegment() {
    if (!_isPlaying || _currentSegmentIndex >= _currentEvents.length) {
      _stopPlayback();
      return;
    }

    // 获取接下来5秒内的事件
    const segmentDurationMs = 5000;
    final currentTimeMs = DateTime.now().millisecondsSinceEpoch - _playbackStartTime;
    final segmentEndMs = currentTimeMs + segmentDurationMs;

    final segmentEvents = <HapticEvent>[];
    var endIndex = _currentSegmentIndex;

    while (endIndex < _currentEvents.length &&
        _currentEvents[endIndex].timeMs < segmentEndMs) {
      segmentEvents.add(_currentEvents[endIndex]);
      endIndex++;
    }

    if (segmentEvents.isNotEmpty) {
      _playEventsBatch(segmentEvents, baseTimeMs: currentTimeMs);
    }

    _currentSegmentIndex = endIndex;

    // 发送位置更新
    _positionController?.add(currentTimeMs);

    // 安排下一段
    if (_currentSegmentIndex < _currentEvents.length) {
      final nextEventTime = _currentEvents[_currentSegmentIndex].timeMs;
      final delayMs = nextEventTime - currentTimeMs - 100; // 提前100ms准备
      _playbackTimer = Timer(
        Duration(milliseconds: delayMs.clamp(100, segmentDurationMs)),
        _scheduleNextSegment,
      );
    } else {
      _stopPlayback();
    }
  }

  Future<void> _playEventsBatch(List<HapticEvent> events, {required int baseTimeMs}) async {
    if (events.isEmpty) return;

    // 转换为waveform格式
    final timings = <int>[];
    final amplitudes = <int>[];

    var lastEndTime = baseTimeMs;

    for (final event in events) {
      // 添加静默间隔
      if (event.timeMs > lastEndTime) {
        timings.add(event.timeMs - lastEndTime);
        amplitudes.add(0);
      }

      // 添加震动
      timings.add(event.durationMs);
      amplitudes.add(event.amplitude);

      lastEndTime = event.timeMs + event.durationMs;
    }

    if (timings.isNotEmpty) {
      await playWaveform(timings: timings, amplitudes: amplitudes);
    }
  }

  void _stopPlayback() {
    _isPlaying = false;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _positionController?.close();
    _positionController = null;
  }

  /// 释放资源
  void dispose() {
    _stopPlayback();
    _instance = null;
  }
}

/// 震动引擎异常
class HapticEngineException implements Exception {
  final String message;
  HapticEngineException(this.message);

  @override
  String toString() => 'HapticEngineException: $message';
}

