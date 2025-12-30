import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../widgets/waveform_view.dart';
import '../widgets/parameter_panel.dart';
import '../widgets/timeline_editor.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 自动开始分析
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      if (appState.analysisResult == null) {
        appState.analyzeAudio();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _savePattern() async {
    final appState = context.read<AppState>();

    final controller = TextEditingController(
      text: appState.currentFileName ?? 'Untitled',
    );

    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('保存作品'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '作品名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (title != null && title.isNotEmpty) {
      await appState.saveCurrentPattern(title: title);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功!')),
        );
      }
    }
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
              _buildTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPreviewTab(),
                    _buildEditTab(),
                  ],
                ),
              ),
              _buildPlaybackControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  appState.reset();
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.currentFileName ?? '未知文件',
                      style: AppTextStyles.headline3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      TimeFormatter.formatMsShort(appState.audioDurationMs),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.save_alt),
                onPressed: appState.hapticEvents.isNotEmpty ? _savePattern : null,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: appState.hapticEvents.isNotEmpty
                    ? () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final path = await appState.exportPattern();
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('已导出到: $path')),
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '预览'),
          Tab(text: '编辑'),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.status == AppStatus.analyzing) {
          return _buildAnalyzingView();
        }

        if (appState.status == AppStatus.error) {
          return _buildErrorView(appState.errorMessage ?? '未知错误');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventStats(),
              const SizedBox(height: AppSpacing.md),
              const WaveformView(),
              const SizedBox(height: AppSpacing.lg),
              const ParameterPanel(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditTab() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.hapticEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timeline,
                  size: 64,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('尚无震动事件', style: AppTextStyles.body2),
                const Text('请先分析音频生成事件', style: AppTextStyles.caption),
              ],
            ),
          );
        }

        return const TimelineEditor();
      },
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('正在分析音频...', style: AppTextStyles.headline3),
          const SizedBox(height: AppSpacing.sm),
          const Text('提取能量波形与节拍信息', style: AppTextStyles.body2),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('分析失败', style: AppTextStyles.headline3),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTextStyles.body2, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                context.read<AppState>().analyzeAudio();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventStats() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final events = appState.hapticEvents;
        final avgAmplitude = events.isEmpty
            ? 0
            : events.map((e) => e.amplitude).reduce((a, b) => a + b) ~/ events.length;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('事件数', '${events.length}'),
              _buildStatItem('模式', appState.analysisParams.mode.displayName),
              _buildStatItem('平均强度', '$avgAmplitude'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headline2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            border: Border(
              top: BorderSide(color: AppColors.backgroundElevated),
            ),
          ),
          child: Column(
            children: [
              // 进度条
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: appState.playbackPositionMs.toDouble(),
                  max: appState.audioDurationMs.toDouble().clamp(1, double.infinity),
                  onChanged: (value) {
                    // 拖动进度条
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TimeFormatter.formatMs(appState.playbackPositionMs),
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    TimeFormatter.formatMs(appState.audioDurationMs),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // 播放控制
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    iconSize: 32,
                    onPressed: appState.hapticEvents.isEmpty
                        ? null
                        : () {
                            // 后退10秒
                          },
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        appState.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      iconSize: 36,
                      onPressed: appState.hapticEvents.isEmpty
                          ? null
                          : () {
                              if (appState.isPlaying) {
                                appState.stopPlayback();
                              } else {
                                appState.startPlayback();
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    iconSize: 32,
                    onPressed: appState.hapticEvents.isEmpty
                        ? null
                        : () {
                            // 前进10秒
                          },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // 快速预览按钮
              if (appState.hapticEvents.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    appState.previewRange(0, AnalysisDefaults.previewDurationMs);
                  },
                  icon: const Icon(Icons.preview, size: 18),
                  label: const Text('快速预览 5s'),
                ),
            ],
          ),
        );
      },
    );
  }
}

