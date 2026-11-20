package `in`.appamania.memo

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

    /** The reminder on screen and sound now; the rest wait their turn. */
    private var current: JSONObject? = null
    private val queue = ArrayDeque<JSONObject>()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val entry = intent?.getStringExtra("entry")?.let(::JSONObject)
        when (intent?.action) {
            ACTION_DONE, ACTION_SNOOZE -> {
                val reminderId = intent.getStringExtra("reminderId") ?: current?.getString("reminderId")
                if (reminderId != null) {
                    AlarmArm.quietOccurrence(this, reminderId)
                    AlarmStore(this).appendAction(
                        reminderId,
                        if (intent.action == ACTION_DONE) "done" else "snooze",
                    )
                    if (intent.action == ACTION_SNOOZE) snooze(intent)
                    finish(reminderId)
                }
            }
            ACTION_STOP -> intent.getStringExtra("reminderId")?.let { reminderId ->
                AlarmArm.quietOccurrence(this, reminderId)
                finish(reminderId)
            }
            else -> if (entry != null) enqueue(entry) else current?.let { foreground(it, alertOnce = true) } ?: stopSelf()
        }
        return START_NOT_STICKY
    }

    /**
     * One reminder rings at a time. A second one is posted as a quiet
     * notification and rings when the first is answered. Every
     * startForegroundService must be answered by startForeground, even when
     * the service is already foreground, so each path below re-posts it.
     */
    private fun enqueue(entry: JSONObject) {
        val reminderId = entry.getString("reminderId")
        val active = current
        if (active == null) {
            ring(entry)
            return
        }
        if (active.getString("reminderId") != reminderId) {
            queue.removeAll { it.getString("reminderId") == reminderId }
            queue.addLast(entry)
            getSystemService(NotificationManager::class.java)
                .notify(notifId(reminderId), notification(entry, ringing = false))
        }
        // Re-posting the ringing card must not re-fire its heads-up or screen.
        foreground(active, alertOnce = true)
    }

    private fun finish(reminderId: String) {
        queue.removeAll { it.getString("reminderId") == reminderId }
        if (current?.getString("reminderId") == reminderId) advance()
        // After advance: the next ring has taken over the foreground slot, so
        // the old card is no longer the foreground notification and can go.
        getSystemService(NotificationManager::class.java).cancel(notifId(reminderId))
        if (current == null && queue.isEmpty()) stopSelf()
    }

    /** Stops the current sound and rings the next waiting reminder, if any. */
    private fun advance() {
        player?.release()
        player = null
        handler.removeCallbacksAndMessages(null)
        current = null
        ringing = null
        // With a next alarm stay foreground: re-entering startForeground from
        // the background (timeout path) can throw on Android 12+.
        val next = queue.removeFirstOrNull()
        if (next != null) {
            ring(next)
        } else {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    private fun ring(entry: JSONObject) {
        val reminderId = entry.getString("reminderId")
        current = entry
        ringing = reminderId
        foreground(entry)
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
        handler.postDelayed({ missed(entry); finish(reminderId) }, TIMEOUT_MS)
    }

    private fun foreground(entry: JSONObject, alertOnce: Boolean = false) {
        val notification = notification(entry, ringing = true, alertOnce = alertOnce)
        val id = notifId(entry.getString("reminderId"))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(id, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(id, notification)
        }
    }

    /** Unanswered for the whole window: it stays in the shade, and opens the reminder. */
    private fun missed(entry: JSONObject) {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(MISSED_CHANNEL, "Missed", NotificationManager.IMPORTANCE_DEFAULT).apply {
                setSound(null, null)
            },
        )
        val reminderId = entry.getString("reminderId")
        val open = PendingIntent.getActivity(
            this,
            notifId(reminderId) * 4 + 3,
            Intent(Intent.ACTION_VIEW, Uri.parse("memo:///reminder/$reminderId"), this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        manager.notify(
            missedId(reminderId),
            Notification.Builder(this, MISSED_CHANNEL)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(entry.optString("missedText").ifEmpty { "Missed: " + entry.optString("title") })
                .setCategory(Notification.CATEGORY_REMINDER)
                .setAutoCancel(true)
                .setContentIntent(open)
                .build(),
        )
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

    /** Only the ringing one takes the screen; a queued one is a quiet banner. */
    private fun notification(entry: JSONObject, ringing: Boolean, alertOnce: Boolean = !ringing): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL,
                entry.optString("channelName").ifEmpty { "Alarms" },
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Reminders ringing now"
                setSound(null, null) // the service plays the sound itself
            },
        )
        val reminderId = entry.getString("reminderId")
        // Per reminder, so two alarms never share a PendingIntent.
        val base = notifId(reminderId) * 4
        val open = PendingIntent.getActivity(
            this,
            base,
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
        val builder = Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(entry.optString("title"))
            .setContentText(entry.optString("body").ifEmpty { "Memō" })
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(ringing)
            .setOnlyAlertOnce(alertOnce)
            .setContentIntent(open)
            .addAction(
                Notification.Action.Builder(
                    null,
                    entry.optString("doneLabel").ifEmpty { "Done" },
                    action(ACTION_DONE, base + 1),
                ).build(),
            )
            .addAction(
                Notification.Action.Builder(
                    null,
                    entry.optString("snoozeLabel").ifEmpty { "Snooze 10m" },
                    action(ACTION_SNOOZE, base + 2),
                ).build(),
            )
        if (ringing) builder.setFullScreenIntent(open, true)
        return builder.build()
    }

    private fun alarmIntent(reminderId: String) =
        Intent(Intent.ACTION_VIEW, Uri.parse("memo:///alarm/$reminderId"), this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        player?.release()
        player = null
        val manager = getSystemService(NotificationManager::class.java)
        queue.forEach { manager.cancel(notifId(it.getString("reminderId"))); missed(it) }
        queue.clear()
        current = null
        ringing = null
        super.onDestroy()
    }

    companion object {
        const val ACTION_DONE = "in.appamania.memo.DONE"
        const val ACTION_SNOOZE = "in.appamania.memo.SNOOZE"
        private const val ACTION_STOP = "in.appamania.memo.STOP"
        private const val CHANNEL = "alarm"
        private const val MISSED_CHANNEL = "missed"
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

        fun stop(context: Context, reminderId: String?) {
            if (reminderId == null) {
                context.stopService(Intent(context, AlarmService::class.java))
                return
            }
            context.startService(
                Intent(context, AlarmService::class.java)
                    .setAction(ACTION_STOP)
                    .putExtra("reminderId", reminderId),
            )
        }

        private fun notifId(reminderId: String) = (reminderId.hashCode() and 0x0FFFFFFF) or 0x10000000

        private fun missedId(reminderId: String) = (reminderId.hashCode() and 0x0FFFFFFF) or 0x40000000
    }
}
