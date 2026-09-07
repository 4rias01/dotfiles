// ---------------------------------------------------------------------------
//  Tooltip.qml  --  el tooltip de la barra (uno por ventana).
//  Los modulos registran `tooltipItem`/`tooltipTexto` en la PanelWindow
//  (ver Module.qml); esto solo lo dibuja debajo del modulo.
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell
import qs.bar

PopupWindow {
    id: root

    required property var barra     // la PanelWindow de Bar.qml

    readonly property bool mostrar: root.barra.tooltipItem !== null
                                 && root.barra.tooltipTexto !== ""
                                 && BarState.popupAbierto === ""
    visible: mostrar
    color: "transparent"

    anchor {
        item: root.barra.tooltipItem ?? root.barra.contentItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: 4
        adjustment: PopupAdjustment.SlideX
    }

    implicitWidth: caja.implicitWidth
    implicitHeight: caja.implicitHeight

    Rectangle {
        id: caja
        implicitWidth: txt.implicitWidth + BarConfig.s(20)
        implicitHeight: txt.implicitHeight + BarConfig.s(12)
        color: BarConfig.popupFondo
        border.width: 1
        border.color: BarConfig.popupBorde
        radius: BarConfig.s(8)
        transformOrigin: Item.Top
        scale: root.mostrar ? 1 : 0.7
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
        }

        Text {
            id: txt
            anchors.centerIn: parent
            text: root.barra.tooltipTexto
            color: BarConfig.texto
            font.family: BarConfig.fuente
            font.pixelSize: BarConfig.tamFuente - 2
        }
    }
}
