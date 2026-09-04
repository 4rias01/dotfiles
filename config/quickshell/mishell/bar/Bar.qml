// ---------------------------------------------------------------------------
//  Bar.qml  --  la barra (reemplazo de Waybar).
//
//  Una PanelWindow por monitor con tres zonas, igual que la Waybar:
//
//    izquierda  [ launcher | workspaces ] [ bateria cpu ram temp ds4 ]
//    centro     [ reloj ]
//    derecha    [ spotify ] [ compartir red bluetooth brillo volumen notif ]
//
//  Cada [ ] es una Bubble (pill oscuro). Los popups cuelgan de su modulo y
//  se declaran aqui abajo, junto al tooltip. El aviso de bateria baja vive
//  fuera del Variants para que se dispare una sola vez y no una por monitor.
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.bar
import qs.bar.modules
import qs.bar.popups
import qs.bar.services

Scope {
    id: root

    BatteryNotifier { id: notificador }
    function probarBateria(pct: int): void { notificador.probar(pct) }

    // Convivencia con Waybar (ver BarConfig.ocultarSiHayWaybar)
    Process {
        command: ["pgrep", "-x", "waybar"]
        running: BarConfig.ocultarSiHayWaybar
        onExited: (codigo, estado) => { if (codigo === 0) BarState.ocultar() }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property string pantalla: win.screen.name

            // Registro del tooltip (lo llenan los modulos, lo dibuja Tooltip.qml)
            property Item   tooltipItem: null
            property string tooltipTexto: ""

            anchors { top: true; left: true; right: true }
            implicitHeight: BarConfig.alto + BarConfig.margenSuperior + BarConfig.margenInferior
            color: "transparent"

            WlrLayershell.namespace: "qs-bar"
            WlrLayershell.layer: WlrLayer.Top

            // Oculta: no reserva espacio y deja pasar los clics (mascara vacia).
            readonly property bool mostrada: BarState.visible
            exclusiveZone: mostrada ? Math.max(0, implicitHeight - BarConfig.recorteZona) : 0
            mask: Region {
                x: 0; y: 0
                width:  win.mostrada ? win.width  : 0
                height: win.mostrada ? win.height : 0
            }
            onMostradaChanged: if (!mostrada) BarState.cerrarPopup()

            Item {
                id: contenido
                anchors.fill: parent
                anchors.topMargin: BarConfig.margenSuperior
                anchors.bottomMargin: BarConfig.margenInferior

                // sube/baja con rebote al ocultar/mostrar
                transform: Translate {
                    y: win.mostrada ? 0 : -(win.height + 10)
                    Behavior on y {
                        NumberAnimation {
                            duration: 380
                            easing.type: win.mostrada ? Easing.OutBack : Easing.InBack
                            easing.overshoot: 1.2
                        }
                    }
                }

                // ---------------- izquierda ----------------
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: BarConfig.margenLateral
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: BarConfig.separacionBurbujas

                    Bubble {
                        retardo: 0
                        Launcher {}
                        Workspaces { pantalla: win.screen }
                    }

                    Bubble {
                        retardo: BarConfig.cascada
                        Battery { id: bateria; pantalla: win.pantalla }
                        Cpu {}
                        Memory {}
                        Temperature {}
                        Ds4Battery {}
                    }
                }

                // ---------------- centro -------------------
                Bubble {
                    anchors.centerIn: parent
                    retardo: BarConfig.cascada * 2
                    Clock { id: reloj; pantalla: win.pantalla }
                }

                // ---------------- derecha ------------------
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: BarConfig.margenLateral
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: BarConfig.separacionBurbujas

                    Bubble {
                        retardo: BarConfig.cascada * 3
                        Media {}
                    }

                    Bubble {
                        retardo: BarConfig.cascada * 4
                        Sharing {}
                        Network {}
                        Bluetooth {}
                        Backlight { id: brillo; pantalla: win.pantalla }
                        Volume { id: volumen; pantalla: win.pantalla }
                        Notifications {}
                    }
                }
            }

            // ---------------- popups -------------------
            Popup {
                nombre: "bateria"; pantalla: win.pantalla
                ancla: bateria; anclaHover: bateria.hovered
                BatteryPopup {}
            }

            Popup {
                nombre: "reloj"; pantalla: win.pantalla
                ancla: reloj; anclaHover: reloj.hovered
                ClockPopup {}
            }

            Popup {
                nombre: "brillo"; pantalla: win.pantalla
                ancla: brillo; anclaHover: brillo.hovered
                padding: 10
                SliderPopup {
                    icono: ""
                    valor: Brightness.valor / 100
                    paso: BarConfig.pasoBrillo / 100
                    onCambiar: v => Brightness.fijar(v * 100)
                }
            }

            Popup {
                nombre: "volumen"; pantalla: win.pantalla
                ancla: volumen; anclaHover: volumen.hovered
                padding: 10
                SliderPopup {
                    icono: volumen.icono
                    valor: volumen.vol
                    maximo: BarConfig.volumenMax / 100
                    apagado: volumen.mute
                    paso: BarConfig.pasoVolumen / 100
                    etiqueta: volumen.mute ? "mute" : Math.round(volumen.vol * 100) + "%"
                    onCambiar: v => volumen.fijar(v)
                    onClicIcono: volumen.alternarMute()
                }
            }

            Tooltip { barra: win }
        }
    }
}
