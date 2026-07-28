// ~/.config/quickshell/mishell/LogoutState.qml
pragma Singleton

import Quickshell

Singleton {
    id: root

    property bool abierto: false

    function abrir(): void { root.abierto = true }
    function cerrar(): void { root.abierto = false }
    function alternar(): void { root.abierto = !root.abierto }
    function ejecutar(comando) {
        root.cerrar()
        Quickshell.execDetached(comando)
    }
}
