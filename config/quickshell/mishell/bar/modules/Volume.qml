// ---------------------------------------------------------------------------
//  Volume.qml  --  sink por defecto de Pipewire.
//  Rueda: +-paso. Clic: slider. Clic medio: mute. Clic derecho: pavucontrol.
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.bar
import qs.bar.services

Module {
    id: root
    required property string pantalla

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    readonly property bool listo: root.sink && root.sink.ready && root.sink.audio
    readonly property real vol: listo ? root.sink.audio.volume : 0
    readonly property bool mute: listo ? root.sink.audio.muted : false
    readonly property int  pct: Math.round(root.vol * 100)
    readonly property bool bluetooth: listo && (root.sink.name ?? "").startsWith("bluez")

    visible: root.listo
    icono: root.mute ? "󰝟" : root.bluetooth ? "󰋋" : (root.pct < 50 ? "" : "")
    texto: root.mute ? "" : root.pct + "%"
    color: root.mute ? BarConfig.textoTenue : BarConfig.texto
    popAlCambiar: true
    activo: BarState.popupActivo("volumen", root.pantalla)
    tooltip: listo ? (root.sink.description ?? root.sink.name) : ""

    function fijar(p: real): void {
        if (!root.listo) return
        root.sink.audio.volume = Math.max(0, Math.min(BarConfig.volumenMax / 100, p))
    }
    function alternarMute(): void { if (root.listo) root.sink.audio.muted = !root.sink.audio.muted }

    onRueda: d => root.fijar(root.vol + d * BarConfig.pasoVolumen / 100)
    onClic: BarState.alternarPopup("volumen", root.pantalla)
    onClicMedio: root.alternarMute()
    onClicDerecho: Quickshell.execDetached(BarConfig.cmdVolumenDerecho)
}
