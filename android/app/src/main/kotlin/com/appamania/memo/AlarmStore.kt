package com.appamania.memo

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * The alarm plan Dart computed, kept natively so boot and a ringing alarm
 * never need a Dart isolate. Also the queue of Done/Snooze taps made while
 * Dart was not running; Dart drains it on its next launch or resume.
 *
 * Entry: {id, at (epoch ms), repeat: none|daily|weekly, reminderId, title,
 * body, sound (path or null), snoozeId}.
 */
class AlarmStore(context: Context) {
    private val prefs = context.getSharedPreferences("memo_alarms", Context.MODE_PRIVATE)

    fun all(): List<JSONObject> {
        val array = JSONArray(prefs.getString("plan", "[]"))
        return (0 until array.length()).map { array.getJSONObject(it) }
    }

    fun get(id: Int): JSONObject? = all().firstOrNull { it.getInt("id") == id }

    fun save(entries: List<JSONObject>) {
        prefs.edit().putString("plan", JSONArray(entries).toString()).apply()
    }

    fun put(entry: JSONObject) =
        save(all().filter { it.getInt("id") != entry.getInt("id") } + entry)

    fun remove(id: Int) = save(all().filter { it.getInt("id") != id })

    fun appendAction(reminderId: String, action: String) {
        val queue = JSONArray(prefs.getString("actions", "[]"))
        queue.put(
            JSONObject()
                .put("reminderId", reminderId)
                .put("action", action)
                .put("at", System.currentTimeMillis()),
        )
        prefs.edit().putString("actions", queue.toString()).apply()
    }

    fun drainActions(): String {
        val queue = prefs.getString("actions", "[]")!!
        prefs.edit().remove("actions").apply()
        return queue
    }
}
