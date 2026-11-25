/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

.pragma library

// Media Controls (Horologist M3 PlayerScreen on the Pixel Watch 2, 192 dp).
// Sizes are dp: the QML files multiply with Theme.dp(). Evidence in the
// gaps media-controls-01..09 (MS/hds.java, fl.java, gye.java, hj.java).
// The Wear OS 6 look (N61-51, emulator screenshot S33) centres the button
// group on the screen, grows the play shape and lowers the output pill:
// TOP_H, BOTTOM_H, PLAY_SHAPE, BOTTOM_TOP and the shape radii.

// ---- layout (media-controls-01, -02, -04, -06) ----
var TOP_H = 64            // S33: group centred on y 192 (CP3A 68, MS/hds.java:1291-1308)
var TOP_PAD_TOP = 24      // ceil(12 % of 192 dp)
var TOP_PAD_BOTTOM = 2
var DISPLAY_H = 38        // MS/fl.java:2213
var TITLE_W = 128         // 66.72 % of 192 dp
var TITLE_H = 20
var ARTIST_W = 144        // 75 %
var ARTIST_H = 18
var MID_H = 64
var BOTTOM_H = 64         // the rest of the 192 dp (CP3A 60)
var GROUP_SIDE = 14       // pill group: outer padding (MS/gyf.java:1154-1167)
var PILL_W = 40
var PILL_H = 48
var PILL_GAP = 10
var PLAY_SLOT = 64
var PLAY_SHAPE = 64       // scallop / circle across (S33: 128 px; CP3A 60)
var PLAY_ICON = 32
var SKIP_ICON = 32
var EXPAND = 12           // a pressed button grows 12 dp (ButtonGroupLayout.kt)
var BOTTOM_SIDE = 28      // MS/gye.java:123
var BOTTOM_TOP = 16       // S33: output pill y 288-351 (CP3A 3)
var OUT_PILL_W = 44       // MS/gye.java:4512
var OUT_PILL_H = 32
var OUT_ICON = 24
var BADGE = 18
var BADGE_ICON = 14
var BADGE_SHIFT = 9

// ---- marquee (media-controls-02; MS/fl.java:936-1157) ----
var MARQUEE_PAUSE = 4000
var MARQUEE_SPEED = 64    // dp/s
var MARQUEE_GAP = 96      // dp between the copies
var MARQUEE_FADE = 8      // dp edge fade
var SWAP_MS = 300
var SWAP_SHIFT = 0.125    // of the row width
var TITLE_IN = 60, TITLE_OUT = 0
var ARTIST_IN = 90, ARTIST_OUT = 30

// ---- shapes (media-controls-03; MS/auw.java:27-38) ----
var SCALLOP_POINTS = 10   // vertices per radius
var SCALLOP_OUTER = 32    // dp (64 px): PLAY_SHAPE / 2 (CP3A 30)
var SCALLOP_INNER = 25.6  // dp (0.8)
var SCALLOP_ROUND = 12    // dp corner rounding
var ROTATE_DEG = -36      // per ROTATE_MS, linear, restarting
var ROTATE_MS = 3000
var ICON_MORPH_MS = 170
var RING_STROKE = 4       // dp (MS/fl.java:4636)
var RING_GAP = 1          // dp of free path between the caps (about 2 px)
var RING_INNER = 51.2     // dp across: the filled shape while the ring shows (0.8)
var RING_SAMPLES = 120

// ---- crown (media-controls-08; MS/gvo.java:11-43) ----
var CROWN_STEP_PX = 48
var CROWN_GAP_MS = 200
var CROWN_PX_PER_COUNT = 1.75     // 42 px per 24-count detent (RotaryInput default)

// ---- level arc (media-controls-09; MS/gsc.java:140-153) ----
var LEVEL_SWEEP = 72
var LEVEL_STROKE = 6      // dp
var LEVEL_HOLD_MS = 2500

// ---- loading (media-controls-14; MS/fl.java:1479-1566) ----
var LOADING_MS = 2000

// ---- rounded polygon, polar sampling ----

