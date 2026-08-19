package com.example.flowra.focus

import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.provider.Settings
import android.text.TextUtils
import org.json.JSONArray

/**
 * One focus block, as absolute epoch milliseconds. [title] is shown on the lock overlay.
 */
data class FocusWindow(val startMs: Long, val endMs: Long, val title: String)

/**
 * Reads/writes the **dedicated** native SharedPreferences file that the
 * [FocusAccessibilityService] relies on.
 *
 * This is deliberately separate from Flutter's own shared_preferences file: the service
 * keeps running after the Flutter engine (and even the whole app process' Activity) is
 * gone, so it must source everything it needs from a store it fully controls. The Flutter
 * side writes here only via [FocusBlockerChannel.updatePolicy] / [clear].
 */
class FocusPolicyStore(context: Context) {

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun isEnabled(): Boolean = prefs.getBoolean(KEY_ENABLED, false)

    fun blockedPackages(): Set<String> =
        prefs.getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()

    fun blockStyle(): String = prefs.getString(KEY_BLOCK_STYLE, STYLE_HOME) ?: STYLE_HOME

    /** All configured focus windows (may be empty / stale — the service decides relevance). */
    fun windows(): List<FocusWindow> {
        val raw = prefs.getString(KEY_WINDOWS, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONArray(i)
                FocusWindow(o.getLong(0), o.getLong(1), o.optString(2, ""))
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    /** The window containing [nowMs], or null if we're outside every focus block. */
    fun activeWindow(nowMs: Long): FocusWindow? =
        windows().firstOrNull { nowMs in it.startMs..it.endMs }

    fun write(
        enabled: Boolean,
        packages: List<String>,
        windows: List<FocusWindow>,
        blockStyle: String,
    ) {
        val arr = JSONArray()
        for (w in windows) {
            val entry = JSONArray()
            entry.put(w.startMs)
            entry.put(w.endMs)
            entry.put(w.title)
            arr.put(entry)
        }
        prefs.edit()
            .putBoolean(KEY_ENABLED, enabled)
            .putStringSet(KEY_PACKAGES, packages.toSet())
            .putString(KEY_WINDOWS, arr.toString())
            .putString(KEY_BLOCK_STYLE, blockStyle)
            .apply()
    }

    fun clear() {
        prefs.edit().clear().apply()
    }

    fun registerListener(listener: SharedPreferences.OnSharedPreferenceChangeListener) {
        prefs.registerOnSharedPreferenceChangeListener(listener)
    }

    fun unregisterListener(listener: SharedPreferences.OnSharedPreferenceChangeListener) {
        prefs.unregisterOnSharedPreferenceChangeListener(listener)
    }

    companion object {
        const val PREFS_NAME = "flowra_focus_policy"

        const val KEY_ENABLED = "enabled"
        const val KEY_PACKAGES = "packages"
        const val KEY_WINDOWS = "windows"
        const val KEY_BLOCK_STYLE = "blockStyle"

        const val STYLE_OVERLAY = "overlay"
        const val STYLE_HOME = "home"

        /**
         * True if our accessibility service is currently enabled by the user.
         *
         * We parse [Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES] directly rather than
         * relying on any in-process flag, because the source of truth lives in system
         * settings and the user can revoke it at any time from outside the app.
         */
        fun isServiceEnabled(context: Context): Boolean {
            val expected =
                ComponentName(context, FocusAccessibilityService::class.java).flattenToString()
            val enabled = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
            ) ?: return false

            val splitter = TextUtils.SimpleStringSplitter(':')
            splitter.setString(enabled)
            for (component in splitter) {
                if (component.equals(expected, ignoreCase = true)) return true
            }
            return false
        }
    }
}
