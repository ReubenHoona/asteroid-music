/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtTest
import org.asteroid.controls
import Nemo.DBus
import "../src/media.js" as Media

// D-25 (media-controls-11): the phone's artwork behind the player at 60 %, under the radial gradient (clear to
// 65 % of the radius, the background at the edge), cross-faded in; the colour scheme seeded from its colour
// (tonal spot) on every role while it is shown, the system's colours without it; a change that comes while the
// screen is off is taken over when it comes back on, at once. btsyncd's org.asteroidos.btsyncd.Media is the
// D-Bus double of tests/mocks (DBusMock). The picture is tests/fixtures/art.png (an invented gradient with a
// disc); the track is invented.
TestCase {
    id: tc
    name: "ArtScheme"
    when: windowShown
    visible: true
    width: 384
    height: 384

    readonly property string mediaIface: "org.asteroidos.btsyncd.Media"
    readonly property string artFile: String(Qt.resolvedUrl("fixtures/art.png")).replace(/^file:\/\//, "")
    property var app: null

    function init() {
        DBusMock.reset()
    }

    function cleanup() {
        if (app)
            app.destroy()
        app = null
        Theme._colorSourceValue = "static"
        Theme._colorSeedValue = ""
        Theme.applyColorTheme(true)
        wait(30)
    }

    function start(playing) {
        var comp = Qt.createComponent("../src/main.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        app = comp.createObject(tc, { width: 384, height: 384 })
        app.interactive = true
        app.linkUp = true
        app.mpris.currentService = "org.mpris.MediaPlayer2.test"
        app.mpris.metaData = { title: "Invented Track", contributingArtist: ["Sample Artist"] }
        app.mpris.playbackStatus = playing ? 0 : 1
        wait(50)
        return app
    }

    function background() {
        return findChild(app, "artBackground")
    }

    function sameColor(a, b, msg) {
        var x = Qt.color(a), y = Qt.color(b)
        verify(Math.abs(x.r - y.r) < 0.004 && Math.abs(x.g - y.g) < 0.004 && Math.abs(x.b - y.b) < 0.004,
               msg + ": " + x + " != " + y)
    }

    function lum(img, x, y) {
        var c = img.pixel(x, y)
        return Math.max(c.r, c.g, c.b) * 255
    }

    function test_1_constants() {
        compare(Media.ART_OPACITY, 0.6, "artwork at 60 % (MS/gva.java:88-123)")
        compare(Media.ART_CLEAR, 0.65, "clear to 65 % of the radius (MS/hmv.java:40-44)")
        compare(Media.ART_SCHEME_STYLE, 1, "tonal spot (MS/gts.java, MS/iid.java)")
        compare(Media.artSeed("3366cc"), "#3366CC")
        compare(Media.artSeed("#A0B1C2"), "#A0B1C2")
        compare(Media.artSeed(""), "")
        compare(Media.artSeed("12345"), "")
        compare(Media.artSeed("red"), "")
        compare(Media.artSeed(undefined), "")
    }

    function test_2_noArtwork() {
        start(true)
        var bg = background()
        verify(bg !== null)
        compare(app.artThemed, false, "no colour: the system's roles")
        sameColor(Theme.color.primary, Theme.staticPalette.primary, "primary as the system's")
        compare(bg.shown, false, "no picture")
        verify(DBusMock.callsTo("ArtPath").length === 1, "the picture asked for once at start")
        var img = grabImage(app)
        verify(lum(img, 192, 272) < 8, "black under the controls: " + lum(img, 192, 272))
    }

    function test_3_artworkAtStart() {
        DBusMock.reply(mediaIface, "ArtPath", artFile)
        DBusMock.reply(mediaIface, "ArtColor", "3366CC")
        start(true)
        tryCompare(app, "shownArtColor", "#3366CC", 2000)
        compare(app.shownArtPath, artFile)
        verify(app.artThemed, "the artwork's colours")
        var g = PaletteGenerator.generate("#3366CC", "", 1)
        var roles = ["primary", "primaryDim", "primaryContainer", "onPrimary", "onPrimaryContainer", "secondary",
                     "tertiary", "surfaceContainer", "onSurface", "onSurfaceVariant", "outline", "background"]
        for (var i = 0; i < roles.length; i++)
            sameColor(Theme.color[roles[i]], g[roles[i]], roles[i] + " from the artwork's colour")
        verify(String(Theme.color.primary) !== String(Qt.color(Theme.staticPalette.primary)), "not the system's primary")
        var bg = background()
        tryCompare(bg, "shown", true, 2000)
        compare(String(bg.frontImage.source), "file://" + artFile)
        compare(bg.frontImage.fillMode, Image.PreserveAspectCrop, "cropped to the screen")
        tryVerify(function () { return !bg.fade.running }, 3000)
        compare(bg.frontImage.opacity, 0.6, "60 % opacity")
        compare(bg.backImage.opacity, 0, "the other slot hidden")
        // the radial gradient: clear to 65 % of the half width, the background at the edge
        var grad = bg.vignette.data[0].fillGradient
        compare(grad.centerRadius, 192, "radius: half the screen")
        compare(grad.centerX, 192); compare(grad.centerY, 192)
        compare(grad.stops.length, 3)
        compare(grad.stops[1].position, 0.65)
        compare(grad.stops[1].color.a, 0, "clear at 65 %")
        sameColor(grad.stops[2].color, Theme.color.background, "the background at the edge")
        compare(grad.stops[2].color.a, 1)
        wait(100)
        var img = grabImage(app)
        // inside 65 % (78 px from the centre): the artwork at 60 %, blue-green, not black, not full
        var c = img.pixel(192, 272)
        verify(lum(img, 192, 272) > 40 && lum(img, 192, 272) < 170, "the artwork at 60 %: " + c)
        verify(c.b > c.r, "the blue-green artwork: " + c)
        // at 99 % of the radius: the background
        var e = img.pixel(2, 192), bgc = Qt.color(Theme.color.background)
        verify(Math.abs(e.r - bgc.r) * 255 < 12 && Math.abs(e.g - bgc.g) * 255 < 12 && Math.abs(e.b - bgc.b) * 255 < 12,
               "the background at the edge: " + e + " (" + bgc + ")")
        // between: darker than inside (16 px from the edge, 92 % of the radius; 72 px from the centre, 38 %)
        verify(lum(img, 16, 192) < lum(img, 118, 192), "darker towards the edge")
        img.save("shots/art-player.png")
    }

    function test_4_changesFadeAndClear() {
        start(true)
        var bg = background()
        DBusMock.emit(mediaIface, "ArtChanged", [artFile, "AA3344"])
        compare(app.shownArtColor, "#AA3344", "taken over at once while shown")
        sameColor(Theme.color.primary, PaletteGenerator.generate("#AA3344", "", 1).primary, "the new colour's primary")
        verify(bg.fade.running, "the artwork fades in")
        verify(bg.frontImage.opacity < 0.6)
        tryVerify(function () { return !bg.fade.running }, 3000)
        compare(bg.frontImage.opacity, 0.6)
        // the same picture with another colour: the scheme follows
        DBusMock.emit(mediaIface, "ArtChanged", [artFile, "22AA55"])
        sameColor(Theme.color.primary, PaletteGenerator.generate("#22AA55", "", 1).primary, "a new colour")
        // no artwork any more: the system's colours, the picture fades out
        DBusMock.emit(mediaIface, "ArtChanged", ["", ""])
        compare(app.shownArtPath, "")
        compare(app.artThemed, false)
        sameColor(Theme.color.primary, Theme.staticPalette.primary, "back to the system's primary")
        verify(bg.shown, "still fading out")
        tryCompare(bg, "shown", false, 3000)
        // a colour without a picture is no colour
        DBusMock.emit(mediaIface, "ArtChanged", ["", "112233"])
        compare(app.shownArtColor, "")
        compare(app.artThemed, false)
    }

    function test_5_screenOff() {
        start(true)
        var bg = background()
        app.interactive = false
        DBusMock.emit(mediaIface, "ArtChanged", [artFile, "3366CC"])
        compare(app.shownArtPath, "", "nothing taken over with the screen off")
        compare(app.artThemed, false, "the roles not worked out")
        compare(bg.shown, false)
        app.interactive = true
        compare(app.shownArtColor, "#3366CC", "taken over when the screen comes on")
        verify(app.artThemed)
        verify(!bg.fade.running, "shown at once, no fade")
        compare(bg.frontImage.opacity, 0.6)
    }

    function test_6_systemThemeChanges() {
        DBusMock.reply(mediaIface, "ArtPath", artFile)
        DBusMock.reply(mediaIface, "ArtColor", "3366CC")
        start(false)
        tryCompare(app, "artThemed", true, 2000)
        var art = PaletteGenerator.generate("#3366CC", "", 1).primary
        // Settings > Color theme while the player shows the artwork's colours
        Theme._colorSeedValue = "#FF6F7F"
        Theme._colorSourceValue = "preset"
        tryVerify(function () {
            var x = Qt.color(Theme.color.primary), y = Qt.color(art)
            return Math.abs(x.r - y.r) < 0.004 && Math.abs(x.g - y.g) < 0.004 && Math.abs(x.b - y.b) < 0.004
        }, 1000, "the artwork's colours stay")
        // the artwork goes: the system's (new) theme
        DBusMock.emit(mediaIface, "ArtChanged", ["", ""])
        sameColor(Theme.color.primary, PaletteGenerator.generate("#FF6F7F", "", 2).primary, "the preset's colours (Peony, vibrant)")
    }
}
