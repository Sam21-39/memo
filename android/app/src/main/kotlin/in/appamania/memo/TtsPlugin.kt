package `in`.appamania.memo

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale

/**
 * `memo/tts`, the app's own voice, offline only (network voices are never
 * used):
 * - render(text, gender, language, name) -> path|null: writes
 *   files/sounds/<name>.wav once (cached by name) via a temp file renamed into
 *   place; null when no offline voice speaks [language];
 * - preview(text, gender, language) -> Boolean: speaks now, for Settings;
 * - voices() -> languages among en/hi/bn with an offline voice;
 * - prune(prefix, keep): deletes a reminder's older renders, after its alarm
 *   was re-registered;
 * - forget(prefix): deletes a removed reminder's renders;
 * - openTtsSettings(): the system text-to-speech screen.
 */
class TtsPlugin(private val context: Context, messenger: BinaryMessenger) {
    private val dir = File(context.filesDir, "sounds").apply { mkdirs() }
    private val main = Handler(Looper.getMainLooper())
    private var tts: TextToSpeech? = null
    private var ready = false
    private val waiting = mutableListOf<() -> Unit>()

    init {
        // A kill mid-render leaves a partial temp file: never a sound.
        dir.listFiles { f -> f.name.endsWith(".tmp") }?.forEach { it.delete() }
        MethodChannel(messenger, "memo/tts").setMethodCallHandler { call, result ->
            val gender = call.argument<String>("gender") ?: "female"
            val language = call.argument<String>("language") ?: "en"
            when (call.method) {
                "render" -> {
                    val file = File(dir, "${call.argument<String>("name")}.wav")
                    if (file.exists() && file.length() > 0) return@setMethodCallHandler result.success(file.path)
                    render(call.argument<String>("text")!!, gender, language, file) { ok ->
                        result.success(if (ok) file.path else null)
                    }
                }
                "preview" -> withTts { engine ->
                    val ok = engine != null && pickVoice(engine, gender, language)
                    if (ok) engine!!.speak(call.argument<String>("text"), TextToSpeech.QUEUE_FLUSH, null, "preview")
                    result.success(ok)
                }
                "voices" -> withTts { engine ->
                    result.success(
                        if (engine == null) emptyList<String>()
                        else listOf("en", "hi", "bn").filter { candidates(engine, it).isNotEmpty() },
                    )
                }
                "prune" -> {
                    val prefix = call.argument<String>("prefix")!!
                    val keep = call.argument<String>("keep")
                    dir.listFiles { f ->
                        f.name.startsWith(prefix) && !f.name.endsWith(".tmp") && f.name != keep
                    }?.forEach { it.delete() }
                    result.success(null)
                }
                "openTtsSettings" -> {
                    try {
                        context.startActivity(
                            Intent("com.android.settings.TTS_SETTINGS").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                    } catch (_: Exception) {
                    }
                    result.success(null)
                }
                "forget" -> {
                    val prefix = call.argument<String>("prefix")!!
                    dir.listFiles { f -> f.name.startsWith(prefix) }?.forEach { it.delete() }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun withTts(action: (TextToSpeech?) -> Unit) {
        if (ready) return action(tts)
        waiting += { action(tts) }
        if (tts != null) return
        // Google's engine has named male and female offline voices; Samsung's
        // default engine reports none. Prefer Google's when installed.
        val google = "com.google.android.tts"
        val engine = if (isInstalled(google)) google else null
        tts = TextToSpeech(context, { status ->
            ready = true
            if (status != TextToSpeech.SUCCESS) tts = null
            waiting.toList().forEach { it() }
            waiting.clear()
        }, engine)
    }

    private fun isInstalled(pkg: String) = try {
        context.packageManager.getPackageInfo(pkg, 0)
        true
    } catch (_: Exception) {
        false
    }

    private fun render(text: String, gender: String, language: String, file: File, reply: (Boolean) -> Unit) {
        // Utterance callbacks arrive on a TTS thread; channel replies must not.
        var replied = false
        val tmp = File(file.path + ".tmp")
        val done = { ok: Boolean ->
            main.post {
                if (!replied) {
                    replied = true
                    reply(ok)
                }
            }
            Unit
        }
        // Written aside, renamed into place only once complete.
        val finish = { ok: Boolean ->
            val placed = ok && tmp.length() > 0 && tmp.renameTo(file)
            if (!placed) tmp.delete()
            done(placed)
        }
        withTts { engine ->
            if (engine == null || !pickVoice(engine, gender, language)) return@withTts done(false)
            val id = "memo-${System.nanoTime()}"
            // One listener for the engine's life: a render Dart gave up on still
            // cleans its temp file when the engine finishes it.
            finishers[id] = finish
            ensureListener(engine)
            file.parentFile?.mkdirs()
            tmp.delete()
            if (engine.synthesizeToFile(text, Bundle(), tmp, id) != TextToSpeech.SUCCESS) {
                finishers.remove(id)
                finish(false)
            }
        }
    }

    private val finishers = java.util.concurrent.ConcurrentHashMap<String, (Boolean) -> Unit>()
    private var listening = false

    private fun ensureListener(engine: TextToSpeech) {
        if (listening) return
        listening = true
        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {}
            override fun onDone(utteranceId: String?) { finishers.remove(utteranceId)?.invoke(true) }
            @Deprecated("Deprecated in Java")
            override fun onError(utteranceId: String?) { finishers.remove(utteranceId)?.invoke(false) }
            override fun onError(utteranceId: String?, errorCode: Int) {
                finishers.remove(utteranceId)?.invoke(false)
            }
        })
    }

    /** Offline, installed voices of [language], the phone's own country first, then India. */
    private fun candidates(engine: TextToSpeech, language: String): List<Voice> {
        val voices = try {
            engine.voices.orEmpty()
        } catch (_: Exception) {
            emptySet()
        }
        val local = Locale.getDefault()
        return voices.filter {
            (it.locale.language == language || it.locale.isO3Language == Locale(language).isO3Language) &&
                !it.isNetworkConnectionRequired &&
                !it.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED)
        }.sortedByDescending { (if (it.locale.country == local.country) 2 else 0) + (if (it.locale.country == "IN") 1 else 0) }
    }

    /**
     * Selects an offline voice for [language]; false when there is none (the
     * caller then does not speak: no cross-language reading). Android does not
     * expose a voice's gender, so known Google voice codes decide, best effort;
     * for English, if none match, the default voice is pitched up or down.
     * Hindi and Bengali take the first offline voice, unpitched.
     */
    private fun pickVoice(engine: TextToSpeech, gender: String, language: String): Boolean {
        val ranked = candidates(engine, language)
        if (ranked.isEmpty()) return false
        val male = gender == "male"
        val match = ranked.firstOrNull { voiceIsMale(it) == male }
        if (language != "en") {
            engine.voice = match ?: ranked.first()
            engine.setPitch(1f)
        } else if (match != null) {
            engine.voice = match
            engine.setPitch(1f)
        } else {
            engine.voice = ranked.first()
            engine.setPitch(if (male) 0.8f else 1.1f)
        }
        engine.setSpeechRate(0.95f)
        return true
    }

    private fun voiceIsMale(voice: Voice): Boolean? {
        val code = Regex("-x-([a-z]{3})").find(voice.name)?.groupValues?.get(1) ?: return null
        return when (code) {
            in MALE -> true
            in FEMALE -> false
            else -> null
        }
    }

    companion object {
        // Google speech services voice codes (en-US, en-GB, en-IN, en-AU).
        private val MALE = setOf("iol", "iom", "tpd", "gbb", "gbd", "rjs", "end", "ene", "aub", "aud")
        private val FEMALE = setOf(
            "iob", "iog", "tpc", "tpf", "sfg", "gba", "gbc", "gbg", "ahp", "cxx", "ena", "enc",
            "afh", "aua", "auc",
        )
    }
}