// vertices [[x, y], ...] in order, each corner rounded with radius `rounding`
// (cut down where the neighbouring edges are too short, as Compose's
// RoundedPolygon does); returns the outline points.
function roundedPolygon(v, rounding) {
    var n = v.length, out = []
    for (var i = 0; i < n; i++) {
        var p = v[(i + n - 1) % n], c = v[i], q = v[(i + 1) % n]
        var ux = p[0] - c[0], uy = p[1] - c[1], wx = q[0] - c[0], wy = q[1] - c[1]
        var lu = Math.sqrt(ux * ux + uy * uy), lw = Math.sqrt(wx * wx + wy * wy)
        ux /= lu; uy /= lu; wx /= lw; wy /= lw
        var phi = Math.acos(Math.max(-1, Math.min(1, ux * wx + uy * wy)))
        var t = Math.tan(phi / 2)
        var d = rounding / t
        var dmax = Math.min(lu, lw) / 2
        if (d > dmax) d = dmax
        var rad = d * t
        var bx = ux + wx, by = uy + wy
        var lb = Math.sqrt(bx * bx + by * by)
        bx /= lb; by /= lb
        var dc = rad / Math.sin(phi / 2)
        var cx = c[0] + bx * dc, cy = c[1] + by * dc
        var s0 = Math.atan2(c[1] + uy * d - cy, c[0] + ux * d - cx)
        var s1 = Math.atan2(c[1] + wy * d - cy, c[0] + wx * d - cx)
        var da = s1 - s0
        while (da > Math.PI) da -= 2 * Math.PI
        while (da < -Math.PI) da += 2 * Math.PI
        var steps = Math.max(2, Math.ceil(Math.abs(da) / (Math.PI / 18)))
        for (var k = 0; k <= steps; k++) {
            var a = s0 + da * k / steps
            out.push([cx + rad * Math.cos(a), cy + rad * Math.sin(a)])
        }
    }
    return out
}

// the star: `points` outer and `points` inner vertices, an outer one at the top
function starVertices(points, outer, inner) {
    var v = []
    for (var k = 0; k < 2 * points; k++) {
        var a = -Math.PI / 2 + k * Math.PI / points
        var r = k % 2 === 0 ? outer : inner
        v.push([r * Math.cos(a), r * Math.sin(a)])
    }
    return v
}

function scallopPolygon() {
    return roundedPolygon(starVertices(SCALLOP_POINTS, SCALLOP_OUTER, SCALLOP_INNER), SCALLOP_ROUND)
}

// a w x h pill (rounded rectangle with a full radius) about the origin
function pillPolygon(w, h) {
    var x = w / 2, y = h / 2
    return roundedPolygon([[-x, -y], [x, -y], [x, y], [-x, y]], Math.min(w, h) / 2)
}

// distance from the origin to the outline of a star-shaped polygon along theta
function rayDistance(poly, theta) {
    var dx = Math.cos(theta), dy = Math.sin(theta), best = -1
    var n = poly.length
    for (var i = 0; i < n; i++) {
        var a = poly[i], b = poly[(i + 1) % n]
        var ex = b[0] - a[0], ey = b[1] - a[1]
        var den = dx * ey - dy * ex
        if (Math.abs(den) < 1e-12) continue
        var t = (a[0] * ey - a[1] * ex) / den
        var s = (a[0] * dy - a[1] * dx) / den
        if (t > 0 && s >= -1e-9 && s <= 1 + 1e-9 && (best < 0 || t < best)) best = t
    }
    return best
}

// radii at n angles, the first at the top, going clockwise
function radii(poly, n) {
    var r = []
    for (var i = 0; i < n; i++)
        r.push(rayDistance(poly, -Math.PI / 2 + 2 * Math.PI * i / n))
    return r
}

function circleRadii(r, n) {
    var a = []
    for (var i = 0; i < n; i++) a.push(r)
    return a
}

function blend(a, b, t) {
    var r = []
    for (var i = 0; i < a.length; i++) r.push(a[i] + (b[i] - a[i]) * t)
    return r
}

// outline points of radii scaled by `scale` and shrunk by `inset`
function outline(rad, scale, inset) {
    var n = rad.length, pts = []
    for (var i = 0; i < n; i++) {
        var a = -Math.PI / 2 + 2 * Math.PI * i / n
        var r = (rad[i] - (inset || 0)) * scale
        pts.push(Qt.point(r * Math.cos(a), r * Math.sin(a)))
    }
    return pts
}

function pathLength(pts) {
    var l = 0
    for (var i = 1; i < pts.length; i++)
        l += Math.sqrt(Math.pow(pts[i].x - pts[i - 1].x, 2) + Math.pow(pts[i].y - pts[i - 1].y, 2))
    return l
}

function closed(pts) { return pts.concat([pts[0]]) }

// the part of the polyline between the path lengths s0 and s1
function subPath(pts, s0, s1) {
    var out = [], acc = 0
    if (s1 <= s0) return out
    for (var i = 1; i < pts.length; i++) {
        var a = pts[i - 1], b = pts[i]
        var seg = Math.sqrt(Math.pow(b.x - a.x, 2) + Math.pow(b.y - a.y, 2))
        var e = acc + seg
        if (seg > 0 && e > s0 && acc < s1) {
            var f0 = Math.max(0, (s0 - acc) / seg), f1 = Math.min(1, (s1 - acc) / seg)
            if (out.length === 0)
                out.push(Qt.point(a.x + (b.x - a.x) * f0, a.y + (b.y - a.y) * f0))
            out.push(Qt.point(a.x + (b.x - a.x) * f1, a.y + (b.y - a.y) * f1))
        }
        acc = e
    }
    return out
}

