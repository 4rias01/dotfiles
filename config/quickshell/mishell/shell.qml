// ~/.config/quickshell/mishell/shell.qml
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.logout
import qs.wallpaper
import qs.bar

Scope {
    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup() }

        // Queremos errores para debug por lo que comentamos esta linea
        // function onReloadFailed(err) { Quickshell.inhibitReloadPopup() }
    }

    LogoutOverlay {}
    WallpaperPicker { id: picker }
    Bar { id: barra }

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
        // moverse por el carrusel desde fuera (binds, pruebas): -1 / 1
        function step(dir: int): void { picker.stepToValid(dir) }
        function apply(): void { picker.applyCurrent() }
        function filter(nombre: string): void { picker.currentFilter = nombre }
    }

    IpcHandler {

        target: "bar"

        // (open/close y no show/hide: `show` es un subcomando de `qs ipc`)
        function toggle(): void { BarState.alternar() }
        function open(): void { BarState.mostrar() }
        function close(): void { BarState.ocultar() }
        // lo mismo que el clic derecho en el reloj, pero desde un bind
        function hora(): void { BarState.alternarHora() }
        // abre/cierra un popup en el monitor enfocado: bateria | reloj | media | brillo | volumen
        function popup(nombre: string): void {
            const m = Hyprland.focusedMonitor
            BarState.alternarPopup(nombre, m ? m.name : Quickshell.screens[0].name)
        }
        // simula el aviso de bateria baja: qs ipc -c mishell call bar probarBateria 10
        function probarBateria(pct: int): void { barra.probarBateria(pct) }
        // que umbrales de bateria ya avisaron en esta sesion (ver BatteryNotifier.qml)
        function estadoBateria(): string { return barra.estadoBateria() }
    }
}
