package com.drip.drip

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Themed launcher icon: each theme has an <activity-alias> in the
        // manifest (".Alias_<id>"). Exactly one is enabled at a time.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "drip/app_icon")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setIcon" -> {
                        val id = call.argument<String>("id")
                        val all = call.argument<List<String>>("all")
                        if (id == null || all == null || !all.contains(id)) {
                            result.error("bad_args", "unknown icon id", null)
                            return@setMethodCallHandler
                        }
                        try {
                            setLauncherAlias(id, all)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setLauncherAlias(id: String, all: List<String>) {
        val pm = packageManager
        fun component(name: String) = ComponentName(packageName, "$packageName.Alias_$name")

        // Enable the new alias first, then disable the rest, so there is never
        // a moment with no launcher entry. DONT_KILL_APP keeps the app open.
        val target = component(id)
        if (pm.getComponentEnabledSetting(target) != PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
            pm.setComponentEnabledSetting(
                target,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
        for (other in all) {
            if (other == id) continue
            val c = component(other)
            val state = pm.getComponentEnabledSetting(c)
            // "default" state means the manifest's android:enabled applies:
            // only the default theme's alias is enabled there.
            val enabledNow = state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                (state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && other == "retro_cyber")
            if (enabledNow) {
                pm.setComponentEnabledSetting(
                    c,
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP,
                )
            }
        }
    }
}
