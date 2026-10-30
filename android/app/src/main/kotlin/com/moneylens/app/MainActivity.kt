package com.moneylens.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val ocrThread = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Text recognition for slips: the path and the pass (how the image is
        // prepared, see SlipOcr) in, the recognised text out.
        // Errors carry only a code, never the text or the path.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "moneylens/ocr")
            .setMethodCallHandler { call, result ->
                if (call.method != "recognize") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("bad_arguments", null, null)
                    return@setMethodCallHandler
                }
                val pass = call.argument<Int>("pass") ?: 0
                ocrThread.execute {
                    try {
                        val text = SlipOcr.recognize(applicationContext, path, pass)
                        runOnUiThread { result.success(text) }
                    } catch (e: IllegalArgumentException) {
                        runOnUiThread { result.error("unreadable_image", null, null) }
                    } catch (e: Throwable) {
                        runOnUiThread { result.error("ocr_failed", null, null) }
                    }
                }
            }
    }

    override fun onDestroy() {
        ocrThread.shutdown()
        super.onDestroy()
    }
}
