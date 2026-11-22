pragma Singleton
// ---------------------------------------------------------------------------
//  GpuStats.qml  --  uso, VRAM y temperatura de la tarjeta grafica.
//
//  Detecta solo el backend al arrancar:
//    - "nvidia": driver nvidia cargado + nvidia-smi. Antes de cada consulta
//      se mira /sys/bus/pci/devices/<bus>/power/runtime_status: si la dGPU
//      esta "suspended" (laptops hibridas con la iGPU dibujando) NO se llama
//      a nvidia-smi, porque despertaria la tarjeta solo para medirla y se
//      come la bateria. En la Lenovo LOQ (Ryzen 7235HS, sin iGPU) la RTX
//      4050 es la unica GPU, asi que siempre esta activa.
//    - "amd": amdgpu por sysfs (gpu_busy_percent, mem_info_vram_*, hwmon).
//    - "":   no hay nada que medir; el modulo y la tarjeta del panel se ocultan.
//
//  Guarda historial de uso y temperatura para las graficas del panel.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Io
import QtQuick
import qs.bar

Singleton {
    id: root

    property string backend: ""        // "nvidia" | "amd" | ""
    property string nombre: ""
    property string ruta: ""           // dispositivo PCI en sysfs
    readonly property bool disponible: root.backend !== ""

    property bool suspendida: false    // dGPU en D3 (no se consulto)
    property int  uso: 0               // %
    property real vramUsadaMiB: 0
    property real vramTotalMiB: 0
    property int  temp: 0              // °C
    property bool listo: false

    property var histUso:  []
    property var histTemp: []

    // --- deteccion -----------------------------------------------------------
    Process {
        id: detectar
        running: true
        command: ["sh", "-c", `
            for d in /sys/bus/pci/drivers/nvidia/0000:*; do
                [ -e "$d" ] || continue
                if command -v nvidia-smi >/dev/null 2>&1; then
                    echo "nvidia $(readlink -f "$d")"; exit 0
                fi
            done
            for c in /sys/class/drm/card*/device; do
                [ -r "$c/gpu_busy_percent" ] && { echo "amd $(readlink -f "$c")"; exit 0; }
            done
            echo none`]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split(/\s+/)
                if (p[0] === "nvidia" || p[0] === "amd") {
                    root.ruta = p[1] || ""
                    root.backend = p[0]
                    sondeo.running = true
                }
            }
        }
    }

    // --- sondeo ------------------------------------------------------------
    readonly property string scriptNvidia: `
        st=$(cat "${root.ruta}/power/runtime_status" 2>/dev/null)
        if [ "$st" = "suspended" ]; then echo SUSP; exit 0; fi
        nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu \
                   --format=csv,noheader,nounits 2>/dev/null | head -1`

    readonly property string scriptAmd: `
        d="${root.ruta}"
        echo "AMD $(cat $d/gpu_busy_percent 2>/dev/null || echo 0) \
$(cat $d/mem_info_vram_used 2>/dev/null || echo 0) \
$(cat $d/mem_info_vram_total 2>/dev/null || echo 0) \
$(cat $d/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)"`

    Process {
        id: sondeo
        command: ["sh", "-c", root.backend === "nvidia" ? root.scriptNvidia : root.scriptAmd]
        stdout: StdioCollector {
            onStreamFinished: root.parsear(this.text.trim())
        }
    }

    Timer {
        interval: BarConfig.intervaloGpu
        running: root.disponible
        repeat: true
        onTriggered: sondeo.running = true
    }

    function empujar(arr: var, v: real): var {
        const n = arr.slice(Math.max(0, arr.length - BarConfig.puntosHistorial + 1))
        n.push(v)
        return n
    }

    function parsear(t: string): void {
        if (t === "") return
        if (t === "SUSP") {
            // la dGPU duerme: se dibuja en 0 sin despertarla
            root.suspendida = true
            root.uso = 0
            if (root.nombre === "") root.nombre = "NVIDIA (en reposo)"
        } else if (root.backend === "nvidia") {
            // "NVIDIA GeForce RTX 4050 Laptop GPU, 25, 434, 6141, 44"
            const p = t.split(",").map(s => s.trim())
            if (p.length < 5) return
            root.suspendida = false
            root.nombre = p[0]
            root.uso = Number(p[1]) || 0
            root.vramUsadaMiB = Number(p[2]) || 0
            root.vramTotalMiB = Number(p[3]) || 0
            root.temp = Number(p[4]) || 0
        } else {
            const p = t.split(/\s+/)
            if (p[0] !== "AMD") return
            root.suspendida = false
            root.uso = Number(p[1]) || 0
            root.vramUsadaMiB = (Number(p[2]) || 0) / 1048576
            root.vramTotalMiB = (Number(p[3]) || 0) / 1048576
            root.temp = Math.round((Number(p[4]) || 0) / 1000)
            if (root.nombre === "") nombreAmd.running = true
        }
        root.listo = true
        root.histUso  = root.empujar(root.histUso,  root.uso)
        root.histTemp = root.empujar(root.histTemp, root.temp)
    }

    // nombre legible de la AMD (solo una vez)
    Process {
        id: nombreAmd
        command: ["sh", "-c", "lspci -s \"$(basename '" + root.ruta + "')\" 2>/dev/null | cut -d: -f3- | sed 's/^ *//'"]
        stdout: StdioCollector {
            onStreamFinished: root.nombre = this.text.trim() || "GPU AMD"
        }
    }
}
