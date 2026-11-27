/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Test double of Nemo.DBus' DBusInterface: calls go to DBusMock (a log and the answer the
 * test scripted), signals are sent by DBusMock.emit(). Nothing touches a bus.
 */
import QtQuick

QtObject {
    id: me

    property int bus: 1
    property string service: ""
    property string path: ""
    property string iface: ""
    property bool signalsEnabled: false
    property bool watchServiceStatus: false

    // Nemo.DBus deletes an interface's pending calls with it (~DeclarativeDBusInterface): the answer to
    // a call of an interface that is gone reaches no callback
    property var _life: ({ on: true })

    function typedCall(method, args, onSuccess, onError) {
        var name = me.iface !== "" ? me.iface : me.service
        var life = me._life
        DBusMock.log.push({ iface: name, method: method, args: args || [] })
        DBusMock.calls++
        DBusMock.enqueue(function () {
            if (!life.on)
                return
            var r = DBusMock.answer(name, method, args || [])
            if (r === DBusMock.noAnswer) {
                if (onError)
                    onError()
            } else if (onSuccess)
                onSuccess(r)
        })
    }

    function call(method, args, onSuccess, onError) { typedCall(method, args, onSuccess, onError) }

    Component.onCompleted: DBusMock.instances.push(me)
    Component.onDestruction: {
        me._life.on = false
        var i = DBusMock.instances.indexOf(me)
        if (i >= 0)
            DBusMock.instances.splice(i, 1)
    }
}
