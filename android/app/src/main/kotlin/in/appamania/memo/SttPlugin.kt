package `in`.appamania.memo

import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.util.Locale

/**
 * `memo/stt`: transcribeFile(path) -> String. Feeds the recorded 16 kHz mono
 * WAV to the ON-DEVICE recogniser (Android 13+, EXTRA_AUDIO_SOURCE). Never
 * falls back to a network recogniser: no on-device model means "".
 */
class SttPlugin(private val context: Context, messenger: BinaryMessenger) {
    private val main = Handler(Looper.getMainLooper())

    init {
        MethodChannel(messenger, "memo/stt").setMethodCallHandler { call, result ->
            when (call.method) {
                "available" -> result.success(available())
                "transcribeFile" -> transcribe(call.argument<String>("path")!!) { result.success(it) }
                else -> result.notImplemented()
            }
        }
    }

    /** The phone's own English (en-IN, en-GB…) has the best chance of a pack. */
    private fun language(): String {
        val locale = Locale.getDefault()
        return if (locale.language == "en") locale.toLanguageTag() else "en-US"
    }

    private fun available() = Build.VERSION.SDK_INT >= 33 &&
        SpeechRecognizer.isOnDeviceRecognitionAvailable(context)

    private fun transcribe(path: String, done: (String) -> Unit) {
        val file = File(path)
        if (!available() || !file.exists()) return done("")
        var finished = false
        fun finish(text: String, recognizer: SpeechRecognizer?) {
            if (finished) return
            finished = true
            recognizer?.destroy()
            done(text)
        }

        val (read, write) = ParcelFileDescriptor.createPipe()
        // Stream the PCM after the WAV "data" chunk header into the pipe.
        Thread {
            ParcelFileDescriptor.AutoCloseOutputStream(write).use { out ->
                FileInputStream(file).use { input ->
                    input.skip(pcmOffset(file))
                    input.copyTo(out)
                }
            }
        }.start()

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
            .putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            .putExtra(RecognizerIntent.EXTRA_LANGUAGE, language())
            .putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            .putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            .putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE, read)
            // Segmented: keep listening across pauses until the file ends,
            // delivering each stretch of speech via onSegmentResults.
            .putExtra(RecognizerIntent.EXTRA_SEGMENTED_SESSION, RecognizerIntent.EXTRA_AUDIO_SOURCE)
            .putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_CHANNEL_COUNT, 1)
            .putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
            .putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_SAMPLING_RATE, 16000)
        val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
        // Speech splits into segments at pauses. Collect each finished one;
        // some engines only ever send partials, so a partial that no longer
        // extends the previous one also closes a segment.
        val segments = mutableListOf<String>()
        var lastPartial = ""
        fun text() = (segments + lastPartial).filter { it.isNotBlank() }.joinToString(" ")
        recognizer.setRecognitionListener(object : RecognitionListener {
            override fun onResults(results: Bundle) {
                val text = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    ?.firstOrNull().orEmpty()
                if (text.isNotBlank()) {
                    lastPartial = ""
                    segments += text
                }
                finish(text(), recognizer)
            }
            override fun onError(error: Int) {
                // No offline pack for this locale yet: ask Android to fetch it
                // (a model download; no audio leaves the phone). This clip
                // saves as "Voice note"; later ones get a title.
                if (error == SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE) {
                    SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
                        .triggerModelDownload(intent)
                }
                finish(text(), recognizer)
            }
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onPartialResults(partialResults: Bundle?) {
                val p = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    ?.firstOrNull()?.takeIf { it.isNotBlank() } ?: return
                val head = lastPartial.substringBefore(' ')
                if (lastPartial.isNotBlank() && !p.startsWith(head)) segments += lastPartial
                lastPartial = p
            }

            override fun onSegmentResults(segmentResults: Bundle) {
                segmentResults.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    ?.firstOrNull()?.takeIf { it.isNotBlank() }?.let {
                        segments += it
                        lastPartial = ""
                    }
            }

            override fun onEndOfSegmentedSession() = finish(text(), recognizer)
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
        recognizer.startListening(intent)
        main.postDelayed({ finish(text(), recognizer) }, 15_000)
    }

    /** Byte offset of PCM samples: after the "data" chunk id and its size. */
    private fun pcmOffset(file: File): Long {
        val head = file.inputStream().use { it.readNBytes(16_384) }
        for (i in 12 until head.size - 8) {
            if (head[i] == 'd'.code.toByte() && head[i + 1] == 'a'.code.toByte() &&
                head[i + 2] == 't'.code.toByte() && head[i + 3] == 'a'.code.toByte()
            ) return (i + 8).toLong()
        }
        return 44
    }
}
