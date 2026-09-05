// ---------------------------------------------------------------------------
//  Media.qml  --  lo que suena en Spotify (custom/mpd de la Waybar, por MPRIS).
//  Marquee real en pixeles: solo se desplaza si el texto no cabe (o si
//  BarConfig.mediaScrollSiempre).
//
//  Clic izquierdo (se cuentan dentro de BarConfig.multiClicMs):
//      1 clic  -> play / pausa
//      2 clics -> siguiente cancion
//      3 clics -> cancion anterior
//  Clic derecho: popup con portada, progreso arrastrable, aleatorio/repetir.
//  Clic medio: traer la ventana de Spotify.  Rueda: siguiente / anterior.
// ---------------------------------------------------------------------------
import QtQuick
import qs.bar
import qs.bar.services

Module {
    id: root

    required property string pantalla

    icono: !Players.hay ? "" : (Players.esSpotify ? "" : "")
    colorIcono: Players.sonando ? BarConfig.verde : BarConfig.texto
    tooltip: Players.hay ? (Players.linea + (Players.album ? "\n" + Players.album : "")) : ""
    activo: BarState.popupActivo("media", root.pantalla)

    // --- clics multiples ---------------------------------------------------
    //  No se puede usar doubleClicked del MouseArea: Qt lo manda ADEMAS del
    //  clicked, y no existe un "triple". Se cuentan a mano y se decide cuando
    //  pasa la ventana sin un clic nuevo.
    property int clics: 0
    Timer {
        id: multiClic
        interval: BarConfig.multiClicMs
        onTriggered: {
            const n = root.clics
            root.clics = 0
            if (n === 1)      Players.alternar()
            else if (n === 2) { root.pulso(); Players.siguiente() }
            else              { root.pulso(); Players.anterior() }
        }
    }
    onClic: { root.clics++; multiClic.restart() }

    onClicDerecho: BarState.alternarPopup("media", root.pantalla)
    onClicMedio:   Players.mostrar()
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
