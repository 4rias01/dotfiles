// ---------------------------------------------------------------------------
//  WallpaperConfig.qml  --  TODO lo que vas a querer tocar esta aqui.
//
//  Singleton, igual que Theme y WallpaperState: se usa como
//  `WallpaperConfig.wallpaperDir` desde cualquier archivo de qs.wallpaper.
// ---------------------------------------------------------------------------
pragma Singleton
import Quickshell

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // --- Rutas -------------------------------------------------------------
    // Respeta $WALLPAPER_DIR si existe; si no, la carpeta de fondos de hypr.
    // Se escanea RECURSIVAMENTE, asi que las subcarpetas (chainsaw, steins,
    // jujutsu, ...) entran solas y aparecen como chips de filtro en la barra.
    property string wallpaperDir: {
        const env = Quickshell.env("WALLPAPER_DIR")
        return (env && env !== "") ? env : home + "/.config/hypr/wp"
    }
    property string cacheDir: home + "/.cache/quickshell-wallpaper"

    // Nombre del chip para los archivos que estan sueltos en la raiz.
    property string etiquetaRaiz: "sueltos"

    // --- Que archivos se listan -------------------------------------------
    property var imageExtensions: ["jpg", "jpeg", "png", "webp"]
    property var videoExtensions: ["mp4", "mkv", "webm", "mov"]

    // Videos como fondo (requiere mpvpaper). En false, ni se listan.
    property bool enableVideo: true

    // --- Miniaturas --------------------------------------------------------
    //  El picker NUNCA lee los archivos originales para dibujar el carrusel:
    //  usa una copia chica en cacheDir/thumbs (ver scripts/thumbs.sh). Sin
    //  esto, cada tarjeta decodifica un 4K de varios MB y tarda segundos.
    property int thumbHeight: 500   // alto de la miniatura cacheada, en px
    property int thumbJobs: 0       // procesos en paralelo; 0 = tantos como nucleos

    // --- Backend de wallpaper ---------------------------------------------
    // Imagenes: awww  (el fork de swww; necesita `awww-daemon` corriendo, el
    //                  script lo levanta solo si no responde)
    // Videos:   mpvpaper
    property var transitions: ["fade", "wipe", "grow", "center", "outer", "wave", "random"]
    property int  transitionFps: 120
    property real transitionDuration: 1.2
    property string mpvpaperOptions: "no-audio --loop-file=inf --hwdec=auto"

    // Como encaja la imagen en la pantalla:
    //   smartResize true  -> misma regla que tu smart_fill.sh: si la imagen es
    //                        mas "angosta" que el monitor se recorta (crop),
    //                        si es mas ancha entra completa con barras (fit).
    //   smartResize false -> se usa resizeMode siempre.
    property bool smartResize: true
    property string resizeMode: "crop"      // crop | fit | no

    // --- POST-COMMAND ------------------------------------------------------
    //  Se ejecuta DESPUES de que awww/mpvpaper aplica el fondo.
    //  Variables disponibles dentro del script:
    //     $WALLPAPER  -> ruta absoluta del archivo aplicado
    //     $WALL_NAME  -> nombre del archivo (sin ruta)
    //     $CACHE_DIR  -> directorio de cache del picker
    //
    //  Se corre con `bash -c`, asi que puedes meter varias lineas, pipes,
    //  condicionales, lo que quieras. El `|| true` evita que un comando que
    //  falle corte los siguientes.
    //
    //  NOTA: el picker no genera ni aplica paletas de color. De eso se encarga
    //  tu herramienta aparte; si algun dia quieres engancharla al cambio de
    //  fondo, este es el unico lugar donde hay que ponerlo.
    //  Las comillas de "$WALLPAPER" no son opcionales: hay wallpapers con
    //  espacios en el nombre y sin ellas ucs recibiria dos argumentos.
    property string postCommand: `
        ucs automatic --from-image "$WALLPAPER" --mode shading --colors 7 || true
    `
}
