package com.appamania.memo

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import org.json.JSONObject
import java.io.File

/**
 * Rings like an alarm: a full-screen-intent notification over the lock
 * screen and the voice clip (or the Memō ring) looping on the alarm
 * stream until Done, Snooze or two minutes pass. Done and Snooze tapped here
 * are queued for Dart; a snooze also arms its one-off so it rings even if the
 * app is never opened.
 */
class AlarmService : Service() {
    private var player: MediaPlayer? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val entry = intent?.getStringExtra("entry")?.let(::JSONObject)
        when (intent?.action) {
            ACTION_DONE, ACTION_SNOOZE -> {
                val reminderId = intent.getStringExtra("reminderId") ?: ringing
                if (reminderId != null) {
                    AlarmStore(this).appendAction(
                        reminderId,
                        if (intent.action == ACTION_DONE) "done" else "snooze",
                    )
                    if (intent.action == ACTION_SNOOZE) snooze(intent)
                }
                stopSelf()
            }
            else -> if (entry != null) ring(entry) else stopSelf()
        }
        return START_NOT_STICKY
    }

    private fun ring(entry: JSONObject) {
        val reminderId = entry.getString("reminderId")
        ringing = reminderId
        val notification = notification(entry)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        player?.release()
        val sound = entry.optString("sound").takeIf { it.isNotEmpty() && File(it).exists() }
        player = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            setDataSource(
                this@AlarmService,
                sound?.let { Uri.fromFile(File(it)) }
                    ?: Uri.parse("android.resource://$packageName/${R.raw.memo_ring}"),
            )
            isLooping = true
            prepare()
            start()
        }
        handler.removeCallbacksAndMessages(null)
        handler.postDelayed({ stopSelf() }, TIMEOUT_MS)
    }

    private fun snooze(intent: Intent) {
        val snoozeId = intent.getIntExtra("snoozeId", -1)
        if (snoozeId == -1) return
        val entry = JSONObject(intent.getStringExtra("entryJson") ?: return)
            .put("id", snoozeId)
            .put("repeat", "none")
            .put("at", System.currentTimeMillis() + SNOOZE_MS)
        AlarmStore(this).put(entry)
        AlarmArm.arm(this, entry)
    }

    private fun notification(entry: JSONObject): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, "Alarms", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Reminders ringing now"
                setSound(null, null) // the service plays the sound itself
            },
        )
        val reminderId = entry.getString("reminderId")
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(Intent.ACTION_VIEW, Uri.parse("memo:///alarm/$reminderId"), this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        fun action(name: String, code: Int) = PendingIntent.getService(
            this,
            code,
            Intent(this, AlarmService::class.java).setAction(name)
                .putExtra("reminderId", reminderId)
                .putExtra("snoozeId", entry.optInt("snoozeId", -1))
                .putExtra("entryJson", entry.toString()),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(entry.optString("title"))
            .setContentText(entry.optString("body").ifEmpty { "Memō" })
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setFullScreenIntent(open, true)
            .setContentIntent(open)
            .addAction(Notification.Action.Builder(null, "Done", action(ACTION_DONE, 1)).build())
            .addAction(Notification.Action.Builder(null, "Snooze 10m", action(ACTION_SNOOZE, 2)).build())
            .build()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        player?.release()
        player = null
        ringing = null
        super.onDestroy()
    }

    companion object {
        const val ACTION_DONE = "com.appamania.memo.DONE"
        const val ACTION_SNOOZE = "com.appamania.memo.SNOOZE"
        private const val CHANNEL = "alarm"
        private const val NOTIFICATION_ID = 7001
        private const val TIMEOUT_MS = 120_000L
        private const val SNOOZE_MS = 10 * 60_000L

        /** The reminder ringing right now, if any. */
        @Volatile
        var ringing: String? = null
            private set

        fun start(context: Context, entry: JSONObject) {
            context.startForegroundService(
                Intent(context, AlarmService::class.java).putExtra("entry", entry.toString()),
            )
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, AlarmService::class.java))
        }
    }
}
