package com.example.flowra

import com.example.flowra.focus.FocusBlockerChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Wire the focus-blocker bridge. Use the application context so the channel
        // outlives this Activity for writing policy / opening settings.
        FocusBlockerChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }
}