// The progress ring (media-controls-05): the outline is split at the played
// fraction; `gap` is the free path between the round caps at both joins.
function ringPaths(rad, scale, inset, fraction, gap, stroke) {
    var pts = closed(outline(rad, scale, inset))
    var L = pathLength(pts)
    var f = Math.max(0, Math.min(1, fraction))
    var g = (gap + stroke) / 2
    var played = [], rest = []
    if (f >= 0.9999) {
        played = pts
    } else if (f <= 0.0001) {
        rest = pts
    } else {
        played = subPath(pts, g, f * L - g)
        rest = subPath(pts, f * L + g, L - g)
    }
    return { played: played, rest: rest, length: L }
}

// ---- the play / pause glyph: two bars <-> a triangle (media-controls-03) ----
// 4-vertex quads in a 32 dp box centred on the origin. pause: two bars; play:
// the triangle cut in two (a trapezoid and a point), so the vertices morph one to one.
var PAUSE_A = [[-9, -8], [-9, 8], [-3, 8], [-3, -8]]
var PAUSE_B = [[3, -8], [3, 8], [9, 8], [9, -8]]
var PLAY_A = [[-6, -9], [-6, 9], [2, 4.5], [2, -4.5]]
var PLAY_B = [[2, -4.5], [2, 4.5], [10, 0], [10, 0]]

function quadPoints(from, to, t, scale) {
    var p = []
    for (var i = 0; i < 4; i++)
        p.push(Qt.point((from[i][0] + (to[i][0] - from[i][0]) * t) * scale,
                        (from[i][1] + (to[i][1] - from[i][1]) * t) * scale))
    return p
}

// t = 0: pause, 1: play
function glyphA(t, scale) { return quadPoints(PAUSE_A, PLAY_A, t, scale) }
function glyphB(t, scale) { return quadPoints(PAUSE_B, PLAY_B, t, scale) }

// ---- the button group (media-controls-04) ----
// widths of the [previous, play, next] slots in dp for the pressed index
// (-1: none) at expansion e (0..1): the pressed one grows 12 dp, its
// neighbours give that back between them, so the row keeps its width.
function groupWidths(base, pressed, e) {
    var w = base.slice()
    if (pressed < 0) return w
    var d = EXPAND * e
    w[pressed] += d
    var nb = pressed === 1 ? [0, 2] : [1]
    for (var i = 0; i < nb.length; i++) w[nb[i]] -= d / nb.length
    return w
}

// ---- state and texts (media-controls-14, -25) ----
// in: linkUp, hasService, status ("playing" | "paused" | "stopped"),
// title, artist, waitedOut (the 2 s of loading are over)
// out: kind "loading" | "nothing" | "media", title, artist, unknown
function describe(m) {
    var title = m.title || "", artist = m.artist || ""
    var live = m.hasService && (m.status === "playing" || m.status === "paused")
    var session = m.hasService && (title !== "" || live)
    if (!(m.linkUp && session) && !m.waitedOut)
        return { kind: "loading", title: "", artist: "", unknown: false }
    if (!m.linkUp || !session)
        return { kind: "nothing", title: "", artist: "", unknown: false }
    if (title.trim() === "")
        return { kind: "media", title: "", artist: "", unknown: true }
    return { kind: "media", title: title, artist: artist, unknown: false }
}

// ---- the crown (media-controls-08) ----
// One volume change per 48 px of rotary scroll: pixels add up while events
// are at most 200 ms apart; steps = round(px x max(maxVolume x 0.001, 1/48)).
// st = { sum, last } is kept by the caller; returns the signed step count.
function crownFeed(st, counts, now, pxPerCount, maxVolume) {
    if (st.last >= 0 && now - st.last > CROWN_GAP_MS) st.sum = 0
    st.last = now
    st.sum += counts * pxPerCount
    if (Math.abs(st.sum) < CROWN_STEP_PX) return 0
    var steps = Math.round(st.sum * Math.max(maxVolume * 0.001, 1 / CROWN_STEP_PX))
    st.sum = 0
    return steps
}

// ---- volume icon chosen by the level (MS/hg.java:755-773) ----
function volumeIcon(level) {
    if (level <= 0) return "ms-volume_off"
    if (level >= 1) return "ms-volume_up"
    return "ms-volume_down"
}

function clamp01(v) { return Math.max(0, Math.min(1, v)) }
