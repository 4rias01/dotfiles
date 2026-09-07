pragma Singleton
// ---------------------------------------------------------------------------
//  FileSharing.qml  --  estado del "compartir archivos" (~/Shadow -> clipboard).
//  El estado es la existencia de BarConfig.archivoFileSharing; el toggle lo
//  hace scripts/file-sharing.sh, igual que en la Waybar.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Io
import QtQuick
import qs.bar

Singleton {
    id: root

    property bool activo: false

    Process {
        id: comprobar
        command: ["test", "-f", BarConfig.archivoFileSharing]
        running: true
        onExited: (codigo, estado) => { root.activo = (codigo === 0) }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: comprobar.running = true }
    Timer { id: recomprobar; interval: 300; onTriggered: comprobar.running = true }

    function alternar(): void {
        Quickshell.execDetached(BarConfig.cmdFileSharing)
        recomprobar.restart()
    }
}
