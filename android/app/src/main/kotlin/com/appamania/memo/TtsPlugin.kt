package com.appamania.memo

import android.content.Context
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
 * - render(text, gender, name, prefix) -> path: writes files/sounds/<name>.wav
 *   once (cached by name) and deletes the reminder's older renders (prefix);
 * - preview(text, gender): speaks now, for Settings;
 * - forget(prefix): deletes a removed reminder's renders.
 */
class TtsPlugin(private val context: Context, messenger: BinaryMessenger) {
    private val dir = File(context.filesDir, "sounds").apply { mkdirs() }
    private val main = Handler(Looper.getMainLooper())
    private var tts: TextToSpeech? = null
    private var ready = false
    private val waiting = mutableListOf<() -> Unit>()

    init {
        MethodChannel(messenger, "memo/tts").setMethodCallHandler { call, result ->
            val gender = call.argument<String>("gender") ?: "female"
            when (call.method) {
                "render" -> {
                    val file = File(dir, "${call.argument<String>("name")}.wav")
                    val prefix = call.argument<String>("prefix")!!
                    dir.listFiles { f -> f.name.startsWith(prefix) && f != file }?.forEach { it.delete() }
                    if (file.exists() && file.length() > 0) return@setMethodCallHandler result.success(file.path)
                    render(call.argument<String>("text")!!, gender, file.path) { ok ->
                        result.success(if (ok) file.path else null)
                    }
                }
                "preview" -> withTts { engine ->
                    engine?.let {
                        pickVoice(it, gender)
                        it.speak(call.argument<String>("text"), TextToSpeech.QUEUE_FLUSH, null, "preview")
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

    private fun render(text: String, gender: String, path: String, reply: (Boolean) -> Unit) {
        // Utterance callbacks arrive on a TTS thread; channel replies must not.
        var replied = false
        val done = { ok: Boolean ->
            main.post {
                if (!replied) {
                    replied = true
                    reply(ok)
                }
            }
            Unit
        }
        withTts { engine ->
            if (engine == null) return@withTts done(false)
            pickVoice(engine, gender)
            val id = "memo-${System.nanoTime()}"
            engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {}
                override fun onDone(utteranceId: String?) { if (utteranceId == id) done(true) }
                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) { if (utteranceId == id) done(false) }
                override fun onError(utteranceId: String?, errorCode: Int) {
                    if (utteranceId == id) done(false)
                }
            })
            File(path).parentFile?.mkdirs()
            if (engine.synthesizeToFile(text, Bundle(), File(path), id) != TextToSpeech.SUCCESS) done(false)
        }
    }

    /**
     * An offline English voice of the asked gender. Android does not expose a
     * voice's gender, so known Google voice codes decide; if none match, the
     * default voice is pitched up or down.
     */
    private fun pickVoice(engine: TextToSpeech, gender: String) {
        val male = gender == "male"
        val english = engine.voices.orEmpty().filter {
            it.locale.language == "en" && !it.isNetworkConnectionRequired &&
                !it.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED)
        }
        val local = Locale.getDefault()
        val ranked = english.sortedByDescending { (if (it.locale.country == local.country) 2 else 0) + (if (it.locale.country == "US") 1 else 0) }
        val match = ranked.firstOrNull { voiceIsMale(it) == male }
        if (match != null) {
            engine.voice = match
            engine.setPitch(1f)
        } else {
            ranked.firstOrNull()?.let { engine.voice = it }
            engine.setPitch(if (male) 0.8f else 1.1f)
        }
        engine.setSpeechRate(0.95f)
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
