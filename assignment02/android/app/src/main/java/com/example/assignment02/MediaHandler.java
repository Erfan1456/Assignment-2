package com.example.assignment02;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.media.AudioAttributes;
import android.media.MediaPlayer;
import android.os.Handler;
import android.os.Looper;
import android.view.Surface;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;

public class MediaHandler implements MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private static final String METHOD_CHANNEL = "assignment02/media";
    private static final String EVENT_CHANNEL = "assignment02/media_events";

    private final Context context;
    private final TextureRegistry textureRegistry;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    private EventChannel.EventSink events;

    private TextureRegistry.SurfaceTextureEntry textureEntry;
    private Surface videoSurface;
    private MediaPlayer videoPlayer;
    private MediaPlayer audioPlayer;
    private boolean videoReady = false;
    private boolean audioReady = false;
    private boolean videoMuted = false;

    private final Runnable progressTick =
            new Runnable() {
                @Override
                public void run() {
                    sendProgress();
                    if (videoReady || audioReady) {
                        mainHandler.postDelayed(this, 400);
                    }
                }
            };

    public MediaHandler(Context context, FlutterEngine flutterEngine) {
        this.context = context.getApplicationContext();
        textureRegistry = flutterEngine.getRenderer();
        MethodChannel methods =
                new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), METHOD_CHANNEL);
        methods.setMethodCallHandler(this);
        EventChannel eventChannel =
                new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), EVENT_CHANNEL);
        eventChannel.setStreamHandler(this);
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.events = events;
    }

    @Override
    public void onCancel(Object arguments) {
        stopProgress();
        events = null;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        try {
            switch (call.method) {
                case "videoInit":
                    initVideo(call.argument("asset"), result);
                    break;
                case "videoPlay":
                    if (videoReady && videoPlayer != null) {
                        videoPlayer.start();
                        startProgress();
                    }
                    result.success(videoReady && isPlaying(videoPlayer));
                    break;
                case "videoPause":
                    if (videoReady && videoPlayer != null && videoPlayer.isPlaying()) {
                        videoPlayer.pause();
                    }
                    result.success(true);
                    break;
                case "videoSeek": {
                    Integer ms = call.argument("ms");
                    if (videoReady && videoPlayer != null && ms != null) {
                        videoPlayer.seekTo(ms);
                    }
                    result.success(true);
                    break;
                }
                case "videoMute": {
                    Boolean muted = call.argument("muted");
                    videoMuted = muted != null && muted;
                    applyVideoVolume();
                    result.success(videoMuted);
                    break;
                }
                case "videoDispose":
                    releaseVideo();
                    result.success(true);
                    break;
                case "audioPlay":
                    playAudio(call.argument("asset"), result);
                    break;
                case "audioPause":
                    if (audioReady && audioPlayer != null && audioPlayer.isPlaying()) {
                        audioPlayer.pause();
                    }
                    result.success(true);
                    break;
                case "audioResume":
                    if (audioReady && audioPlayer != null) {
                        audioPlayer.start();
                        startProgress();
                    }
                    result.success(true);
                    break;
                case "audioSeek": {
                    Integer ms = call.argument("ms");
                    if (audioReady && audioPlayer != null && ms != null) {
                        audioPlayer.seekTo(ms);
                    }
                    result.success(true);
                    break;
                }
                case "audioStop":
                    releaseAudio();
                    result.success(true);
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Exception error) {
            result.error("MEDIA_ERROR", error.getMessage(), null);
        }
    }

    private void initVideo(String asset, MethodChannel.Result result) throws IOException {
        releaseVideo();
        textureEntry = textureRegistry.createSurfaceTexture();
        videoSurface = new Surface(textureEntry.surfaceTexture());
        videoPlayer = new MediaPlayer();
        videoPlayer.setAudioAttributes(
                new AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE)
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .build());
        videoPlayer.setSurface(videoSurface);
        setAssetDataSource(videoPlayer, asset);
        videoPlayer.setOnVideoSizeChangedListener(
                (mp, width, height) -> {
                    if (textureEntry != null && width > 0 && height > 0) {
                        textureEntry.surfaceTexture().setDefaultBufferSize(width, height);
                    }
                });
        videoPlayer.setOnPreparedListener(
                mp -> {
                    videoReady = true;
                    applyVideoVolume();
                    Map<String, Object> info = new HashMap<>();
                    info.put("textureId", textureEntry.id());
                    info.put("duration", mp.getDuration());
                    info.put("width", mp.getVideoWidth());
                    info.put("height", mp.getVideoHeight());
                    result.success(info);
                    mp.start();
                    startProgress();
                });
        videoPlayer.setOnCompletionListener(
                mp -> {
                    sendEvent(videoState("complete"));
                    stopProgress();
                });
        videoPlayer.setOnErrorListener(
                (mp, what, extra) -> {
                    if (!videoReady) {
                        result.error("MEDIA_ERROR", "Could not play video", null);
                    }
                    return true;
                });
        videoPlayer.prepareAsync();
    }

    private void playAudio(String asset, MethodChannel.Result result) throws IOException {
        releaseAudio();
        audioPlayer = new MediaPlayer();
        audioPlayer.setAudioAttributes(
                new AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .build());
        setAssetDataSource(audioPlayer, asset);
        audioPlayer.setOnPreparedListener(
                mp -> {
                    audioReady = true;
                    Map<String, Object> info = new HashMap<>();
                    info.put("duration", mp.getDuration());
                    result.success(info);
                    mp.start();
                    startProgress();
                });
        audioPlayer.setOnCompletionListener(
                mp -> {
                    sendEvent(audioState("complete"));
                    stopProgress();
                });
        audioPlayer.setOnErrorListener(
                (mp, what, extra) -> {
                    if (!audioReady) {
                        result.error("MEDIA_ERROR", "Could not play audio", null);
                    }
                    return true;
                });
        audioPlayer.prepareAsync();
    }

    private void setAssetDataSource(MediaPlayer player, String asset) throws IOException {
        String flutterAsset = "flutter_assets/" + asset;
        try {
            AssetFileDescriptor afd = context.getAssets().openFd(flutterAsset);
            try {
                player.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
            } finally {
                afd.close();
            }
        } catch (IOException ignored) {
            player.setDataSource(copyAssetToCache(flutterAsset, asset).getAbsolutePath());
        }
    }

    private File copyAssetToCache(String flutterAsset, String asset) throws IOException {
        File out = new File(context.getCacheDir(), asset.replace('/', '_'));
        if (out.exists() && out.length() > 0) {
            return out;
        }
        InputStream in = context.getAssets().open(flutterAsset);
        FileOutputStream fos = new FileOutputStream(out);
        try {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = in.read(buffer)) > 0) {
                fos.write(buffer, 0, read);
            }
        } finally {
            in.close();
            fos.close();
        }
        return out;
    }

    private void applyVideoVolume() {
        if (!videoReady || videoPlayer == null) {
            return;
        }
        float volume = videoMuted ? 0f : 1f;
        videoPlayer.setVolume(volume, volume);
    }

    private void sendProgress() {
        if (videoReady) {
            sendEvent(videoState("position"));
        }
        if (audioReady) {
            sendEvent(audioState("position"));
        }
    }

    private Map<String, Object> videoState(String event) {
        Map<String, Object> map = new HashMap<>();
        map.put("player", "video");
        map.put("event", event);
        map.put("textureId", textureEntry == null ? -1 : textureEntry.id());
        fillPlayer(map, videoReady ? videoPlayer : null);
        if (videoReady && videoPlayer != null) {
            map.put("width", videoPlayer.getVideoWidth());
            map.put("height", videoPlayer.getVideoHeight());
        }
        map.put("muted", videoMuted);
        return map;
    }

    private Map<String, Object> audioState(String event) {
        Map<String, Object> map = new HashMap<>();
        map.put("player", "audio");
        map.put("event", event);
        fillPlayer(map, audioReady ? audioPlayer : null);
        return map;
    }

    private Map<String, Object> errorState(String player, String message) {
        Map<String, Object> map = new HashMap<>();
        map.put("player", player);
        map.put("event", "error");
        map.put("message", message);
        return map;
    }

    private void fillPlayer(Map<String, Object> map, MediaPlayer player) {
        int position = 0;
        int duration = 0;
        boolean playing = false;
        if (player != null) {
            try {
                position = player.getCurrentPosition();
                duration = Math.max(player.getDuration(), 0);
                playing = player.isPlaying();
            } catch (IllegalStateException ignored) {
                // Player is not ready yet.
            }
        }
        map.put("position", position);
        map.put("duration", duration);
        map.put("playing", playing);
    }

    private boolean isPlaying(MediaPlayer player) {
        try {
            return player != null && player.isPlaying();
        } catch (IllegalStateException ignored) {
            return false;
        }
    }

    private void sendEvent(Map<String, Object> event) {
        if (events == null) {
            return;
        }
        mainHandler.post(
                () -> {
                    if (events != null) {
                        events.success(event);
                    }
                });
    }

    private void startProgress() {
        mainHandler.removeCallbacks(progressTick);
        mainHandler.post(progressTick);
    }

    private void stopProgress() {
        mainHandler.removeCallbacks(progressTick);
    }

    private void releaseVideo() {
        videoReady = false;
        if (videoPlayer != null) {
            try {
                videoPlayer.reset();
                videoPlayer.release();
            } catch (Exception ignored) {
                // Already released.
            }
            videoPlayer = null;
        }
        if (videoSurface != null) {
            videoSurface.release();
            videoSurface = null;
        }
        if (textureEntry != null) {
            textureEntry.release();
            textureEntry = null;
        }
        videoMuted = false;
    }

    private void releaseAudio() {
        audioReady = false;
        if (audioPlayer != null) {
            try {
                audioPlayer.reset();
                audioPlayer.release();
            } catch (Exception ignored) {
                // Already released.
            }
            audioPlayer = null;
        }
    }

    public void dispose() {
        stopProgress();
        releaseVideo();
        releaseAudio();
        events = null;
    }
}
