pragma Singleton
// ---------------------------------------------------------------------------
//  LimiteCarga.qml  --  limitar la carga de la bateria (~80 %).
//
//  Igual que noctalia: no se escribe sysfs a mano (eso pide root), se usa el
//  metodo D-Bus de UPower `EnableChargeThreshold(b)`. Polkit lo permite sin
//  contrasena a la sesion activa (org.freedesktop.UPower.enable-charging-limit,
//  allow_active = yes).
//
//  En la Lenovo LOQ (ideapad_acpi) UPower lo traduce a
//      /sys/class/power_supply/BAT1/charge_types = Long_Life
//  que es el "modo conservacion" de Lenovo Vantage: el firmware corta en
//  ~80 % y el umbral NO es configurable. En otras laptops UPower usa
//  charge_control_{start,end}_threshold y ahi si se respeta ChargeEndThreshold.
//
//  Estado: se toma como activo si UPower lo dice O si el hardware ya esta en
//  modo conservacion (puede venir activado de fabrica / desde Windows sin que
//  UPower se entere).
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Io
import QtQuick
import qs.bar

Singleton {
    id: root

    property string ruta: ""          // objeto D-Bus de la bateria
    property bool soportado: false
    property bool activo: false
    property int  limite: 80          // % (en ideapad siempre ~80)
    property bool ocupado: false      // hay un cambio en vuelo
    property string error: ""

    readonly property string servicio: "org.freedesktop.UPower"
    readonly property string interfaz: "org.freedesktop.UPower.Device"

    function refrescar(): void { if (!leer.running) leer.running = true }

    function fijar(v: bool): void {
        if (!root.soportado || root.ocupado) return
        root.ocupado = true
        root.error = ""
        escribir.command = ["busctl", "call", root.servicio, root.ruta, root.interfaz,
                            "EnableChargeThreshold", "b", v ? "true" : "false"]
        escribir.running = true
    }
    function alternar(): void { root.fijar(!root.activo) }

    // Lee: ruta, soportado, habilitado, umbral fin y el charge_types del kernel
    Process {
        id: leer
        running: true
        command: ["sh", "-c", `
            p=$(upower -e 2>/dev/null | grep -m1 '/battery_')
            [ -z "$p" ] && { echo NONE; exit 0; }
            echo "PATH $p"
            busctl get-property ${root.servicio} "$p" ${root.interfaz} \
                ChargeThresholdSupported ChargeThresholdEnabled ChargeEndThreshold 2>/dev/null \
                | awk '{ print "P", $2 }'
            native=$(busctl get-property ${root.servicio} "$p" ${root.interfaz} NativePath 2>/dev/null | cut -d'"' -f2)
            ct=/sys/class/power_supply/$native/charge_types
            [ -r "$ct" ] && echo "CT $(grep -o '\\[[^]]*\\]' "$ct" | tr -d '[]')"
            cm=$(cat /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode 2>/dev/null | head -1)
            [ -n "$cm" ] && echo "CM $cm"`]
        stdout: StdioCollector {
            onStreamFinished: {
                const props = []
                let ct = "", cm = ""
                for (const l of this.text.split("\n")) {
                    const p = l.trim().split(/\s+/)
                    if (p[0] === "NONE") { root.soportado = false; return }
                    if (p[0] === "PATH") root.ruta = p[1]
                    else if (p[0] === "P") props.push(p[1])
                    else if (p[0] === "CT") ct = p[1]
                    else if (p[0] === "CM") cm = p[1]
                }
                root.soportado = props[0] === "true"
                const upower = props[1] === "true"
                const fin = Number(props[2]) || 0
                root.limite = (fin > 0 && fin < 100) ? fin : 80
                root.activo = upower || ct === "Long_Life" || cm === "1"
            }
        }
    }

    Process {
        id: escribir
        stderr: StdioCollector { id: errEscribir }
        onExited: (codigo, estado) => {
            root.ocupado = false
            if (codigo !== 0) root.error = errEscribir.text.trim() || "UPower rechazó el cambio"
            root.refrescar()
        }
    }

    // por si lo cambia otra cosa (Fn, noctalia, Windows...)
    Timer {
        interval: 30000
        running: root.soportado
        repeat: true
        onTriggered: root.refrescar()
    }
}
