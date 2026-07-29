// ~/.config/quickshell/mishell/wallpaper/WallpaperState.qml
//
// Estado compartido del picker. Igual que LogoutState: el IpcHandler vive en
// shell.qml y solo toca este singleton, asi que la ventana no necesita saber
// quien la abre.
pragma Singleton
import Quickshell

Singleton {
    id: root

    property bool abierto: false

    function abrir(): void { root.abierto = true }
    function cerrar(): void { root.abierto = false }
    function alternar(): void { root.abierto = !root.abierto }
}
