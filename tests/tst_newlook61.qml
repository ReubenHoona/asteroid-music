/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtTest
import org.asteroid.controls
import Amber.Mpris
import "../src" as M
import "../src/media.js" as Media

// N61-51: Media Controls in the Wear OS 6 look (emulator screenshot S33,
// nothing playing) on the 384 px screen, 2 px per dp: the button group
// centred on the screen, a 64 dp play disc (S33: 128 px, x and y 128-255),
// outlined skip glyphs, the output pill at y 288-351 with the struck phone
// and speaker glyph, 'Nothing playing' from y 72, the time digit top at y 10.
// N61-55: the launcher icon in the emulator's colours, a #F5F0E5 disc with a
// #1D1C15 glyph.
//
// Run with qmltestrunner -import tests/mocks (the Amber.Mpris double), the
// org.asteroid.controls of qml-asteroid newlook-61 (c88dfea or later:
// Application.timeTextMargin), the Material Symbols of asteroid-icons-ion
// newlook-61 (c90a176 or later: ms-skip_previous, ms-skip_next,
// ms-media_output_off) in the icon folder, the app's English catalog
// (-translation, made with lrelease -idbased) and QML_XHR_ALLOW_FILE_READ=1.
TestCase {
    id: tc
    name: "NewLook61"
    when: windowShown
    visible: true
    width: 384
    height: 384

    function near(a, b, tol, msg) {
        verify(Math.abs(a - b) <= tol, msg + ": " + a + " != " + b + " (tol " + tol + ")")
    }
    function lum(img, x, y) {
        var c = img.pixel(x, y)
        return Math.max(c.r, c.g, c.b) * 255
    }
    function nearRgb(img, x, y, hex, tol, msg) {
        var c = img.pixel(x, y), e = Qt.color(hex)
        verify(Math.abs(c.r - e.r) * 255 <= tol && Math.abs(c.g - e.g) * 255 <= tol
               && Math.abs(c.b - e.b) * 255 <= tol, msg + ": " + c + " != " + hex)
    }
    // the first and last row with a pixel brighter than t in [x0, x1) x [y0, y1)
    function litRows(img, x0, x1, y0, y1, t) {
        var first = -1, last = -1
        for (var y = y0; y < y1; y++) {
            for (var x = x0; x < x1; x++) {
                if (lum(img, x, y) > t) {
                    if (first < 0) first = y
                    last = y
                    break
                }
            }
        }
        return [first, last]
    }
    // the first and last column with a pixel brighter than t
    function litCols(img, x0, x1, y0, y1, t) {
        var first = -1, last = -1
        for (var x = x0; x < x1; x++) {
            for (var y = y0; y < y1; y++) {
                if (lum(img, x, y) > t) {
                    if (first < 0) first = x
                    last = x
                    break
                }
            }
        }
        return [first, last]
    }
    // the first item under `it` whose `name` is an icon name
    function iconIn(it) {
        for (var i = 0; i < it.children.length; i++) {
            var c = it.children[i]
            if (typeof c.name === "string" && c.name.indexOf("ms-") === 0)
                return c
            var d = iconIn(c)
            if (d)
                return d
        }
        return null
    }

    Component { id: playerC; M.PlayerPage { width: 384; height: 384 } }
    Component { id: blackC; Rectangle { width: 384; height: 384; color: "black" } }

    function test_1_constants() {
        compare(Theme.dp(1), 2, "2 px per dp")
        compare(Media.TOP_H, 64, "top box 64 dp (CP3A 68)")
        compare(Media.MID_H, 64, "middle box 64 dp")
        compare(Media.BOTTOM_H, 64, "bottom box: the rest of the screen")
        compare(Media.TOP_H + Media.MID_H + Media.BOTTOM_H, 192, "the boxes fill the screen")
        compare(Media.TOP_H + Media.MID_H / 2, 96, "the group centred on the screen")
        compare(Media.PLAY_SLOT, 64, "play slot 64 dp")
        compare(Media.PLAY_SHAPE, 64, "play disc 64 dp (S33 128 px; CP3A 60)")
        compare(2 * Media.SCALLOP_OUTER, Media.PLAY_SHAPE, "the circle is the shape")
        compare(Media.SCALLOP_INNER / Media.SCALLOP_OUTER, 0.8, "scallop inner radius 0.8")
        compare(Media.RING_INNER / Media.PLAY_SHAPE, 0.8, "filled shape 0.8 while the ring shows")
        compare(Media.BOTTOM_TOP, 16, "output pill 16 dp into the bottom box (CP3A 3)")
        compare(Media.PILL_W, 40); compare(Media.PILL_H, 48)
        compare(Media.OUT_PILL_W, 44); compare(Media.OUT_PILL_H, 32)
    }

    function test_2_geometry() {
        var p = createTemporaryObject(playerC, tc, { kind: "nothing" })
        var b = p.playButton
        compare(b.x, 128, "play slot x 128")
        compare(b.y, 128, "play slot y 128")
        compare(b.width, 128, "play slot 128 px")
        compare(b.fillScale, 1, "no ring, full disc")
        near(b.half - b.fillPoints[0].y, 64, 0.01, "disc radius 64 px")
        compare(p.displayTop, 48, "the status box 8 px higher (CP3A 56)")
        compare(p.previousButton.y, 144, "side pills from y 144")
        compare(p.previousButton.height, 96, "side pills 96 px")
        compare(p.nextButton.y, 144)
        compare(p.outputRow.y + p.outputRow.outputPill.y, 288, "output pill from y 288")
        compare(p.outputRow.outputPill.height, 64, "output pill 64 px")
        compare(p.previousButton.iconName, "ms-skip_previous", "outlined previous (FILL 0)")
        compare(p.nextButton.iconName, "ms-skip_next", "outlined next (FILL 0)")
        var ic = iconIn(p.outputRow.outputPill)
        verify(ic !== null, "the output pill has an icon")
        compare(ic.name, "ms-media_output_off", "no output: struck phone and speaker")
        p.kind = "media"
        compare(ic.name, "ms-smartphone", "with media: the phone")
    }

    function test_3_pixels() {
        var bg = createTemporaryObject(blackC, tc)
        var p = playerC.createObject(bg, { kind: "nothing" })
        compare(p.statusLabel.text, "Nothing playing", "the English catalog is loaded")
        wait(100)
        var img = grabImage(bg)
        // the play disc (#252526 with the #6F6F72 triangle)
        var r = litRows(img, 190, 194, 112, 270, 20)
        near(r[0], 128, 2, "disc top")
        near(r[1], 255, 2, "disc bottom")
        var c = litCols(img, 112, 272, 190, 194, 20)
        near(c[0], 130, 2, "disc left")
        near(c[1], 254, 2, "disc right")
        nearRgb(img, 150, 192, "#252526", 3, "disc fill")
        // the side pills
        r = litRows(img, 66, 69, 112, 270, 20)
        near(r[0], 144, 2, "previous pill top")
        near(r[1], 239, 2, "previous pill bottom")
        r = litRows(img, 315, 318, 112, 270, 20)
        near(r[0], 144, 2, "next pill top")
        near(r[1], 239, 2, "next pill bottom")
        // outlined skip glyphs: the triangle's inside is the pill, its outline the glyph
        nearRgb(img, 76, 192, "#252526", 3, "previous triangle inside")
        nearRgb(img, 306, 192, "#252526", 3, "next triangle inside")
        verify(lum(img, 83, 192) > 80, "previous triangle outline")
        verify(lum(img, 301, 192) > 80, "next triangle outline")
        // the output pill and its glyph (S33: glyph x 170-211, y 300-341)
        r = litRows(img, 190, 194, 262, 384, 20)
        near(r[0], 288, 2, "output pill top")
        near(r[1], 351, 2, "output pill bottom")
        r = litRows(img, 150, 234, 290, 350, 60)
        c = litCols(img, 150, 234, 290, 350, 60)
        near(r[0], 300, 2, "output glyph top"); near(r[1], 341, 2, "output glyph bottom")
        near(c[0], 170, 2, "output glyph left"); near(c[1], 211, 2, "output glyph right")
        // 'Nothing playing'
        r = litRows(img, 40, 344, 40, 125, 100)
        near(r[0], 72, 2, "text top")
    }

    function test_4_main() {
        var comp = Qt.createComponent("../src/main.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var app = comp.createObject(tc, { width: 384, height: 384 })
        compare(app.timeTextMargin, 2, "time text 1 dp from the edge")
        wait(2300)
        compare(app.shown.kind, "nothing", "nothing playing after 2 s")
        var img = grabImage(app)
        var t = litRows(img, 120, 264, 0, 60, 100)
        near(t[0], 10, 1, "time digit top")
        var s = litRows(img, 40, 344, 60, 125, 100)
        near(s[0], 72, 2, "text top")
        app.destroy()
    }

    function test_5_launcherIcon() {
        var x = new XMLHttpRequest()
        x.open("GET", Qt.resolvedUrl("../asteroid-music.desktop.template"), false)
        x.send()
        var t = x.responseText
        verify(t.indexOf("Icon=ios-musical-notes-outline\n") >= 0, "the same glyph")
        verify(t.indexOf("X-Asteroid-Center-Color=#F5F0E5\n") >= 0, "disc #F5F0E5 (emulator; CP3A white)")
        verify(t.indexOf("X-Eos-Glyph-Color=#1D1C15\n") >= 0, "glyph #1D1C15 (emulator; CP3A #3186FF)")
        verify(t.indexOf("X-Eos-Own-Icon") < 0, "a glyph on a disc, not an own icon")
    }
}
