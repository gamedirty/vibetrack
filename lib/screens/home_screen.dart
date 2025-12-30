import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import 'editor_screen.dart';
import 'library_screen.dart';
import 'calibration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          if (!mounted) return;
          final appState = context.read<AppState>();
          await appState.loadAudioFile(file.path!, file.name);

          if (!mounted) return;
          if (appState.status != AppStatus.error) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditorScreen()),
            );
          } else {
            _showError(appState.errorMessage ?? '加载失败');
          }
        }
      }
    } catch (e) {
      _showError('选择文件失败: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _buildAppBar(),
                    const Spacer(),
                    _buildLogo(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildTagline(),
                    const Spacer(),
                    _buildMainButton(),
                    const SizedBox(height: AppSpacing.md),
                    _buildSecondaryButtons(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildStatusIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('VibeTrack', style: AppTextStyles.headline3),
        IconButton(
          icon: const Icon(Icons.tune, color: AppColors.textSecondary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalibrationScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.vibration,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Column(
      children: [
        Text(
          '感受音乐的每一个节拍',
          style: AppTextStyles.headline2.copyWith(
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [AppColors.textPrimary, AppColors.textSecondary],
              ).createShader(const Rect.fromLTWH(0, 0, 300, 30)),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          '将音乐转化为独特的触觉体验',
          style: AppTextStyles.body2,
        ),
      ],
    );
  }

  Widget _buildMainButton() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final isLoading = appState.status == AppStatus.loading;

        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: isLoading ? null : _pickAudioFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Container(
                alignment: Alignment.center,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_note, color: Colors.white),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            '选择音频文件',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecondaryButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              );
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('我的作品'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalibrationScreen()),
              );
            },
            icon: const Icon(Icons.settings),
            label: const Text('设备校准'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final hasAmplitudeControl = appState.deviceProfile.hasAmplitudeControl;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundElevated,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasAmplitudeControl ? Icons.check_circle : Icons.info,
                size: 16,
                color: hasAmplitudeControl ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                hasAmplitudeControl ? '支持振幅控制' : '基础震动模式',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        );
      },
    );
  }
}

