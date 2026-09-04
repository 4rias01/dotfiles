pragma Singleton
// ---------------------------------------------------------------------------
//  Swaync.qml  --  estado del centro de notificaciones.
//
//  `swaync-client -swb` se queda corriendo e imprime una linea JSON cada vez
//  que cambia algo: {"text":"2","alt":"notification","class":"notification"}.
//  Si swaync se reinicia el proceso muere; se relanza a los 2 s.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string clase: "none"    // none | notification | dnd-none | dnd-notification | inhibited-* | dnd-inhibited-*
    property int    cantidad: 0
    property string tooltip: ""
    property bool   disponible: false

    readonly property bool hayNotificaciones: clase.endsWith("notification")
    readonly property bool dnd: clase.startsWith("dnd")
    readonly property bool inhibido: clase.includes("inhibited")

    Process {
        id: proc
        command: ["swaync-client", "-swb"]
        running: true
        stdout: SplitParser {
            onRead: linea => {
                try {
                    const j = JSON.parse(linea)
                    root.clase = j.class ?? "none"
                    root.cantidad = parseInt(j.text) || 0
                    root.tooltip = j.tooltip ?? ""
                    root.disponible = true
                } catch (e) { }
            }
        }
        onExited: reintento.restart()
    }
    Timer { id: reintento; interval: 2000; onTriggered: proc.running = true }
}
