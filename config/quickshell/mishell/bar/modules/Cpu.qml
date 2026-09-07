import QtQuick
import Quickshell
import qs.bar
import qs.bar.services

Module {
    icono: ""
    texto: (SysStats.listo ? SysStats.cpu : "--") + "%"
    tooltip: "CPU " + SysStats.cpu + "%"
    onClic: Quickshell.execDetached(BarConfig.cmdCpu)
}
