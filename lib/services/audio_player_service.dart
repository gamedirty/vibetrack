import 'dart:async';
import 'package:just_audio/just_audio.dart';

/// 音频播放服务
class AudioPlayerService {
  static AudioPlayerService? _instance;
  static AudioPlayerService get instance => _instance ??= AudioPlayerService._();

  AudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();

  bool get isPlaying => _player.playing;
  Duration? get duration => _player.duration;
  Duration get position => _player.position;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  /// 加载音频文件
  Future<Duration?> loadFile(String filePath) async {
    try {
      return await _player.setFilePath(filePath);
    } catch (e) {
      throw AudioPlayerException('加载音频失败: $e');
    }
  }

  /// 播放
  Future<void> play() async {
    await _player.play();
  }

  /// 暂停
  Future<void> pause() async {
    await _player.pause();
  }

  /// 停止
  Future<void> stop() async {
    await _player.stop();
  }

  /// 跳转到指定位置
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// 设置播放速度
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  /// 释放资源
  Future<void> dispose() async {
    await _player.dispose();
    _instance = null;
  }
}

/// 音频播放异常
class AudioPlayerException implements Exception {
  final String message;
  AudioPlayerException(this.message);

  @override
  String toString() => 'AudioPlayerException: $message';
}

