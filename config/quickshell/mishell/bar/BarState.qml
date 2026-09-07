pragma Singleton
// ---------------------------------------------------------------------------
//  BarState.qml  --  estado compartido de la barra.
//
//  Mismo patron que LogoutState/WallpaperState: el IpcHandler de shell.qml
//  solo toca esto; las ventanas reaccionan a las propiedades.
// ---------------------------------------------------------------------------
import Quickshell

Singleton {
    id: root

    // Mostrar/ocultar la barra entera (SUPER+ALT+SPACE, via IPC)
    property bool visible: true
    function mostrar():  void { root.visible = true }
    function ocultar():  void { root.visible = false }
    function alternar(): void { root.visible = !root.visible }

    // Formato de la hora (clic derecho en el reloj)
    property bool horaAlt: false
    function alternarHora(): void { root.horaAlt = !root.horaAlt }

    // Popup abierto. Solo puede haber uno a la vez en toda la sesion, y se
    // guarda en que pantalla esta para que los otros monitores no lo repitan.
    property string popupAbierto: ""
    property string popupPantalla: ""

    function abrirPopup(nombre: string, pantalla: string): void {
        root.popupAbierto = nombre
        root.popupPantalla = pantalla
    }
    function cerrarPopup(): void {
        root.popupAbierto = ""
        root.popupPantalla = ""
    }
    function alternarPopup(nombre: string, pantalla: string): void {
        if (root.popupAbierto === nombre && root.popupPantalla === pantalla)
            root.cerrarPopup()
        else
            root.abrirPopup(nombre, pantalla)
    }
    function popupActivo(nombre: string, pantalla: string): bool {
        return root.popupAbierto === nombre && root.popupPantalla === pantalla
    }
}
