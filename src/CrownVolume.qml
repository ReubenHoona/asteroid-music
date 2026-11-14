/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import "media.js" as Media

// RotaryVolumeControls (media-controls-08; MS/gvo.java:11-43, MS/hlk.java:16-29):
// the crown's counts become pixels (1.75 px per count: 42 px per 24-count
// detent), they add up while the events are at most 200 ms apart, and every
// 48 px one change fires: steps = round(px x max(maxSteps x 0.001, 1/48)).
// `maxSteps` is the phone's step count (not sent over our link: 5 %, 20 steps).
Item {
    id: root

    property real volume: 0
    property int maxSteps: 20
    property real pxPerCount: Media.CROWN_PX_PER_COUNT
    property bool wheelEnabled: true
    /*! A change the crown made: the new level 0..1 and the steps taken. */
    signal stepped(real level, int steps)

    property var _state: ({ sum: 0, last: -1 })

    function feed(counts, now) {
        var steps = Media.crownFeed(_state, counts, now === undefined ? Date.now() : now, pxPerCount, maxSteps)
        if (steps === 0)
            return 0
        var next = Media.clamp01(volume + steps / maxSteps)
        // the crown haptics option (default off, media-controls-10): a tick per
        // step, the limit bump at 0 % and 100 % (both gated by Haptics itself)
        try {
            if (next === volume)
                Haptics.limit()
            else
                Haptics.tick()
        } catch (e) { }
        stepped(next, steps)
        return steps
    }

    WheelHandler {
        enabled: root.wheelEnabled
        onWheel: function (event) {
            if (event.angleDelta.y !== 0)
                root.feed(event.angleDelta.y / 120, Date.now())
        }
    }
}
