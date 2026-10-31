package com.appamania.memo

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject
import java.util.Calendar

/** Registers plan entries with AlarmManager. */
object AlarmArm {
    fun arm(context: Context, entry: JSONObject) {
        val manager = context.getSystemService(AlarmManager::class.java)
        val at = entry.getLong("at")
        val pending = pendingIntent(context, entry.getInt("id"))
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || manager.canScheduleExactAlarms()
        if (exact) {
            manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        } else {
            // Exact-alarm grant revoked: still ring, possibly late. Settings
            // shows the grant as "Not allowed" so the user can fix it.
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        }
    }

    fun cancel(context: Context, id: Int) {
        context.getSystemService(AlarmManager::class.java).cancel(pendingIntent(context, id))
    }

    /** Next wall-clock occurrence after [at]; calendar math keeps 07:00 across DST. */
    fun next(at: Long, repeat: String, now: Long): Long? {
        val days = when (repeat) {
            "daily" -> 1
            "weekly" -> 7
            else -> return null
        }
        val cal = Calendar.getInstance().apply { timeInMillis = at }
        while (cal.timeInMillis <= now) cal.add(Calendar.DAY_OF_MONTH, days)
        return cal.timeInMillis
    }

    private fun pendingIntent(context: Context, id: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            id,
            Intent(context, AlarmReceiver::class.java).putExtra("id", id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /**
     * Done or Snooze on a ringing alarm: this occurrence is handled, so its
     * remaining nags must not ring before Dart catches up. One-off fires go;
     * a repeat's nags and pre-alarm still ahead of their main move one cycle.
     */
    fun quietOccurrence(context: Context, reminderId: String) {
        val store = AlarmStore(context)
        val mine = store.all().filter { it.getString("reminderId") == reminderId }
        val mains = mine.filter { it.optString("kind") == "main" }.associateBy { it.getInt("id") }
        val kept = store.all().filter { it.getString("reminderId") != reminderId }.toMutableList()
        for (entry in mine) {
            val repeat = entry.getString("repeat")
            val kind = entry.optString("kind", "main")
            if (repeat == "none") {
                cancel(context, entry.getInt("id"))
                continue
            }
            val main = mains[entry.optInt("group", entry.getInt("id"))]
            if (kind != "main" && main != null && entry.getLong("at") < main.getLong("at")) {
                entry.put("at", next(entry.getLong("at"), repeat, entry.getLong("at"))!!)
                arm(context, entry)
            }
            kept += entry
        }
        store.save(kept)
    }
}
