package com.moneylens.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.ExifInterface
import com.googlecode.tesseract.android.TessBaseAPI
import java.io.File
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Reads the text of a payment slip with Tesseract (Thai).
 *
 * The language data ships in `assets/tessdata` (tessdata_fast, Apache-2.0)
 * and is copied once to app-private storage, because Tesseract needs a real
 * directory. Nothing leaves the device.
 *
 * Tesseract's misreadings change with how the picture is prepared, so the
 * Dart side asks for several passes and compares them. Each [Prep] was
 * chosen on real slips: grey at two sizes, and the darkest colour channel,
 * which keeps coloured text (a green amount) dark on a light background.
 */
object SlipOcr {
    // Thai only. With English added the engine "helps" by writing Thai letters
    // as look-alike Latin ones ("พ.ค." became "W.A."), which broke dates.
    // Digits are part of the Thai model.
    private const val LANGUAGES = "tha"
    private val models = listOf("tha.traineddata")

    private enum class Channel { LUMINANCE, DARKEST }

    /** Scale to [longSide] on the longest side, or to [width] across. */
    private class Prep(val channel: Channel, val longSide: Int = 0, val width: Int = 0)

    private val passes = listOf(
        Prep(Channel.LUMINANCE, longSide = 1600),
        Prep(Channel.DARKEST, longSide = 2000),
        Prep(Channel.LUMINANCE, width = 1440),
    )

    private var engine: TessBaseAPI? = null

    @Synchronized
    fun recognize(context: Context, imagePath: String, pass: Int): String {
        val prep = passes.getOrNull(pass) ?: throw IllegalStateException("pass")
        val image = prepare(imagePath, prep) ?: throw IllegalArgumentException("unreadable")
        val api = engine(context)
        try {
            api.setImage(image.pixels, image.width, image.height, 1, image.width)
            return api.utF8Text ?: ""
        } finally {
            api.clear()
        }
    }

    /** Kept between passes and slips: loading the model is the slow part. */
    private fun engine(context: Context): TessBaseAPI {
        engine?.let { return it }
        val api = TessBaseAPI()
        if (!api.init(prepareModels(context).absolutePath, LANGUAGES)) {
            api.recycle()
            throw IllegalStateException("init")
        }
        api.pageSegMode = TessBaseAPI.PageSegMode.PSM_AUTO
        engine = api
        return api
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

    // ---------------------------------------------------------------- image

    /** 8-bit grey pixels, row by row. */
    private class Gray(val width: Int, val height: Int, val pixels: ByteArray)

    private fun prepare(path: String, prep: Prep): Gray? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        val rotation = rotationOf(path)
        // The size as shown, after the camera's rotation.
        val upright = rotation % 180 == 0
        val shownW = if (upright) bounds.outWidth else bounds.outHeight
        val shownH = if (upright) bounds.outHeight else bounds.outWidth
        val scale = if (prep.width > 0) {
            prep.width.toDouble() / shownW
        } else {
            prep.longSide.toDouble() / max(shownW, shownH)
        }
        val targetW = max(1, (shownW * scale).roundToInt())
        val targetH = max(1, (shownH * scale).roundToInt())

        // Decode large photos smaller, but never below the target size.
        var sample = 1
        while (shownW / (sample * 2) >= targetW && shownH / (sample * 2) >= targetH) {
            sample *= 2
        }
        val bitmap = BitmapFactory.decodeFile(
            path,
            BitmapFactory.Options().apply {
                inSampleSize = sample
                inPreferredConfig = Bitmap.Config.ARGB_8888
            },
        ) ?: return null
        var w = bitmap.width
        var h = bitmap.height
        var plane: IntArray
        try {
            val argb = IntArray(w * h)
            bitmap.getPixels(argb, 0, w, 0, 0, w, h)
            plane = toGray(argb, prep.channel)
        } finally {
            bitmap.recycle()
        }
        if (rotation != 0) {
            plane = rotate(plane, w, h, rotation)
            if (rotation % 180 != 0) w = h.also { h = w }
        }
        plane = resize(plane, w, h, targetW, targetH)
        stretchContrast(plane)
        return Gray(targetW, targetH, ByteArray(plane.size) { plane[it].toByte() })
    }

