// ---------------------------------------------------------------------------
//  MediaPanel.qml  --  la columna de "lo que suena": portada, titulo, barra
//  de progreso ARRASTRABLE y controles (aleatorio, anterior, play, siguiente,
//  repetir). La usan MediaPopup (clic derecho en el modulo de Spotify) y la
//  mitad derecha de ClockPopup.
//
//  Progreso: MprisPlayer.position no avisa solo, se le pide cada segundo
//  mientras suena (positionChanged()). Al soltar el arrastre se manda el
//  seek y se sigue mostrando la posicion elegida un momento, para que la
//  barra no salte atras hasta que Spotify confirme.
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.bar
import qs.bar.services

Column {
    id: root
    width: 220
    spacing: 8

    property int tamPortada: 150

    readonly property var p: Players.activo
    readonly property real progreso: {
        const q = root.p
        if (!q || !q.length) return 0
        return Math.max(0, Math.min(1, q.position / q.length))
    }
    function mmss(s: real): string {
        s = Math.max(0, Math.floor(s))
        const m = Math.floor(s / 60), r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    //  Se pide tambien en pausa: si no, al abrir el popup con la cancion
    //  pausada la barra marcaba 0:00 hasta darle play.
    Timer {
        interval: 1000
        running: root.visible && Players.hay
        repeat: true
        triggeredOnStart: true
        onTriggered: if (Players.hay) Players.activo.positionChanged()
    }

    // ---------------- portada ----------------
    ClippingRectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.tamPortada; height: root.tamPortada
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
            text: Players.hay ? "" : "󰝛"
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
        text: Players.hay ? (Players.artista || Players.activo.identity) : "Abre Spotify"
        color: BarConfig.textoTenue
        font.family: BarConfig.fuente
        font.pixelSize: BarConfig.tamFuente - 3
    }

    // ---------------- progreso (arrastrable) ----------------
    Column {
        width: parent.width
        spacing: 3

        Item {
            id: barra
            width: parent.width
            height: 16          // zona de agarre mas alta que la barra dibujada

            property bool arrastrando: false
            property real prevista: 0
            readonly property bool  interactiva: Players.puedeBuscar
            readonly property bool  caliente: barra.arrastrando || (barra.interactiva && zona.containsMouse)
            readonly property real  frac: barra.arrastrando ? barra.prevista : root.progreso

            function fraccion(x: real): real { return Math.max(0, Math.min(1, x / barra.width)) }

            // tras soltar, mostrar lo elegido hasta que el player confirme
            Timer {
                id: soltar
                interval: 700
                onTriggered: {
                    barra.arrastrando = false
                    if (Players.hay) Players.activo.positionChanged()
                }
            }

            Rectangle {
                id: pista
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: barra.caliente ? 7 : 5
                radius: height / 2
                color: BarConfig.popupSuperficie
                Behavior on height { NumberAnimation { duration: 150 } }

                Rectangle {
                    width: parent.width * barra.frac
                    height: parent.height
                    radius: parent.radius
                    color: BarConfig.acento
                    Behavior on width {
                        enabled: !barra.arrastrando && !zona.pressed
                        NumberAnimation { duration: 900; easing.type: Easing.Linear }
                    }
                }
            }

            // el "pomo"
            Rectangle {
                width: 14; height: 14; radius: 7
                color: BarConfig.texto
                border.width: 2
                border.color: BarConfig.acento
                anchors.verticalCenter: parent.verticalCenter
                x: barra.frac * barra.width - width / 2
                scale: barra.caliente ? 1 : 0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2 } }
            }

            MouseArea {
                id: zona
                anchors.fill: parent
                hoverEnabled: true
                enabled: barra.interactiva
                cursorShape: Qt.PointingHandCursor
                onPressed: e => {
                    soltar.stop()
                    barra.arrastrando = true
                    barra.prevista = barra.fraccion(e.x)
                }
                onPositionChanged: e => { if (pressed) barra.prevista = barra.fraccion(e.x) }
                onReleased: e => {
                    barra.prevista = barra.fraccion(e.x)
                    if (root.p) Players.buscar(barra.prevista * root.p.length)
                    soltar.restart()
                }
                onCanceled: { barra.arrastrando = false; soltar.stop() }
            }
        }

        Item {
            width: parent.width
            height: t1.implicitHeight
            Text {
                id: t1
                anchors.left: parent.left
                text: root.p ? root.mmss(barra.arrastrando ? barra.prevista * root.p.length : root.p.position) : "0:00"
                color: barra.arrastrando ? BarConfig.acento : BarConfig.textoTenue
                font.family: BarConfig.fuente
                font.pixelSize: 10
            }
            Text {
                anchors.right: parent.right
                text: root.p && root.p.length ? root.mmss(root.p.length) : "0:00"
                color: BarConfig.textoTenue
                font.family: BarConfig.fuente
                font.pixelSize: 10
            }
        }
    }

    // ---------------- controles ----------------
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Control {
            icono: "󰒝"
            chico: true
            activo: Players.aleatorio
            habilitado: Players.puedeAleatorio
            onClic: Players.alternarAleatorio()
        }
        Control { icono: "󰒮"; habilitado: Players.hay && Players.activo.canGoPrevious; onClic: Players.anterior() }
        Control {
            icono: Players.sonando ? "󰏤" : "󰐊"
            grande: true
            habilitado: Players.hay && Players.activo.canTogglePlaying
            onClic: Players.alternar()
        }
        Control { icono: "󰒭"; habilitado: Players.hay && Players.activo.canGoNext; onClic: Players.siguiente() }
        Control {
            // sin repetir / lista / una cancion
            icono: Players.repetir === MprisLoopState.Track ? "󰑘"
                 : Players.repetir === MprisLoopState.Playlist ? "󰑖" : "󰑗"
            chico: true
            activo: Players.repetir !== MprisLoopState.None
            habilitado: Players.puedeRepetir
            onClic: Players.ciclarRepetir()
        }
    }

    component Control: Item {
        id: ctl
        property string icono: ""
        property bool grande: false
        property bool chico: false      // aleatorio / repetir: sin fondo, mas discretos
        property bool activo: false     // aleatorio / repetir encendidos
        property bool habilitado: true
        signal clic()
        width: grande ? 44 : (chico ? 30 : 34)
        height: width
        anchors.verticalCenter: parent.verticalCenter
        opacity: habilitado ? 1 : 0.35

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: ctl.grande ? BarConfig.acento : BarConfig.popupSuperficie
            opacity: ctl.chico ? (cm.containsMouse ? 0.6 : 0) : 1
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            anchors.centerIn: parent
            text: ctl.icono
            color: ctl.grande ? BarConfig.activoTexto
                 : ctl.activo ? BarConfig.acento : BarConfig.texto
            font.family: BarConfig.fuente
            font.pixelSize: ctl.grande ? 22 : 16
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        // puntito bajo aleatorio/repetir cuando estan activos
        Rectangle {
            visible: ctl.chico
            width: 4; height: 4; radius: 2
            color: BarConfig.acento
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            scale: ctl.activo ? 1 : 0
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
        }
        scale: cm.pressed ? 0.85 : (cm.containsMouse ? 1.1 : 1)
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
        MouseArea {
            id: cm
            anchors.fill: parent
            hoverEnabled: true
            enabled: ctl.habilitado
            cursorShape: Qt.PointingHandCursor
            onClicked: ctl.clic()
        }
    }
}
