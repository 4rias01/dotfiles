pragma Singleton
// ---------------------------------------------------------------------------
//  Teclado.qml  --  distribucion de teclado activa (ES <-> EN).
//
//  Las distribuciones se definen en Hyprland (modules/input.lua):
//      kb_layout = "latam,us"
//  y aqui solo se lee cual esta activa y se pasa a la siguiente:
//    - al arrancar: `hyprctl devices -j`, teclado con main = true;
//    - en vivo: el evento `activelayout>>TECLADO,NOMBRE` del socket de
//      Hyprland (Hyprland.rawEvent), que llega cada vez que cambia;
//    - cambiar: `hyprctl switchxkblayout all next` (no es un dispatcher, asi
//      que funciona igual con la config en Lua).
//
//  Etiquetas cortas (ES / EN) en BarConfig.tecladoEtiquetas.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.bar

Singleton {
    id: root

    property string nombre: ""          // "Spanish (Latin American)"
    readonly property string corto: root.etiqueta(root.nombre)

    function etiqueta(n: string): string {
        if (n === "") return "--"
        const tabla = BarConfig.tecladoEtiquetas
        for (const clave in tabla)
            if (n.indexOf(clave) === 0) return tabla[clave]
        return n.slice(0, 2).toUpperCase()
    }

    // Nombre legible en espanol para el tooltip
    function legible(n: string): string {
        const tabla = BarConfig.tecladoNombres
        for (const clave in tabla)
            if (n.indexOf(clave) === 0) return tabla[clave]
        return n
    }

    function siguiente(): void {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
    }

    function refrescar(): void { leer.running = true }

    Process {
        id: leer
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text)
                    const ks = d.keyboards || []
                    const k = ks.find(x => x.main) || ks[0]
                    if (k) root.nombre = k.active_keymap
                } catch (e) {}
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(ev): void {
            if (ev.name === "activelayout") {
                // data = "nombre-del-teclado,Nombre del layout" (el teclado
                // puede tener comas, el layout no)
                const i = ev.data.lastIndexOf(",")
                if (i >= 0) root.nombre = ev.data.slice(i + 1)
            } else if (ev.name === "configreloaded") {
                // un reload puede cambiar la lista de layouts
                root.refrescar()
            }
        }
    }
}
