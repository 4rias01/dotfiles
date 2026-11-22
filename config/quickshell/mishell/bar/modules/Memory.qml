import QtQuick
import qs.bar
import qs.bar.services

Module {
    id: root
    required property string pantalla

    icono: ""
    texto: SysStats.mem + "%"
    tooltip: "RAM en uso " + SysStats.mem + "% (" + SysStats.gib(SysStats.memUsadaKiB)
           + " / " + SysStats.gib(SysStats.memTotalKiB) + " GiB)"
    activo: BarState.popupActivo("sistema", root.pantalla)
    onClic: BarState.alternarPopup("sistema", root.pantalla)
}
