/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import Nemo.DBus
import "media.js" as Media

// What the phone tells asteroid-btsyncd about its player beyond MPRIS (btsyncd's src/mediaphonedata.h, the
// session bus API org.asteroidos.btsyncd.Media on /org/asteroidos/btsyncd/media): the artwork the phone sent
// (a JPEG under ~/.cache/asteroid-btsyncd/art) and its dominant colour, the seed of the player's colours
// (media-controls-11). Read once when the app starts and again on the ArtChanged signal: nothing is polled. A
// btsyncd without the interface answers errors: no artwork, no colour.
QtObject {
    id: link

    /*! The artwork's file ("" none). */
    property string artPath: ""
    /*! Its dominant colour "#RRGGBB" ("" none). */
    property string artColor: ""
    /*! A new artwork or colour arrived. */
    signal artUpdated()

    readonly property string service: "org.asteroidos.btsyncd"
    readonly property string path: "/org/asteroidos/btsyncd/media"
    readonly property string iface: "org.asteroidos.btsyncd.Media"

    function setArt(p, c) {
        var np = String(p === undefined || p === null ? "" : p)
        var nc = Media.artSeed(c)
        if (np === "")
            nc = ""          // the colour belongs to the picture
        if (np === artPath && nc === artColor)
            return
        artPath = np
        artColor = nc
        artUpdated()
    }

    function refresh() {
        _iface.typedCall("ArtPath", [], function (p) {
            _iface.typedCall("ArtColor", [], function (c) { link.setArt(p, c) }, function () { link.setArt(p, "") })
        }, function () { })
    }

    // Nemo.DBus names the handler of a signal either "rc" + the Signal or the signal with a lower case first
    // letter, depending on its version: both are defined
    property DBusInterface _iface: DBusInterface {
        bus: DBus.SessionBus
        service: link.service
        path: link.path
        iface: link.iface
        signalsEnabled: true
        function rcArtChanged(p: string, c: string) { link.setArt(p, c) }
        function artChanged(p: string, c: string) { link.setArt(p, c) }
    }

    Component.onCompleted: refresh()
}
