package com.example.assignment02

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CUSTOM_EVENT_CHANNEL = "assignment02/custom_broadcast"
        private const val BATTERY_EVENT_CHANNEL = "assignment02/battery_broadcast"
        private const val AUDIO_CHANNEL = "assignment02/audio"
        private const val VIDEO_VIEW_TYPE = "assignment02/video"
        const val CUSTOM_ACTION = "com.example.assignment02.CUSTOM_BROADCAST"
        const val EXTRA_MESSAGE = "message"
    }

    private var customReceiver: BroadcastReceiver? = null
    private var batteryReceiver: BroadcastReceiver? = null
    private val audioPlayer = NativeAudioPlayer()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setMethodCallHandler(audioPlayer)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            VIDEO_VIEW_TYPE,
            NativeVideoViewFactory(),
        )

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CUSTOM_EVENT_CHANNEL)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        unregisterCustomReceiver()
                        customReceiver =
                            object : BroadcastReceiver() {
                                override fun onReceive(context: Context?, intent: Intent?) {
                                    events?.success(intent?.getStringExtra(EXTRA_MESSAGE) ?: "")
                                }
                            }
                        registerReceiverCompat(customReceiver, IntentFilter(CUSTOM_ACTION))

                        val message = arguments as? String
                        if (message != null) {
                            sendCustomBroadcast(message)
                        }
                    }

                    override fun onCancel(arguments: Any?) {
                        unregisterCustomReceiver()
                    }
                },
            )

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_EVENT_CHANNEL)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        unregisterBatteryReceiver()
                        batteryReceiver =
                            object : BroadcastReceiver() {
                                override fun onReceive(context: Context?, intent: Intent?) {
                                    val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                                    val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
                                    val percent =
                                        if (level >= 0 && scale > 0) {
                                            (level * 100) / scale
                                        } else {
                                            -1
                                        }
                                    events?.success(percent)
                                }
                            }
                        registerReceiverCompat(
                            batteryReceiver,
                            IntentFilter(Intent.ACTION_BATTERY_CHANGED),
                        )
                    }

                    override fun onCancel(arguments: Any?) {
                        unregisterBatteryReceiver()
                    }
                },
            )
    }

    private fun sendCustomBroadcast(message: String) {
        val intent = Intent(CUSTOM_ACTION)
        intent.setPackage(packageName)
        intent.putExtra(EXTRA_MESSAGE, message)
        sendBroadcast(intent)
    }

    private fun registerReceiverCompat(receiver: BroadcastReceiver?, filter: IntentFilter) {
        if (receiver == null) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(receiver, filter)
        }
    }

    private fun unregisterCustomReceiver() {
        customReceiver?.let { unregisterReceiver(it) }
        customReceiver = null
    }

    private fun unregisterBatteryReceiver() {
        batteryReceiver?.let { unregisterReceiver(it) }
        batteryReceiver = null
    }

    override fun onDestroy() {
        unregisterCustomReceiver()
        unregisterBatteryReceiver()
        audioPlayer.release()
        super.onDestroy()
    }
}
