// custom/notification (swaync). Puntito rojo = hay notificaciones sin ver.
import QtQuick
import Quickshell
import qs.bar
import qs.bar.services

Module {
    visible: Swaync.disponible
    icono: Swaync.dnd ? "" : ""
    punto: Swaync.hayNotificaciones
    color: Swaync.dnd ? BarConfig.textoTenue : BarConfig.texto
    tooltip: Swaync.tooltip || (Swaync.dnd ? "No molestar" : "Sin notificaciones")
    onClic:        Quickshell.execDetached(BarConfig.cmdNotificaciones)
    onClicDerecho: Quickshell.execDetached(BarConfig.cmdNotificacionesDerecho)
}
