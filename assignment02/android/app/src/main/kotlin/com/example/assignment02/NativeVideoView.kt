package com.example.assignment02

import android.content.Context
import android.net.Uri
import android.view.View
import android.widget.MediaController
import android.widget.VideoView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class NativeVideoViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val url = (args as? Map<*, *>)?.get("url") as? String ?: ""
        return NativeVideoView(context, url)
    }
}

class NativeVideoView(context: Context, url: String) : PlatformView {
    private val videoView = VideoView(context)

    init {
        val controller = MediaController(context)
        controller.setAnchorView(videoView)
        videoView.setMediaController(controller)
        if (url.isNotEmpty()) {
            videoView.setVideoURI(Uri.parse(url))
        }
    }

    override fun getView(): View = videoView

    override fun dispose() {
        videoView.stopPlayback()
    }
}
