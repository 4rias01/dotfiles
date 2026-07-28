import QtQuick

Rectangle {
    id: root

    property string icono: ""
    property string etiqueta: ""
    property string atajo: ""
    signal activado()

    implicitWidth: 200
    implicitHeight: 300
    radius: 20

    color: mouse.containsMouse ? "#00287f" : "#001d62"
    border.width: 2
    border.color: mouse.containsMouse ? "#89b4fa" : "#313244"
    scale: mouse.containsMouse ? 1.08 : 1.0
    z: mouse.containsMouse ? 1 : 0

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on scale {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutBack
            easing.overshoot: 1.6
        }
    }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -12
        
        text: root.icono
        font.family: "JetbrainsMono Nerd Font"
        font.pixelSize: 70
        color: mouse.containsMouse ? "#cba6f7" : "#bac2de"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: "JetbrainsMono Nerd Font"
            text: root.etiqueta
            color: "#cdd6f4"
            font.pixelSize:18
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: "JetbrainsMono Nerd Font"
            text: root.atajo
            color: "#6c7086"
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