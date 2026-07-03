package com.example.moid_share

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Android side of the platform seams the Flutter app talks to.
 *
 * Implemented bridges:
 *   * Clipboard — MethodChannel `com.moidshare/clipboard/methods` (read/write)
 *     and EventChannel `com.moidshare/clipboard/events` (primary-clip changes).
 *   * Transfer  — MethodChannel `com.moidshare/transfer/methods` and
 *     EventChannel `com.moidshare/transfer/events`.
 *
 * Channel names + payload shapes are the single-source-of-truth contract on the
 * Dart side (`PlatformChannels`, `MethodChannelClipboardBridge`,
 * `MethodChannelTransferSenderBridge`, `MethodChannelTransferReceiverBridge`).
 * macOS implements the same contracts in Swift later.
 *
 * Note: Android 10+ restricts clipboard reads to the foreground app, so the
 * clipboard change listener only fires while this app has focus. OS limit, not
 * a bug — background clipboard capture is intentionally not possible.
 */
class MainActivity : FlutterActivity() {
    private companion object {
        const val CLIP_METHODS = "com.moidshare/clipboard/methods"
        const val CLIP_EVENTS = "com.moidshare/clipboard/events"
        const val TRANSFER_METHODS = "com.moidshare/transfer/methods"
        const val TRANSFER_EVENTS = "com.moidshare/transfer/events"
        const val PICK_FILE_REQUEST = 0x9001
    }

    private val clipboard: ClipboardManager
        get() = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

    private var clipListener: ClipboardManager.OnPrimaryClipChangedListener? = null

    /** In-flight `pickFile` call awaiting the SAF activity result. */
    private var pendingPick: MethodChannel.Result? = null

    /** Sink for native transfer progress events (receive side). */
    private var transferEvents: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        configureClipboard(messenger)
        configureTransfer(messenger)
    }

    // -- Clipboard -----------------------------------------------------------

    private fun configureClipboard(messenger: io.flutter.plugin.common.BinaryMessenger) {
        MethodChannel(messenger, CLIP_METHODS).setMethodCallHandler { call, result ->
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

        EventChannel(messenger, CLIP_EVENTS).setStreamHandler(
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

    // -- Transfer ------------------------------------------------------------

    private fun configureTransfer(messenger: io.flutter.plugin.common.BinaryMessenger) {
        MethodChannel(messenger, TRANSFER_METHODS).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFile" -> startPickFile(result)
                "readChunk" -> readChunk(call, result)
                // Receive side is a native seam: it needs the direct byte
                // transport (LAN socket) that is intentionally not wired here.
                // Accept/reject/cancel are acknowledged so the Dart signaling
                // flow proceeds; the actual write-to-disk lands with the socket.
                "acceptReceive", "rejectReceive", "cancelReceive" -> result.success(null)
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, TRANSFER_EVENTS).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    // Progress is emitted by the receive pipeline once the native
                    // socket seam is installed; hold the sink until then.
                    transferEvents = events
                }

                override fun onCancel(arguments: Any?) {
                    transferEvents = null
                }
            },
        )
    }

    /** Opens the system document picker; result delivered in [onActivityResult]. */
    private fun startPickFile(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("BUSY", "A file pick is already in progress", null)
            return
        }
        pendingPick = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivityForResult(intent, PICK_FILE_REQUEST)
    }

    /**
     * Reads `length` bytes at `offset` from a previously picked `content://`
     * URI. Returns a byte array (empty when past end-of-file).
     */
    private fun readChunk(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        val id = call.argument<String>("id")
        val offset = (call.argument<Number>("offset") ?: 0).toLong()
        val length = (call.argument<Number>("length") ?: 0).toInt()
        if (id == null || length <= 0) {
            result.error("ARG", "Missing id/length", null)
            return
        }
        try {
            contentResolver.openInputStream(Uri.parse(id)).use { input ->
                if (input == null) {
                    result.error("IO", "Cannot open $id", null)
                    return
                }
                var skipped = 0L
                while (skipped < offset) {
                    val s = input.skip(offset - skipped)
                    if (s <= 0) break
                    skipped += s
                }
                val buffer = ByteArray(length)
                var read = 0
                while (read < length) {
                    val n = input.read(buffer, read, length - read)
                    if (n < 0) break
                    read += n
                }
                result.success(buffer.copyOf(read))
            }
        } catch (e: Exception) {
            result.error("IO", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_FILE_REQUEST) return
        val result = pendingPick ?: return
        pendingPick = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null) // user cancelled
            return
        }
        // Persist read access so later readChunk calls succeed.
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        } catch (_: SecurityException) {
            // Some providers don't grant persistable permission; transient read
            // still works for the immediate transfer.
        }
        result.success(describeFile(uri))
    }

    /** Reads display name + size for a picked `content://` URI. */
    private fun describeFile(uri: Uri): Map<String, Any> {
        var name = "file"
        var size = 0L
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val nameIdx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            val sizeIdx = cursor.getColumnIndex(OpenableColumns.SIZE)
            if (cursor.moveToFirst()) {
                if (nameIdx >= 0) name = cursor.getString(nameIdx) ?: name
                if (sizeIdx >= 0 && !cursor.isNull(sizeIdx)) size = cursor.getLong(sizeIdx)
            }
        }
        return mapOf(
            "id" to uri.toString(),
            "name" to name,
            "size" to size,
            "contentType" to (contentResolver.getType(uri) ?: "application/octet-stream"),
        )
    }
}
