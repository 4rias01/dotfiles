pragma Singleton
// ---------------------------------------------------------------------------
//  BarConfig.qml  --  TODO lo que vas a querer tocar de la barra esta aqui.
//
//  Singleton, igual que WallpaperConfig: se usa como `BarConfig.alto` desde
//  cualquier archivo de qs.bar.*. Los colores son FIJOS a proposito (no los
//  toca ucs): es el mismo look oscuro/blanco de la Waybar vieja, con los
//  acentos de Catppuccin Mocha que usa serpantinum por defecto.
// ---------------------------------------------------------------------------
import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string scriptsDir: home + "/.config/quickshell/mishell/bar/scripts"
    // $XDG_RUNTIME_DIR (/run/user/UID): se borra al cerrar sesion, asi que lo
    // que se guarde ahi sobrevive a recargas y reinicios de qs pero no a un
    // reinicio de la maquina.
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    // --- Arranque ----------------------------------------------------------
    // true = si al arrancar mishell ya hay un `waybar` corriendo, la barra
    // arranca oculta (util si vuelves a poner Waybar en el autostart).
    property bool ocultarSiHayWaybar: false

    // --- Escala global -----------------------------------------------------
    // 1.0 = tamano de diseno. 0.9 = la barra (pill, fuentes, iconos, tooltip)
    // un 10 % mas chica. Los POPUPS no la siguen: tienen tamano fijo. Las
    // medidas de abajo ya la aplican via s(); si agregas una medida nueva en
    // px de la barra, envuelvela igual.
    property real escala: 1.0
    function s(v: real): int { return Math.max(1, Math.round(v * escala)) }

    // --- Geometria ---------------------------------------------------------
    property int alto:               s(30)    // alto de cada burbuja (el "pill")
    property int margenSuperior:     s(3)     // aire entre el borde de la pantalla y la barra
    property int margenInferior:     s(2)     // no bajar de 0: el contenido (y el rebote del hover) se recorta
    // Cuanto se ACERCAN las ventanas a la barra: px que se restan a la zona
    // reservada, para que entren en el margen transparente. Hyprland suma
    // ademas sus gaps_out (10 en decoration.lua). Con 8, las ventanas quedan
    // a ~4 px del pill.
    property int recorteZona:        s(8)
    property int margenLateral:      s(10)    // aire a izquierda y derecha
    property int separacionBurbujas: s(35)    // entre burbujas del mismo lado
    property int paddingBurbuja:     s(5)     // relleno interno de la burbuja
    property int paddingModulo:      s(7)     // relleno interno de cada modulo
    property int separacionModulos:  s(5)     // entre modulos dentro de una burbuja
    property int radio:              s(9)     // radio de la burbuja
    property int radioModulo:        s(7)     // radio del fondo de hover de un modulo

    // --- Launcher ----------------------------------------------------------
    // CachyOS (nf-linux-cachyos). Para el de Arch: "\uf303".
    property string iconoLauncher: ""

    // --- Tipografia --------------------------------------------------------
    property string fuente:   "JetBrainsMono Nerd Font"
    property int    tamFuente: s(15)
    property int    tamIcono:  s(16)

    // --- Colores (fijos) ---------------------------------------------------
    property color fondo:        "#b3000008"   // rgba(0,0,8,.7), como la Waybar
    property color texto:        "#e8eaed"
    property color textoTenue:   "#9399b2"
    property color hover:        "#24ffffff"   // fondo del modulo bajo el mouse
    property color activoFondo:  "#e8eaed"     // workspace activo
    property color activoTexto:  "#121212"
    property color acento:       "#94e2d5"     // launcher, hoy en el calendario, switch
    property color verde:        "#a6e3a1"
    property color amarillo:     "#f9e2af"
    property color rojo:         "#f38ba8"
    property color naranja:      "#fab387"
    property color azul:         "#89b4fa"
    property color morado:       "#cba6f7"

    // Popups (burbujas que cuelgan de la barra)
    property color popupFondo:      "#f2181825"
    property color popupBorde:      "#45475a"
    property color popupSuperficie: "#313244"   // pistas de sliders, fondo del switch
    property int   popupRadio:      14
    property int   popupPadding:    14
    property int   popupSeparacion: 8           // aire entre la barra y el popup
    property int   popupCierreMs:   500         // cuanto espera sin mouse antes de cerrarse
    property int   popupCierreSinMouseMs: 4000  // si se abrio por IPC/bind y el mouse nunca entro

    // --- Animaciones ("burbuja") ------------------------------------------
    property int  durHover:    140    // fondo de hover
    property int  durPop:      280    // rebote de escala al pasar el mouse
    property real overshoot:   2.2    // cuanto se pasa el rebote (Easing.OutBack)
    property real escalaHover: 1.10
    property real escalaClic:  0.88
    property int  durAparecer: 460    // entrada de las burbujas al arrancar
    property int  cascada:     70     // retardo entre burbuja y burbuja al arrancar
    property int  durPopup:    300    // apertura de los popups
    property int  durAncho:    220    // cuando un modulo cambia de ancho

    // --- Workspaces --------------------------------------------------------
    // Igual que en la Waybar: 5 persistentes en todos los monitores salvo
    // los que esten en la tabla.
    property int workspacesPersistentes: 5
    property var workspacesPorMonitor: ({ "HDMI-A-1": 3 })
    property int anchoWorkspace: s(26)

    // --- Bateria -----------------------------------------------------------
    property int bateriaAviso:   25   // amarillo
    property int bateriaCritico: 10   // rojo
    property int bateriaParpadeo: 5   // desde aqui (y descargando) el modulo parpadea
    // Notificaciones tipo Windows. Se avisa UNA vez por umbral mientras se
    // descarga; al enchufar el cargador se reinician todos.
    property var umbralesNotificacion: [20, 10, 5, 1]
    property int umbralCritico: 5     // desde aqui la notificacion es "critical"
    // Donde se apunta "este umbral ya sono": un archivo y no memoria del
    // shell, porque cada cambio de wallpaper (ucs) recarga qs y la memoria
    // se perdia. Al cerrar sesion el archivo desaparece solo.
    property string archivoAvisosBateria: runtimeDir + "/mishell-bateria.json"
    // Sonido de los avisos ("" = sin sonido). Los .oga vienen con sound-theme-freedesktop.
    property var    cmdSonido:     ["paplay"]
    property string sonidoAviso:   "/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"
    property string sonidoCritico: "/usr/share/sounds/freedesktop/stereo/suspend-error.oga"

    // --- Reloj -------------------------------------------------------------
    // Formatos de Qt (no strftime). "AP" se reemplaza por AM/PM a mano, asi
    // no depende de lo que el locale opine del a.m./p.m.
    property string formatoHora:    "hh:mm AP"
    property string formatoHoraAlt: "ddd, dd. MMM  hh:mm"
    property string locale:         ""    // "" = el del sistema (es_MX)

    // --- Media (Spotify) ---------------------------------------------------
    property string playerPreferido: "spotify"
    // true  = SOLO se muestra el playerPreferido (Firefox, mpv, etc. se ignoran)
    // false = si no esta, se muestra el que este sonando o el primero que haya
    property bool   soloPlayerPreferido: true
    property int    mediaAnchoMax:   s(200)        // px antes de empezar a desplazar
    property real   mediaVelocidad:  28         // px por segundo del marquee
    property bool   mediaScrollSiempre: false   // true = desplaza aunque quepa
    property int    mediaPausaMs:    1500       // pausa al inicio de cada vuelta

    // --- Stats -------------------------------------------------------------
    // Cada cuanto se muestrean CPU/RAM/red/temp. Tambien es el paso de las
    // graficas del panel de sistema (puntosHistorial muestras = ventana:
    // 60 x 2 s = 2 minutos).
    property int    intervaloStats: 2000
    property int    intervaloInfo:  30000   // disco, uptime "lento", SO, kernel
    property int    intervaloGpu:   2000    // nvidia-smi / sysfs amdgpu
    property int    puntosHistorial: 60
    property int    intervaloDs4:   10000
    // Sensor de temperatura del CPU: el primer hwmon cuyo `name` coincida, en
    // este orden. k10temp = AMD (Lenovo LOQ), coretemp = Intel.
    property var    hwmonNombres: ["k10temp", "zenpower", "coretemp", "cpu_thermal", "acpitz"]
    property int    tempCritica: 100
    property int    gpuTempAviso: 85        // la GPU se pinta de rojo desde aqui

    // --- Panel de sistema -------------------------------------------------
    property color colorPanelTitulo:   "#b4befe"   // "Sistema"
    property color colorGraficaUso:    "#b4befe"   // lavanda: uso de CPU/RAM/GPU
    property color colorGraficaTemp:   "#eba0ac"   // salmon: temperaturas
    property color colorGraficaBajada: "#f5c2e7"   // rosa: red, bajada
    property color colorGraficaSubida: "#b4befe"   // lavanda: red, subida
    property color tarjetaFondo:       "#0effffff" // relleno de las tarjetas

    // --- Teclado -------------------------------------------------------------
    // Las distribuciones se eligen en hypr/modules/input.lua (kb_layout).
    // Aqui: como se ve cada una en la barra (por prefijo del nombre de xkb).
    property var tecladoEtiquetas: ({ "Spanish": "ES", "English": "EN" })
    property var tecladoNombres: ({
        "Spanish (Latin American)": "Español (Latinoamérica)",
        "Spanish": "Español",
        "English (US)": "Inglés (EE. UU.)",
        "English": "Inglés"
    })
    property int    ds4AjusteCarga: 20   // el mando reporta +20 mientras carga (ver ds4-battery.sh)

    // --- Brillo / volumen --------------------------------------------------
    property int pasoBrillo:  2     // % por tick de rueda
    property int pasoVolumen: 2
    property int volumenMax:  100

    // --- Comandos ----------------------------------------------------------
    property var    cmdLauncher:              [home + "/.config/rofi/launcher.sh"]   // clic derecho en el logo
    property var    cmdCpu:                   ["kitty", "-e", "btop"]
    property var    cmdRed:                   ["wifi-manager", "--toggle"]   // scripts/wifi_menu.sh es la alternativa con wofi
    property var    cmdBluetooth:             ["wifi-manager", "--toggle"]
    property var    cmdVolumenDerecho:        ["pavucontrol"]
    property var    cmdNotificaciones:        ["swaync-client", "-t", "-sw"]
    property var    cmdNotificacionesDerecho: ["swaync-client", "-d", "-sw"]
    property string archivoFileSharing:       home + "/.config/cache/file-sharing/.file-sharing-enabled"
    property var    cmdFileSharing:           [scriptsDir + "/file-sharing.sh", "toggle"]
    property var    sinksIgnorados:           ["Easy Effects Sink"]
}
