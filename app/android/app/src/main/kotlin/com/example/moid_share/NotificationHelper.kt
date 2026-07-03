package com.example.moid_share

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * Central place for the app's notification channel + notification building.
 *
 * Keeping this out of both [MainActivity] and [TransferForegroundService]
 * avoids duplicating channel setup and gives us one definition of what a
 * transfer notification looks like.
 */
object NotificationHelper {
    const val CHANNEL_ID = "moidshare.transfers"
    private const val CHANNEL_NAME = "Transfers"
    const val SERVICE_NOTIFICATION_ID = 0x5EED

    /** Creates the transfers channel once (no-op on API < 26 or if it exists). */
    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW, // ongoing progress: quiet
        ).apply {
            description = "File transfer progress and completion"
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    /** The persistent notification shown while the foreground service runs. */
    fun buildServiceNotification(context: Context): Notification {
        ensureChannel(context)
        return baseBuilder(context)
            .setContentTitle("Moid-Share")
            .setContentText("Transfer in progress")
            .setOngoing(true)
            .build()
    }

    fun buildProgress(
        context: Context,
        title: String,
        text: String,
        progress: Int,
        max: Int,
        indeterminate: Boolean,
    ): Notification {
        ensureChannel(context)
        return baseBuilder(context)
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(true)
            .setProgress(max, progress, indeterminate)
            .build()
    }

    fun buildDone(context: Context, title: String, text: String): Notification {
        ensureChannel(context)
        return baseBuilder(context)
            .setContentTitle(title)
            .setContentText(text)
            .setAutoCancel(true)
            .build()
    }

    private fun baseBuilder(context: Context): NotificationCompat.Builder =
        NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_upload)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setPriority(NotificationCompat.PRIORITY_LOW)
}
