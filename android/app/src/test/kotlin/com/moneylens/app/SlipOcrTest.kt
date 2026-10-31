package com.moneylens.app

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** The pixel helpers behind the OCR passes; they need no device or engine. */
class SlipOcrTest {
    // 3 wide, 2 high:
    //   1 2 3
    //   4 5 6
    private val grid = intArrayOf(1, 2, 3, 4, 5, 6)

    @Test
    fun rotate90TurnsClockwise() {
        assertArrayEquals(intArrayOf(4, 1, 5, 2, 6, 3), SlipOcr.rotate(grid, 3, 2, 90))
    }

    @Test
    fun rotate180ReversesThePixels() {
        assertArrayEquals(intArrayOf(6, 5, 4, 3, 2, 1), SlipOcr.rotate(grid, 3, 2, 180))
    }

    @Test
    fun rotate270TurnsAnticlockwise() {
        assertArrayEquals(intArrayOf(3, 6, 2, 5, 1, 4), SlipOcr.rotate(grid, 3, 2, 270))
    }

    @Test
    fun fourQuarterTurnsGiveTheOriginal() {
        var pixels = grid
        var w = 3
        var h = 2
        repeat(4) {
            pixels = SlipOcr.rotate(pixels, w, h, 90)
            w = h.also { h = w }
        }
        assertArrayEquals(grid, pixels)
    }

    @Test
    fun greyOfPureColoursUsesLumaOrDarkestChannel() {
        val green = 0xFF00C800.toInt()
        val white = 0xFFFFFFFF.toInt()
        val luma = SlipOcr.toGray(intArrayOf(green, white), SlipOcr.Channel.LUMINANCE)
        assertEquals(255, luma[1])
        assertEquals((200 * 38470 + 0x8000) shr 16, luma[0])
        // Coloured text stays dark in the darkest channel.
        val darkest = SlipOcr.toGray(intArrayOf(green, white), SlipOcr.Channel.DARKEST)
        assertEquals(0, darkest[0])
        assertEquals(255, darkest[1])
    }

    @Test
    fun resizeToTheSameSizeReturnsThePixelsUntouched() {
        assertArrayEquals(grid, SlipOcr.resize(grid, 3, 2, 3, 2))
    }

    @Test
    fun resizeKeepsAFlatImageFlatAndInRange() {
        val flat = IntArray(8 * 8) { 200 }
        val up = SlipOcr.resize(flat, 8, 8, 20, 12)
        assertEquals(20 * 12, up.size)
        assertTrue(up.all { it == 200 })
        val down = SlipOcr.resize(flat, 8, 8, 3, 5)
        assertEquals(3 * 5, down.size)
        assertTrue(down.all { it == 200 })
    }

    @Test
    fun resizeNeverLeavesTheGreyRange() {
        val edge = IntArray(10 * 10) { if (it % 10 < 5) 0 else 255 }
        val out = SlipOcr.resize(edge, 10, 10, 23, 17)
        assertTrue(out.all { it in 0..255 })
    }

    @Test
    fun stretchContrastSpreadsANarrowRangeToFull() {
        val plane = IntArray(200) { 100 + it % 50 }
        SlipOcr.stretchContrast(plane)
        assertEquals(0, plane.min())
        assertEquals(255, plane.max())
    }

    @Test
    fun stretchContrastLeavesAFlatPlaneAlone() {
        val plane = IntArray(100) { 128 }
        SlipOcr.stretchContrast(plane)
        assertTrue(plane.all { it == 128 })
    }
}
