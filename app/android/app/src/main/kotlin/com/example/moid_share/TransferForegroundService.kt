package com.example.moid_share

import android.app.Notification
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.ServiceCompat

/**
 * Keeps in-flight transfers alive while the app is backgrounded.
 *
 * Android kills background work aggressively; a foreground service with an
 * ongoing notification is the sanctioned way to continue a user-initiated data
 * sync. [NotificationHelper] owns the channel + notification building so this
 * class stays a thin lifecycle wrapper (single responsibility).
 *
 * Started/stopped from Dart via the `system` method channel
 * (`startTransferService` / `stopTransferService`).
 */
class TransferForegroundService : Service() {
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification: Notification = NotificationHelper.buildServiceNotification(this)
        // Declare the data-sync FGS type on Android 10+ (required on 14+).
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
        } else {
            0
        }
        ServiceCompat.startForeground(
            this,
            NotificationHelper.SERVICE_NOTIFICATION_ID,
            notification,
            type,
        )
        // If the system kills us, don't recreate with a null intent — the app
        // re-starts the service when a new transfer begins.
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
