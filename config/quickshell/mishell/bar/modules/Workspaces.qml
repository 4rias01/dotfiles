// ---------------------------------------------------------------------------
//  Workspaces.qml  --  hyprland/workspaces.
//
//  Muestra siempre los N persistentes del monitor (BarConfig) mas cualquier
//  workspace que exista en ese monitor. El indicador del activo es UNA sola
//  burbuja clara que se desliza entre botones (con rebote), en vez de
//  pintar/despintar cada boton.
//
//  OJO: con la config de Hyprland en Lua, `hyprctl dispatch` ya no acepta
//  "workspace 2": lo envuelve en hl.dispatch(...) y espera una expresion
//  Lua. Por eso se manda hl.dsp.focus({ workspace = 2 }), igual que en
//  binds.lua.
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.bar

Item {
    id: root

    required property var pantalla          // ShellScreen de la barra

    readonly property var monitor: Hyprland.monitorFor(root.pantalla)
    readonly property int persistentes: BarConfig.workspacesPorMonitor[root.pantalla.name]
                                     ?? BarConfig.workspacesPersistentes
    readonly property int activoId: root.monitor?.activeWorkspace?.id ?? -1

    property var ids: []            // ids visibles, ordenados
    property var existentes: ({})   // id -> true si Hyprland lo tiene creado

    function recalcular(): void {
        const set = {}, ex = {}, arr = []
        for (let i = 1; i <= root.persistentes; i++) { set[i] = true; arr.push(i) }
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id <= 0) continue                                  // especiales
            if (ws.monitor && ws.monitor.name !== root.pantalla.name) continue
            ex[ws.id] = true
            if (!set[ws.id]) { set[ws.id] = true; arr.push(ws.id) }
        }
        arr.sort((a, b) => a - b)
        root.ids = arr
        root.existentes = ex
    }

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { root.recalcular() }
    }
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            // moveworkspace / createworkspace / destroyworkspace cambian el monitor
            if (ev.name.startsWith("moveworkspace") || ev.name.endsWith("workspace"))
                root.recalcular()
        }
    }
    onPersistentesChanged: recalcular()

    function ir(ws): void {
        const v = typeof ws === "number" ? ws : '"' + ws + '"'
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + v + " })")
    }
    Component.onCompleted: recalcular()

    height: parent ? parent.height : BarConfig.alto
    implicitWidth: fila.implicitWidth + 2 * BarConfig.paddingModulo
    width: implicitWidth
    Behavior on width { NumberAnimation { duration: BarConfig.durAncho; easing.type: Easing.OutCubic } }

    readonly property int indiceActivo: root.ids.indexOf(root.activoId)
    readonly property int paso: BarConfig.anchoWorkspace + fila.spacing

    // --- la burbuja del activo ----------------------------------------------
    Rectangle {
        id: indicador
        visible: root.indiceActivo >= 0
        x: fila.x + root.indiceActivo * root.paso
        y: 3
        width: BarConfig.anchoWorkspace
        height: parent.height - 6
        radius: BarConfig.radioModulo
        color: BarConfig.activoFondo
        Behavior on x {
            NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
        }
    }

    Row {
        id: fila
        x: BarConfig.paddingModulo
        height: parent.height
        spacing: 2

        Repeater {
            model: root.ids

            delegate: Item {
                id: boton
                required property int modelData
                readonly property bool activo: modelData === root.activoId
                readonly property bool existe: root.existentes[modelData] === true

                width: BarConfig.anchoWorkspace
                height: fila.height

                scale: m.pressed ? BarConfig.escalaClic : (m.containsMouse ? BarConfig.escalaHover : 1)
                Behavior on scale {
                    NumberAnimation { duration: BarConfig.durPop; easing.type: Easing.OutBack; easing.overshoot: BarConfig.overshoot }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 3
                    anchors.bottomMargin: 3
                    radius: BarConfig.radioModulo
                    color: BarConfig.hover
                    opacity: (m.containsMouse && !boton.activo) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: BarConfig.durHover } }
                }

                Text {
                    anchors.centerIn: parent
                    text: boton.modelData
                    font.family: BarConfig.fuente
                    font.pixelSize: BarConfig.tamFuente
                    font.bold: boton.activo
                    color: boton.activo ? BarConfig.activoTexto
                         : (boton.existe ? BarConfig.texto : BarConfig.textoTenue)
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    id: m
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.ir(boton.modelData)
                    onWheel: e => root.ir(e.angleDelta.y > 0 ? "e-1" : "e+1")
                }
            }
        }
    }
}
