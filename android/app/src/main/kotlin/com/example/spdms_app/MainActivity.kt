package jjcet.PragatiX

import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pragatix/security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDebuggingEnabled" -> {
                    try {
                        val isUsbDebugging = isUsbDebuggingEnabled()
                        val isWirelessDebugging = isWirelessDebuggingEnabled()
                        val isDebugging = isUsbDebugging || isWirelessDebugging

                        val response = mapOf(
                            "isDebuggingEnabled" to isDebugging,
                            "isUsbDebuggingEnabled" to isUsbDebugging,
                            "isWirelessDebuggingEnabled" to isWirelessDebugging
                        )
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("SECURITY_CHECK_FAILED", e.localizedMessage, null)
                    }
                }
                "openDevelopmentSettings" -> {
                    try {
                        val opened = openDevelopmentSettings()
                        result.success(opened)
                    } catch (e: Exception) {
                        result.error("SETTINGS_OPEN_FAILED", e.localizedMessage, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Checks if USB Debugging (Android Debug Bridge via USB) is explicitly enabled.
     * Note: This does NOT check if Developer Options is on; only actual ADB debugging state.
     */
    private fun isUsbDebuggingEnabled(): Boolean {
        return try {
            val adbGlobal = Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED, 0)
            adbGlobal == 1
        } catch (e: Exception) {
            try {
                @Suppress("DEPRECATION")
                val adbSecure = Settings.Secure.getInt(contentResolver, Settings.Secure.ADB_ENABLED, 0)
                adbSecure == 1
            } catch (e2: Exception) {
                false
            }
        }
    }

    /**
     * Checks if Wireless Debugging (ADB over Wi-Fi) is enabled on Android 11+ (API 30+).
     */
    private fun isWirelessDebuggingEnabled(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val adbWifi = Settings.Global.getInt(contentResolver, "adb_wifi_enabled", 0)
                adbWifi == 1
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Opens Android Developer Options settings so the user can easily disable debugging.
     */
    private fun openDevelopmentSettings(): Boolean {
        return try {
            val devIntent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            if (devIntent.resolveActivity(packageManager) != null) {
                startActivity(devIntent)
                true
            } else {
                val generalIntent = Intent(Settings.ACTION_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(generalIntent)
                true
            }
        } catch (e: Exception) {
            try {
                val generalIntent = Intent(Settings.ACTION_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(generalIntent)
                true
            } catch (e2: Exception) {
                false
            }
        }
    }
}
