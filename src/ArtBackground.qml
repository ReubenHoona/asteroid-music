/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Shapes
import org.asteroid.controls
import "media.js" as Media

// The player's background (media-controls-11): the artwork the phone sent, cropped to the screen at 60 %
// opacity (MS/gva.java:88-123: Image, ContentScale.Crop, alpha 0.6), under a radial gradient that is clear
// from the centre to 65 % of the radius and the scheme's background (black) at the edge (MS/hmv.java:40-44:
// stops 0.65 transparent, 1.0 background), the screen's half width being the radius (Compose's radial
// gradient default). A new artwork cross-fades in over the old one (MS/fl.java:1705-1734: Crossfade with the
// motion scheme's effects spec; here the standard default effects spring, 500 / 1.0). No artwork: nothing is
// drawn, the plain background shows.
//
// A change made while \l animate is false (the screen is off, the app is not in front) shows at once: no
// frame is drawn for a fade nobody sees.
Item {
    id: root

    /*! The picture ("" none): a local file URL. */
    property string source: ""
    /*! false: the next change is shown at once. */
    property bool animate: true

    readonly property real u: Theme.dp(1)
    /*! An artwork is on screen (or fading out). */
    readonly property bool shown: _front.source != "" || fade.running
    readonly property alias vignette: vignette
    readonly property alias fade: fade
    /*! The picture in front, for tests. */
    readonly property Image frontImage: _front
    readonly property Image backImage: _back

    // the slot in front: 0 = first, 1 = second; fade.value goes to it
    property int _frontIndex: 0
    readonly property Image _front: _frontIndex === 0 ? first : second
    readonly property Image _back: _frontIndex === 0 ? second : first

    // a picture is being put in the back slot: it comes to the front once it is loaded (or failed)
    property bool _waiting: false

    onSourceChanged: _take()
    Component.onCompleted: if (source !== "") _take()

    function _take() {
        var back = _back
        _waiting = true
        back.source = source
        if (_waiting && (source === "" || back.status !== Image.Loading)) {
            _waiting = false
            _swap()
        }
    }

    function _swap() {
        _frontIndex = 1 - _frontIndex
        if (!animate)
            fade.snapTo(_frontIndex)
    }

    function _loaded(img) {
        // the picture that was waited for: in front now
        if (_waiting && img === _back && img.source == source && img.status !== Image.Loading) {
            _waiting = false
            _swap()
        }
    }

    WearSpring {
        id: fade
        to: root._frontIndex
        stiffness: Motion.standard.defaultEffects.stiffness
        dampingRatio: Motion.standard.defaultEffects.dampingRatio
    }

    Image {
        id: first
        objectName: "artFirst"
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        opacity: Media.ART_OPACITY * (1 - fade.value)
        visible: opacity > 0 && source != ""
        onStatusChanged: root._loaded(first)
    }

    Image {
        id: second
        objectName: "artSecond"
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        opacity: Media.ART_OPACITY * fade.value
        visible: opacity > 0 && source != ""
        onStatusChanged: root._loaded(second)
    }

    Shape {
        id: vignette
        objectName: "artVignette"
        anchors.fill: parent
        visible: root.shown
        readonly property color edge: Theme.color.background
        readonly property real radius: Math.min(width, height) / 2
        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: vignette.width / 2
                centerY: vignette.height / 2
                centerRadius: vignette.radius
                focalX: centerX
                focalY: centerY
                focalRadius: 0
                GradientStop { position: 0; color: Qt.rgba(vignette.edge.r, vignette.edge.g, vignette.edge.b, 0) }
                GradientStop { position: Media.ART_CLEAR; color: Qt.rgba(vignette.edge.r, vignette.edge.g, vignette.edge.b, 0) }
                GradientStop { position: 1; color: vignette.edge }
            }
            startX: 0; startY: 0
            PathLine { x: vignette.width; y: 0 }
            PathLine { x: vignette.width; y: vignette.height }
            PathLine { x: 0; y: vignette.height }
            PathLine { x: 0; y: 0 }
        }
    }
}
