// ---------------------------------------------------------------------------
//  Launcher.qml  --  el logo de CachyOS.
//  Clic: menu de apagado (logout/ de este mismo shell, via LogoutState).
//  Clic derecho: Rofi (BarConfig.cmdLauncher).
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell
import qs.bar
import qs.logout

Module {
    icono: BarConfig.iconoLauncher
    colorIcono: BarColors.logo
    tamIcono: BarConfig.tamIcono + 2
    tooltip: "Apagar / cerrar sesión\nClic derecho: launcher"
    onClic:        LogoutState.abrir()
    onClicDerecho: Quickshell.execDetached(BarConfig.cmdLauncher)
}
