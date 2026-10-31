package com.appamania.memo

import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showOverLockScreen(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        showOverLockScreen(intent)
    }

    /** Only the alarm route may appear over the lock screen. */
    private fun showOverLockScreen(intent: Intent?) {
        val alarm = intent?.data?.path?.startsWith("/alarm/") == true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(alarm)
            setTurnScreenOn(alarm)
        }
    }

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "memo/alarm").setMethodCallHandler { call, result ->
            val store = AlarmStore(this)
            when (call.method) {
                "schedule" -> {
                    val reminderId = call.argument<String>("reminderId")!!
                    store.all().filter { it.getString("reminderId") == reminderId }
                        .forEach { AlarmArm.cancel(this, it.getInt("id")) }
                    val fires = entries(call.argument<String>("fires")!!)
                    store.save(store.all().filter { it.getString("reminderId") != reminderId } + fires)
                    fires.forEach { AlarmArm.arm(this, it) }
                    result.success(null)
                }
                "cancel" -> {
                    val reminderId = call.argument<String>("reminderId")!!
                    val (gone, kept) = store.all().partition { it.getString("reminderId") == reminderId }
                    gone.forEach { AlarmArm.cancel(this, it.getInt("id")) }
                    store.save(kept)
                    result.success(null)
                }
                "replaceAll" -> {
                    store.all().forEach { AlarmArm.cancel(this, it.getInt("id")) }
                    val fires = entries(call.argument<String>("fires")!!)
                    store.save(fires)
                    fires.forEach { AlarmArm.arm(this, it) }
                    result.success(null)
                }
                "drainActions" -> result.success(store.drainActions())
                "ringing" -> result.success(AlarmService.ringing)
                "stopRinging" -> {
                    AlarmService.stop(this)
                    result.success(null)
                }
                "canUseFullScreenIntent" -> result.success(
                    Build.VERSION.SDK_INT < 34 ||
                        getSystemService(NotificationManager::class.java).canUseFullScreenIntent(),
                )
                "openFullScreenSettings" -> {
                    if (Build.VERSION.SDK_INT >= 34) {
                        startActivity(
                            Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, Uri.parse("package:$packageName")),
                        )
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun entries(json: String): List<JSONObject> {
        val array = JSONArray(json)
        return (0 until array.length()).map { array.getJSONObject(it) }
    }
}
