// ---------------------------------------------------------------------------
//  ClockPopup.qml  --  el "dashboard" chico del reloj: calendario + musica.
//  Inspirado en el dash de caelestia (calendario a la izquierda, portada y
//  controles a la derecha).
// ---------------------------------------------------------------------------
import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import qs.bar
import qs.bar.services

Row {
    id: root
    spacing: 18

    readonly property var loc: BarConfig.locale !== "" ? Qt.locale(BarConfig.locale) : Qt.locale()

    // ======================================================================
    //  CALENDARIO
    // ======================================================================
    Column {
        id: cal
        width: 268
        spacing: 4

        property date fecha: new Date()
        readonly property int mes: cal.fecha.getMonth()
        readonly property int anio: cal.fecha.getFullYear()
        readonly property bool esHoy: {
            const hoy = new Date()
            return cal.mes === hoy.getMonth() && cal.anio === hoy.getFullYear()
        }

        function mover(delta: int): void { cal.fecha = new Date(cal.anio, cal.mes + delta, 1) }
        function hoy(): void { cal.fecha = new Date() }
        function capitalizar(s: string): string { return s.charAt(0).toUpperCase() + s.slice(1) }

        // cabecera: < mes año >
        Item {
            width: parent.width
            height: 32

            Flecha { anchors.left: parent.left; icono: ""; onClic: cal.mover(-1) }

            Text {
                id: titulo
                anchors.centerIn: parent
                text: cal.capitalizar(root.loc.toString(cal.fecha, "MMMM yyyy"))
                color: cal.esHoy ? BarConfig.acento : BarConfig.texto
                font.family: BarConfig.fuente
                font.pixelSize: BarConfig.tamFuente
                font.bold: true
                Behavior on color { ColorAnimation { duration: 200 } }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cal.hoy()
                }
            }

            Flecha { anchors.right: parent.right; icono: ""; onClic: cal.mover(1) }
        }

        DayOfWeekRow {
            width: parent.width
            locale: root.loc
            delegate: Text {
                required property var model
                horizontalAlignment: Text.AlignHCenter
                text: cal.capitalizar(model.shortName.replace(".", ""))
                color: (model.day === 0 || model.day === 6) ? BarConfig.morado : BarConfig.textoTenue
                font.family: BarConfig.fuente
                font.pixelSize: BarConfig.tamFuente - 3
            }
        }

        // el grid entra deslizandose cuando cambias de mes
        Item {
            width: parent.width
            height: grid.implicitHeight
            clip: true

            MonthGrid {
                id: grid
                anchors.fill: parent
                month: cal.mes
                year: cal.anio
                locale: root.loc
                spacing: 2

                property real desliz: 0
                transform: Translate { x: grid.desliz }
                onMonthChanged: entrada.restart()
                SequentialAnimation {
                    id: entrada
                    PropertyAction { target: grid; property: "opacity"; value: 0 }
                    PropertyAction { target: grid; property: "desliz"; value: 24 }
                    ParallelAnimation {
                        NumberAnimation { target: grid; property: "desliz"; to: 0; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                        NumberAnimation { target: grid; property: "opacity"; to: 1; duration: 200 }
                    }
                }

                delegate: Item {
                    id: dia
                    required property var model
                    implicitWidth: 30
                    implicitHeight: 28

                    readonly property bool finde: model.date.getDay() === 0 || model.date.getDay() === 6
                    readonly property bool delMes: model.month === grid.month

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26; height: 26; radius: 13
                        color: dia.model.today ? BarConfig.acento : BarConfig.hover
                        opacity: dia.model.today ? 1 : (dm.containsMouse ? 1 : 0)
                        scale: dia.model.today ? 1 : (dm.containsMouse ? 1 : 0.6)
                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: dia.model.day
                        color: dia.model.today ? BarConfig.activoTexto
                             : dia.finde ? BarConfig.morado : BarConfig.texto
                        opacity: dia.delMes || dia.model.today ? 1 : 0.35
                        font.family: BarConfig.fuente
                        font.pixelSize: BarConfig.tamFuente - 2
                        font.bold: dia.model.today
                    }
                    MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }

        // rueda sobre el calendario: mes anterior / siguiente
        WheelHandler {
            target: null
            onWheel: e => cal.mover(e.angleDelta.y > 0 ? -1 : 1)
        }
    }

    component Flecha: Item {
        property string icono: ""
        signal clic()
        width: 28; height: 28
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            anchors.fill: parent
            radius: 14
            color: BarConfig.hover
            opacity: fm.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            anchors.centerIn: parent
            text: parent.icono
            color: BarConfig.texto
            font.family: BarConfig.fuente
            font.pixelSize: 14
        }
        scale: fm.pressed ? 0.85 : 1
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2 } }
        MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clic() }
    }

    Rectangle { width: 1; height: cal.height; color: BarConfig.popupBorde }

    // ======================================================================
    //  MUSICA
    // ======================================================================
    Column {
        id: musica
        width: 190
        spacing: 8

        readonly property var p: Players.activo
        readonly property real progreso: {
            const q = musica.p
            if (!q || !q.length) return 0
            return Math.max(0, Math.min(1, q.position / q.length))
        }
        function mmss(s: real): string {
            s = Math.max(0, Math.floor(s))
            const m = Math.floor(s / 60), r = s % 60
            return m + ":" + (r < 10 ? "0" : "") + r
        }

        // MprisPlayer.position no avisa solo: hay que pedirlo mientras suena
        Timer {
            interval: 1000
            running: root.visible && Players.sonando
            repeat: true
            triggeredOnStart: true
            onTriggered: if (Players.hay) Players.activo.positionChanged()
        }

        // portada
        ClippingRectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 150; height: 150
            radius: 14
            color: BarConfig.popupSuperficie

            Image {
                id: portada
                anchors.fill: parent
                source: Players.portada
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }
            Text {
                anchors.centerIn: parent
                visible: portada.status !== Image.Ready
                text: Players.hay ? "" : "󰝛"
                color: BarConfig.textoTenue
                font.family: BarConfig.fuente
                font.pixelSize: 48
            }

            // la portada "respira" mientras suena
            scale: Players.sonando ? 1 : 0.94
            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: Players.hay ? (Players.titulo || "Sin título") : "Nada sonando"
            color: BarConfig.texto
            font.family: BarConfig.fuente
            font.pixelSize: BarConfig.tamFuente
            font.bold: true
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: Players.hay ? (Players.artista || Players.activo.identity) : "Abre Spotify o cualquier reproductor"
            color: BarConfig.textoTenue
            font.family: BarConfig.fuente
            font.pixelSize: BarConfig.tamFuente - 3
        }

        // progreso
        Column {
            width: parent.width
            spacing: 3
            Rectangle {
                width: parent.width
                height: 5
                radius: 2.5
                color: BarConfig.popupSuperficie
                Rectangle {
                    width: parent.width * musica.progreso
                    height: parent.height
                    radius: parent.radius
                    color: BarConfig.acento
                    Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                }
            }
            Item {
                width: parent.width
                height: t1.implicitHeight
                Text { id: t1; anchors.left: parent.left; text: musica.p ? musica.mmss(musica.p.position) : "0:00"; color: BarConfig.textoTenue; font.family: BarConfig.fuente; font.pixelSize: 10 }
                Text { anchors.right: parent.right; text: musica.p && musica.p.length ? musica.mmss(musica.p.length) : "0:00"; color: BarConfig.textoTenue; font.family: BarConfig.fuente; font.pixelSize: 10 }
            }
        }

        // controles
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            Control { icono: "󰒮"; habilitado: Players.hay && Players.activo.canGoPrevious; onClic: Players.anterior() }
            Control {
                icono: Players.sonando ? "󰏤" : "󰐊"
                grande: true
                habilitado: Players.hay && Players.activo.canTogglePlaying
                onClic: Players.alternar()
            }
            Control { icono: "󰒭"; habilitado: Players.hay && Players.activo.canGoNext; onClic: Players.siguiente() }
        }
    }

    component Control: Item {
        property string icono: ""
        property bool grande: false
        property bool habilitado: true
        signal clic()
        width: grande ? 44 : 34
        height: width
        anchors.verticalCenter: parent.verticalCenter
        opacity: habilitado ? 1 : 0.35

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: parent.grande ? BarConfig.acento : BarConfig.popupSuperficie
        }
        Text {
            anchors.centerIn: parent
            text: parent.icono
            color: parent.grande ? BarConfig.activoTexto : BarConfig.texto
            font.family: BarConfig.fuente
            font.pixelSize: parent.grande ? 22 : 16
        }
        scale: cm.pressed ? 0.85 : (cm.containsMouse ? 1.1 : 1)
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
        MouseArea {
            id: cm
            anchors.fill: parent
            hoverEnabled: true
            enabled: parent.habilitado
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clic()
        }
    }
}
