// System meters for the top bar: CPU %, used RAM, network down/up rates.
// One shared reader for all screens; samples /proc every `interval` ms.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: stats

    property int interval: 2000

    property real cpu: 0          // 0..1
    property real ramUsed: 0      // bytes
    property real ramTotal: 0     // bytes
    property real down: 0         // bytes per second
    property real up: 0           // bytes per second

    property var last: null       // previous sample, for deltas

    FileView { id: procStat; path: "/proc/stat" }
    FileView { id: procMem; path: "/proc/meminfo" }
    FileView { id: procNet; path: "/proc/net/dev" }

    function sample() {
        for (const f of [procStat, procMem, procNet]) { f.reload(); f.waitForJob(); }

        // cpu  user nice system idle iowait irq softirq steal ...
        const c = procStat.text().split("\n")[0].trim().split(/\s+/).slice(1, 9).map(Number);
        const busy = c[0] + c[1] + c[2] + c[5] + c[6] + c[7];
        const total = busy + c[3] + c[4];

        const mem = {};
        for (const line of procMem.text().split("\n")) {
            const m = line.match(/^(\w+):\s+(\d+)/);
            if (m) mem[m[1]] = Number(m[2]) * 1024;
        }

        // iface: rx_bytes (7 more rx fields) tx_bytes ...; loopback excluded
        let rx = 0, tx = 0;
        for (const line of procNet.text().split("\n").slice(2)) {
            const [name, rest] = line.split(":");
            if (!rest || name.trim() === "lo") continue;
            const f = rest.trim().split(/\s+/).map(Number);
            rx += f[0]; tx += f[8];
        }

        const now = Date.now();
        if (last) {
            const dt = (now - last.time) / 1000;
            cpu = total > last.total ? (busy - last.busy) / (total - last.total) : 0;
            down = Math.max(0, rx - last.rx) / dt;
            up = Math.max(0, tx - last.tx) / dt;
        }
        ramTotal = mem.MemTotal || 0;
        ramUsed = ramTotal - (mem.MemAvailable || 0);
        last = { time: now, busy, total, rx, tx };
    }

    // 1.2M, 340K, 0K: compact rates that keep the bar width steady
    function rate(bytes) {
        if (bytes >= 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + "M";
        return Math.round(bytes / 1024) + "K";
    }

    Timer {
        interval: stats.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: stats.sample()
    }
}
