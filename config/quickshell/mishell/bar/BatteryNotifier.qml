// ---------------------------------------------------------------------------
//  BatteryNotifier.qml  --  avisos de bateria baja "estilo Windows".
//
//  Umbrales en BarConfig.umbralesNotificacion (20, 10, 5, 1). Cada umbral
//  avisa UNA sola vez mientras se descarga; al enchufar el cargador se
//  reinician todos. Si al arrancar ya estamos por debajo de un umbral, avisa
//  igual. Se manda por notify-send (swaync lo muestra) con un id sincrono,
//  asi el aviso del 10% reemplaza al del 20% en vez de apilarse, y suena
//  BarConfig.sonidoAviso / sonidoCritico.
//
//  La memoria de "ya avise este umbral" vive en un ARCHIVO
//  (BarConfig.archivoAvisosBateria, dentro de $XDG_RUNTIME_DIR), no en el
//  shell: cada cambio de wallpaper corre ucs, ucs reescribe Theme.qml y
//  BarColors.qml y eso recarga qs. PersistentProperties sobrevivia a una
//  recarga limpia pero no a esa (dos recargas seguidas, la primera con el
//  archivo a medio escribir), y el aviso del umbral vigente volvia a sonar.
//  El archivo se lee de forma sincrona al crear este objeto y el sistema lo
//  borra al cerrar sesion, que es justo cuando queremos olvidarlo.
//
//  Para probar sin descargar la laptop:
//      qs ipc -c mishell call bar probarBateria 10     (solo la notificacion)
//      qs ipc -c mishell call bar estadoBateria        (que umbrales ya sonaron)
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.bar

Item {
    id: root

    readonly property var  dev: UPower.displayDevice
    readonly property int  pct: dev.ready ? Math.round(dev.percentage * 100) : 100
    readonly property bool descargando: dev.ready && dev.isLaptopBattery
                                     && UPower.onBattery
                                     && dev.state !== UPowerDeviceState.Charging
                                     && dev.state !== UPowerDeviceState.FullyCharged
                                     && dev.state !== UPowerDeviceState.PendingCharge

    FileView {
        id: archivo
        path: BarConfig.archivoAvisosBateria
        blockLoading: true      // leer ANTES del primer revisar()
        printErrors: false      // la primera vez de la sesion no existe
        adapter: JsonAdapter {
            id: memoria
            property list<int> avisados: []
        }
    }
    function guardar(lista): void {
        memoria.avisados = lista
        archivo.writeAdapter()
    }
    function estado(): string { return JSON.stringify(memoria.avisados) }

    onPctChanged: revisar()
    onDescargandoChanged: revisar()
    Component.onCompleted: revisar()

    function revisar(): void {
        if (!root.descargando) {
            if (memoria.avisados.length) root.guardar([])
            return
        }
        // el umbral mas bajo que ya cruzamos
        const umbrales = BarConfig.umbralesNotificacion.slice().sort((a, b) => b - a)
        let objetivo = -1
        for (const u of umbrales) if (root.pct <= u) objetivo = u
        if (objetivo < 0 || memoria.avisados.includes(objetivo)) return

        // marcar este y todos los de arriba (si saltamos de 25 a 8, el 20 y
        // el 10 no tienen que sonar despues)
        const nuevo = memoria.avisados.slice()
        for (const u of umbrales) if (u >= objetivo && !nuevo.includes(u)) nuevo.push(u)
        root.guardar(nuevo)
        root.notificar(objetivo, root.pct, root.dev.timeToEmpty)
    }

    function tiempo(seg: real): string {
        if (!seg || seg <= 0) return ""
        const h = Math.floor(seg / 3600), m = Math.floor(seg / 60) % 60
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }

    function notificar(umbral: int, pct: int, restante: real): void {
        const critico = umbral <= BarConfig.umbralCritico
        const t = root.tiempo(restante)
        let titulo, cuerpo, icono
        if (umbral <= 1) {
            titulo = "Batería casi agotada"
            cuerpo = "Queda un " + pct + " %. Guarda tu trabajo y conecta el cargador ahora."
            icono = "battery-empty"
        } else if (critico) {
            titulo = "Nivel de batería crítico"
            cuerpo = "Queda un " + pct + " %" + (t ? " (≈ " + t + ")" : "") + ". Conecta el cargador."
            icono = "battery-caution"
        } else {
            titulo = "Batería baja"
            cuerpo = "Queda un " + pct + " % de batería" + (t ? " (≈ " + t + ")" : "") + ". Conecta el cargador."
            icono = "battery-low"
        }
        Quickshell.execDetached([
            "notify-send",
            "-a", "Batería",
            "-u", critico ? "critical" : "normal",
            "-i", icono,
            "-h", "string:x-canonical-private-synchronous:bateria",
            "-h", "int:value:" + pct,
            titulo, cuerpo
        ])
        const sonido = critico ? BarConfig.sonidoCritico : BarConfig.sonidoAviso
        if (sonido !== "") Quickshell.execDetached(BarConfig.cmdSonido.concat([sonido]))
    }

    // Para probar desde IPC: simula estar en `pct` sin tocar el estado real.
    function probar(pct: int): void {
        const umbrales = BarConfig.umbralesNotificacion.slice().sort((a, b) => b - a)
        let objetivo = umbrales[0]
        for (const u of umbrales) if (pct <= u) objetivo = u
        root.notificar(objetivo, pct, root.dev.ready ? root.dev.timeToEmpty : 0)
    }
}
