package com.example.flowra.focus

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the Flutter focus coordinator to the native enforcement layer.
 *
 * Writes go into [FocusPolicyStore]; reads report permission state and open the relevant
 * system settings screens. All settings intents use FLAG_ACTIVITY_NEW_TASK because they're
 * launched from an application context.
 */
class FocusBlockerChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL).also {
        it.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(true)

            "isAccessibilityEnabled" ->
                result.success(FocusPolicyStore.isServiceEnabled(context))

            "openAccessibilitySettings" -> {
                startSettings(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                result.success(null)
            }

            "canDrawOverlays" -> result.success(canDrawOverlays())

            "openOverlaySettings" -> {
                val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${context.packageName}"),
                    )
                } else {
                    Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:${context.packageName}"),
                    )
                }
                startSettings(intent)
                result.success(null)
            }

            "updatePolicy" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val packages = call.argument<List<String>>("packages") ?: emptyList()
                val rawWindows =
                    call.argument<List<List<Number>>>("windows") ?: emptyList()
                val titles = call.argument<List<String>>("titles") ?: emptyList()
                val blockStyle =
                    call.argument<String>("blockStyle") ?: FocusPolicyStore.STYLE_HOME

                val windows = rawWindows.mapIndexedNotNull { i, pair ->
                    if (pair.size < 2) return@mapIndexedNotNull null
                    FocusWindow(
                        pair[0].toLong(),
                        pair[1].toLong(),
                        titles.getOrNull(i) ?: "",
                    )
                }

                FocusPolicyStore(context).write(enabled, packages, windows, blockStyle)
                result.success(null)
            }

            "clearPolicy" -> {
                FocusPolicyStore(context).clear()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun canDrawOverlays(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)

    private fun startSettings(intent: Intent) {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    companion object {
        const val CHANNEL = "flowra/focus_blocker"
    }
}
