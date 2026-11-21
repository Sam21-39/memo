package `in`.appamania.memo

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Share target for plain text. A trampoline: it stores the text, brings the
 * existing Memō task forward and finishes. The text is untrusted; Dart
 * sanitises it again and shows it for a tap, never saves it.
 */
class ShareActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
                val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()?.take(4000)
                if (!text.isNullOrBlank()) ShareStore(this).add(text)
            }
            packageManager.getLaunchIntentForPackage(packageName)?.let(::startActivity)
        } catch (e: Exception) {
            // A malformed share must never crash; fall through to finish.
        }
        finish()
    }
}

/** Shares waiting for Dart: [{id, text, at}], newest last, at most 20. */
class ShareStore(context: Context) {
    private val prefs = context.getSharedPreferences("memo_shares", Context.MODE_PRIVATE)

    private fun all(): List<JSONObject> {
        val array = JSONArray(prefs.getString("pending", "[]"))
        return (0 until array.length()).map { array.getJSONObject(it) }
    }

    private fun save(entries: List<JSONObject>) {
        prefs.edit().putString("pending", JSONArray(entries).toString()).apply()
    }

    fun add(text: String) {
        val entry = JSONObject()
            .put("id", UUID.randomUUID().toString())
            .put("text", text)
            .put("at", System.currentTimeMillis())
        synchronized(lock) { save((all() + entry).takeLast(20)) }
    }

    fun pending(): String = JSONArray(all()).toString()

    fun ack(id: String) = synchronized(lock) { save(all().filter { it.getString("id") != id }) }

    private companion object {
        // One lock for every instance: ShareActivity and MainActivity each make their own.
        val lock = Any()
    }
}
