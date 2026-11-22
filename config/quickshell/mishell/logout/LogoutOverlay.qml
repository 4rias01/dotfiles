// ~/.config/quickshell/mishell/LogoutOverlay.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.logout
import qs.config

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData

        visible: LogoutState.abierto

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Theme.velo

            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    LogoutState.cerrar()
                    event.accepted = true
                    return
                }

                if (!event.text) return
                const pulsada = event.text.toLowerCase()

                for (let i = 0; i < grid.children.length; i++) {
                    const boton = grid.children[i]
                    if (boton.atajo && boton.atajo.toLowerCase() === pulsada) {
                        boton.activado()
                        event.accepted = true
                        return
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: LogoutState.cerrar()
            }

            Rectangle{
                anchors.fill: grid
                color: Theme.colorBoton
                radius: 40
            }

            Grid {
                columns: 6
                id: grid
                anchors.centerIn: parent
                spacing: 2

                LogoutButton {
                    icono: "\uf023"
                    etiqueta: "Bloquear"
                    atajo: "L"
                    onActivado: LogoutState.ejecutar(["hyprlock"])
                }
                LogoutButton {
                    icono: "\uf08b"
                    etiqueta: "Cerrar sesión"
                    atajo: "E"
                    // uwsm solo si la sesion la maneja uwsm (existe su unidad
                    // wayland-wm@...). Con greetd + start-hyprland (Lenovo)
                    // se sale directo de Hyprland. Ojo: `uwsm check is-active`
                    // da verdadero aunque no haya uwsm (mira graphical-session).
                    onActivado: LogoutState.ejecutar(["sh", "-c",
                        "if systemctl --user -q is-active 'wayland-wm@*.service'; then uwsm stop; "
                        + "else hyprctl dispatch 'hl.dsp.exit()'; fi"])
                }
                LogoutButton {
                    icono: "\uf04c"
                    etiqueta: "Suspender"
                    atajo: "S"
                    onActivado: LogoutState.ejecutar(["systemctl", "suspend"])
                }
                LogoutButton {
                    icono: "\uf2dc"
                    etiqueta: "Hibernar"
                    atajo: "H"
                    onActivado: LogoutState.ejecutar(["systemctl", "hibernate"])
                }
                LogoutButton {
                    icono: "\uf021"
                    etiqueta: "Reiniciar"
                    atajo: "R"
                    onActivado: LogoutState.ejecutar(["systemctl", "reboot"])
                }
                LogoutButton {
                    icono: "\uf011"
                    etiqueta: "Apagar"
                    atajo: "P"
                    onActivado: LogoutState.ejecutar(["systemctl", "poweroff"])
                }
            }
        }
    }
}
