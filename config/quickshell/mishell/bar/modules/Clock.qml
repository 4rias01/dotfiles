// ---------------------------------------------------------------------------
//  Clock.qml  --  reloj del centro.
//  Clic izquierdo: popup con calendario + musica.  Clic derecho: cambia el
//  formato (hora <-> fecha corta), como el format-alt de la Waybar.
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell
import qs.bar

Module {
    id: root

    required property string pantalla

    SystemClock { id: reloj; precision: SystemClock.Minutes }

    readonly property var loc: BarConfig.locale !== "" ? Qt.locale(BarConfig.locale) : Qt.locale()

    // "hh" y "AP" se resuelven a mano para tener 12 h con AM/PM sin depender
    // del a. m./p. m. del locale; el resto del formato lo hace Qt.
    function formatear(fecha: date, formato: string): string {
        const h = fecha.getHours()
        const h12 = (h % 12) === 0 ? 12 : h % 12
        const hh = (h12 < 10 ? "0" : "") + h12
        const ap = h < 12 ? "AM" : "PM"
        const f = formato.replace(/hh/g, "'" + hh + "'").replace(/AP/g, "'" + ap + "'")
        return root.loc.toString(fecha, f)
    }

    texto: root.formatear(reloj.date, BarState.horaAlt ? BarConfig.formatoHoraAlt : BarConfig.formatoHora)
    negrita: true
    activo: BarState.popupActivo("reloj", root.pantalla)
    tooltip: root.loc.toString(reloj.date, "dddd, d 'de' MMMM 'de' yyyy")

    onClic:        BarState.alternarPopup("reloj", root.pantalla)
    onClicDerecho: BarState.alternarHora()
}
