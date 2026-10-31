package com.appamania.memo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** An exact alarm fired: re-arm a repeat, then start the ringing service. */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val store = AlarmStore(context)
        val entry = store.get(intent.getIntExtra("id", -1)) ?: return
        val next = AlarmArm.next(entry.getLong("at"), entry.getString("repeat"), System.currentTimeMillis())
        if (next == null) {
            store.remove(entry.getInt("id"))
        } else {
            entry.put("at", next)
            store.put(entry)
            AlarmArm.arm(context, entry)
        }
        AlarmService.start(context, entry)
    }
}

/** Reboot, app update or a clock change: re-arm every stored alarm. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val store = AlarmStore(context)
        val now = System.currentTimeMillis()
        val kept = store.all().mapNotNull { entry ->
            if (entry.getLong("at") > now) return@mapNotNull entry
            // Missed while off: a repeat moves to its next time; a one-off
            // stays overdue in the app rather than ringing late.
            AlarmArm.next(entry.getLong("at"), entry.getString("repeat"), now)
                ?.let { entry.put("at", it) }
        }
        store.save(kept)
        kept.forEach { AlarmArm.arm(context, it) }
    }
}
