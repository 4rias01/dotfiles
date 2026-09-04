pragma Singleton
// ---------------------------------------------------------------------------
//  Players.qml  --  que reproductor MPRIS mostramos.
//
//  Prioridad: BarConfig.playerPreferido (spotify) > el que este sonando >
//  el primero que haya. `isPlaying` de un player no dispara re-evaluacion
//  del modelo, por eso hay un Timer ademas de la senal del modelo.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import qs.bar

Singleton {
    id: root

    property var activo: null
    readonly property bool hay: activo !== null
    readonly property bool sonando: hay && activo.isPlaying
    readonly property bool esSpotify: hay && (activo.identity || "").toLowerCase().includes("spotify")

    readonly property string titulo:  hay ? (activo.trackTitle  || "") : ""
    readonly property string artista: hay ? (activo.trackArtist || "") : ""
    readonly property string album:   hay ? (activo.trackAlbum  || "") : ""
    readonly property string portada: hay ? (activo.trackArtUrl || "") : ""
    readonly property string linea: {
        if (!hay) return ""
        if (artista && titulo) return artista + " - " + titulo
        return titulo || artista || activo.identity
    }

    function esPreferido(p): bool {
        const q = BarConfig.playerPreferido.toLowerCase()
        if (!q) return false
        return (p.identity || "").toLowerCase().includes(q)
            || (p.dbusName || "").toLowerCase().includes(q)
            || (p.desktopEntry || "").toLowerCase().includes(q)
    }

    function elegir(): void {
        const lista = Mpris.players.values
        let pref = null, sonando = null
        for (const p of lista) {
            if (!pref && root.esPreferido(p)) pref = p
            if (!sonando && p.isPlaying) sonando = p
        }
        const nuevo = pref ?? sonando ?? (lista.length ? lista[0] : null)
        if (nuevo !== root.activo) root.activo = nuevo
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.elegir() }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.elegir() }
    Component.onCompleted: elegir()

    function alternar():  void { if (hay && activo.canTogglePlaying) activo.togglePlaying() }
    function siguiente(): void { if (hay && activo.canGoNext) activo.next() }
    function anterior():  void { if (hay && activo.canGoPrevious) activo.previous() }
    function mostrar():   void { if (hay && activo.canRaise) activo.raise() }
}
