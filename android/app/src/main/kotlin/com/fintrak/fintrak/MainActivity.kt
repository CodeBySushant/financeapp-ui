package com.fintrak.fintrak

import android.content.pm.ApplicationInfo
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
        //
        // Release builds only: with FLAG_SECURE on in debug you cannot capture
        // a screenshot for the store listing or for a bug report.
        //
        // Read from the merged manifest rather than BuildConfig.DEBUG. Android
        // Gradle Plugin 8 stopped generating BuildConfig unless a module opts
        // in, so referencing it here would mean editing build.gradle.kts as
        // well. This flag is set by the build type and needs no such opt-in.
        val debuggable =
            (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

        if (!debuggable) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }
    }
}
