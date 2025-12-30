# VibeTrack

将音频转换为触觉反馈的 Flutter 应用。

## 功能特点

- **离线音频分析** - 本地解析 mp3/aac/m4a/wav/flac 格式音频
- **三种分析模式**
  - Beat（节拍）：基于能量峰值检测，适合鼓点明显的音乐
  - Energy（能量）：按能量包络采样，适合电子/氛围音乐
  - Hybrid（混合）：综合节拍与能量，推荐大多数音乐
- **参数可调** - 灵敏度、密度、强度三个滑块即可调出满意效果
- **实时预览** - 调整参数后可即时预览震动效果
- **时间轴编辑** - 可视化编辑震动事件，支持拖动调整
- **Pattern 管理** - 保存、重命名、导出、分享震动作品
- **设备校准** - 针对不同设备调整震动参数

## 技术架构

### 目录结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # 应用配置和主题
├── models/                   # 数据模型
│   ├── haptic_event.dart     # 触觉事件
│   ├── haptic_pattern.dart   # 触觉模式
│   ├── analysis_mode.dart    # 分析模式枚举
│   ├── analysis_params.dart  # 分析参数
│   └── device_profile.dart   # 设备配置
├── services/                 # 服务层
│   ├── audio_analyzer.dart   # 音频分析服务
│   ├── haptic_engine.dart    # 震动引擎
│   ├── pattern_storage.dart  # Pattern存储
│   └── audio_player_service.dart # 音频播放
├── providers/                # 状态管理
│   └── app_state.dart        # 全局状态
├── screens/                  # 页面
│   ├── home_screen.dart      # 主页
│   ├── editor_screen.dart    # 编辑器
│   ├── library_screen.dart   # 作品库
│   └── calibration_screen.dart # 设备校准
├── widgets/                  # 组件
│   ├── waveform_view.dart    # 波形视图
│   ├── parameter_panel.dart  # 参数面板
│   └── timeline_editor.dart  # 时间轴编辑器
└── utils/                    # 工具类
    └── constants.dart        # 常量定义
```

### 核心数据模型

```dart
// 触觉事件
class HapticEvent {
  final int timeMs;      // 相对音频起点的时间
  final int durationMs;  // 震动持续时长
  final int amplitude;   // 1-255
}

// 触觉模式 (导出JSON格式)
{
  "id": "uuid",
  "title": "Song Name - Beat Pattern",
  "source": {
    "durationMs": 183000,
    "analysisMode": "hybrid"
  },
  "events": [
    { "timeMs": 520, "durationMs": 40, "amplitude": 220 }
  ]
}
```

### 音频分析流程

```
音频文件
    ↓
MediaExtractor + MediaCodec 解码
    ↓
PCM 16bit / 44.1kHz / mono
    ↓
Frame 切分 (20ms/帧)
    ↓
RMS 能量计算
    ↓
移动平均平滑
    ↓
Peak / Onset 检测
    ↓
事件筛选 (最小间隔/能量排序)
    ↓
生成 HapticEvent 列表
```

### 震动引擎

- API 26+ 使用 `VibrationEffect.createWaveform`
- 自动检测设备振幅控制能力
- 分段播放策略，每段3-8秒
- 与音频播放同步

## 使用方法

1. 点击「选择音频文件」选取本地音乐
2. 等待分析完成
3. 调整参数：
   - **灵敏度**：降低以减少弱节拍
   - **密度**：降低使震动更密集
   - **强度**：调整全局震动强度
4. 点击「快速预览 5s」体验效果
5. 满意后保存作品

## 设备适配

在「设备校准」页面可以：
- 查看设备震动能力
- 测试不同强度和时长的震动
- 调整强度缩放和最小脉冲时长
- 保存设备配置

## 隐私说明

- 所有音频分析在本地完成
- 不上传、不分享音乐文件
- 仅分享震动 Pattern（JSON 格式）

## 开发

```bash
# 获取依赖
flutter pub get

# 运行应用
flutter run

# 构建 APK
flutter build apk
```

## 系统要求

- Android 8.0 (API 26) 及以上
- Flutter 3.8+
- Dart 3.8+

## License

MIT
