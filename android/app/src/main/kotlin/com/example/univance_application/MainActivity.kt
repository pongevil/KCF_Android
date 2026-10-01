package app.bsmobile.businessolution

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.MainlauncherSDK
import android.view.KeyEvent

class MainActivity: FlutterActivity() {
    private lateinit var sdkChannel: MethodChannel

      override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
          super.configureFlutterEngine(flutterEngine)
      sdkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sdk_function_channel")
          flutterEngine.plugins.add(MainlauncherSDK())
        }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
      if (::sdkChannel.isInitialized) {
        val actionName = when (event.action) {
          KeyEvent.ACTION_DOWN -> "down"
          KeyEvent.ACTION_UP -> "up"
          else -> "other"
        }

        sdkChannel.invokeMethod(
          "urovoonTriggerKey",
          mapOf(
            "keyCode" to event.keyCode,
            "action" to actionName,
            "repeatCount" to event.repeatCount,
          )
        )
      }

      return super.dispatchKeyEvent(event)
    }
}
