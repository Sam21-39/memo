package com.appamania.memo

import android.app.KeyguardManager
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
import android.os.PowerManager
import android.provider.Settings
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
                    AlarmArm.quietOccurrence(this, reminderId)
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
        // Unlocked and in use: a full-screen intent only shows a banner, so
        // take the screen directly, as an alarm clock does. Needs "Display
        // over other apps"; without it the banner remains.
        val keyguard = getSystemService(KeyguardManager::class.java)
        val power = getSystemService(PowerManager::class.java)
        if (power.isInteractive && !keyguard.isKeyguardLocked && Settings.canDrawOverlays(this)) {
            startActivity(alarmIntent(reminderId))
        }
        // The chime, then the reminder read aloud, over and over.
        val ring = Uri.parse("android.resource://$packageName/${R.raw.memo_ring}")
        val speech = entry.optString("speech").takeIf { it.isNotEmpty() && File(it).exists() }
            ?.let { Uri.fromFile(File(it)) }
        playLoop(if (speech == null) listOf(ring) else listOf(ring, speech), 0)
        handler.removeCallbacksAndMessages(null)
        handler.postDelayed({ stopSelf() }, TIMEOUT_MS)
    }

    /** Plays [parts] in order, forever, on the alarm stream. */
    private fun playLoop(parts: List<Uri>, index: Int) {
        player?.release()
        player = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            setDataSource(this@AlarmService, parts[index])
            if (parts.size == 1) isLooping = true
            else setOnCompletionListener { handler.postDelayed({ playLoop(parts, (index + 1) % parts.size) }, GAP_MS) }
            prepare()
            start()
        }
    }

    private fun snooze(intent: Intent) {
        val snoozeId = intent.getIntExtra("snoozeId", -1)
        if (snoozeId == -1) return
        val entry = JSONObject(intent.getStringExtra("entryJson") ?: return)
            .put("id", snoozeId)
            .put("group", snoozeId)
            .put("kind", "snooze")
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
            alarmIntent(reminderId),
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

    private fun alarmIntent(reminderId: String) =
        Intent(Intent.ACTION_VIEW, Uri.parse("memo:///alarm/$reminderId"), this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

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
        private const val GAP_MS = 400L

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
