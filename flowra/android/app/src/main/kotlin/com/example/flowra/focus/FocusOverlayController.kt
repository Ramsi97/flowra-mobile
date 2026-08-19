package com.example.flowra.focus

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.text.format.DateFormat
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import com.example.flowra.R
import java.util.Date

/**
 * Owns the full-screen "In Focus" lock view drawn on top of a blocked app.
 *
 * A single instance is created by [FocusAccessibilityService]; it adds/removes exactly one
 * [WindowManager] view. All calls are expected on the service's main thread (accessibility
 * callbacks already run there).
 */
class FocusOverlayController(private val context: Context) {

    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    private var view: View? = null

    /** Invoked when the user taps "Close" — the service wires this to GLOBAL_ACTION_HOME. */
    var onClose: (() -> Unit)? = null

    fun isShowing(): Boolean = view != null

    fun show(window: FocusWindow?) {
        if (view != null) return // already covering the screen

        val overlay = LayoutInflater.from(context).inflate(R.layout.focus_block_overlay, null)

        val title = overlay.findViewById<TextView>(R.id.focus_overlay_title)
        val subtitle = overlay.findViewById<TextView>(R.id.focus_overlay_subtitle)
        title.text = window?.title?.takeIf { it.isNotBlank() } ?: "Focus session"
        subtitle.text = if (window != null) "Until ${formatTime(window.endMs)}" else ""

        overlay.findViewById<Button>(R.id.focus_overlay_close).setOnClickListener {
            hide()
            onClose?.invoke()
        }

        // Swallow the Back key so it can't dismiss the lock straight back into the app.
        overlay.isFocusableInTouchMode = true
        overlay.setOnKeyListener { _, keyCode, _ -> keyCode == KeyEvent.KEYCODE_BACK }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            overlayType(),
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        )

        try {
            windowManager.addView(overlay, params)
            overlay.requestFocus()
            view = overlay
        } catch (e: Exception) {
            // Adding can fail if the overlay permission was revoked between the strategy's
            // check and here; treat as "not showing" so the caller's fallback still runs.
            view = null
        }
    }

    fun hide() {
        val current = view ?: return
        try {
            windowManager.removeView(current)
        } catch (e: Exception) {
            // Already detached — nothing to do.
        }
        view = null
    }

    @Suppress("DEPRECATION")
    private fun overlayType(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

    private fun formatTime(ms: Long): String =
        DateFormat.getTimeFormat(context).format(Date(ms))
}
