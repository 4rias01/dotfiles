// ---------------------------------------------------------------------------
//  Battery.qml  --  bateria (UPower) + perfil de energia como sufijo.
//  Clic: popup con el switch ahorro / balanceado / rendimiento.
//  Colores: verde cargando, amarillo <= aviso, rojo <= critico. Parpadea solo
//  desde BarConfig.bateriaParpadeo (5 %) y descargando.
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell.Services.UPower
import qs.bar

Module {
    id: root

    required property string pantalla

    readonly property var  dev: UPower.displayDevice
    readonly property int  pct: dev.ready ? Math.round(dev.percentage * 100) : 0
    readonly property bool cargando: dev.state === UPowerDeviceState.Charging
                                  || dev.state === UPowerDeviceState.PendingCharge
    readonly property bool llena: dev.state === UPowerDeviceState.FullyCharged
    readonly property bool enchufada: cargando || llena || !UPower.onBattery

    readonly property var iconos:      ["󰂎", "󰁻", "󰁾", "󰂁", "󰁹"]
    readonly property var iconosCarga: ["󰢟", "󰂆", "󰢝", "󰂊", "󰂅"]
    readonly property int indice: Math.min(4, Math.floor(root.pct / 20))

    readonly property string perfilIcono: {
        switch (PowerProfiles.profile) {
            case PowerProfile.PowerSaver:  return "󰌪"
            case PowerProfile.Performance: return "󱓞"
            default:                       return "󰾅"
        }
    }
    readonly property color perfilColor: {
        switch (PowerProfiles.profile) {
            case PowerProfile.PowerSaver:  return BarConfig.verde
            case PowerProfile.Performance: return BarConfig.naranja
            default:                       return BarConfig.textoTenue
        }
    }

    visible: dev.ready && dev.isLaptopBattery

    icono: root.cargando ? root.iconosCarga[root.indice] : root.iconos[root.indice]
    texto: root.pct + "%"
    sufijo: root.perfilIcono
    colorSufijo: root.perfilColor

    color: root.cargando || root.llena ? BarConfig.verde
         : root.pct <= BarConfig.bateriaCritico ? BarConfig.rojo
         : root.pct <= BarConfig.bateriaAviso   ? BarConfig.amarillo
         : BarConfig.texto
    parpadeo: !root.enchufada && root.pct <= BarConfig.bateriaParpadeo

    activo: BarState.popupActivo("bateria", root.pantalla)
    tooltip: {
        if (root.llena) return "Cargada · " + PowerProfile.toString(PowerProfiles.profile)
        const s = root.cargando ? root.dev.timeToFull : root.dev.timeToEmpty
        const t = root.tiempo(s)
        return (root.cargando ? "Cargando" : "Descargando") + (t ? " · " + t : "")
    }

    function tiempo(seg: real): string {
        if (!seg || seg <= 0) return ""
        const h = Math.floor(seg / 3600), m = Math.floor(seg / 60) % 60
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }

    onClic: BarState.alternarPopup("bateria", root.pantalla)
}