    private fun rotationOf(path: String): Int = try {
        when (
            ExifInterface(path).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )
        ) {
            ExifInterface.ORIENTATION_ROTATE_90 -> 90
            ExifInterface.ORIENTATION_ROTATE_180 -> 180
            ExifInterface.ORIENTATION_ROTATE_270 -> 270
            else -> 0
        }
    } catch (e: Exception) {
        0
    }

    private fun toGray(argb: IntArray, channel: Channel): IntArray = IntArray(argb.size) {
        val p = argb[it]
        val r = (p shr 16) and 0xFF
        val g = (p shr 8) and 0xFF
        val b = p and 0xFF
        when (channel) {
            // ITU-R 601 luma, as most image libraries compute grey.
            Channel.LUMINANCE -> (r * 19595 + g * 38470 + b * 7471 + 0x8000) shr 16
            Channel.DARKEST -> min(r, min(g, b))
        }
    }

    /** Clockwise rotation by [degrees] (90, 180 or 270). */
    private fun rotate(src: IntArray, w: Int, h: Int, degrees: Int): IntArray {
        val out = IntArray(src.size)
        for (y in 0 until h) {
            for (x in 0 until w) {
                val v = src[y * w + x]
                when (degrees) {
                    90 -> out[x * h + (h - 1 - y)] = v
                    180 -> out[(h - 1 - y) * w + (w - 1 - x)] = v
                    else -> out[(w - 1 - x) * h + y] = v
                }
            }
        }
        return out
    }

    /**
     * Bicubic resampling, widened when shrinking so every source pixel counts.
     * Android's own bitmap scaling is bilinear, which on real slips cost
     * Tesseract a date or two in twelve.
     */
    private fun resize(src: IntArray, sw: Int, sh: Int, dw: Int, dh: Int): IntArray {
        if (sw == dw && sh == dh) return src
        val across = taps(sw, dw)
        val tmp = FloatArray(dw * sh)
        for (y in 0 until sh) {
            val row = y * sw
            for (x in 0 until dw) {
                val start = across.start[x]
                val weights = across.weights[x]
                var sum = 0f
                for (k in weights.indices) sum += src[row + start + k] * weights[k]
                tmp[y * dw + x] = sum
            }
        }
        val down = taps(sh, dh)
        val out = IntArray(dw * dh)
        for (y in 0 until dh) {
            val start = down.start[y]
            val weights = down.weights[y]
            for (x in 0 until dw) {
                var sum = 0f
                for (k in weights.indices) sum += tmp[(start + k) * dw + x] * weights[k]
                out[y * dw + x] = sum.roundToInt().coerceIn(0, 255)
            }
        }
        return out
    }

    private class Taps(val start: IntArray, val weights: Array<FloatArray>)

    private fun taps(inSize: Int, outSize: Int): Taps {
        val scale = inSize.toDouble() / outSize
        val filterScale = max(scale, 1.0)
        val support = 2.0 * filterScale
        val start = IntArray(outSize)
        val weights = Array(outSize) { i ->
            val center = (i + 0.5) * scale
            val lo = max(0, (center - support + 0.5).toInt())
            val hi = min(inSize, (center + support + 0.5).toInt())
            start[i] = lo
            val w = DoubleArray(hi - lo) { cubic((lo + it - center + 0.5) / filterScale) }
            val total = w.sum()
            FloatArray(w.size) { (if (total != 0.0) w[it] / total else w[it]).toFloat() }
        }
        return Taps(start, weights)
    }

    private fun cubic(x: Double): Double {
        val a = -0.5
        val t = abs(x)
        return when {
            t < 1 -> ((a + 2) * t - (a + 3)) * t * t + 1
            t < 2 -> (((t - 5) * t + 8) * t - 4) * a
            else -> 0.0
        }
    }

    /** Spreads the grey levels over 0..255, ignoring the darkest and lightest 1%. */
    private fun stretchContrast(plane: IntArray) {
        val hist = IntArray(256)
        for (v in plane) hist[v]++
        var cut = plane.size / 100
        var lo = 0
        while (lo < 255 && cut >= hist[lo]) cut -= hist[lo++]
        cut = plane.size / 100
        var hi = 255
        while (hi > 0 && cut >= hist[hi]) cut -= hist[hi--]
        if (hi <= lo) return
        val scale = 255.0 / (hi - lo)
        for (i in plane.indices) {
            plane[i] = ((plane[i] - lo) * scale).toInt().coerceIn(0, 255)
        }
    }
}
