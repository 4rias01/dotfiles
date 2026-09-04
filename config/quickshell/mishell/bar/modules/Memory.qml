import QtQuick
import qs.bar
import qs.bar.services

Module {
    icono: ""
    texto: SysStats.mem + "%"
    tooltip: "RAM en uso " + SysStats.mem + "%"
}
