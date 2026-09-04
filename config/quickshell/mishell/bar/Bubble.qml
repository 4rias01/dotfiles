// ---------------------------------------------------------------------------
//  Bubble.qml  --  una "burbuja": el pill oscuro que agrupa modulos.
//  Equivale a los #group-* de la Waybar. Al arrancar entra con un rebote
//  (scale 0.5 -> 1 con OutBack) y `retardo` permite escalonar las burbujas.
//
//  Si la burbuja tiene UN solo modulo visible (reloj, reproductor), el rebote
//  del hover lo hace la burbuja entera y no el modulo: si no, el modulo
//  crecia mas que su propio pill. El modulo lo sabe por `solo` y se queda
//  quieto; aqui se sigue su `escalaObjetivo`.
// ---------------------------------------------------------------------------
import QtQuick
import qs.bar

Rectangle {
    id: root

    default property alias contenido: fila.data
    property int retardo: 0

    height: BarConfig.alto
    implicitWidth: fila.implicitWidth + 2 * BarConfig.paddingBurbuja
    width: implicitWidth
    radius: BarConfig.radio
    color: BarConfig.fondo

    // Si todos los modulos de adentro estan ocultos, la burbuja tambien
    visible: fila.implicitWidth > 0

    // --- un solo modulo: la burbuja rebota por el ------------------------------
    readonly property Item unico: {
        let u = null, n = 0
        for (const c of fila.children) {
            if (!c.visible) continue
            n++
            u = c
        }
        return n === 1 ? u : null
    }
    readonly property bool solo: root.unico !== null
    readonly property real escalaObjetivo: (root.unico && root.unico.escalaObjetivo !== undefined)
                                         ? root.unico.escalaObjetivo : 1
    property bool listo: false     // la animacion de entrada ya termino
    onEscalaObjetivoChanged: if (root.listo) root.rebotar()
    function rebotar(): void {
        hoverAnim.stop()
        hoverAnim.to = root.escalaObjetivo
        hoverAnim.start()
    }
    NumberAnimation {
        id: hoverAnim
        target: root
        property: "scale"
        duration: BarConfig.durPop
        easing.type: Easing.OutBack
        easing.overshoot: BarConfig.overshoot
    }

    Behavior on width {
        NumberAnimation { duration: BarConfig.durAncho; easing.type: Easing.OutCubic }
    }

    Row {
        id: fila
        anchors.centerIn: parent
        height: parent.height
        spacing: BarConfig.separacionModulos
    }

    // --- entrada -----------------------------------------------------------
    opacity: 0
    scale: 0.5
    transformOrigin: Item.Center

    SequentialAnimation {
        id: aparecer
        PauseAnimation { duration: root.retardo }
        ParallelAnimation {
            NumberAnimation {
                target: root; property: "scale"; to: 1
                duration: BarConfig.durAparecer
                easing.type: Easing.OutBack; easing.overshoot: 1.6
            }
            NumberAnimation { target: root; property: "opacity"; to: 1; duration: 220 }
        }
        onFinished: {
            root.listo = true
            if (root.escalaObjetivo !== 1) root.rebotar()
        }
    }
    Component.onCompleted: aparecer.start()
}
