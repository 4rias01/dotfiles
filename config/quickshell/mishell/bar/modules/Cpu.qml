// ---------------------------------------------------------------------------
//  Cpu.qml  --  uso del CPU.
//  Clic: panel de sistema (graficas).  Clic derecho: btop (BarConfig.cmdCpu).
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell
import qs.bar
import qs.bar.services

Module {
    id: root
    required property string pantalla

    icono: ""
    texto: (SysStats.listo ? SysStats.cpu : "--") + "%"
    tooltip: "CPU " + SysStats.cpu + "%\nClic: panel de sistema · clic derecho: btop"
    activo: BarState.popupActivo("sistema", root.pantalla)
    onClic: BarState.alternarPopup("sistema", root.pantalla)
    onClicDerecho: { root.pulso(); Quickshell.execDetached(BarConfig.cmdCpu) }
}
