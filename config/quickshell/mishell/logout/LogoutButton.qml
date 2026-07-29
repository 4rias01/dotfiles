import QtQuick
import qs.logout
import qs.config

Rectangle {
    id: root

    property string icono: ""
    property string etiqueta: ""
    property string atajo: ""
    signal activado()

    implicitWidth: 200
    implicitHeight: 300
    radius: 20

    color: mouse.containsMouse ? Theme.colorBotonHover : Theme.colorBoton
    border.width: 2
    border.color: mouse.containsMouse ? Theme.colorBordeHover : Theme.colorBorde
    scale: mouse.containsMouse ? 1.08 : 1.0
    z: mouse.containsMouse ? 1 : 0

    Behavior on color { ColorAnimation { duration: Theme.duracionColor } }
    Behavior on border.color { ColorAnimation { duration: Theme.duracionColor } }
    Behavior on scale {
        NumberAnimation {
            duration: Theme.duracionScale
            easing.type: Easing.OutBack
            easing.overshoot: 1.6
        }
    }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -12
        
        text: root.icono
        font.family: Theme.fuente
        font.pixelSize: 70
        color: mouse.containsMouse ? Theme.texto : Theme.textoSuave
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: Theme.fuente
            text: root.etiqueta
            color: Theme.texto
            font.pixelSize:18
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: Theme.fuente
            text: root.atajo
            color: Theme.textoTenue
            font.pixelSize: 13
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activado()
    }
}