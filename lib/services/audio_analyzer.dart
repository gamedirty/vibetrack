import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/haptic_event.dart';
import '../models/analysis_mode.dart';
import '../models/analysis_params.dart';

/// 音频分析结果
class AudioAnalysisResult {
  final int sampleRate;
  final int channelCount;
  final int durationMs;
  final int frameCount;
  final List<double> rmsValues;
  final List<int> timeStamps;

  const AudioAnalysisResult({
    required this.sampleRate,
    required this.channelCount,
    required this.durationMs,
    required this.frameCount,
    required this.rmsValues,
    required this.timeStamps,
  });

  factory AudioAnalysisResult.fromMap(Map<dynamic, dynamic> map) {
    return AudioAnalysisResult(
      sampleRate: map['sampleRate'] as int,
      channelCount: map['channelCount'] as int,
      durationMs: map['durationMs'] as int,
      frameCount: map['frameCount'] as int,
      rmsValues: (map['rmsValues'] as List).map((e) => (e as num).toDouble()).toList(),
      timeStamps: (map['timeStamps'] as List).map((e) => (e as num).toInt()).toList(),
    );
  }
}

/// 音频分析服务
class AudioAnalyzer {
  static const MethodChannel _channel = MethodChannel('com.iwannasee.vibetrack/audio');

  static AudioAnalyzer? _instance;
  static AudioAnalyzer get instance => _instance ??= AudioAnalyzer._();

  AudioAnalyzer._();

  AudioAnalysisResult? _lastResult;
  AudioAnalysisResult? get lastResult => _lastResult;

  /// 获取音频时长
  Future<int> getAudioDuration(String filePath) async {
    try {
      final result = await _channel.invokeMethod<int>('getAudioDuration', {
        'filePath': filePath,
      });
      return result ?? 0;
    } on PlatformException catch (e) {
      throw AudioAnalyzerException('获取音频时长失败: ${e.message}');
    }
  }

  /// 分析音频文件
  Future<AudioAnalysisResult> analyzeAudio(String filePath, {int frameSize = 1024}) async {
    try {
      final result = await _channel.invokeMethod<Map>('analyzeAudio', {
        'filePath': filePath,
        'frameSize': frameSize,
      });

      if (result == null) {
        throw AudioAnalyzerException('分析结果为空');
      }

      _lastResult = AudioAnalysisResult.fromMap(result);
      return _lastResult!;
    } on PlatformException catch (e) {
      throw AudioAnalyzerException('音频分析失败: ${e.message}');
    }
  }

  /// 根据分析结果生成触觉事件
  List<HapticEvent> generateHapticEvents(
    AudioAnalysisResult analysis,
    AnalysisParams params,
  ) {
    switch (params.mode) {
      case AnalysisMode.beat:
        return _generateBeatEvents(analysis, params);
      case AnalysisMode.energy:
        return _generateEnergyEvents(analysis, params);
      case AnalysisMode.hybrid:
        return _generateHybridEvents(analysis, params);
    }
  }

  /// Beat模式：基于能量峰值检测
  List<HapticEvent> _generateBeatEvents(
    AudioAnalysisResult analysis,
    AnalysisParams params,
  ) {
    final events = <HapticEvent>[];
    final rms = analysis.rmsValues;
    final times = analysis.timeStamps;

    if (rms.isEmpty) return events;

    // 计算平滑能量（移动平均）
    const windowSize = 5;
    final smoothedRms = _movingAverage(rms, windowSize);

    // 峰值检测
    int lastEventTime = -params.minIntervalMs;

    for (var i = 1; i < smoothedRms.length - 1; i++) {
      final current = smoothedRms[i];
      final prev = smoothedRms[i - 1];
      final next = smoothedRms[i + 1];

      // 检测局部峰值
      if (current > prev && current > next && current > params.threshold) {
        final timeMs = times[i];

        // 检查最小间隔
        if (timeMs - lastEventTime >= params.minIntervalMs) {
          final amplitude = (current * 255 * params.globalGain).round().clamp(1, 255);
          events.add(HapticEvent(
            timeMs: timeMs,
            durationMs: params.defaultDurationMs,
            amplitude: amplitude,
          ));
          lastEventTime = timeMs;
        }
      }
    }

    return events;
  }

