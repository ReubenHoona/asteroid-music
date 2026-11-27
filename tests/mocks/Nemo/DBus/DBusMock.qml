/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * The test side of the Nemo.DBus double: what was called, what the test answers, signals.
 *   DBusMock.reply("org.asteroidos.btsyncd.Phone", "Connected", true)
 *   DBusMock.reply(iface, method, function (args) { return ... })
 *   DBusMock.emit("org.asteroidos.btsyncd.Assistant", "ActResult", [id, json])
 *   DBusMock.reset()
 */
pragma Singleton
import QtQuick

QtObject {
    id: mock

    property var log: []
    property int calls: 0
    property var replies: ({})
    property var instances: []
    readonly property var noAnswer: ({ none: true })

    // Qt.callLater joins calls of closures made from the same code: a queue of its own keeps every call
    property var _queue: []
    property Timer _timer: Timer {
        interval: 0
        repeat: false
        onTriggered: mock._drain()
    }
    function enqueue(fn) {
        _queue.push(fn)
        if (!_timer.running)
            _timer.start()
    }
    function _drain() {
        var q = _queue
        _queue = []
        for (var i = 0; i < q.length; i++)
            q[i]()
        if (_queue.length > 0)
            _timer.start()
    }

    function reset() {
        log = []
        calls = 0
        replies = {}
    }

    function reply(iface, method, value) {
        var r = replies
        r[iface + "." + method] = value
        replies = r
    }

    function answer(iface, method, args) {
        var key = iface + "." + method
        if (!(key in replies))
            return noAnswer
        var v = replies[key]
        return typeof v === "function" ? v(args) : v
    }

    /* calls to one method, as the arguments' values */
    function callsTo(method) {
        var out = []
        for (var i = 0; i < log.length; i++)
            if (log[i].method === method)
                out.push(log[i])
        return out
    }

    /* the JSON of every Act(id, json) the app made */
    function acts() {
        var out = []
        for (var i = 0; i < log.length; i++)
            if (log[i].method === "Act")
                out.push({ id: log[i].args[0].value, json: JSON.parse(log[i].args[1].value) })
        return out
    }

    function emit(iface, name, args) {
        var fn = "rc" + name
        var lower = name.charAt(0).toLowerCase() + name.substring(1)
        for (var i = 0; i < instances.length; i++) {
            var o = instances[i]
            if (o.iface !== iface || !o.signalsEnabled)
                continue
            if (typeof o[fn] === "function")
                o[fn].apply(o, args)
            else if (typeof o[lower] === "function")
                o[lower].apply(o, args)
        }
    }
}
