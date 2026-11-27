/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtTest
import "../src/media.js" as Media

// The start (src/main.qml): the play button at rest and not playing is the circle, so the outlines the first
// frame does not show (the scallop of a playing track, the pills of a press: Media.shapeRadii, about 120 rays
// each) are not worked out before it; they are worked out after it, one after each frame, and are the same as
// the button worked out at its creation before. A press or a playing track still morphs toward them.
// Run with the Amber.Mpris double of tests/mocks (as tst_newlook61.qml); no other test of this file may
// ask Media for a shape before test_1 (the library is one per engine).
TestCase {
    id: tc
    name: "MusicStart"
    when: windowShown
    visible: true
    width: 384
    height: 384

    property var app: null

    function cleanup() {
        if (app)
            app.destroy()
        app = null
        wait(30)
    }

    function findAll(item, pred, out) {
        out = out || []
        if (!item)
            return out
        if (pred(item))
            out.push(item)
        var kids = item.children || []
        for (var i = 0; i < kids.length; i++)
            findAll(kids[i], pred, out)
        return out
    }

    function playButton() {
        var b = findAll(app, function (o) { return o.radiiNow !== undefined && o.squeeze !== undefined })
        compare(b.length, 1)
        return b[0]
    }

    function made() {
        return Object.keys(Media._shapes).sort().join(" ")
    }

    function sameList(a, b, msg) {
        compare(a.length, b.length, msg)
        for (var i = 0; i < a.length; i++)
            if (a[i] !== b[i])
                fail(msg + ": " + i + ": " + a[i] + " != " + b[i])
    }

    function test_1_outlines_after_the_first_frame() {
        var comp = Qt.createComponent("../src/main.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        app = comp.createObject(null, { width: 384, height: 384 })
        var button = playButton()
        compare(made(), "", "no outline worked out with the app")
        sameList(button.radiiNow, button._circle, "at rest: the circle")
        app.parent = tc
        tryVerify(function () { return app.shapesMade === 3 }, 5000)
        compare(made(), "narrow scallop wide")
        // the outlines the button had before (worked out at its creation)
        var d = 2 * Media.SCALLOP_OUTER
        sameList(Media.shapeRadii("scallop"), Media.radii(Media.scallopPolygon(), Media.RING_SAMPLES), "scallop")
        sameList(Media.shapeRadii("wide"), Media.radii(Media.pillPolygon(d + Media.EXPAND, d), Media.RING_SAMPLES), "wide")
        sameList(Media.shapeRadii("narrow"), Media.radii(Media.pillPolygon(d - Media.EXPAND, d), Media.RING_SAMPLES), "narrow")
    }

    function test_2_press_and_play_morph_as_before() {
        var comp = Qt.createComponent("../src/main.qml")
        app = comp.createObject(tc, { width: 384, height: 384 })
        var button = playButton()
        var circle = button._circle
        // grown by a press of the button itself, narrowed by a neighbour's
        button.squeeze = Media.EXPAND
        sameList(button.radiiNow, Media.blend(Media.blend(circle, Media.shapeRadii("scallop"), 0), Media.shapeRadii("wide"), 1), "pressed")
        button.squeeze = -Media.EXPAND / 2
        sameList(button.radiiNow, Media.blend(circle, Media.shapeRadii("narrow"), 0.5), "neighbour pressed")
        button.squeeze = 0
        // playing: the scallop (the morph animates to 1)
        button.playing = true
        tryCompare(button, "morph", 1, 2000)
        sameList(button.radiiNow, Media.blend(circle, Media.shapeRadii("scallop"), 1), "playing")
    }
}
