// ~/.config/quickshell/mishell/shell.qml
import Quickshell
import Quickshell.Io

Scope {
    LogoutOverlay {}

    IpcHandler {
        target: "logout"

        function toggle(): void { LogoutState.alternar() }
        function open(): void { LogoutState.abrir() }
        function close(): void { LogoutState.cerrar() }
    }
}
