import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  int _testAmplitude = 128;
  int _testDuration = 50;
  double _amplitudeScale = 1.0;
  int _minPulseMs = 10;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().deviceProfile;
    _amplitudeScale = profile.amplitudeScale;
    _minPulseMs = profile.minPulseMs;
  }

  void _saveProfile() {
    final appState = context.read<AppState>();
    final newProfile = appState.deviceProfile.copyWith(
      amplitudeScale: _amplitudeScale,
      minPulseMs: _minPulseMs,
    );
    appState.updateDeviceProfile(newProfile);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设备配置已保存')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDeviceInfo(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildVibrationTest(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildCalibrationSettings(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildAmplitudeTest(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text('设备校准', style: AppTextStyles.headline2),
          ),
          TextButton(
            onPressed: _saveProfile,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final profile = appState.deviceProfile;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_android, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('设备能力', style: AppTextStyles.headline3),
                  ],
                ),
                const Divider(height: AppSpacing.lg),
                _buildInfoRow(
                  '振幅控制',
                  profile.hasAmplitudeControl ? '支持' : '不支持',
                  profile.hasAmplitudeControl ? AppColors.success : AppColors.warning,
                ),
                _buildInfoRow('最小脉冲时长', '${profile.minPulseMs}ms', null),
                _buildInfoRow('最大连续时长', '${profile.maxContinuousDurationMs}ms', null),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body2),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibrationTest() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.vibration, color: AppColors.accent),
                const SizedBox(width: AppSpacing.sm),
                const Text('震动测试', style: AppTextStyles.headline3),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            const Text('测试强度', style: AppTextStyles.body2),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _testAmplitude.toDouble(),
                    min: 1,
                    max: 255,
                    divisions: 254,
                    label: '$_testAmplitude',
                    onChanged: (value) {
                      setState(() {
                        _testAmplitude = value.round();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$_testAmplitude',
                    style: AppTextStyles.body1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('测试时长 (ms)', style: AppTextStyles.body2),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _testDuration.toDouble(),
                    min: 10,
                    max: 500,
                    divisions: 49,
                    label: '${_testDuration}ms',
                    onChanged: (value) {
                      setState(() {
                        _testDuration = value.round();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    '${_testDuration}ms',
                    style: AppTextStyles.body1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<AppState>().testVibration(
                        durationMs: _testDuration,
                        amplitude: _testAmplitude,
                      );
                },
                icon: const Icon(Icons.play_circle_filled),
                label: const Text('测试震动'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                const Text('校准参数', style: AppTextStyles.headline3),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            const Text('强度缩放', style: AppTextStyles.body2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '根据您的设备调整震动强度感知',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Text('弱', style: AppTextStyles.caption),
                Expanded(
                  child: Slider(
                    value: _amplitudeScale,
                    min: 0.5,
                    max: 2.0,
                    divisions: 30,
                    label: _amplitudeScale.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() {
                        _amplitudeScale = value;
                      });
                    },
                  ),
                ),
                const Text('强', style: AppTextStyles.caption),
                SizedBox(
                  width: 48,
                  child: Text(
                    'x${_amplitudeScale.toStringAsFixed(1)}',
                    style: AppTextStyles.body2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('最小脉冲时长 (ms)', style: AppTextStyles.body2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '设备能感知的最短震动时长',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _minPulseMs.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: '${_minPulseMs}ms',
                    onChanged: (value) {
                      setState(() {
                        _minPulseMs = value.round();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    '${_minPulseMs}ms',
                    style: AppTextStyles.body1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmplitudeTest() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.equalizer, color: AppColors.accent),
                const SizedBox(width: AppSpacing.sm),
                const Text('强度感知测试', style: AppTextStyles.headline3),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            Text(
              '点击下方按钮测试不同强度，找到最适合您设备的强度缩放值',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [25, 50, 75, 100, 150, 200, 255].map((amp) {
                return OutlinedButton(
                  onPressed: () {
                    context.read<AppState>().testVibration(
                          durationMs: 100,
                          amplitude: amp,
                        );
                  },
                  child: Text('$amp'),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '测试不同时长',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [10, 20, 40, 80, 150, 300].map((duration) {
                return OutlinedButton(
                  onPressed: () {
                    context.read<AppState>().testVibration(
                          durationMs: duration,
                          amplitude: 200,
                        );
                  },
                  child: Text('${duration}ms'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

