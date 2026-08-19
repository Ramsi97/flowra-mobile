package com.example.flowra.focus

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent

/**
 * Watches which app comes to the foreground and, during an active focus window, blocks the
 * user-chosen apps.
 *
 * The service is intentionally self-sufficient: it reads everything from [FocusPolicyStore]
 * (a dedicated on-disk prefs file) so it keeps enforcing even after the Flutter engine and
 * the app's Activity have been destroyed. It never retrieves window content — only the
 * package name of the newly-focused window — matching the narrow accessibility declaration.
 */
class FocusAccessibilityService : AccessibilityService() {

    private lateinit var policy: FocusPolicyStore
    private lateinit var overlay: FocusOverlayController
    private lateinit var overlayStrategy: BlockStrategy
    private lateinit var homeStrategy: BlockStrategy

    private var homePackage: String? = null
    private var lastBlockedPkg: String? = null
    private var lastActionAt = 0L

    // Kept as a field so the weak listener registration isn't garbage-collected.
    private val policyListener =
        SharedPreferences.OnSharedPreferenceChangeListener { _, _ ->
            if (!policy.isEnabled()) overlay.hide()
        }

    override fun onServiceConnected() {
        super.onServiceConnected()
        policy = FocusPolicyStore(this)
        overlay = FocusOverlayController(this)
        overlay.onClose = { performGlobalAction(GLOBAL_ACTION_HOME) }
        homeStrategy = HomeBounceStrategy(this)
        overlayStrategy = OverlayBlockStrategy(this, overlay, homeStrategy)
        homePackage = resolveHomePackage()
        policy.registerListener(policyListener)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }
        val pkg = event.packageName?.toString() ?: return

        // Never touch ourselves, the system UI (status bar / shade / recents), or the
        // launcher — the last is also where a home-bounce lands, so blocking it would loop.
        if (pkg == packageName || pkg == SYSTEM_UI_PKG) return
        if (pkg == homePackage) {
            overlay.hide()
            return
        }

        if (!policy.isEnabled()) {
            overlay.hide()
            return
        }

        val window = policy.activeWindow(System.currentTimeMillis())
        if (window == null) {
            // Outside every focus block — make sure no stale lock lingers.
            overlay.hide()
            return
        }

        if (!policy.blockedPackages().contains(pkg)) {
            // An allowed app is now foreground; drop any lock we were showing.
            overlay.hide()
            return
        }

        // Throttle: window-state can fire several times for one launch.
        val elapsed = SystemClock.elapsedRealtime()
        if (pkg == lastBlockedPkg && elapsed - lastActionAt < BLOCK_THROTTLE_MS) return
        lastBlockedPkg = pkg
        lastActionAt = elapsed

        val strategy =
            if (policy.blockStyle() == FocusPolicyStore.STYLE_OVERLAY) overlayStrategy
            else homeStrategy
        strategy.block(this, pkg, window)
    }

    override fun onInterrupt() {
        // No ongoing feedback to interrupt.
    }

    override fun onUnbind(intent: Intent?): Boolean {
        overlay.hide()
        policy.unregisterListener(policyListener)
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        overlay.hide()
        super.onDestroy()
    }

    private fun resolveHomePackage(): String? {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val resolved = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return resolved?.activityInfo?.packageName
    }

    companion object {
        private const val SYSTEM_UI_PKG = "com.android.systemui"
        private const val BLOCK_THROTTLE_MS = 1000L
    }
}
