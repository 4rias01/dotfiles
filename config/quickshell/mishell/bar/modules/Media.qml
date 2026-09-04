// ---------------------------------------------------------------------------
//  Media.qml  --  lo que suena (custom/mpd de la Waybar, pero por MPRIS).
//  Marquee real en pixeles: solo se desplaza si el texto no cabe (o si
//  BarConfig.mediaScrollSiempre). Clic: play/pause. Rueda: siguiente /
//  anterior. Clic derecho: traer la ventana del reproductor.
// ---------------------------------------------------------------------------
import QtQuick
import qs.bar
import qs.bar.services

Module {
    id: root

    icono: !Players.hay ? "" : (Players.esSpotify ? "" : "")
    colorIcono: Players.sonando ? BarConfig.verde : BarConfig.texto
    tooltip: Players.hay ? (Players.linea + (Players.album ? "\n" + Players.album : "")) : ""

    onClic:        Players.alternar()
    onClicDerecho: Players.mostrar()
    onRueda: d => d > 0 ? Players.siguiente() : Players.anterior()

    extra: Item {
        id: marquee

        readonly property string t: Players.hay ? Players.linea : "Music Off"
        readonly property real  anchoTexto: medida.implicitWidth
        readonly property bool  desplazar: Players.hay
            && (BarConfig.mediaScrollSiempre || marquee.anchoTexto > BarConfig.mediaAnchoMax)
        readonly property real  gap: 32

        width: Math.min(marquee.anchoTexto, BarConfig.mediaAnchoMax)
        height: root.height
        clip: true

        Text {
            id: medida
            visible: false
            text: marquee.t
            font.family: BarConfig.fuente
            font.pixelSize: BarConfig.tamFuente
        }

        Item {
            id: pista
            height: parent.height
            width: marquee.anchoTexto * 2 + marquee.gap

            Text {
                id: a
                text: marquee.t
                color: BarConfig.texto
                font.family: BarConfig.fuente
                font.pixelSize: BarConfig.tamFuente
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: marquee.desplazar
                text: marquee.t
                color: BarConfig.texto
                font.family: BarConfig.fuente
                font.pixelSize: BarConfig.tamFuente
                anchors.verticalCenter: parent.verticalCenter
                x: marquee.anchoTexto + marquee.gap
            }
        }

        SequentialAnimation {
            id: anim
            running: marquee.desplazar
            loops: Animation.Infinite
            PropertyAction { target: pista; property: "x"; value: 0 }
            PauseAnimation { duration: BarConfig.mediaPausaMs }
            NumberAnimation {
                target: pista; property: "x"
                to: -(marquee.anchoTexto + marquee.gap)
                duration: Math.max(500, (marquee.anchoTexto + marquee.gap) / BarConfig.mediaVelocidad * 1000)
            }
            onRunningChanged: if (!running) pista.x = 0
        }
        onTChanged: if (marquee.desplazar) anim.restart()
    }
}
