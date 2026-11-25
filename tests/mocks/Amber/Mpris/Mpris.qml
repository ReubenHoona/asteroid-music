/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

// Test double of Amber.Mpris: the playback status enum (as the plugin numbers it)
pragma Singleton
import QtQuick

QtObject {
    enum PlaybackStatus { Playing, Paused, Stopped }
}
