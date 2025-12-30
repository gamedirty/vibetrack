import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/haptic_event.dart';
import '../utils/constants.dart';

class TimelineEditor extends StatefulWidget {
  const TimelineEditor({super.key});

  @override
  State<TimelineEditor> createState() => _TimelineEditorState();
}

class _TimelineEditorState extends State<TimelineEditor> {
  final ScrollController _scrollController = ScrollController();
  final double _pixelsPerSecond = 100;
  int? _selectedEventIndex;
  bool _isDragging = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectEvent(int index) {
    setState(() {
      _selectedEventIndex = index == _selectedEventIndex ? null : index;
    });
  }

  void _deleteSelectedEvent() {
    if (_selectedEventIndex != null) {
      context.read<AppState>().deleteHapticEvent(_selectedEventIndex!);
      setState(() {
        _selectedEventIndex = null;
      });
    }
  }

  void _adjustEventAmplitude(int delta) {
    if (_selectedEventIndex == null) return;
    final appState = context.read<AppState>();
    final event = appState.hapticEvents[_selectedEventIndex!];
    final newAmplitude = (event.amplitude + delta).clamp(1, 255);
    appState.updateHapticEvent(
      _selectedEventIndex!,
      event.copyWith(amplitude: newAmplitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final events = appState.hapticEvents;
        final durationMs = appState.audioDurationMs;
        final totalWidth = (durationMs / 1000) * _pixelsPerSecond;

        return Column(
          children: [
            if (_selectedEventIndex != null) _buildEventToolbar(events),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.backgroundElevated),
                ),
                child: Column(
                  children: [
                    _buildTimeRuler(totalWidth, durationMs),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: max(totalWidth, MediaQuery.of(context).size.width - 32),
                          child: Stack(
                            children: [
                              _buildGridLines(totalWidth, durationMs),
                              _buildEventMarkers(events, totalWidth, durationMs),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildEventList(events),
          ],
        );
      },
    );
  }

  Widget _buildEventToolbar(List<HapticEvent> events) {
    final event = events[_selectedEventIndex!];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Text(
            '事件 #${_selectedEventIndex! + 1}',
            style: AppTextStyles.body2,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${event.timeMs}ms',
            style: AppTextStyles.caption,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            onPressed: () => _adjustEventAmplitude(-10),
            tooltip: '降低强度',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '强度: ${event.amplitude}',
              style: AppTextStyles.body2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () => _adjustEventAmplitude(10),
            tooltip: '提高强度',
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
            onPressed: _deleteSelectedEvent,
            tooltip: '删除事件',
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRuler(double totalWidth, int durationMs) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.md),
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: max(totalWidth, MediaQuery.of(context).size.width - 32),
          child: CustomPaint(
            painter: TimeRulerPainter(
              durationMs: durationMs,
              pixelsPerSecond: _pixelsPerSecond,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridLines(double totalWidth, int durationMs) {
    return CustomPaint(
      painter: GridLinesPainter(
        durationMs: durationMs,
        pixelsPerSecond: _pixelsPerSecond,
      ),
      size: Size(totalWidth, double.infinity),
    );
  }

  Widget _buildEventMarkers(List<HapticEvent> events, double totalWidth, int durationMs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: events.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final x = (event.timeMs / durationMs) * totalWidth;
            final isSelected = index == _selectedEventIndex;

            return Positioned(
              left: x - 8,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => _selectEvent(index),
                onHorizontalDragStart: (_) {
                  _selectEvent(index);
                  _isDragging = true;
                },
                onHorizontalDragUpdate: (details) {
                  if (!_isDragging) return;
                  final appState = context.read<AppState>();
                  final newX = x + details.delta.dx;
                  final newTimeMs = ((newX / totalWidth) * durationMs).round();
                  appState.updateHapticEvent(
                    index,
                    event.copyWith(timeMs: newTimeMs.clamp(0, durationMs)),
                  );
                },
                onHorizontalDragEnd: (_) {
                  _isDragging = false;
                },
                child: _EventMarker(
                  event: event,
                  isSelected: isSelected,
                  maxHeight: constraints.maxHeight,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEventList(List<HapticEvent> events) {
    return Container(
      height: 120,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Text(
                  '事件列表 (${events.length})',
                  style: AppTextStyles.body2,
                ),
                const Spacer(),
                Text(
                  '点击选择，拖动调整时间',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final isSelected = index == _selectedEventIndex;

                return GestureDetector(
                  onTap: () => _selectEvent(index),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.backgroundElevated,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: isSelected
                          ? Border.all(color: AppColors.primary)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '#${index + 1}',
                          style: AppTextStyles.caption,
                        ),
                        Text(
                          TimeFormatter.formatMs(event.timeMs),
                          style: AppTextStyles.body2,
                        ),
                        Container(
                          height: 4,
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: AppColors.hapticEvent.withValues(
                              alpha: event.amplitude / 255,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventMarker extends StatelessWidget {
  final HapticEvent event;
  final bool isSelected;
  final double maxHeight;

  const _EventMarker({
    required this.event,
    required this.isSelected,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final height = (event.amplitude / 255) * maxHeight * 0.8;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 16,
          height: height.clamp(20, maxHeight),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.hapticEventSelected
                : AppColors.hapticEvent.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
            border: isSelected
                ? Border.all(color: AppColors.accent, width: 2)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.hapticEvent.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

class TimeRulerPainter extends CustomPainter {
  final int durationMs;
  final double pixelsPerSecond;

  TimeRulerPainter({
    required this.durationMs,
    required this.pixelsPerSecond,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final paint = Paint()
      ..color = AppColors.textMuted
      ..strokeWidth = 1;

    final totalSeconds = (durationMs / 1000).ceil();

    for (var i = 0; i <= totalSeconds; i++) {
      final x = i * pixelsPerSecond;

      // 主刻度
      canvas.drawLine(
        Offset(x, size.height - 8),
        Offset(x, size.height),
        paint,
      );

      // 时间标签
      textPainter.text = TextSpan(
        text: TimeFormatter.formatMsShort(i * 1000),
        style: AppTextStyles.caption.copyWith(fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, 4),
      );

      // 次刻度（每0.5秒）
      if (i < totalSeconds) {
        final halfX = x + pixelsPerSecond / 2;
        canvas.drawLine(
          Offset(halfX, size.height - 4),
          Offset(halfX, size.height),
          paint..color = AppColors.textMuted.withValues(alpha: 0.5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(TimeRulerPainter oldDelegate) => false;
}

class GridLinesPainter extends CustomPainter {
  final int durationMs;
  final double pixelsPerSecond;

  GridLinesPainter({
    required this.durationMs,
    required this.pixelsPerSecond,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.backgroundElevated.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    final totalSeconds = (durationMs / 1000).ceil();

    for (var i = 0; i <= totalSeconds; i++) {
      final x = i * pixelsPerSecond;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridLinesPainter oldDelegate) => false;
}

