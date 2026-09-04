// ---------------------------------------------------------------------------
//  Network.qml  --  wifi / cable via Quickshell.Networking (NetworkManager).
//  Clic: wifi-manager (con pulso). Clic derecho: apagar/encender el wifi.
//  `connected` de cada WifiNetwork no re-dispara bindings, por eso hay un
//  `tick` cada 5 s que fuerza la re-evaluacion.
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell
import Quickshell.Networking
import qs.bar

Module {
    id: root

    property int tick: 0
    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.tick++ }

    function dispositivo(tipo) {
        for (const d of Networking.devices.values) if (d.type === tipo) return d
        return null
    }
    readonly property var wifi:  { root.tick; return root.dispositivo(DeviceType.Wifi) }
    readonly property var cable: { root.tick; return root.dispositivo(DeviceType.Wired) }

    readonly property var redWifi: {
        root.tick
        if (!root.wifi || !root.wifi.connected) return null
        for (const n of root.wifi.networks.values) if (n.connected) return n
        return null
    }
    readonly property bool cableConectado: { root.tick; return root.cable ? root.cable.connected : false }
    readonly property bool wifiApagado: !Networking.wifiEnabled

    icono: root.wifiApagado ? "󱚼"
         : root.cableConectado ? "󰈀"
         : root.redWifi ? "" : "󰖪"
    texto: root.wifiApagado ? "off" : ""
    color: root.wifiApagado || (!root.redWifi && !root.cableConectado) ? BarConfig.textoTenue : BarConfig.texto

    tooltip: {
        root.tick
        if (root.wifiApagado) return "Wi-Fi apagado"
        if (root.redWifi) {
            const s = Math.round((root.redWifi.signalStrength ?? 0) * 100)
            return root.redWifi.name + " (" + s + "%) "
        }
        if (root.cableConectado) return (root.cable.name ?? "ethernet") + " "
        return "Desconectado"
    }

    onClic: { root.pulso(); Quickshell.execDetached(BarConfig.cmdRed) }
    onClicDerecho: Networking.wifiEnabled = !Networking.wifiEnabled
}
