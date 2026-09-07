// ---------------------------------------------------------------------------
//  SliderPopup.qml  --  un slider chico con icono y porcentaje (brillo, volumen).
//  `valor` va de 0 a 1; al arrastrar o hacer rueda emite cambiar(v).
// ---------------------------------------------------------------------------
import QtQuick
import qs.bar

Row {
    id: root
    spacing: 12

    property string icono: ""
    property real   valor: 0
    property real   maximo: 1          // volumen puede pasar de 1 si BarConfig.volumenMax > 100
    property string etiqueta: Math.round(root.valor * 100) + "%"
    property bool   apagado: false     // mute
    property real   paso: 0.02
    signal cambiar(real v)
    signal clicIcono()

    readonly property real frac: Math.max(0, Math.min(1, root.valor / root.maximo))

    Text {
        text: root.icono
        color: root.apagado ? BarConfig.textoTenue : BarConfig.acento
        font.family: BarConfig.fuente
        font.pixelSize: 20
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicIcono()
        }
    }

    Item {
        id: pista
        width: 190
        height: 26
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 8
            radius: 4
            color: BarConfig.popupSuperficie

            Rectangle {
                width: Math.max(height, parent.width * root.frac)
                height: parent.height
                radius: 4
                color: root.apagado ? BarConfig.textoTenue : BarConfig.acento
                Behavior on width { enabled: !ma.pressed; NumberAnimation { duration: 120 } }
            }
        }

        // la "burbuja" que se arrastra
        Rectangle {
            x: (pista.width - width) * root.frac
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18; radius: 9
            color: BarConfig.texto
            scale: ma.pressed ? 1.35 : (ma.containsMouse ? 1.15 : 1)
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2 } }
            Behavior on x { enabled: !ma.pressed; NumberAnimation { duration: 120 } }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function aplicar(mx) {
                root.cambiar(Math.max(0, Math.min(1, mx / pista.width)) * root.maximo)
            }
            onPressed: e => aplicar(e.x)
            onPositionChanged: e => { if (pressed) aplicar(e.x) }
            onWheel: e => root.cambiar(Math.max(0, Math.min(root.maximo,
                root.valor + (e.angleDelta.y > 0 ? root.paso : -root.paso))))
        }
    }

    Text {
        text: root.etiqueta
        color: BarConfig.texto
        font.family: BarConfig.fuente
        font.pixelSize: BarConfig.tamFuente
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        horizontalAlignment: Text.AlignRight
    }
}
