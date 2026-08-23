package com.example.assignment02

import android.media.AudioAttributes
import android.media.MediaPlayer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeAudioPlayer : MethodChannel.MethodCallHandler {
    private var player: MediaPlayer? = null
    private var paused: Boolean = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "play" -> {
                val url = call.argument<String>("url")
                if (url.isNullOrEmpty()) {
                    result.error("NO_URL", "Audio url is missing", null)
                    return
                }
                play(url)
                result.success(true)
            }
            "pause" -> {
                pause()
                result.success(true)
            }
            "resume" -> {
                resume()
                result.success(true)
            }
            "stop" -> {
                release()
                result.success(true)
            }
            "isPlaying" -> result.success(player?.isPlaying == true)
            else -> result.notImplemented()
        }
    }

    private fun play(url: String) {
        release()
        player =
            MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .build(),
                )
                setDataSource(url)
                setOnPreparedListener { start() }
                setOnCompletionListener {
                    paused = false
                }
                prepareAsync()
            }
        paused = false
    }

    private fun pause() {
        val current = player ?: return
        if (current.isPlaying) {
            current.pause()
            paused = true
        }
    }

    private fun resume() {
        val current = player ?: return
        if (paused) {
            current.start()
            paused = false
        }
    }

    fun release() {
        player?.reset()
        player?.release()
        player = null
        paused = false
    }
}
