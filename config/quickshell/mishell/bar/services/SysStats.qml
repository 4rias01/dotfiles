pragma Singleton
// ---------------------------------------------------------------------------
//  SysStats.qml  --  CPU, RAM, swap, temperatura, red, carga y disco.
//
//  Un solo proceso cada BarConfig.intervaloStats que imprime la primera linea
//  de /proc/stat, /proc/meminfo, la temperatura del CPU, los bytes de red,
//  el loadavg y el uptime. El % de CPU y la velocidad de red salen de la
//  diferencia entre dos muestras, asi que la primera lectura tarda un
//  intervalo en aparecer.
//
//  La temperatura ya no depende de una ruta fija (antes era coretemp, que
//  solo existe en Intel): se busca el primer hwmon cuyo `name` este en
//  BarConfig.hwmonNombres (k10temp en AMD, coretemp en Intel...).
//
//  Ademas guarda un HISTORIAL de cada serie (BarConfig.puntosHistorial
//  muestras) para las graficas del panel de sistema (popups/SystemPopup.qml).
//  Lo lento (disco, modelo de CPU, SO, kernel) va en otro proceso cada
//  BarConfig.intervaloInfo.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Io
import QtQuick
import qs.bar

Singleton {
    id: root

    // --- valores actuales --------------------------------------------------
    property int  cpu:  0          // %
    property int  mem:  0          // %
    property int  temp: 0          // °C (CPU)
    property bool listo: false

    property real memTotalKiB:  0
    property real memUsadaKiB:  0
    property real swapTotalKiB: 0
    property real swapUsadaKiB: 0

    property real rxBps: 0         // bytes/s bajada
    property real txBps: 0         // bytes/s subida

    property string carga: "--"    // loadavg 1 / 5 / 15
    property real   uptimeSeg: 0

    // --- info lenta --------------------------------------------------------
    property string cpuModelo: ""
    property string so: ""
    property string kernel: ""
    property real   discoUsado: 0   // bytes en /
    property real   discoTotal: 0

    // --- historial (para las graficas) ------------------------------------
    property var histCpu:  []
    property var histTemp: []
    property var histMem:  []
    property var histRx:   []
    property var histTx:   []

    property real _idleAnt:  -1
    property real _totalAnt: -1
    property real _rxAnt: -1
    property real _txAnt: -1
    property real _tAnt:  0

    // hwmon: primer sensor cuyo name este en la lista (en orden de preferencia)
    readonly property string script: `
        head -1 /proc/stat
        grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo
        t=""
        for n in ${BarConfig.hwmonNombres.join(" ")}; do
            for h in /sys/class/hwmon/hwmon*; do
                [ "$(cat "$h/name" 2>/dev/null)" = "$n" ] && [ -r "$h/temp1_input" ] && { t=$(cat "$h/temp1_input"); break 2; }
            done
        done
        echo "TEMP $t"
        awk 'NR>2 { sub(/^ +/, ""); split($0, a, /[: ]+/); if (a[1] != "lo") { rx += a[2]; tx += a[10] } } END { print "NET", rx+0, tx+0 }' /proc/net/dev
        echo "LOAD $(cut -d' ' -f1-3 /proc/loadavg)"
        echo "UP $(cut -d' ' -f1 /proc/uptime)"
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

    Process {
        id: info
        command: ["sh", "-c", `
            echo "CPU $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//')"
            . /etc/os-release 2>/dev/null; echo "OS \${PRETTY_NAME:-\${NAME:-Linux}}"
            echo "KER $(uname -r)"
            df -B1 --output=used,size / | tail -1 | awk '{ print "DF", $1, $2 }'
        `]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                for (const l of this.text.split("\n")) {
                    const i = l.indexOf(" ")
                    if (i < 0) continue
                    const k = l.slice(0, i), v = l.slice(i + 1).trim()
                    if (k === "CPU")      root.cpuModelo = v
                    else if (k === "OS")  root.so = v
                    else if (k === "KER") root.kernel = v
                    else if (k === "DF") {
                        const p = v.split(/\s+/).map(Number)
                        root.discoUsado = p[0]; root.discoTotal = p[1]
                    }
                }
            }
        }
    }
    Timer {
        interval: BarConfig.intervaloInfo
        running: true
        repeat: true
        onTriggered: info.running = true
    }

    // agrega una muestra al final y recorta al largo del historial
    function empujar(arr: var, v: real): var {
        const n = arr.slice(Math.max(0, arr.length - BarConfig.puntosHistorial + 1))
        n.push(v)
        return n
    }

    function parsear(salida: string): void {
        let total = 0, idle = 0, memTotal = 0, memDisp = 0, swT = 0, swF = 0
        let t = -1, rx = -1, tx = -1
        for (const linea of salida.split("\n")) {
            const p = linea.trim().split(/\s+/)
            switch (p[0]) {
            case "cpu": {
                // user nice system idle iowait irq softirq steal
                const n = p.slice(1, 9).map(Number)
                total = n.reduce((a, b) => a + b, 0)
                idle  = n[3] + n[4]
                break
            }
            case "MemTotal:":     memTotal = Number(p[1]); break
            case "MemAvailable:": memDisp  = Number(p[1]); break
            case "SwapTotal:":    swT = Number(p[1]); break
            case "SwapFree:":     swF = Number(p[1]); break
            case "TEMP":          if (p[1] && /^\d+$/.test(p[1])) t = Number(p[1]); break
            case "NET":           rx = Number(p[1]); tx = Number(p[2]); break
            case "LOAD":          root.carga = p.slice(1, 4).join(" / "); break
            case "UP":            root.uptimeSeg = Number(p[1]); break
            }
        }

        if (root._totalAnt >= 0 && total > root._totalAnt) {
            const dt = total - root._totalAnt
            const di = idle  - root._idleAnt
            root.cpu = Math.round(100 * (1 - di / dt))
            root.listo = true
        }
        root._totalAnt = total
        root._idleAnt  = idle

        if (memTotal > 0) {
            root.memTotalKiB = memTotal
            root.memUsadaKiB = memTotal - memDisp
            root.mem = Math.round(100 * (memTotal - memDisp) / memTotal)
        }
        root.swapTotalKiB = swT
        root.swapUsadaKiB = swT - swF
        if (t >= 0) root.temp = Math.round(t / 1000)

        const ahora = Date.now()
        if (rx >= 0 && root._rxAnt >= 0 && root._tAnt > 0) {
            const seg = Math.max(0.1, (ahora - root._tAnt) / 1000)
            root.rxBps = Math.max(0, (rx - root._rxAnt) / seg)
            root.txBps = Math.max(0, (tx - root._txAnt) / seg)
        }
        root._rxAnt = rx; root._txAnt = tx; root._tAnt = ahora

        if (root.listo) {
            root.histCpu  = root.empujar(root.histCpu,  root.cpu)
            root.histTemp = root.empujar(root.histTemp, root.temp)
            root.histMem  = root.empujar(root.histMem,  root.mem)
            root.histRx   = root.empujar(root.histRx,   root.rxBps)
            root.histTx   = root.empujar(root.histTx,   root.txBps)
        }
    }

    // --- formato (compartido con el panel) --------------------------------
    function gib(kib: real): string { return (kib / 1048576).toFixed(1) }
    function velocidad(bps: real): string {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " MB/s"
        if (bps >= 1024)    return (bps / 1024).toFixed(1) + " kB/s"
        return Math.round(bps) + " B/s"
    }
    function duracion(seg: real): string {
        const d = Math.floor(seg / 86400)
        const h = Math.floor(seg / 3600) % 24
        const m = Math.floor(seg / 60) % 60
        const partes = []
        if (d > 0) partes.push(d + (d === 1 ? " día" : " días"))
        if (h > 0) partes.push(h + " h")
        partes.push(m + " min")
        return partes.join(" ")
    }
}
