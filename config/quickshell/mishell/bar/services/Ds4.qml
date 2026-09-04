pragma Singleton
// ---------------------------------------------------------------------------
//  Ds4.qml  --  bateria del mando de PS4 (misma logica que ds4-battery.sh).
//  Busca /sys/class/power_supply/ps-controller-battery*; si no hay, el
//  modulo se oculta.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Io
import QtQuick
import qs.bar

Singleton {
    id: root

    property bool   presente: false
    property int    capacidad: 0
    property string estado: ""      // Charging | Discharging | Full | ...

    Process {
        id: proc
        command: ["sh", "-c", `
            for p in /sys/class/power_supply/ps-controller-battery*; do
                [ -e "$p" ] || exit 0
                echo "$(cat "$p/capacity" 2>/dev/null) $(cat "$p/status" 2>/dev/null)"
                exit 0
            done`]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim()
                if (!t) { root.presente = false; return }
                const p = t.split(/\s+/)
                let cap = parseInt(p[0]) || 0
                const st = p[1] ?? ""
                if (st === "Charging") cap = Math.max(0, cap - BarConfig.ds4AjusteCarga)
                root.capacidad = cap
                root.estado = st
                root.presente = true
            }
        }
    }
    Timer { interval: BarConfig.intervaloDs4; running: true; repeat: true; onTriggered: proc.running = true }
}
