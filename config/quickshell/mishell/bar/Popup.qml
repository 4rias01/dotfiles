// ---------------------------------------------------------------------------
//  Popup.qml  --  burbuja que cuelga de un modulo de la barra.
//
//  Es una PopupWindow (xdg_popup de la capa de la barra) anclada al modulo.
//  Se abre creciendo desde arriba con rebote y se cierra sola medio segundo
//  despues de que el mouse abandona tanto el modulo como el popup. Solo hay
//  un popup abierto a la vez en toda la sesion (BarState.popupAbierto).
//
//  Uso (en Bar.qml):
//      Popup { nombre: "bateria"; ancla: bateria; anclaHover: bateria.hovered
//              pantalla: win.screen.name;  BatteryPopup {} }
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell
import qs.bar

PopupWindow {
    id: root

    required property Item   ancla
    required property string nombre
    required property string pantalla
    property bool anclaHover: false
    default property alias contenido: cont.data
    property int padding: BarConfig.popupPadding

    readonly property bool abierto: BarState.popupAbierto === root.nombre
                                 && BarState.popupPantalla === root.pantalla

    property bool _mostrar: false
    visible: _mostrar
    color: "transparent"

    anchor {
        item: root.ancla
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: BarConfig.popupSeparacion
        adjustment: PopupAdjustment.SlideX
    }

    implicitWidth: caja.implicitWidth
    implicitHeight: caja.implicitHeight

    onAbiertoChanged: {
        if (root.abierto) {
            cierre.stop()
            cerrarAnim.stop()
            root._mostrar = true
            abrirAnim.restart()
            // si se abrio sin el mouse encima (IPC/bind), que no se quede para
            // siempre, pero da tiempo a leerlo
            if (!root.conMouse) { cierre.interval = BarConfig.popupCierreSinMouseMs; cierre.restart() }
        } else {
            abrirAnim.stop()
            cerrarAnim.restart()
        }
    }

    // --- cierre por hover-out ---------------------------------------------
    readonly property bool conMouse: hover.hovered || root.anclaHover
    onConMouseChanged: {
        if (!root.abierto) return
        if (root.conMouse) cierre.stop()
        else { cierre.interval = BarConfig.popupCierreMs; cierre.restart() }
    }
    Timer {
        id: cierre
        interval: BarConfig.popupCierreMs
        onTriggered: if (root.abierto && !root.conMouse) BarState.cerrarPopup()
    }

    Rectangle {
        id: caja
        implicitWidth: cont.implicitWidth + 2 * root.padding
        implicitHeight: cont.implicitHeight + 2 * root.padding
        color: BarConfig.popupFondo
        radius: BarConfig.popupRadio
        border.width: 1
        border.color: BarConfig.popupBorde
        transformOrigin: Item.Top
        scale: 0.6
        opacity: 0

        HoverHandler { id: hover }

        Item {
            id: cont
            anchors.fill: parent
            anchors.margins: root.padding
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }

    ParallelAnimation {
        id: abrirAnim
        NumberAnimation {
            target: caja; property: "scale"; to: 1
            duration: BarConfig.durPopup
            easing.type: Easing.OutBack; easing.overshoot: 1.3
        }
        NumberAnimation { target: caja; property: "opacity"; to: 1; duration: 150 }
    }
    SequentialAnimation {
        id: cerrarAnim
        ParallelAnimation {
            NumberAnimation { target: caja; property: "scale";   to: 0.7; duration: 150; easing.type: Easing.InQuad }
            NumberAnimation { target: caja; property: "opacity"; to: 0;   duration: 130 }
        }
        ScriptAction { script: root._mostrar = false }
    }
}
