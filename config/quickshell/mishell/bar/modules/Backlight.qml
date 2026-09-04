// Brillo: rueda +-BarConfig.pasoBrillo, clic abre el slider.
import QtQuick
import qs.bar
import qs.bar.services

Module {
    id: root
    required property string pantalla

    visible: Brightness.disponible
    icono: ""
    texto: Brightness.valor + "%"
    popAlCambiar: true
    activo: BarState.popupActivo("brillo", root.pantalla)
    tooltip: "Brillo"

    onRueda: d => d > 0 ? Brightness.subir() : Brightness.bajar()
    onClic: BarState.alternarPopup("brillo", root.pantalla)
}
