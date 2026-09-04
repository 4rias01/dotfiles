// Bluetooth: icono + N conectados / "off". Clic: wifi-manager (con pulso);
// clic derecho: encender/apagar el adaptador.
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.bar

Module {
    id: root

    property int tick: 0
    Timer { interval: 3000; running: true; repeat: true; onTriggered: root.tick++ }

    readonly property var adaptador: Bluetooth.defaultAdapter
    readonly property bool encendido: root.adaptador ? root.adaptador.enabled : false
    readonly property var conectados: {
        root.tick
        const r = []
        if (!root.adaptador) return r
        for (const d of root.adaptador.devices.values) if (d.connected) r.push(d)
        return r
    }

    visible: root.adaptador !== null
    icono: ""
    texto: !root.encendido ? "off" : (root.conectados.length > 0 ? String(root.conectados.length) : "")
    color: root.encendido ? (root.conectados.length > 0 ? BarConfig.azul : BarConfig.texto) : BarConfig.textoTenue

    tooltip: {
        root.tick
        if (!root.adaptador) return ""
        if (!root.encendido) return "Bluetooth apagado"
        if (root.conectados.length === 0) return root.adaptador.name + " · sin dispositivos"
        return root.conectados.map(d => d.name + (d.batteryAvailable ? "  " + Math.round(d.battery * 100) + "%" : "")).join("\n")
    }

    onClic: { root.pulso(); Quickshell.execDetached(BarConfig.cmdBluetooth) }
    onClicDerecho: if (root.adaptador) root.adaptador.enabled = !root.adaptador.enabled
}
