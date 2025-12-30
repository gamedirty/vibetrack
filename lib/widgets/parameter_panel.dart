import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/analysis_mode.dart';
import '../models/analysis_params.dart';
import '../utils/constants.dart';

class ParameterPanel extends StatelessWidget {
  const ParameterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final params = appState.analysisParams;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune, size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('参数调节', style: AppTextStyles.headline3),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      appState.updateAnalysisParams(const AnalysisParams());
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('重置'),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),

              // 分析模式选择
              const Text('分析模式', style: AppTextStyles.body2),
              const SizedBox(height: AppSpacing.sm),
              _buildModeSelector(context, appState),
              const SizedBox(height: AppSpacing.lg),

              // 灵敏度
              _buildSliderSection(
                context,
                title: '灵敏度',
                subtitle: '降低以减少弱节拍，提高以捕捉更多细节',
                value: 1 - params.threshold, // 反转显示
                min: 0.2,
                max: 0.9,
                divisions: 14,
                onChanged: (value) {
                  appState.updateThreshold(1 - value);
                },
                valueFormatter: (v) => '${(v * 100).round()}%',
              ),
              const SizedBox(height: AppSpacing.md),

              // 密度
              _buildSliderSection(
                context,
                title: '密度',
                subtitle: '最小事件间隔，降低使震动更密集',
                value: params.minIntervalMs.toDouble(),
                min: AnalysisDefaults.minInterval.toDouble(),
                max: AnalysisDefaults.maxInterval.toDouble(),
                divisions: 9,
                onChanged: (value) {
                  appState.updateMinInterval(value.round());
                },
                valueFormatter: (v) => '${v.round()}ms',
              ),
              const SizedBox(height: AppSpacing.md),

              // 强度
              _buildSliderSection(
                context,
                title: '强度',
                subtitle: '全局震动强度增益',
                value: params.globalGain,
                min: AnalysisDefaults.minGain,
                max: AnalysisDefaults.maxGain,
                divisions: 15,
                onChanged: (value) {
                  appState.updateGlobalGain(value);
                },
                valueFormatter: (v) => 'x${v.toStringAsFixed(1)}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeSelector(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: AnalysisMode.values.map((mode) {
          final isSelected = appState.analysisParams.mode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => appState.updateAnalysisMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Column(
                  children: [
                    Text(
                      mode.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSliderSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String Function(double) valueFormatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.body1),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                valueFormatter(value),
                style: AppTextStyles.body2.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.backgroundElevated,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withValues(alpha: 0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

