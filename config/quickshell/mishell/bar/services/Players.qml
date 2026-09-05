pragma Singleton
// ---------------------------------------------------------------------------
//  Players.qml  --  que reproductor MPRIS mostramos.
//
//  Con BarConfig.soloPlayerPreferido (por defecto) SOLO se muestra Spotify
//  (BarConfig.playerPreferido); Firefox, mpv y compania se ignoran aunque
//  esten sonando. Si lo apagas: preferido > el que este sonando > el primero.
//  `isPlaying` de un player no dispara re-evaluacion del modelo, por eso hay
//  un Timer ademas de la senal del modelo.
//
//  Tambien concentra las acciones (play/pausa, siguiente, aleatorio, repetir,
//  buscar) para que modulo y popups no repitan las comprobaciones de `can*`.
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

    // --- capacidades -------------------------------------------------------
    readonly property bool puedeBuscar:    hay && activo.canSeek && activo.canControl
                                        && activo.positionSupported && activo.lengthSupported
    readonly property bool puedeAleatorio: hay && activo.canControl && activo.shuffleSupported
    readonly property bool puedeRepetir:   hay && activo.canControl && activo.loopSupported
    readonly property bool aleatorio:      hay && activo.shuffle
    // MprisLoopState.None | Playlist | Track
    readonly property int  repetir:        hay ? activo.loopState : MprisLoopState.None

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
        let nuevo = pref
        if (!nuevo && !BarConfig.soloPlayerPreferido)
            nuevo = sonando ?? (lista.length ? lista[0] : null)
        if (nuevo !== root.activo) root.activo = nuevo
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.elegir() }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.elegir() }
    Component.onCompleted: elegir()

    // --- acciones ----------------------------------------------------------
    function alternar():  void { if (hay && activo.canTogglePlaying) activo.togglePlaying() }
    function siguiente(): void { if (hay && activo.canGoNext) activo.next() }
    function anterior():  void { if (hay && activo.canGoPrevious) activo.previous() }
    function mostrar():   void { if (hay && activo.canRaise) activo.raise() }

    // segundos absolutos dentro de la pista
    function buscar(seg: real): void {
        if (!root.puedeBuscar) return
        activo.position = Math.max(0, Math.min(activo.length, seg))
    }
    function alternarAleatorio(): void {
        if (root.puedeAleatorio) activo.shuffle = !activo.shuffle
    }
    // sin repetir -> lista -> una cancion -> sin repetir
    function ciclarRepetir(): void {
        if (!root.puedeRepetir) return
        switch (activo.loopState) {
            case MprisLoopState.None:     activo.loopState = MprisLoopState.Playlist; break
            case MprisLoopState.Playlist: activo.loopState = MprisLoopState.Track;    break
            default:                      activo.loopState = MprisLoopState.None;     break
        }
    }
}
