// custom/bluetooth-file-sharing: vigila ~/Shadow y manda lo que aparezca al portapapeles.
import QtQuick
import qs.bar
import qs.bar.services

Module {
    icono: FileSharing.activo ? "󰒖" : "󰼣"
    colorIcono: FileSharing.activo ? BarConfig.acento : BarConfig.texto
    tooltip: FileSharing.activo ? "Compartir archivos: activo" : "Compartir archivos: apagado"
    onClic: FileSharing.alternar()
}
