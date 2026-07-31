// ~/.config/quickshell/mishell/shell.qml
import Quickshell
import Quickshell.Io
import QtQuick
import qs.logout
import qs.wallpaper

Scope {
    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup() }

        // Queremos errores para debug por lo que comentamos esta linea
        // function onReloadFailed(err) { Quickshell.inhibitReloadPopup() }
    }

    LogoutOverlay {}
    WallpaperPicker {}

    IpcHandler {

        target: "logout"

        function toggle(): void { LogoutState.alternar() }
        function open(): void { LogoutState.abrir() }
        function close(): void { LogoutState.cerrar() }
    }

    IpcHandler {

        target: "wallpaper"

        function toggle(): void { WallpaperState.alternar() }
        function open(): void { WallpaperState.abrir() }
        function close(): void { WallpaperState.cerrar() }
    }
}
