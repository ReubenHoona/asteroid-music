/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtTest
import org.asteroid.controls
import Nemo.DBus
import "../src/media.js" as Media

// D-04 and D-05 (media-controls-19, -20): the player's custom actions and its queue from btsyncd's
// org.asteroidos.btsyncd.Media (Extras, ExtrasChanged, CustomAction, SkipToQueueItem; the D-Bus double of
// tests/mocks). The More pill shows while a track plays and the phone sent actions or a queue; More Actions
// lists the app's name, the first three actions as a button group and the Up Next card (the next item's
// title, disabled without one); the queue lists every item, the one that plays marked (primaryContainer,
// the equaliser looping while it plays and the screen is on, the paused bars "Paused" else); a tap on
// another item plays it and goes back to the player. Every name, title and player is invented.
TestCase {
    id: tc
    name: "Extras"
    when: windowShown
    visible: true
    width: 384
    height: 384

    readonly property string mediaIface: "org.asteroidos.btsyncd.Media"
    property var app: null

    readonly property var fourActions: ["Shuffle", "Thumbs up", "Invented action", "Repeat"]
    readonly property var queue5: [{ t: "First Invented Song", s: "Sample Band" }, { t: "Second Song", s: "Sample Band" },
                                   { t: "A Third Song With A Long Invented Title That Wraps", s: "" },
                                   { t: "Fourth", s: "Other Band" }, { t: "Fifth", s: "" }]

    function extras(actions, queue, current) {
        return JSON.stringify({ actions: actions, queue: queue, current: current })
    }

    function init() {
        DBusMock.reset()
    }

    function cleanup() {
        if (app)
            app.destroy()
        app = null
        Theme.applyColorTheme(true)
        wait(30)
    }

    function start(json, playing, identity) {
        if (json !== undefined)
            DBusMock.reply(mediaIface, "Extras", json)
        DBusMock.reply(mediaIface, "CustomAction", true)
        DBusMock.reply(mediaIface, "SkipToQueueItem", true)
        var comp = Qt.createComponent("../src/main.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        app = comp.createObject(tc, { width: 384, height: 384 })
        app.interactive = true
        app.linkUp = true
        app.mpris.currentService = "org.mpris.MediaPlayer2.test"
        app.mpris.identity = identity === undefined ? "Invented Player" : identity
        app.mpris.metaData = { title: "First Invented Song", contributingArtist: ["Sample Band"] }
        app.mpris.playbackStatus = playing === false ? 1 : 0
        wait(80)
        return app
    }

    function player() { return findChild(app, "player") }
    function layers() { return findChild(app, "layerStack").layers.length }

    function openMore() {
        var pill = player().outputRow.morePill
        verify(pill.visible, "the More pill shows")
        mouseClick(pill)
        tryVerify(function () { return layers() === 1 }, 2000)
        var page = findChild(app, "morePage")
        verify(page !== null, "More Actions open")
        tryVerify(function () { return !findChild(app, "layerStack").pushing }, 3000)
        wait(300)
        return page
    }

    function openQueue() {
        var more = openMore()
        var card = findChild(more, "upNextCard")
        verify(card !== null && card.enabled, "Up Next enabled")
        mouseClick(card)
        tryVerify(function () { return layers() === 2 }, 2000)
        var page = findChild(app, "queuePage")
        verify(page !== null, "the queue open")
        tryVerify(function () { return !findChild(app, "layerStack").pushing }, 3000)
        wait(300)
        return page
    }

    function sameColor(a, b, msg) {
        var x = Qt.color(a), y = Qt.color(b)
        verify(Math.abs(x.r - y.r) < 0.004 && Math.abs(x.g - y.g) < 0.004 && Math.abs(x.b - y.b) < 0.004,
               msg + ": " + x + " != " + y)
    }

    function test_1_parse() {
        var e = Media.parseExtras(extras(["Shuffle", "Repeat"], [{ t: "A", s: "B" }, { t: "C" }], 0))
        compare(e.actions, ["Shuffle", "Repeat"])
        compare(e.queue.length, 2)
        compare(e.queue[0].title, "A"); compare(e.queue[0].subtitle, "B")
        compare(e.queue[1].title, "C"); compare(e.queue[1].subtitle, "")
        compare(e.current, 0)
        compare(Media.parseExtras(extras([], [{ t: "A" }], 3)).current, -1, "a current past the list: not known")
        compare(Media.parseExtras(extras([], [{ t: "A" }], 1.5)).current, -1)
        compare(Media.parseExtras(extras([], [], -1)).current, -1)
        var bad = Media.parseExtras("{not json")
        compare(bad.actions.length, 0); compare(bad.queue.length, 0); compare(bad.current, -1)
        compare(Media.parseExtras("").queue.length, 0)
        compare(Media.parseExtras("[1,2]").actions.length, 0)
        compare(Media.parseExtras(undefined).current, -1)
        // Up Next: the item after the one that plays (MS/a.java V())
        var q = Media.parseExtras(extras([], queue5, 0)).queue
        compare(Media.upNextTitle(q, 0), "Second Song")
        compare(Media.upNextTitle(q, 3), "Fifth")
        compare(Media.upNextTitle(q, 4), "", "the last plays: none")
        compare(Media.upNextTitle(q, -1), "", "the one that plays not known: none")
        compare(Media.upNextTitle([], 0), "")
        // icons for known names, none else
        compare(Media.actionIcon("Shuffle"), "ios-shuffle")
        compare(Media.actionIcon("Repeat one"), "ios-repeat")
        compare(Media.actionIcon("Thumbs down"), "ios-thumbs-down")
        compare(Media.actionIcon("Dislike"), "ios-thumbs-down")
        compare(Media.actionIcon("Thumbs up"), "ios-thumbs-up")
        compare(Media.actionIcon("Like"), "ios-thumbs-up")
        compare(Media.actionIcon("Add to favourites"), "ms-favorite")
        compare(Media.actionIcon("Playback speed"), "ios-speedometer")
        compare(Media.actionIcon("1.5x"), "ios-speedometer")
        compare(Media.actionIcon("Skip back 15 seconds"), "ios-rewind")
        compare(Media.actionIcon("-10 s"), "ios-rewind")
        compare(Media.actionIcon("Skip forward 30 seconds"), "ios-fastforward")
        compare(Media.actionIcon("+30"), "ios-fastforward")
        compare(Media.actionIcon("Sleep timer"), "ms-timer")
        compare(Media.actionIcon("Feedback"), "", "no word match inside another word")
        compare(Media.actionIcon("Invented action"), "")
        compare(Media.actionIcon(undefined), "")
        compare(Media.playerName("Invented Player"), "Invented Player")
        compare(Media.playerName(Media.DAEMON_IDENTITY), "", "btsyncd's own name: not told")
        compare(Media.playerName(""), "")
        compare(Media.MAX_ACTIONS_SHOWN, 3, "the button group's three (MS/fl.java A())")
    }

    function test_2_equaliser() {
        compare(Media.EQ_LOOP_MS, 2000)
        compare(Media.EQ_SIZE, 16)
        var t0 = Media.equaliserTops(0)
        compare(t0, [13.27, 0.94, 3.56], "the drawable's first frame")
        compare(Media.equaliserTops(2000), t0, "a loop")
        compare(Media.equaliserTops(200)[0], 5.38, "bar 1 at its 200 ms key")
        compare(Media.equaliserTops(350)[1], 12.05, "bar 2 at its 350 ms key")
        for (var ms = 0; ms < 2000; ms += 37) {
            var t = Media.equaliserTops(ms)
            for (var b = 0; b < 3; b++)
                verify(t[b] >= 0.9 && t[b] < Media.EQ_BOTTOM, "bar " + b + " at " + ms + " ms: " + t[b])
        }
        compare(Media.bezierEase(Media.EQ_EASE, 0), 0)
        compare(Media.bezierEase(Media.EQ_EASE, 1), 1)
        var last = 0
        for (var p = 0.05; p < 1; p += 0.05) {
            var y = Media.bezierEase(Media.EQ_EASE, p)
            verify(y >= last, "eases forward")
            last = y
        }
        verify(Media.bezierEase(Media.EQ_EASE, 0.25) < 0.25, "slow in")
    }

    function test_3_link() {
        start(extras(fourActions, queue5, 0))
        tryVerify(function () { return app.link.queue.length === 5 }, 2000)
        compare(app.link.actions, fourActions)
        compare(app.link.current, 0)
        compare(app.link.upNext, "Second Song")
        verify(app.link.hasMore)
        compare(DBusMock.callsTo("Extras").length, 1, "read once at start")
        // the phone wrote new lists: read again on the signal
        DBusMock.reply(mediaIface, "Extras", extras([], [{ t: "Only One" }], 0))
        DBusMock.emit(mediaIface, "ExtrasChanged", [])
        tryVerify(function () { return app.link.queue.length === 1 }, 2000)
        compare(app.link.actions.length, 0)
        compare(app.link.upNext, "")
        verify(app.link.hasMore, "a queue alone")
        compare(DBusMock.callsTo("Extras").length, 2)
        // the commands carry the index as an int32
        app.link.customAction(2)
        app.link.playQueueItem(4)
        wait(50)          // the answers (true) come back
        var c = DBusMock.callsTo("CustomAction")
        compare(c.length, 1); compare(c[0].args[0].type, "i"); compare(c[0].args[0].value, 2)
        var s = DBusMock.callsTo("SkipToQueueItem")
        compare(s.length, 1); compare(s[0].args[0].type, "i"); compare(s[0].args[0].value, 4)
        compare(DBusMock.callsTo("Extras").length, 2, "a true answer reads nothing")
        // an index the watch's list no longer has: the lists are read again
        DBusMock.reply(mediaIface, "CustomAction", false)
        app.link.customAction(7)
        tryVerify(function () { return DBusMock.callsTo("Extras").length === 3 }, 2000)
        // a change with the screen off is read when it comes back on
        var n = DBusMock.callsTo("Extras").length
        app.interactive = false
        DBusMock.reply(mediaIface, "Extras", extras(["Shuffle"], [], -1))
        DBusMock.emit(mediaIface, "ExtrasChanged", [])
        DBusMock.emit(mediaIface, "ExtrasChanged", [])
        wait(50)
        compare(DBusMock.callsTo("Extras").length, n, "nothing read with the screen off")
        app.interactive = true
        tryVerify(function () { return app.link.actions.length === 1 }, 2000)
        compare(DBusMock.callsTo("Extras").length, n + 1, "read once when it comes on")
        // nothing at all
        DBusMock.reply(mediaIface, "Extras", extras([], [], -1))
        DBusMock.emit(mediaIface, "ExtrasChanged", [])
        tryCompare(app.link, "hasMore", false, 2000)
    }

    function test_4_morePill() {
        start(undefined)
        var row = player().outputRow
        compare(row.morePill.visible, false, "no extras: the output pill alone")
        compare(row.outputPill.x, (row.width - row.outputPill.width) / 2, "centred")
        DBusMock.reply(mediaIface, "Extras", extras(["Shuffle"], [], -1))
        DBusMock.emit(mediaIface, "ExtrasChanged", [])
        tryCompare(row.morePill, "visible", true, 2000)
        verify(row.outputPill.x < (row.width - row.outputPill.width) / 2, "the output pill in the left cell")
        // nothing playing: one output pill (media-controls-14)
        app.mpris.currentService = ""
        tryCompare(row.morePill, "visible", false, 3000)
    }

    function test_5_moreActions() {
        start(extras(fourActions, queue5, 0))
        tryCompare(app.link, "hasMore", true, 2000)
        var page = openMore()
        compare(findChild(page, "moreHeader").label.text, "Invented Player", "the player app's name")
        var group = findChild(page, "moreActions")
        verify(group !== null)
        compare(group.count, 3, "the first three of four")
        var a0 = findChild(group, "action0"), a1 = findChild(group, "action1"), a2 = findChild(group, "action2")
        compare(a0.name, "Shuffle"); compare(a0.iconName, "ios-shuffle")
        compare(a1.name, "Thumbs up"); compare(a1.iconName, "ios-thumbs-up")
        compare(a2.name, "Invented action"); compare(a2.iconName, "", "an unknown action shows its name")
        compare(findChild(group, "action3"), null, "no fourth")
        compare(a0.height, 104, "52 dp")
        compare(a1.x - (a0.x + a0.width), 16, "8 dp apart")
        compare(a0.width, a2.width, "equal widths at rest")
        compare(a0.Accessible.name, "Shuffle")
        var card = findChild(page, "upNextCard")
        compare(card.title, "Up Next")
        compare(card.text, "Second Song", "the next item's title")
        verify(card.enabled)
        grabImage(app).save("shots/more-actions.png")
        mouseClick(a2)
        var c = DBusMock.callsTo("CustomAction")
        compare(c.length, 1, "a tap runs the action")
        compare(c[0].args[0].value, 2)
        compare(layers(), 1, "More Actions stays")
    }

    function test_6_upNextDisabledAndHeader() {
        start(extras([], queue5, -1), true, Media.DAEMON_IDENTITY)
        tryCompare(app.link, "hasMore", true, 2000)
        var page = openMore()
        compare(findChild(page, "moreHeader").label.text, "More Actions", "the screen's name when the app is not told")
        compare(findChild(page, "moreActions"), null, "no actions: no group")
        var card = findChild(page, "upNextCard")
        compare(card.enabled, false, "the one that plays not known: Up Next disabled")
        compare(card.text, "")
        mouseClick(card)
        wait(300)
        compare(layers(), 1, "nothing opens")
    }

    function test_7_queue() {
        DBusMock.reply(mediaIface, "ArtPath", String(Qt.resolvedUrl("fixtures/art.png")).replace(/^file:\/\//, ""))
        DBusMock.reply(mediaIface, "ArtColor", "3366CC")
        start(extras(fourActions, queue5, 0))
        tryCompare(app.link, "hasMore", true, 2000)
        tryCompare(app, "artThemed", true, 2000)
        var page = openQueue()
        compare(findChild(page, "queueHeader").label.text, "Invented Player")
        var cur = findChild(page, "queueItem0"), other = findChild(page, "queueItem1"), long = findChild(page, "queueItem2")
        verify(cur !== null && other !== null && long !== null)
        verify(cur.isCurrent); verify(!other.isCurrent)
        sameColor(cur.container.color, Theme.color.primaryContainer, "the item that plays: primaryContainer")
        sameColor(cur.titleLabel.color, Theme.color.onPrimaryContainer, "its content")
        sameColor(other.container.color, Theme.color.surfaceContainer, "the others: surfaceContainer")
        sameColor(other.titleLabel.color, Theme.color.onSurface, "their content")
        compare(cur.equaliser.visible, true, "the equaliser on the item that plays")
        compare(other.equaliser.visible, false)
        sameColor(cur.equaliser.color, Theme.color.onPrimaryContainer, "in the content colour")
        compare(cur.equaliser.width, 32, "16 dp")
        verify(cur.equaliser.animating, "looping while it plays")
        compare(cur.titleLabel.maximumLineCount, 1, "one line with a subtitle")
        compare(long.titleLabel.maximumLineCount, 2, "two without")
        compare(long.subtitleLabel.visible, false)
        compare(cur.enabled, false, "the item that plays does nothing")
        compare(cur.titleLabel.text, "First Invented Song")
        compare(other.subtitleLabel.text, "Sample Band")
        grabImage(app).save("shots/queue-playing.png")
        // the screen goes off: the loop stops
        app.interactive = false
        verify(!cur.equaliser.animating, "no frames with the screen off")
        app.interactive = true
        verify(cur.equaliser.animating)
        // paused: the static bars, "Paused"
        app.mpris.playbackStatus = 1
        tryCompare(cur.equaliser, "animating", false, 1000)
        compare(cur.equaliser.Accessible.name, "Paused")
        wait(100)
        grabImage(app).save("shots/queue-paused.png")
        // another item: played, back to the player
        mouseClick(other)
        var s = DBusMock.callsTo("SkipToQueueItem")
        compare(s.length, 1, "a tap plays that item")
        compare(s[0].args[0].value, 1)
        tryVerify(function () { return layers() === 0 }, 3000, "back to the player")
    }

    function test_8_queueOpensAtTheItemThatPlays() {
        var long = []
        for (var i = 0; i < 20; i++)
            long.push({ t: "Invented Song " + i, s: "" })
        start(extras([], long, 12))
        tryCompare(app.link, "current", 12, 2000)
        var page = openQueue()
        var cur = findChild(page, "queueItem12")
        verify(cur !== null, "the item that plays is on screen")
        var y = cur.mapToItem(app, 0, cur.height / 2).y
        verify(y > 96 && y < 288, "near the middle: " + y)
    }
}
