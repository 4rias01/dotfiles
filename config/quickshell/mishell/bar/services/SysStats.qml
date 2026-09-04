pragma Singleton
// ---------------------------------------------------------------------------
//  SysStats.qml  --  CPU, RAM y temperatura.
//
//  Un solo proceso cada BarConfig.intervaloStats que imprime la primera linea
//  de /proc/stat, MemTotal/MemAvailable y la temperatura del hwmon. El % de
//  CPU sale de la diferencia entre dos muestras, asi que la primera lectura
//  tarda un intervalo en aparecer.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Io
import QtQuick
import qs.bar

Singleton {
    id: root

    property int  cpu:  0      // %
    property int  mem:  0      // %
    property int  temp: 0      // °C
    property bool listo: false

    property real _idleAnt:  -1
    property real _totalAnt: -1

    readonly property string script: `
        head -1 /proc/stat
        grep -E '^(MemTotal|MemAvailable):' /proc/meminfo
        cat ${BarConfig.hwmonTemp} 2>/dev/null | head -1
    `

    Process {
        id: proc
        command: ["sh", "-c", root.script]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.parsear(this.text)
        }
    }

    Timer {
        interval: BarConfig.intervaloStats
        running: true
        repeat: true
        onTriggered: proc.running = true
    }

    function parsear(salida: string): void {
        let total = 0, idle = 0, memTotal = 0, memDisp = 0, t = -1
        for (const linea of salida.split("\n")) {
            const p = linea.trim().split(/\s+/)
            if (p[0] === "cpu") {
                // user nice system idle iowait irq softirq steal
                const n = p.slice(1, 9).map(Number)
                total = n.reduce((a, b) => a + b, 0)
                idle  = n[3] + n[4]
            } else if (p[0] === "MemTotal:")     memTotal = Number(p[1])
            else if   (p[0] === "MemAvailable:") memDisp  = Number(p[1])
            else if   (/^\d+$/.test(p[0]))       t = Number(p[0])
        }

        if (root._totalAnt >= 0 && total > root._totalAnt) {
            const dt = total - root._totalAnt
            const di = idle  - root._idleAnt
            root.cpu = Math.round(100 * (1 - di / dt))
            root.listo = true
        }
        root._totalAnt = total
        root._idleAnt  = idle

        if (memTotal > 0) root.mem = Math.round(100 * (memTotal - memDisp) / memTotal)
        if (t >= 0)       root.temp = Math.round(t / 1000)
    }
}
