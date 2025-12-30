package com.iwannasee.vibetrack

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import kotlin.math.sqrt

class MainActivity : FlutterActivity() {
    private val hapticChannel = "com.iwannasee.vibetrack/haptic"
    private val audioChannel = "com.iwannasee.vibetrack/audio"

    private lateinit var vibrator: Vibrator

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        // 震动通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, hapticChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceCapabilities" -> {
                    val capabilities = getDeviceCapabilities()
                    result.success(capabilities)
                }
                "vibrate" -> {
                    val durationMs = call.argument<Int>("durationMs") ?: 100
                    val amplitude = call.argument<Int>("amplitude") ?: 255
                    vibrate(durationMs.toLong(), amplitude)
                    result.success(null)
                }
                "playWaveform" -> {
                    val timings = call.argument<List<Int>>("timings") ?: emptyList()
                    val amplitudes = call.argument<List<Int>>("amplitudes") ?: emptyList()
                    playWaveform(timings.map { it.toLong() }.toLongArray(), amplitudes.toIntArray())
                    result.success(null)
                }
                "cancel" -> {
                    vibrator.cancel()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 音频分析通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, audioChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "analyzeAudio" -> {
                    val filePath = call.argument<String>("filePath")
                    val frameSize = call.argument<Int>("frameSize") ?: 1024
                    if (filePath == null) {
                        result.error("INVALID_ARGUMENT", "filePath is required", null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        try {
                            val analysisResult = analyzeAudio(filePath, frameSize)
                            runOnUiThread {
                                result.success(analysisResult)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("ANALYSIS_ERROR", e.message, null)
                            }
                        }
                    }.start()
                }
                "getAudioDuration" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        result.error("INVALID_ARGUMENT", "filePath is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val duration = getAudioDuration(filePath)
                        result.success(duration)
                    } catch (e: Exception) {
                        result.error("DURATION_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getDeviceCapabilities(): Map<String, Any> {
        val hasAmplitudeControl = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.hasAmplitudeControl()
        } else {
            false
        }
        return mapOf(
            "hasAmplitudeControl" to hasAmplitudeControl,
            "minPulseMs" to 10,
            "maxContinuousDurationMs" to 5000,
            "hasVibrator" to vibrator.hasVibrator()
        )
    }

    private fun vibrate(durationMs: Long, amplitude: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = VibrationEffect.createOneShot(durationMs, amplitude.coerceIn(1, 255))
            vibrator.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(durationMs)
        }
    }

    private fun playWaveform(timings: LongArray, amplitudes: IntArray) {
        if (timings.isEmpty()) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val clampedAmplitudes = amplitudes.map { it.coerceIn(0, 255) }.toIntArray()
            val effect = VibrationEffect.createWaveform(timings, clampedAmplitudes, -1)
            vibrator.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(timings, -1)
        }
    }

    private fun getAudioDuration(filePath: String): Long {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(filePath)
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME)
                if (mime?.startsWith("audio/") == true) {
                    return format.getLong(MediaFormat.KEY_DURATION) / 1000 // 转换为毫秒
                }
            }
            throw Exception("未找到音频轨道")
        } finally {
            extractor.release()
        }
    }

    private fun analyzeAudio(filePath: String, frameSize: Int): Map<String, Any> {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null

        try {
            extractor.setDataSource(filePath)

            // 查找音频轨道
            var audioTrackIndex = -1
            var audioFormat: MediaFormat? = null

            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME)
                if (mime?.startsWith("audio/") == true) {
                    audioTrackIndex = i
                    audioFormat = format
                    break
                }
            }

            if (audioTrackIndex < 0 || audioFormat == null) {
                throw Exception("未找到支持的音频轨道")
            }

            extractor.selectTrack(audioTrackIndex)

            val mime = audioFormat.getString(MediaFormat.KEY_MIME)
                ?: throw Exception("无法获取音频格式")
            val sampleRate = audioFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            val channelCount = audioFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            val durationUs = audioFormat.getLong(MediaFormat.KEY_DURATION)

            codec = MediaCodec.createDecoderByType(mime)
            codec.configure(audioFormat, null, null, 0)
            codec.start()

            val rmsValues = mutableListOf<Double>()
            val timeStamps = mutableListOf<Long>()
            val pcmBuffer = mutableListOf<Short>()

            val bufferInfo = MediaCodec.BufferInfo()
            var isEOS = false
            val frameSampleCount = (sampleRate * 0.02).toInt() // 20ms per frame

            while (!isEOS) {
                // 输入
                val inputBufferIndex = codec.dequeueInputBuffer(10000)
                if (inputBufferIndex >= 0) {
                    val inputBuffer = codec.getInputBuffer(inputBufferIndex)
                    if (inputBuffer != null) {
                        val sampleSize = extractor.readSampleData(inputBuffer, 0)
                        if (sampleSize < 0) {
                            codec.queueInputBuffer(
                                inputBufferIndex, 0, 0, 0,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM
                            )
                            isEOS = true
                        } else {
                            codec.queueInputBuffer(
                                inputBufferIndex, 0, sampleSize,
                                extractor.sampleTime, 0
                            )
                            extractor.advance()
                        }
                    }
                }

                // 输出
                var outputBufferIndex = codec.dequeueOutputBuffer(bufferInfo, 10000)
                while (outputBufferIndex >= 0) {
                    val outputBuffer = codec.getOutputBuffer(outputBufferIndex)
                    if (outputBuffer != null && bufferInfo.size > 0) {
                        // 读取PCM数据
                        val pcmData = ShortArray(bufferInfo.size / 2)
                        outputBuffer.asShortBuffer().get(pcmData)

                        // 如果是多声道，转为单声道
                        val monoData = if (channelCount > 1) {
                            ShortArray(pcmData.size / channelCount) { i ->
                                var sum = 0
                                for (c in 0 until channelCount) {
                                    sum += pcmData[i * channelCount + c]
                                }
                                (sum / channelCount).toShort()
                            }
                        } else {
                            pcmData
                        }

                        pcmBuffer.addAll(monoData.toList())

                        // 按帧计算RMS
                        while (pcmBuffer.size >= frameSampleCount) {
                            val frame = pcmBuffer.subList(0, frameSampleCount).toShortArray()
                            val rms = calculateRMS(frame)
                            rmsValues.add(rms)
                            timeStamps.add((timeStamps.size * 20).toLong()) // 20ms per frame
                            repeat(frameSampleCount) { pcmBuffer.removeAt(0) }
                        }
                    }

                    codec.releaseOutputBuffer(outputBufferIndex, false)

                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        isEOS = true
                        break
                    }

                    outputBufferIndex = codec.dequeueOutputBuffer(bufferInfo, 0)
                }
            }

            // 处理剩余数据
            if (pcmBuffer.isNotEmpty()) {
                val frame = pcmBuffer.toShortArray()
                val rms = calculateRMS(frame)
                rmsValues.add(rms)
                timeStamps.add((timeStamps.size * 20).toLong())
            }

            // 归一化RMS值
            val maxRms = rmsValues.maxOrNull() ?: 1.0
            val normalizedRms = rmsValues.map { it / maxRms }

            return mapOf(
                "sampleRate" to sampleRate,
                "channelCount" to channelCount,
                "durationMs" to (durationUs / 1000),
                "frameCount" to rmsValues.size,
                "rmsValues" to normalizedRms,
                "timeStamps" to timeStamps
            )

        } finally {
            codec?.stop()
            codec?.release()
            extractor.release()
        }
    }

    private fun calculateRMS(samples: ShortArray): Double {
        if (samples.isEmpty()) return 0.0
        var sum = 0.0
        for (sample in samples) {
            val normalized = sample.toDouble() / Short.MAX_VALUE
            sum += normalized * normalized
        }
        return sqrt(sum / samples.size)
    }
}
