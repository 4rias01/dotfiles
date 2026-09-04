pragma Singleton
// ---------------------------------------------------------------------------
//  Brightness.qml  --  brillo de pantalla via brightnessctl.
//
//  sysfs no avisa por inotify cuando cambia el brillo, asi que se consulta
//  cada 2 s (para enterarse de las teclas de brillo) y ademas justo despues
//  de cada cambio propio.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Io
import QtQuick
import qs.bar

Singleton {
    id: root

    property int  valor: 0        // 0..100
    property bool disponible: false

    Process {
        id: leer
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // intel_backlight,backlight,14976,78%,19200
                const p = this.text.trim().split(",")
                if (p.length >= 4) {
                    root.valor = parseInt(p[3])
                    root.disponible = true
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: leer.running = true
    }

    Timer { id: releer; interval: 250; onTriggered: leer.running = true }

    function fijar(p: int): void {
        p = Math.max(1, Math.min(100, Math.round(p)))
        root.valor = p                      // UI inmediata
        Quickshell.execDetached(["brightnessctl", "-q", "set", p + "%"])
        releer.restart()
    }

    function subir(): void { root.fijar(root.valor + BarConfig.pasoBrillo) }
    function bajar(): void { root.fijar(root.valor - BarConfig.pasoBrillo) }
}