  /// Energy模式：按能量包络定期采样
  List<HapticEvent> _generateEnergyEvents(
    AudioAnalysisResult analysis,
    AnalysisParams params,
  ) {
    final events = <HapticEvent>[];
    final rms = analysis.rmsValues;
    final times = analysis.timeStamps;

    if (rms.isEmpty) return events;

    // 采样间隔（帧数）
    final sampleInterval = (params.minIntervalMs / 20).ceil(); // 每帧20ms

    for (var i = 0; i < rms.length; i += sampleInterval) {
      final energy = rms[i];

      if (energy > params.threshold * 0.5) {
        // Energy模式阈值更低
        final amplitude = (sqrt(energy) * 255 * params.globalGain).round().clamp(1, 255);
        events.add(HapticEvent(
          timeMs: times[i],
          durationMs: params.defaultDurationMs,
          amplitude: amplitude,
        ));
      }
    }

    return events;
  }

  /// Hybrid模式：Beat决定时间点，Energy决定强度
  List<HapticEvent> _generateHybridEvents(
    AudioAnalysisResult analysis,
    AnalysisParams params,
  ) {
    final events = <HapticEvent>[];
    final rms = analysis.rmsValues;
    final times = analysis.timeStamps;

    if (rms.isEmpty) return events;

    // 计算平滑能量
    const windowSize = 5;
    final smoothedRms = _movingAverage(rms, windowSize);

    // 计算能量变化率
    final deltaRms = <double>[];
    for (var i = 1; i < smoothedRms.length; i++) {
      deltaRms.add((smoothedRms[i] - smoothedRms[i - 1]).abs());
    }
    deltaRms.insert(0, 0);

    // 归一化变化率
    final maxDelta = deltaRms.reduce(max);
    final normalizedDelta = maxDelta > 0
        ? deltaRms.map((d) => d / maxDelta).toList()
        : deltaRms;

    int lastEventTime = -params.minIntervalMs;

    for (var i = 1; i < smoothedRms.length - 1; i++) {
      final current = smoothedRms[i];
      final prev = smoothedRms[i - 1];
      final next = smoothedRms[i + 1];
      final delta = normalizedDelta[i];

      // 综合判断：峰值 + 变化率
      final score = current * 0.6 + delta * 0.4;

      if ((current > prev && current > next) && score > params.threshold) {
        final timeMs = times[i];

        if (timeMs - lastEventTime >= params.minIntervalMs) {
          // 强度由原始能量决定
          final amplitude = (rms[i] * 255 * params.globalGain).round().clamp(1, 255);
          events.add(HapticEvent(
            timeMs: timeMs,
            durationMs: params.defaultDurationMs,
            amplitude: amplitude,
          ));
          lastEventTime = timeMs;
        }
      }
    }

    return events;
  }

  /// 移动平均平滑
  List<double> _movingAverage(List<double> data, int windowSize) {
    if (data.length < windowSize) return List.from(data);

    final result = <double>[];
    for (var i = 0; i < data.length; i++) {
      final start = max(0, i - windowSize ~/ 2);
      final end = min(data.length, i + windowSize ~/ 2 + 1);
      final sum = data.sublist(start, end).reduce((a, b) => a + b);
      result.add(sum / (end - start));
    }
    return result;
  }

  void dispose() {
    _instance = null;
  }
}

/// 音频分析异常
class AudioAnalyzerException implements Exception {
  final String message;
  AudioAnalyzerException(this.message);

  @override
  String toString() => 'AudioAnalyzerException: $message';
}

