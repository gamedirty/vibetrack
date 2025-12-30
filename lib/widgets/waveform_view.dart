import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';

class WaveformView extends StatelessWidget {
  const WaveformView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final analysis = appState.analysisResult;

        if (analysis == null) {
          return _buildPlaceholder();
        }

        return Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.backgroundElevated),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: CustomPaint(
              painter: WaveformPainter(
                rmsValues: analysis.rmsValues,
                hapticEvents: appState.hapticEvents.map((e) {
                  return (
                    time: e.timeMs / appState.audioDurationMs,
                    amplitude: e.amplitude / 255,
                  );
                }).toList(),
                playbackPosition: appState.playbackPositionMs / appState.audioDurationMs,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.graphic_eq, size: 48, color: AppColors.textMuted),
            SizedBox(height: AppSpacing.sm),
            Text('等待分析结果', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> rmsValues;
  final List<({double time, double amplitude})> hapticEvents;
  final double playbackPosition;

  WaveformPainter({
    required this.rmsValues,
    required this.hapticEvents,
    required this.playbackPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rmsValues.isEmpty) return;

    final centerY = size.height / 2;
    final maxHeight = size.height * 0.4;

    // 绘制波形
    final waveformPaint = Paint()
      ..color = AppColors.waveformFill.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final waveformPath = Path();
    waveformPath.moveTo(0, centerY);

    // 降采样以提高性能
    final samplesCount = min(rmsValues.length, size.width.toInt() * 2);
    final step = rmsValues.length / samplesCount;

    for (var i = 0; i < samplesCount; i++) {
      final index = (i * step).floor().clamp(0, rmsValues.length - 1);
      final x = (i / samplesCount) * size.width;
      final value = rmsValues[index];
      final y = centerY - (value * maxHeight);
      waveformPath.lineTo(x, y);
    }

    // 镜像下半部分
    for (var i = samplesCount - 1; i >= 0; i--) {
      final index = (i * step).floor().clamp(0, rmsValues.length - 1);
      final x = (i / samplesCount) * size.width;
      final value = rmsValues[index];
      final y = centerY + (value * maxHeight);
      waveformPath.lineTo(x, y);
    }

    waveformPath.close();
    canvas.drawPath(waveformPath, waveformPaint);

    // 绘制波形线条
    final linePaint = Paint()
      ..color = AppColors.waveformLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final linePath = Path();
    linePath.moveTo(0, centerY);

    for (var i = 0; i < samplesCount; i++) {
      final index = (i * step).floor().clamp(0, rmsValues.length - 1);
      final x = (i / samplesCount) * size.width;
      final value = rmsValues[index];
      final y = centerY - (value * maxHeight);
      linePath.lineTo(x, y);
    }

    canvas.drawPath(linePath, linePaint);

    // 绘制触觉事件标记
    final eventPaint = Paint()
      ..color = AppColors.hapticEvent
      ..style = PaintingStyle.fill;

    for (final event in hapticEvents) {
      final x = event.time * size.width;
      final markerHeight = event.amplitude * maxHeight * 0.8;

      // 绘制事件竖线
      canvas.drawRect(
        Rect.fromLTWH(x - 1, centerY - markerHeight, 2, markerHeight * 2),
        eventPaint..color = AppColors.hapticEvent.withValues(alpha: 0.6),
      );

      // 绘制顶部圆点
      canvas.drawCircle(
        Offset(x, centerY - markerHeight),
        3,
        eventPaint..color = AppColors.hapticEvent,
      );
    }

    // 绘制播放位置指示器
    if (playbackPosition > 0 && playbackPosition < 1) {
      final posX = playbackPosition * size.width;

      final positionPaint = Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(posX, 0),
        Offset(posX, size.height),
        positionPaint,
      );

      // 顶部三角形
      final trianglePath = Path()
        ..moveTo(posX - 6, 0)
        ..lineTo(posX + 6, 0)
        ..lineTo(posX, 8)
        ..close();

      canvas.drawPath(
        trianglePath,
        Paint()..color = AppColors.accent,
      );
    }

    // 绘制中心线
    final centerLinePaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerLinePaint,
    );
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.rmsValues != rmsValues ||
        oldDelegate.hapticEvents != hapticEvents ||
        oldDelegate.playbackPosition != playbackPosition;
  }
}

