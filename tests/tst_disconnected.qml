/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtTest
import org.asteroid.controls
import Amber.Mpris
import "../src" as M
import "../src/media.js" as Media

// C-24 (connectivity-system-ux-05): stock Media Controls shows the session error "Disconnected from media app"
// (media.sessions error_message_disconnected, MS/dac.java:648-650: SessionError -100, the controller is
// disconnected from the media app's session) in the media display, the controls disabled. Here the media app's
// session is the phone player that asteroid-btsyncd bridges over MPRIS: with the phone linked but no MPRIS
// player (the bridge is gone), Media Controls says so; with the phone gone it is "Nothing playing" (stock: the
// bridged sessions time out, MS SessionTimeout), and with the bridge there but nothing playing on the phone too.
// The long text runs as a marquee in the 144 dp display (stock's media display text, MS/fl.java:1479-1566).
//
// Run as the other tests of this folder (run.sh: the Amber.Mpris double, the English catalog).
TestCase {
    id: tc
    name: "Disconnected"
    when: windowShown
    visible: true
    width: 384
    height: 384

    Component { id: playerC; M.PlayerPage { width: 384; height: 384 } }

    function test_1_describe() {
        var base = { linkUp: true, hasService: false, status: "stopped", title: "", artist: "", waitedOut: true }
        function d(o) {
            var m = {}
            for (var k in base) m[k] = base[k]
            for (var j in o) m[j] = o[j]
            return Media.describe(m).kind
        }
        compare(d({}), "disconnected", "the phone linked, no media session bridge")
        compare(d({ waitedOut: false }), "loading", "the first 2 s are Loading")
        compare(d({ linkUp: false }), "nothing", "the phone gone: Nothing playing")
        compare(d({ linkUp: false, waitedOut: false }), "loading")
        compare(d({ hasService: true }), "nothing", "a bridge with nothing playing on the phone")
        compare(d({ hasService: true, title: "Invented Song" }), "media")
        compare(d({ hasService: true, status: "playing" }), "media", "playing without a title (unknown media)")
        compare(d({ hasService: true, linkUp: false, title: "Invented Song" }), "nothing")
    }

    function test_2_player() {
        var p = createTemporaryObject(playerC, tc, { kind: "disconnected" })
        verify(p)
        compare(p.disconnectedText, "Disconnected from media app", "the English catalog has the text")
        compare(p.statusLabel.text, "Disconnected from media app")
        verify(p.statusLabel.visible, "shown in the media display")
        verify(!p.titleRow.visible && !p.artistRow.visible)
        verify(!p.playButton.enabled && !p.previousButton.enabled && !p.nextButton.enabled, "the controls disabled")
        // too long for the 144 dp display: a marquee (it does not fit and is not cut off)
        verify(p.statusLabel.overflows, "longer than the display")
        tryVerify(function () { return p.statusLabel.scrolling }, Media.MARQUEE_PAUSE + 3000, "the text runs")
        // the other states keep their texts
        p.kind = "nothing"
        compare(p.statusLabel.text, "Nothing playing")
        verify(!p.statusLabel.overflows, "Nothing playing fits: still")
        p.kind = "loading"
        compare(p.statusLabel.text, "Loading…")
        p.kind = "media"
        verify(!p.statusLabel.visible)
    }

    function test_3_main() {
        var comp = Qt.createComponent("../src/main.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var app = comp.createObject(tc, { width: 384, height: 384 })
        app.interactive = true
        app.linkUp = true
        compare(app.shown.kind, "loading", "Loading… first")
        tryVerify(function () { return app.shown.kind === "disconnected" }, 4000, "Disconnected from media app after 2 s")
        var p = findChild(app, "player")
        verify(p)
        compare(p.kind, "disconnected")
        compare(p.statusLabel.text, "Disconnected from media app")
        // the bridge comes back with a track
        app.mpris.currentService = "org.mpris.MediaPlayer2.test"
        app.mpris.metaData = { title: "Invented Song", contributingArtist: ["Sample Band"] }
        app.mpris.playbackStatus = 1
        tryVerify(function () { return app.shown.kind === "media" }, 2000)
        // gone again
        app.mpris.currentService = ""
        tryVerify(function () { return app.shown.kind === "disconnected" }, 2000)
        // the phone goes: Nothing playing
        app.linkUp = false
        tryVerify(function () { return app.shown.kind === "nothing" }, 2000)
        app.destroy()
    }
}
