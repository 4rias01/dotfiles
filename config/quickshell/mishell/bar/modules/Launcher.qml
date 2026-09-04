// Boton de Rofi (custom/launcher de la Waybar)
import QtQuick
import Quickshell
import qs.bar

Module {
    icono: BarConfig.iconoLauncher
    colorIcono: BarColors.logo
    tamIcono: BarConfig.tamIcono + 2
    tooltip: "Launcher"
    onClic:        Quickshell.execDetached(BarConfig.cmdLauncher)
    onClicDerecho: Quickshell.execDetached(BarConfig.cmdLauncherDerecho)
}
