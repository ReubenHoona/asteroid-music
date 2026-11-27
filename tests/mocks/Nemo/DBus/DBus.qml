/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Test double of Nemo.DBus' DBus enumeration (the bus kinds).
 */
pragma Singleton
import QtQuick

QtObject {
    enum BusType { SystemBus, SessionBus }
}
