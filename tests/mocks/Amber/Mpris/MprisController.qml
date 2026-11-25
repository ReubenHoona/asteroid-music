/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

// Test double of Amber.Mpris MprisController: plain properties, calls are recorded
import QtQuick

QtObject {
    property string currentService: ""
    property int playbackStatus: 2
    property var metaData: ({})
    property real volume: 0
    property real position: 0
    property real rate: 1
    property string identity: ""
    property bool canGoPrevious: true
    property bool canGoNext: true
    property bool canPlay: true
    property bool canPause: true
    property var calls: []
    function play() { calls.push("play") }
    function pause() { calls.push("pause") }
    function next() { calls.push("next") }
    function previous() { calls.push("previous") }
}
