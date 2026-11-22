// ---------------------------------------------------------------------------
//  BatteryPopup.qml  --  contenido del popup de la bateria.
//  Estado, tiempo restante, salud y el switch de perfil de energia
//  (power-profiles-daemon via Quickshell.Services.UPower.PowerProfiles).
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower
import qs.bar
import qs.bar.services

Column {
    id: root
    spacing: 10
    width: 270

    readonly property var  dev: UPower.displayDevice
    readonly property int  pct: dev.ready ? Math.round(dev.percentage * 100) : 0
    readonly property bool cargando: dev.state === UPowerDeviceState.Charging
    // enchufada pero sin cargar: llego al limite de carga (LimiteCarga)
    readonly property bool enPausa: dev.state === UPowerDeviceState.PendingCharge
    readonly property bool llena: dev.state === UPowerDeviceState.FullyCharged
    readonly property color colorEstado: root.cargando || root.llena || root.enPausa ? BarConfig.verde
                                       : root.pct <= BarConfig.bateriaCritico ? BarConfig.rojo
                                       : root.pct <= BarConfig.bateriaAviso   ? BarConfig.amarillo
                                       : BarConfig.texto

    // Quickshell no expone energy-full-design, asi que la salud (cuanta
    // capacidad le queda respecto a la de fabrica) se lee de sysfs cada vez
    // que se abre el popup.
    property int salud: -1
    onVisibleChanged: if (visible) LimiteCarga.refrescar()
    Process {
        command: ["sh", "-c", `
            for b in /sys/class/power_supply/BAT*; do
                for k in energy charge; do
                    f="$b/\${k}_full"; d="$b/\${k}_full_design"
                    [ -r "$f" ] && [ -r "$d" ] && { echo "$(cat "$f") $(cat "$d")"; exit 0; }
                done
            done`]
        running: root.visible
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split(/\s+/).map(Number)
                root.salud = (p.length === 2 && p[1] > 0) ? Math.round(100 * p[0] / p[1]) : -1
            }
        }
    }

    function tiempo(seg: real): string {
        if (!seg || seg <= 0) return "calculando…"
        const h = Math.floor(seg / 3600), m = Math.floor(seg / 60) % 60
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }

    // --- cabecera ------------------------------------------------------------
    Row {
        spacing: 12
        Text {
            text: root.enPausa ? "󰚥" : root.cargando ? "󰂄" : root.llena ? "󰁹"
                : ["󰂎", "󰁻", "󰁾", "󰂁", "󰁹"][Math.min(4, Math.floor(root.pct / 20))]
            color: root.colorEstado
            font.family: BarConfig.fuente
            font.pixelSize: 38
            anchors.verticalCenter: parent.verticalCenter
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Text {
                text: root.pct + " %"
                color: BarConfig.texto
                font.family: BarConfig.fuente
                font.pixelSize: 24
                font.bold: true
            }
            Text {
                text: root.llena ? "Cargada"
                    : root.enPausa ? "Enchufada · carga en pausa"
                    : root.cargando ? "Cargando · " + root.tiempo(root.dev.timeToFull)
                    : "Restante · " + root.tiempo(root.dev.timeToEmpty)
                color: BarConfig.textoTenue
                font.family: BarConfig.fuente
                font.pixelSize: BarConfig.tamFuente - 2
            }
        }
    }

    Rectangle { width: parent.width; height: 1; color: BarConfig.popupBorde }

    // --- datos -------------------------------------------------------------
    Grid {
        columns: 2
        columnSpacing: 14
        rowSpacing: 3

        Dato { etiqueta: "Salud" }
        Dato { valor: root.salud >= 0 ? root.salud + " %" : "—" }
        Dato { etiqueta: "Consumo" }
        Dato { valor: root.dev.changeRate > 0 ? root.dev.changeRate.toFixed(1) + " W" : "—" }
        Dato { etiqueta: "Capacidad" }
        Dato { valor: root.dev.energyCapacity > 0 ? root.dev.energyCapacity.toFixed(1) + " Wh" : "—" }
    }

    component Dato: Text {
        property string etiqueta: ""
        property string valor: ""
        text: etiqueta !== "" ? etiqueta : valor
        color: etiqueta !== "" ? BarConfig.textoTenue : BarConfig.texto
        font.family: BarConfig.fuente
        font.pixelSize: BarConfig.tamFuente - 2
    }

    // --- aviso de degradacion (tapa cerrada, temperatura) ------------------
    Text {
        visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
        width: parent.width
        wrapMode: Text.WordWrap
        text: "󰀦 Rendimiento limitado: " + PerformanceDegradationReason.toString(PowerProfiles.degradationReason)
        color: BarConfig.naranja
        font.family: BarConfig.fuente
        font.pixelSize: BarConfig.tamFuente - 3
    }

    // --- switch de perfil ----------------------------------------------------
    Text {
        text: "Modo de energía"
        color: BarConfig.textoTenue
        font.family: BarConfig.fuente
        font.pixelSize: BarConfig.tamFuente - 3
    }

    Rectangle {
        id: sw
        width: parent.width
        height: 46
        radius: height / 2
        color: BarConfig.popupSuperficie

        readonly property var perfiles: PowerProfiles.hasPerformanceProfile
            ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
            : [PowerProfile.PowerSaver, PowerProfile.Balanced]
        readonly property int indice: Math.max(0, sw.perfiles.indexOf(PowerProfiles.profile))
        readonly property real anchoSeg: (width - 8) / sw.perfiles.length

        // la burbuja que se desliza
        Rectangle {
            x: 4 + sw.indice * sw.anchoSeg
            y: 4
            width: sw.anchoSeg
            height: parent.height - 8
            radius: height / 2
            color: BarConfig.acento
            Behavior on x {
                NumberAnimation { duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
            }
        }

        Row {
            x: 4; y: 4
            Repeater {
                model: sw.perfiles
                delegate: Item {
                    id: seg
                    required property int modelData
                    required property int index
                    readonly property bool activo: seg.index === sw.indice
                    readonly property string icono: modelData === PowerProfile.PowerSaver ? "󰌪"
                                                  : modelData === PowerProfile.Performance ? "󱓞" : "󰾅"
                    readonly property string nombre: modelData === PowerProfile.PowerSaver ? "Ahorro"
                                                   : modelData === PowerProfile.Performance ? "Rendimiento" : "Balanceado"
                    width: sw.anchoSeg
                    height: sw.height - 8

                    scale: ma.pressed ? 0.92 : 1
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: -1
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: seg.icono
                            color: seg.activo ? BarConfig.activoTexto : BarConfig.texto
                            font.family: BarConfig.fuente
                            font.pixelSize: 16
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: seg.nombre
                            color: seg.activo ? BarConfig.activoTexto : BarConfig.textoTenue
                            font.family: BarConfig.fuente
                            font.pixelSize: 10
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: PowerProfiles.profile = seg.modelData
                    }
                }
            }
        }
    }
    // --- limite de carga (~80 %) ------------------------------------------
    //  UPower EnableChargeThreshold (ver services/LimiteCarga.qml). En la
    //  Lenovo es el "modo conservacion": el firmware corta en ~80 %.
    Rectangle { width: parent.width; height: 1; color: BarConfig.popupBorde; visible: LimiteCarga.soportado }

    Item {
        visible: LimiteCarga.soportado
        width: parent.width
        height: 40

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰂑"
                color: LimiteCarga.activo ? BarConfig.acento : BarConfig.textoTenue
                font.family: BarConfig.fuente
                font.pixelSize: 20
                Behavior on color { ColorAnimation { duration: 200 } }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: "Limitar carga al " + LimiteCarga.limite + " %"
                    color: BarConfig.texto
                    font.family: BarConfig.fuente
                    font.pixelSize: BarConfig.tamFuente - 2
                }
                Text {
                    text: LimiteCarga.error !== "" ? "Error: " + LimiteCarga.error
                        : LimiteCarga.activo ? "Ideal si pasa enchufada"
                        : "Carga hasta el 100 %"
                    color: LimiteCarga.error !== "" ? BarConfig.rojo : BarConfig.textoTenue
                    font.family: BarConfig.fuente
                    font.pixelSize: 10
                    width: 190
                    elide: Text.ElideRight
                }
            }
        }

        // switch
        Rectangle {
            id: interruptor
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 44; height: 24
            radius: height / 2
            color: LimiteCarga.activo ? BarConfig.acento : BarConfig.popupSuperficie
            opacity: LimiteCarga.ocupado ? 0.6 : 1
            Behavior on color { ColorAnimation { duration: 200 } }

            Rectangle {
                width: 18; height: 18
                radius: 9
                y: 3
                x: LimiteCarga.activo ? parent.width - width - 3 : 3
                color: LimiteCarga.activo ? BarConfig.activoTexto : BarConfig.texto
                Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            scale: maLimite.pressed ? 0.9 : 1
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 2 } }

            MouseArea {
                id: maLimite
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: LimiteCarga.alternar()
            }
        }
    }
}
