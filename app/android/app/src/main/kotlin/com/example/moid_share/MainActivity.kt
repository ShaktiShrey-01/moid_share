package com.example.moid_share

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Android side of the platform seams the Flutter app talks to.
 *
 * Today it implements the clipboard bridge:
 *   * MethodChannel `com.moidshare/clipboard/methods` — `read` / `write`.
 *   * EventChannel  `com.moidshare/clipboard/events`  — primary-clip changes.
 *
 * The channel names and payload shape are the single-source-of-truth contract
 * defined on the Dart side in `PlatformChannels` and consumed by
 * `MethodChannelClipboardBridge`. macOS implements the same contract in Swift.
 *
 * Note: Android 10+ restricts clipboard reads to the foreground app, so the
 * change listener only fires while this app has focus. That is an OS limit, not
 * a bug — background clipboard capture is intentionally not possible.
 */
class MainActivity : FlutterActivity() {
    private companion object {
        const val METHOD_CHANNEL = "com.moidshare/clipboard/methods"
        const val EVENT_CHANNEL = "com.moidshare/clipboard/events"
    }

    private val clipboard: ClipboardManager
        get() = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

    private var clipListener: ClipboardManager.OnPrimaryClipChangedListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "read" -> result.success(readClipboard())
                "write" -> {
                    val text = call.argument<String>("text")
                    if (text == null) {
                        result.error("ARG", "Missing \"text\"", null)
                    } else {
                        clipboard.setPrimaryClip(ClipData.newPlainText("moid-share", text))
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val listener = ClipboardManager.OnPrimaryClipChangedListener {
                        readClipboard()?.let { events?.success(it) }
                    }
                    clipListener = listener
                    clipboard.addPrimaryClipChangedListener(listener)
                }

                override fun onCancel(arguments: Any?) {
                    clipListener?.let { clipboard.removePrimaryClipChangedListener(it) }
                    clipListener = null
                }
            },
        )
    }

    /** Returns the current clipboard text as `{text, timestampMs}`, or null if empty. */
    private fun readClipboard(): Map<String, Any>? {
        val clip = clipboard.primaryClip ?: return null
        if (clip.itemCount == 0) return null
        val text = clip.getItemAt(0).coerceToText(this)?.toString()
        if (text.isNullOrEmpty()) return null
        return mapOf(
            "text" to text,
            "timestampMs" to System.currentTimeMillis(),
        )
    }
}
