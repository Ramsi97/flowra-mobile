package com.example.flowra.focus

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.widget.Toast

/**
 * How a blocked app is actually stopped. Pluggable so the block style can change without
 * touching the detection logic in [FocusAccessibilityService].
 */
interface BlockStrategy {
    fun block(service: AccessibilityService, pkg: String, window: FocusWindow?)
}

/**
 * Minimal, permission-free block: bounce to the home screen and show a brief toast.
 * Always available, so it doubles as the fallback for [OverlayBlockStrategy].
 */
class HomeBounceStrategy(private val context: Context) : BlockStrategy {

    private var lastToastAt = 0L

    override fun block(service: AccessibilityService, pkg: String, window: FocusWindow?) {
        service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)

        val now = SystemClock.elapsedRealtime()
        if (now - lastToastAt > TOAST_THROTTLE_MS) {
            lastToastAt = now
            Toast.makeText(context, "Blocked during focus", Toast.LENGTH_SHORT).show()
        }
    }

    companion object {
        private const val TOAST_THROTTLE_MS = 2000L
    }
}

/**
 * Draws the full-screen Flowra lock over the blocked app. Requires the "display over other
 * apps" permission and API 26+ for [android.view.WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY];
 * when either is missing it transparently delegates to [fallback] (home-bounce).
 */
class OverlayBlockStrategy(
    private val context: Context,
    private val overlay: FocusOverlayController,
    private val fallback: BlockStrategy,
) : BlockStrategy {

    override fun block(service: AccessibilityService, pkg: String, window: FocusWindow?) {
        if (canOverlay()) {
            overlay.show(window)
            // show() clears its own view if addView failed; fall back in that case.
            if (!overlay.isShowing()) fallback.block(service, pkg, window)
        } else {
            fallback.block(service, pkg, window)
        }
    }

    private fun canOverlay(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && Settings.canDrawOverlays(context)
}
