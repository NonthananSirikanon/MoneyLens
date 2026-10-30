package com.moneylens.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.googlecode.tesseract.android.TessBaseAPI
import java.io.File

/**
 * Reads the text of a payment slip with Tesseract (Thai).
 *
 * The language data ships in `assets/tessdata` (tessdata_fast, Apache-2.0)
 * and is copied once to app-private storage, because Tesseract needs a real
 * directory. Nothing leaves the device.
 */
object SlipOcr {
    // Thai only. With English added the engine "helps" by writing Thai letters
    // as look-alike Latin ones ("พ.ค." became "W.A."), which broke dates.
    // Digits are part of the Thai model.
    private const val LANGUAGES = "tha"
    private val models = listOf("tha.traineddata")

    /** Longest side the image is scaled to: small text needs enough pixels. */
    private const val TARGET_LONG_SIDE = 2400

    @Synchronized
    fun recognize(context: Context, imagePath: String): String {
        val dataDir = prepareModels(context)
        val bitmap = decode(imagePath) ?: throw IllegalArgumentException("unreadable")
        val api = TessBaseAPI()
        try {
            if (!api.init(dataDir.absolutePath, LANGUAGES)) {
                throw IllegalStateException("init")
            }
            api.pageSegMode = TessBaseAPI.PageSegMode.PSM_AUTO
            api.setImage(bitmap)
            return api.utF8Text ?: ""
        } finally {
            api.recycle()
            bitmap.recycle()
        }
    }

    /** `<files>/` containing `tessdata/<lang>.traineddata`. */
    private fun prepareModels(context: Context): File {
        val root = context.filesDir
        val tessdata = File(root, "tessdata").apply { mkdirs() }
        for (name in models) {
            val target = File(tessdata, name)
            if (target.exists() && target.length() > 0) continue
            context.assets.open("tessdata/$name").use { input ->
                target.outputStream().use { input.copyTo(it) }
            }
        }
        return root
    }

    private fun decode(path: String): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        // Decode at most about twice the target, then scale to the target.
        var sample = 1
        val longSide = maxOf(bounds.outWidth, bounds.outHeight)
        while (longSide / (sample * 2) >= TARGET_LONG_SIDE) sample *= 2
        val decoded = BitmapFactory.decodeFile(
            path,
            BitmapFactory.Options().apply { inSampleSize = sample },
        ) ?: return null
        val side = maxOf(decoded.width, decoded.height)
        if (side >= TARGET_LONG_SIDE) return decoded
        // Slips saved as small screenshots read better when enlarged.
        val scale = minOf(2.0f, TARGET_LONG_SIDE.toFloat() / side)
        val scaled = Bitmap.createScaledBitmap(
            decoded,
            (decoded.width * scale).toInt(),
            (decoded.height * scale).toInt(),
            true,
        )
        if (scaled !== decoded) decoded.recycle()
        return scaled
    }
}
