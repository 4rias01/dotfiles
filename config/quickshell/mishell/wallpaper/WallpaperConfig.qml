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

    // Nombre del symlink (dentro de cacheDir) que apunta al fondo actual, para
    // poder referenciarlo con una ruta fija (hyprlock, scripts, etc.). Va
    // aparte de cacheDir/current, que guarda la ruta del ORIGINAL como texto.
    //
    // El link NO apunta al original: apunta a su miniatura cacheada, la misma
    // que dibuja el carrusel (cacheDir/thumbs/<thumbHeight>/md5(ruta).jpg). Asi
    // es SIEMPRE un JPEG, y las cosas de afuera que solo saben abrir imagenes
    // -hyprlock, extractores de paleta- siguen funcionando cuando el fondo es
    // un video o un gif.
    property string currentLinkName: "current_symlink"

    // Nombre del chip para los archivos que estan sueltos en la raiz.
    property string etiquetaRaiz: "sueltos"

    // --- Que archivos se listan -------------------------------------------
    property var imageExtensions: ["jpg", "jpeg", "png", "webp"]
    property var videoExtensions: ["mp4", "mkv", "webm", "mov"]

    // Los gif van por el mismo camino que las imagenes: awww los anima solo, y
    // la miniatura sale de su primer frame. Para el picker cuentan como imagen,
    // asi que salen en "Todos" y en su carpeta, pero no en el chip "Video".
    // Estan en una lista aparte para poder quitarlos sin tocar el resto.
    property var gifExtensions: ["gif"]

    // Videos como fondo (requiere mpvpaper). En false, ni se listan y el chip
    // de la barra desaparece.
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
    //  --background=color deja OPACO lo que rodea al video. mpv conserva la
    //  proporcion, asi que un video mas panoramico que el monitor entra con
    //  barras arriba y abajo; sin esta opcion esas barras dependen de lo que
    //  traiga mpv por defecto (en 0.41, un tablero de ajedrez) y de si la capa
    //  admite transparencia, que era por donde se colaba el fondo anterior.
    //  El color ya es negro opaco por defecto (--background-color=#FF000000).
    //
    //  Si prefieres que el video LLENE la pantalla recortando lo que sobra a
    //  los lados en vez de entrar con barras, agrega --panscan=1.0.
    property string mpvpaperOptions: "no-audio --loop-file=inf --hwdec=auto --background=color"

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
    //     $WALL_THUMB -> la miniatura cacheada del fondo (siempre un JPEG; es
    //                    a donde apunta el symlink). Si el post-command tiene
    //                    que ABRIR el fondo -sacarle una paleta, por ejemplo-,
    //                    usa esta y no $WALLPAPER: con un mp4 o un gif la
    //                    herramienta de turno normalmente no puede.
    //
    //  Se corre con `bash -c`, asi que puedes meter varias lineas, pipes,
    //  condicionales, lo que quieras. El `|| true` evita que un comando que
    //  falle corte los siguientes.
    //
    //  NOTA: el picker no genera ni aplica paletas de color. De eso se encarga
    //  tu herramienta aparte; si algun dia quieres engancharla al cambio de
    //  fondo, este es el unico lugar donde hay que ponerlo.
    //  Las comillas no son opcionales: hay wallpapers con espacios en el nombre
    //  y sin ellas ucs recibiria dos argumentos.
    //
    //  A ucs se le pasa $WALL_THUMB y no $WALLPAPER a proposito: la miniatura
    //  siempre es un JPEG, asi que la paleta sale igual de un mp4 o un gif (con
    //  el original, ucs fallaba en silencio y te quedabas con los colores del
    //  fondo anterior). Los colores son los mismos: es la misma imagen, chica.
    property string postCommand: `
        ucs automatic --from-image "$WALL_THUMB" --mode shading --colors 7 || true
    `
}
