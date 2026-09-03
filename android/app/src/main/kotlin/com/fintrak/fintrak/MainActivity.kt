package com.fintrak.fintrak

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * FlutterFragmentActivity, not FlutterActivity: local_auth presents the system
 * biometric prompt as a fragment, and on a plain FlutterActivity it fails.
 */
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Keep balances out of the task switcher and out of screenshots.
        // Release only: with this on in debug you cannot capture screenshots
        // for the store listing or for a bug report.
        if (!BuildConfig.DEBUG) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }
    }
}
