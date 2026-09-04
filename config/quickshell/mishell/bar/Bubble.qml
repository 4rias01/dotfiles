// ---------------------------------------------------------------------------
//  Bubble.qml  --  una "burbuja": el pill oscuro que agrupa modulos.
//  Equivale a los #group-* de la Waybar. Al arrancar entra con un rebote
//  (scale 0.5 -> 1 con OutBack) y `retardo` permite escalonar las burbujas.
// ---------------------------------------------------------------------------
import QtQuick
import qs.bar

Rectangle {
    id: root

    default property alias contenido: fila.data
    property int retardo: 0

    height: BarConfig.alto
    implicitWidth: fila.implicitWidth + 2 * BarConfig.paddingBurbuja
    width: implicitWidth
    radius: BarConfig.radio
    color: BarConfig.fondo

    // Si todos los modulos de adentro estan ocultos, la burbuja tambien
    visible: fila.implicitWidth > 0

    Behavior on width {
        NumberAnimation { duration: BarConfig.durAncho; easing.type: Easing.OutCubic }
    }

    Row {
        id: fila
        anchors.centerIn: parent
        height: parent.height
        spacing: BarConfig.separacionModulos
    }

    // --- entrada -----------------------------------------------------------
    opacity: 0
    scale: 0.5
    transformOrigin: Item.Center

    SequentialAnimation {
        id: aparecer
        PauseAnimation { duration: root.retardo }
        ParallelAnimation {
            NumberAnimation {
                target: root; property: "scale"; to: 1
                duration: BarConfig.durAparecer
                easing.type: Easing.OutBack; easing.overshoot: 1.6
            }
            NumberAnimation { target: root; property: "opacity"; to: 1; duration: 220 }
        }
    }
    Component.onCompleted: aparecer.start()
}
