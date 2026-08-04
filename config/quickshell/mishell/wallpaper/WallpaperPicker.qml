// ---------------------------------------------------------------------------
//  WallpaperPicker.qml
//
//  Selector de wallpapers estilo "carrusel inclinado".
//  Inspirado en el picker de github.com/ilyamiro/nixos-configuration
//
//  IDEA CLAVE DEL EFECTO VISUAL (la unica parte "rara" de todo el archivo):
//
//    1. Cada tarjeta se deforma con una matriz de CIZALLA (shear):
//           x' = x + k*y      con k = -0.35
//       Eso convierte el rectangulo en un paralelogramo inclinado.
//
//    2. La imagen que va DENTRO se deforma con -k (la cizalla inversa),
//       asi que se ve recta. Lo unico inclinado es el recorte.
//
//    Resultado: paralelogramos con la foto sin distorsionar dentro.
//
//  Los colores salen de qs.config.Theme (paleta fija). Aqui NO se genera ni
//  se aplica ninguna paleta: de los colores del sistema se encarga tu
//  herramienta aparte.
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.wallpaper

PanelWindow {
    id: root

    // ======================================================================
    //  1. VENTANA
    // ======================================================================
    readonly property bool shown: WallpaperState.abierto
    visible: shown

    // Ocupar toda la pantalla: anclando a los 4 lados el compositor estira
    // la capa hasta llenar el monitor.
    anchors { top: true; bottom: true; left: true; right: true }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore        // no reservar espacio (no empujar ventanas)
    WlrLayershell.layer: WlrLayer.Overlay      // por encima de todo
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "qs-wallpaper"    // para reglas en hyprland.conf

    onShownChanged: {
        if (shown) {
            root.readCurrent()                 // en que wallpaper estamos
            root.rescan()                      // relee la carpeta al abrir
            Qt.callLater(() => view.forceActiveFocus())
        } else {
            searchInput.text = ""
            root.searchQuery = ""
            root.searchOpen = false
        }
    }

    // ======================================================================
    //  2. ESCALADO
    //     Todo tamaño pasa por s(): asi el diseño (pensado en 1080p) se
    //     adapta a 1440p/4K sin tocar numeros a mano.
    // ======================================================================
    readonly property real scaleFactor: {
        const w = root.screen ? root.screen.width : 1920
        return Math.max(0.65, Math.min(2.2, w / 1920))
    }
    function s(v) { return Math.round(v * root.scaleFactor) }

    // ======================================================================
    //  3. GEOMETRIA DEL CARRUSEL  (juega con estos numeros)
    // ======================================================================
    readonly property real itemWidth:   s(400)
    readonly property real itemHeight:  s(420)
    readonly property real borderWidth: s(3)
    readonly property real spacing:     s(10)
    readonly property real skew:        -0.35   // <- la inclinacion

    // ======================================================================
    //  4. ESTADO
    // ======================================================================
    property string currentFilter: "All"
    property string searchQuery: ""
    property bool   searchOpen: false
    property bool   isApplying: false
    property string statusText: ""
    property bool   ready: false
    property var    folderList: []      // subcarpetas encontradas en el scan

    Timer { id: applyUnlock; interval: 400; onTriggered: root.isApplying = false }
    Timer { id: statusClear; interval: 2500; onTriggered: root.statusText = "" }

    // ======================================================================
    //  5. MODELO DE ARCHIVOS  --  scan RECURSIVO
    //
    //  FolderListModel no entra en subcarpetas, y tus fondos viven repartidos
    //  en carpetas por serie. Asi que el listado lo hace `find` y el resultado
    //  se vuelca en un ListModel.
    //
    //  `-printf '%P\n'` imprime la ruta RELATIVA a wallpaperDir, que es justo
    //  lo que necesitamos: la parte con "/" es la carpeta, el resto el nombre.
    // ======================================================================
    ListModel { id: entries }

    // Lo que se lista. Una sola fuente para el scan y para thumbs.sh: si los
    // dos no miran las mismas extensiones, lo que solo ve el scan aparece como
    // tarjeta que nunca recibe miniatura.
    //
    // El chip "Video" de la barra NO entra aqui: filtra lo que se ve, no lo que
    // se escanea. El modelo siempre tiene todo (por eso al activarlo las
    // tarjetas de video ya estan listas, sin volver a escanear ni regenerar).
    function extensionesActivas() {
        const base = WallpaperConfig.imageExtensions.concat(WallpaperConfig.gifExtensions)
        return WallpaperConfig.enableVideo
            ? base.concat(WallpaperConfig.videoExtensions)
            : base
    }

    function scanScript() {
        const exts = root.extensionesActivas()

        const expr = []
        for (let i = 0; i < exts.length; i++) expr.push(`-iname '*.${exts[i]}'`)

        const dir = root.bashEscape(WallpaperConfig.wallpaperDir)
        return `find -L "${dir}" -type f \\( ${expr.join(" -o ")} \\) -printf '%P\\n' | LC_ALL=C sort -f`
    }

    Process {
        id: scanner
        stdout: StdioCollector {
            onStreamFinished: root.rebuild(this.text)
        }
    }

    function rescan() {
        if (scanner.running) return
        scanner.command = ["bash", "-c", root.scanScript()]
        scanner.running = true
    }

    // Una fila del modelo, a partir de la ruta RELATIVA que imprime find.
    function makeEntry(rel) {
        const cut  = rel.lastIndexOf("/")
        const name = cut === -1 ? rel : rel.substring(cut + 1)
        const carpeta = cut === -1 ? WallpaperConfig.etiquetaRaiz : rel.substring(0, cut)
        const path = WallpaperConfig.wallpaperDir + "/" + rel

        return {
            fileName:   name,
            filePath:   path,
            thumbUrl:   root.toFileUrl(root.thumbPath(path)),
            folderName: carpeta,
            isVideo:    root.isVideoFile(name),
            thumbReady: false
        }
    }

    // ----------------------------------------------------------------------
    //  MERGE, no clear+append.
    //
    //  Antes esto hacia entries.clear() y volvia a insertar las ~160 filas en
    //  cada apertura. Costaba carisimo y no se notaba solo porque la primera
    //  vez el carrusel esta invisible (root.ready todavia en false) y el fade
    //  de 500 ms tapaba la recarga: destruia los 160 delegates, reseteaba todos
    //  los thumbReady y Qt volvia a decodificar cada imagen desde cero.
    //
    //  Ahora se recorre el scan y el modelo EN PARALELO. Los dos vienen del
    //  mismo `find | LC_ALL=C sort -f`, o sea en el mismo orden, asi que basta
    //  con un merge lineal: lo que coincide no se toca, lo que aparecio se
    //  inserta en su lugar y lo que desaparecio se borra.
    //
    //  Consecuencias, que son justo lo que se buscaba:
    //    - Si no cambio nada, el modelo no se toca: cero delegates destruidos,
    //      cero imagenes redecodificadas, y los thumbReady sobreviven. Reabrir
    //      el picker es instantaneo siempre, no solo la primera vez.
    //    - Si agregaste un wallpaper, entra UNA fila nueva con thumbReady en
    //      false; thumbs.sh solo genera esa miniatura (las demas ya estan y son
    //      mas nuevas que su original). No hace falta ningun boton de recarga.
    // ----------------------------------------------------------------------
    function rebuild(text) {
        const lines = String(text).split("\n")
        const previo = root.currentPath()

        // Rutas relativas del scan + set de rutas absolutas que hay AHORA en
        // disco (el set es lo que permite decidir, cuando modelo y scan se
        // separan, si sobra una fila vieja o falta una nueva).
        const rels = []
        const enDisco = ({})
        for (let i = 0; i < lines.length; i++) {
            const rel = lines[i]
            if (rel === "") continue
            rels.push(rel)
            enDisco[WallpaperConfig.wallpaperDir + "/" + rel] = true
        }

        let i = 0, j = 0
        while (j < rels.length) {
            if (i >= entries.count) {                 // cola: solo quedan altas
                entries.append(root.makeEntry(rels[j]))
                i++; j++
                continue
            }

            const actual = String(entries.get(i).filePath)
            if (actual === WallpaperConfig.wallpaperDir + "/" + rels[j]) {
                i++; j++                              // el mismo archivo: no tocar
            } else if (enDisco[actual]) {
                entries.insert(i, root.makeEntry(rels[j]))   // rels[j] es nuevo
                i++; j++
            } else {
                entries.remove(i)                     // borrado del disco
            }
        }
        // Lo que sobra al final ya no existe.
        if (i < entries.count) entries.remove(i, entries.count - i)

        // Indices y carpetas se recalculan igual: son O(n) sobre memoria, no
        // tocan la vista.
        const carpetas = []
        const indices = ({})
        for (let k = 0; k < entries.count; k++) {
            const e = entries.get(k)
            indices[String(e.filePath)] = k
            const c = String(e.folderName)
            if (carpetas.indexOf(c) === -1) carpetas.push(c)
        }

        root.indexByPath = indices

        carpetas.sort()
        // Reasignar folderList reconstruye todos los chips de la barra (el
        // Repeater cuelga de filterData). Si la lista es la misma, no se toca.
        if (String(carpetas) !== String(root.folderList)) root.folderList = carpetas

        // Si el filtro activo apuntaba a una carpeta que ya no existe, volver a All.
        if (root.currentFilter !== "All" && root.currentFilter !== "Video"
            && carpetas.indexOf(root.currentFilter) === -1)
            root.currentFilter = "All"

        root.ready = true
        // Primero el fondo actual; si no se sabe cual es, el que estaba centrado.
        if (!root.centerOnCurrent()) root.restoreIndex(previo)

        // El modelo ya existe, asi que ya podemos marcar items. Pero si todavia
        // no se leyo el wallpaper actual, esperamos: es justo el dato que decide
        // desde donde recorrer. De arrancar ahora, se reportaria desde el indice
        // 0 y las tarjetas visibles quedarian para el final.
        if (root.currentRead) root.generateThumbs()
    }

    // ======================================================================
    //  5b. MINIATURAS
    //
    //  Las tarjetas leen SIEMPRE de cacheDir/thumbs, nunca el archivo original
    //  (un 4K de 6 MB tarda segundos en decodificar, y en PNG no hay decodifi-
    //  cacion escalada: Qt descomprime los 3840x2160 completos).
    //
    //  scripts/thumbs.sh va imprimiendo la ruta de cada archivo cuya miniatura
    //  esta lista; aqui se marca el item correspondiente y su tarjeta aparece.
    //  El script ya es incremental (solo genera lo que falta o quedo viejo), y
    //  como el modelo sobrevive entre aperturas, la marca thumbReady tambien:
    //  reabrir el picker no lanza ni el script, salvo que hayas agregado un
    //  wallpaper nuevo, en cuyo caso solo se genera esa miniatura.
    // ======================================================================
    // La altura forma parte de la ruta: si cambias thumbHeight, las miniaturas
    // viejas quedan aparte y se regeneran solas (y si volves atras, se reusan).
    readonly property string thumbDir: WallpaperConfig.cacheDir + "/thumbs/"
                                     + WallpaperConfig.thumbHeight

    // El nombre lo decide md5(ruta absoluta), igual que en thumbs.sh.
    function thumbPath(path) { return root.thumbDir + "/" + Qt.md5(path) + ".jpg" }

    property var indexByPath: ({})      // ruta absoluta -> indice en el modelo

    Process {
        id: thumbGen
        // SplitParser en vez de StdioCollector: queremos las lineas a medida
        // que salen, no todas juntas al terminar.
        stdout: SplitParser {
            onRead: line => root.markThumbReady(line)
        }
    }

    // ¿Queda alguna tarjeta sin miniatura? Corta en la primera que encuentra,
    // asi que en la apertura inicial (donde faltan todas) es O(1).
    function faltanThumbs() {
        for (let i = 0; i < entries.count; i++)
            if (entries.get(i).thumbReady !== true) return true
        return false
    }

    function generateThumbs() {
        if (thumbGen.running) return

        // Con el modelo ya no se resetea en cada apertura, los thumbReady
        // sobreviven: si estan todos marcados no hay literalmente nada que
        // hacer y ni se lanza bash. El script solo corre la primera vez de la
        // sesion y cuando aparecio un wallpaper nuevo (fila con thumbReady en
        // false), que es el unico caso en que hay que generar algo.
        if (!root.faltanThumbs()) return

        const exts = root.extensionesActivas()

        // currentWallpaper le dice desde donde recorrer: el script reporta las
        // miniaturas abriendose desde ahi hacia los dos lados, asi las tarjetas
        // visibles se llenan igual de rapido este el wallpaper actual al
        // principio, en el medio o al final de la lista.
        thumbGen.command = ["bash", root.scriptPath("thumbs.sh"),
                            WallpaperConfig.cacheDir,
                            String(WallpaperConfig.thumbHeight),
                            String(WallpaperConfig.thumbJobs),
                            WallpaperConfig.wallpaperDir,
                            root.currentWallpaper].concat(exts)
        thumbGen.running = true
    }

    // Rutas en espera de marcarse (ver el Timer de abajo). Se guardan rutas y
    // no indices: entre que se encolan y se aplican puede entrar un wallpaper
    // nuevo y correr todos los indices de ahi para abajo.
    property var pendientes: []

    function markThumbReady(path) {
        const p = String(path).trim()
        const i = root.indexByPath[p]
        if (i === undefined) return

        // Ya marcada: no hay que hacer nada. Importa porque thumbs.sh reporta
        // TODAS las miniaturas que ya existen, no solo las que genero, y un
        // setProperty redundante haria rebotar el binding de la tarjeta.
        const e = entries.get(i)
        if (!e || e.thumbReady === true) return

        // La tarjeta central va sola y de inmediato: es la unica que se ve
        // grande, y asi su decodificacion no compite con nadie.
        if (i === view.currentIndex) {
            entries.setProperty(i, "thumbReady", true)
            return
        }

        root.pendientes.push(p)
        if (!flushThumbs.running) flushThumbs.start()
    }

    // Qt decodifica imagenes en UN solo hilo y saca los trabajos por el FINAL de
    // la cola (LIFO): la ultima peticion es la primera en resolverse. Marcando
    // las miniaturas en el orden en que llegan, la tarjeta central -que es la
    // primera en pedirse- terminaba siendo la ULTIMA en dibujarse, y el carrusel
    // parecia llenarse desde los extremos hacia el medio.
    //
    // Por eso las marcas se acumulan y se aplican en lotes ordenados de LEJOS a
    // CERCA del centro: invertido por el LIFO, Qt las resuelve de cerca a lejos.
    Timer {
        id: flushThumbs
        interval: 60
        repeat: true
        onTriggered: {
            if (root.pendientes.length === 0) { flushThumbs.stop(); return }

            // Las rutas se resuelven a indices AHORA, con el modelo tal como
            // esta en este instante.
            const lote = []
            for (let n = 0; n < root.pendientes.length; n++) {
                const i = root.indexByPath[root.pendientes[n]]
                if (i !== undefined) lote.push(i)
            }
            root.pendientes = []

            const c = view.currentIndex
            lote.sort((a, b) => Math.abs(b - c) - Math.abs(a - c))

            for (let k = 0; k < lote.length; k++)
                entries.setProperty(lote[k], "thumbReady", true)
        }
    }

    // Qt.resolvedUrl da "file:///home/..."; los Process quieren una ruta plana.
    function scriptPath(name) {
        let p = Qt.resolvedUrl("scripts/" + name).toString()
        if (p.startsWith("file://")) p = decodeURIComponent(p.substring(7))
        return p
    }

    // Qt.resolvedUrl no sirve para los wallpapers (las rutas vienen de find, no
    // del modulo): hay que percent-encodear cada segmento por espacios/acentos.
    function toFileUrl(path) {
        const parts = String(path).split("/")
        for (let i = 0; i < parts.length; i++) parts[i] = encodeURIComponent(parts[i])
        return "file://" + parts.join("/")
    }

    // Escapar para bash: comillas, backslash, $ y backtick.
    function bashEscape(t) { return String(t).replace(/(["\\$`])/g, "\\$1") }

    function isVideoFile(name) {
        const n = String(name).toLowerCase()
        const exts = WallpaperConfig.videoExtensions
        for (let i = 0; i < exts.length; i++)
            if (n.endsWith("." + exts[i])) return true
        return false
    }

    // ======================================================================
    //  6. FILTRADO  (por carpeta, por tipo y por nombre)
    //
    //  Todos los chips son lo mismo: escriben currentFilter y el carrusel
    //  muestra lo que coincida. "Video" es uno mas, solo que en vez de mirar
    //  la carpeta mira el tipo. Los gif cuentan como imagen, asi que salen en
    //  "Todos" y en su carpeta, pero no en "Video".
    // ======================================================================
    function itemMatches(name, carpeta, isVideo, filter, query) {
        if (query !== "" && String(name).toLowerCase().indexOf(query.toLowerCase()) === -1)
            return false
        if (filter === "All")   return true
        if (filter === "Video") return isVideo
        return carpeta === filter
    }

    function entryMatches(i) {
        const e = entries.get(i)
        if (!e) return false
        return root.itemMatches(e.fileName, e.folderName, e.isVideo,
                                root.currentFilter, root.searchQuery)
    }

    readonly property int visibleCount: {
        let n = 0
        for (let i = 0; i < entries.count; i++) if (root.entryMatches(i)) n++
        return n
    }

    // Chips de la barra: All / Video / una por subcarpeta.
    readonly property var filterData: {
        const out = [{ nombre: "All", etiqueta: "Todos", icono: "grid" }]
        if (WallpaperConfig.enableVideo)
            out.push({ nombre: "Video", etiqueta: "Video", icono: "play" })
        for (let i = 0; i < root.folderList.length; i++)
            out.push({ nombre: root.folderList[i], etiqueta: root.folderList[i], icono: "" })
        return out
    }

    // ======================================================================
    //  7. NAVEGACION
    //
    //  El wallpaper aplicado se guarda en cacheDir/current (lo escribe el
    //  script de applyWallpaper). Al abrir se lee de ahi para que la vista
    //  arranque centrada en el fondo actual y no en el primero de la lista.
    //
    //  El mismo script deja al lado un symlink (cacheDir/currentLinkName) a la
    //  MINIATURA del fondo, no al original: asi es siempre un JPEG y lo de
    //  afuera que solo sabe abrir imagenes -hyprlock, extractores de paleta-
    //  funciona igual con un mp4 o un gif. El picker no lo usa: lee `current`,
    //  que es texto plano y guarda la ruta del archivo de verdad.
    // ======================================================================
    property string currentWallpaper: ""
    property bool   currentRead: false   // ya sabemos (o ya sabemos que no sabemos)

    Process {
        id: currentReader
        stdout: StdioCollector {
            onStreamFinished: {
                root.currentWallpaper = this.text.trim()
                root.currentDone()
            }
        }
        // Si el archivo no existe cat falla y puede no haber stream: sin esto
        // nos quedariamos esperando para siempre y no se generarian miniaturas.
        onExited: root.currentDone()
    }

    function readCurrent() {
        if (currentReader.running) return
        root.currentRead = false
        currentReader.command = ["cat", WallpaperConfig.cacheDir + "/current"]
        currentReader.running = true
    }

    // Se llama cuando ya se leyo (o fallo) la lectura del wallpaper actual.
    function currentDone() {
        root.currentRead = true
        if (!root.ready) return     // todavia no hay modelo: rebuild() sigue
        root.centerOnCurrent()
        root.generateThumbs()
    }

    // Mientras esto esta en true las tarjetas no animan su tamaño (ver los
    // Behavior del delegate) y el ListView deja de imponer su rango (ver
    // highlightRangeMode). Hace falta para centrar con precision: la tarjeta
    // central mide 3x las laterales, y si el ancho esta animandose,
    // positionViewAtIndex calcula con la geometria vieja y, como el ListView
    // usa StrictlyEnforceRange, la vista se re-ajusta a mitad de animacion y
    // termina centrada en la tarjeta vecina.
    property bool positioning: false

    // Cada centerOnCurrent() se lleva un numero. Al abrir el picker la funcion
    // se llama 3 veces (dos por currentDone -onStreamFinished y onExited- y una
    // por rebuild), y sin esto el Qt.callLater de la PRIMERA apagaba
    // `positioning` cuando las otras dos todavia estaban centrando.
    property int posToken: 0

    // Centra la vista en el wallpaper actual. Devuelve false si no se sabe cual
    // es, o si ya no esta en la carpeta.
    function centerOnCurrent() {
        if (root.currentWallpaper === "") return false
        const i = root.indexByPath[root.currentWallpaper]
        if (i === undefined) return false

        const token = ++root.posToken
        root.positioning = true
        view.currentIndex = i
        // Salto directo: sin esto la vista viaja animada desde el indice 0.
        view.positionViewAtIndex(i, ListView.Center)

        Qt.callLater(() => {
            // Si ya hay otra llamada mas nueva en vuelo, esta pasada sobra: lo
            // unico que haria es apagar `positioning` antes de tiempo.
            if (token !== root.posToken) return

            // Segunda pasada: los delegates lejanos se crean recien ahora, y con
            // ellos la geometria real de la fila. Se vuelve a fijar el indice
            // ademas de la posicion, para que el estado final no dependa de en
            // que orden llegaron el `cat` y el `find`.
            view.currentIndex = i
            view.positionViewAtIndex(i, ListView.Center)
            root.positioning = false
            root.snapToValid()
        })
        return true
    }

    function currentPath() {
        const e = entries.get(view.currentIndex)
        return e ? String(e.filePath) : ""
    }

    // Tras un rescan, volver al mismo archivo que estaba centrado.
    function restoreIndex(path) {
        if (path !== "") {
            for (let i = 0; i < entries.count; i++) {
                if (String(entries.get(i).filePath) === path) {
                    view.currentIndex = i
                    Qt.callLater(root.snapToValid)
                    return
                }
            }
        }
        view.currentIndex = 0
        Qt.callLater(root.snapToValid)
    }

    // Salta al siguiente item que pase el filtro actual.
    function stepToValid(dir) {
        let i = view.currentIndex
        for (let n = 0; n < entries.count; n++) {
            i += dir
            if (i < 0 || i >= entries.count) return
            if (root.entryMatches(i)) {
                view.currentIndex = i
                return
            }
        }
    }

    // Si el item centrado quedo filtrado, moverse al primero que si pase.
    function snapToValid() {
        if (entries.count === 0) return
        if (root.entryMatches(view.currentIndex)) return
        for (let i = 0; i < entries.count; i++) {
            if (root.entryMatches(i)) {
                view.currentIndex = i
                return
            }
        }
    }
    onCurrentFilterChanged: Qt.callLater(root.snapToValid)
    onSearchQueryChanged:   Qt.callLater(root.snapToValid)

    // ======================================================================
    //  8. APLICAR EL WALLPAPER  +  POST-COMMAND
    // ======================================================================
    function applyWallpaper(filePath, fileName, isVideo) {
        if (!filePath || root.isApplying) return
        root.isApplying = true
        applyUnlock.restart()

        const file  = root.bashEscape(filePath)
        const name  = root.bashEscape(fileName)
        // La miniatura que ya dibuja el carrusel: a esa apunta el symlink.
        const thumb = root.bashEscape(root.thumbPath(filePath))
        const genThumb = root.bashEscape(root.scriptPath("thumbs.sh"))
        const tr = WallpaperConfig.transitions[
            Math.floor(Math.random() * WallpaperConfig.transitions.length)]

        // --- crop o fit: la regla de smart_fill.sh -------------------------
        //  Si la imagen es mas "angosta" que el monitor, sobra alto y se
        //  recorta (crop). Si es mas ancha (panoramicas), entra completa con
        //  barras (fit) en vez de comerse los lados.
        //  A diferencia de smart_fill.sh, el tamaño de pantalla no va
        //  hardcodeado: sale del monitor donde esta abierto el picker.
        const sw = root.screen ? root.screen.width  : 1920
        const sh = root.screen ? root.screen.height : 1080

        const resizeCmd = WallpaperConfig.smartResize
            ? `RESIZE=${WallpaperConfig.resizeMode}
               read -r IW IH < <(identify -format '%w %h' "$WALLPAPER[0]" 2>/dev/null)
               if [ -n "\${IW:-}" ] && [ -n "\${IH:-}" ]; then
                   if [ $(( IW * ${sh} )) -lt $(( ${sw} * IH )) ]; then RESIZE=crop; else RESIZE=fit; fi
               fi`
            : `RESIZE=${WallpaperConfig.resizeMode}`

        // La capa de awww con la imagen estatica NO se va sola: se queda ahi
        // abajo con el ultimo fondo puesto para siempre. mpvpaper dibuja encima
        // y por eso normalmente no se nota, pero en cuanto el video no tapa
        // hasta el ultimo pixel -uno mas panoramico que la pantalla entra con
        // barras arriba y abajo- por esas barras se seguia viendo el wallpaper
        // anterior. Se apaga antes de arrancar el video; asi lo que hay debajo
        // es negro y no la foto de antes.
        //
        // Es la contraparte del `pkill mpvpaper` de las imagenes, que hasta
        // ahora no existia: se limpiaba en un sentido pero no en el otro.
        // `clear` no mata el demonio, solo lo pinta de negro, asi que volver a
        // una imagen sigue siendo instantaneo (no hay que relevantarlo).
        const setCmd = isVideo
            ? `awww query >/dev/null 2>&1 && awww clear 000000 >/dev/null 2>&1 || true
               mpvpaper -o "${WallpaperConfig.mpvpaperOptions}" '*' "$WALLPAPER" >/dev/null 2>&1 &`
            : `${resizeCmd}
               awww query >/dev/null 2>&1 || { awww-daemon >/dev/null 2>&1 & sleep 0.6; }
               awww img "$WALLPAPER" --resize "$RESIZE" --transition-type ${tr} --transition-pos 0.5,0.5 --transition-fps ${WallpaperConfig.transitionFps} --transition-duration ${WallpaperConfig.transitionDuration}`

        // ------------------------------------------------------------------
        //  Este es el script completo que se ejecuta. Fijate en el orden:
        //  primero se pone el fondo, DESPUES corre el post-command.
        // ------------------------------------------------------------------
        const script = `
            export WALLPAPER="${file}"
            export WALL_NAME="${name}"
            export WALL_THUMB="${thumb}"
            export CACHE_DIR="${WallpaperConfig.cacheDir}"
            export CURRENT_LINK="$CACHE_DIR/${WallpaperConfig.currentLinkName}"

            # Alias en minuscula: waypaper llama a su variable "$wallpaper", y
            # asi un post_command copiado de ahi funciona sin editarlo.
            export wallpaper="$WALLPAPER"
            export wall_name="$WALL_NAME"
            export wall_thumb="$WALL_THUMB"
            export current_link="$CURRENT_LINK"

            mkdir -p "$CACHE_DIR"
            printf '%s' "$WALLPAPER" > "$CACHE_DIR/current"

            pkill mpvpaper 2>/dev/null || true

            ${setCmd}

            # Ademas de la ruta en texto, un symlink en una ruta FIJA, para lo
            # de afuera (hyprlock, Rofi, scripts). Apunta a la miniatura y no al
            # original: es la misma que dibuja el carrusel y siempre es un JPEG,
            # asi que un mp4 o un gif -que hyprlock no abre- se ven igual.
            #
            # Normalmente ya existe (el picker la genero para pintar la tarjeta
            # desde la que acabas de elegir); se genera aqui solo si falta o si
            # quedo mas vieja que el archivo.
            #
            # Va DESPUES de aplicar el fondo a proposito: generar una miniatura
            # que falte cuesta un ffmpeg, y poniendolo antes ese segundo se lo
            # comia el cambio de wallpaper -o sea que te quedabas mirando el
            # fondo anterior-. Lo que se ve va primero; esto es contabilidad.
            [ -s "$WALL_THUMB" ] && [ "$WALL_THUMB" -nt "$WALLPAPER" ] || bash "${genThumb}" --one ${WallpaperConfig.thumbHeight} "$WALLPAPER" "$WALL_THUMB" >/dev/null 2>&1

            # Si aun asi no salio (ffmpeg/magick que no pudieron con el
            # archivo), mejor el original que un symlink roto.
            # -f pisa el link viejo, -n evita que si el destino anterior era un
            # directorio se cree el link ADENTRO de el.
            if [ -s "$WALL_THUMB" ]; then
                ln -sfn "$WALL_THUMB" "$CURRENT_LINK"
            else
                ln -sfn "$WALLPAPER" "$CURRENT_LINK"
            fi

            # ---------------- POST-COMMAND (WallpaperConfig.qml) ----------------
            ${WallpaperConfig.postCommand}
            # -------------------------------------------------------------------
        `

        Quickshell.execDetached(["bash", "-c", script])

        // El script tambien lo escribe en cacheDir/current, pero tenerlo aqui
        // evita depender de que el archivo ya este escrito al reabrir.
        root.currentWallpaper = filePath

        root.statusText = fileName
        statusClear.restart()
    }

    function applyCurrent() {
        const e = entries.get(view.currentIndex)
        if (e) root.applyWallpaper(String(e.filePath), String(e.fileName), e.isVideo)
    }

    // ======================================================================
    //  9. FONDO
    // ======================================================================
    Rectangle {
        anchors.fill: parent
        color: Theme.veloWallpaper
        opacity: root.ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        MouseArea {          // click fuera -> cerrar
            anchors.fill: parent
            onClicked: WallpaperState.cerrar()
        }
    }

    // ======================================================================
    //  10. CARRUSEL
    // ======================================================================
    ListView {
        id: view
        anchors.fill: parent
        orientation: ListView.Horizontal
        clip: false
        spacing: 0
        focus: true
        // Ojo con subirlo: cada tarjeta precargada decodifica una foto grande,
        // y las de fuera de pantalla le roban el turno a las visibles.
        cacheBuffer: root.s(700)
        model: entries

        opacity: root.ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }

        // Mantiene SIEMPRE el item actual centrado.
        //
        // ...salvo mientras centramos a mano (root.positioning). Este modo no
        // solo mueve la vista hacia currentIndex: tambien hace lo contrario,
        // DEDUCE currentIndex de la posicion del contenido. Al reabrir el
        // picker eso deshacia el `view.currentIndex = i` de centerOnCurrent(),
        // porque la deduccion usa la geometria vieja (la tarjeta donde te
        // habias quedado sigue midiendo 3x) y devolvia el indice anterior.
        // Antes no se notaba: el entries.clear() dejaba la vista en -1 y no
        // habia indice viejo contra el que pelear.
        highlightRangeMode: root.positioning ? ListView.NoHighlightRange
                                             : ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width / 2) - ((root.itemWidth * 1.5 + root.spacing) / 2)
        preferredHighlightEnd:   (width / 2) + ((root.itemWidth * 1.5 + root.spacing) / 2)
        highlightMoveDuration: 450

        // Espaciadores para que el primero y el ultimo puedan centrarse.
        header: Item { width: Math.max(0, (view.width / 2) - (root.itemWidth * 1.5 / 2)) }
        footer: Item { width: Math.max(0, (view.width / 2) - (root.itemWidth * 1.5 / 2)) }

        // --- teclado ---
        Keys.onEscapePressed: WallpaperState.cerrar()
        Keys.onLeftPressed:   root.stepToValid(-1)
        Keys.onRightPressed:  root.stepToValid(1)
        Keys.onReturnPressed: root.applyCurrent()
        Keys.onPressed: event => {
            // "/" abre el buscador, como en vim/less.
            if (event.text === "/") {
                root.searchOpen = true
                searchInput.forceActiveFocus()
                event.accepted = true
            }
        }

        // --- rueda del mouse: 1 item por "tick", con throttle ---
        Timer { id: wheelThrottle; interval: 130 }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (w) => {
                if (wheelThrottle.running) { w.accepted = true; return }
                const dx = w.angleDelta.x, dy = w.angleDelta.y
                const delta = Math.abs(dx) > Math.abs(dy) ? dx : dy
                if (delta !== 0) {
                    root.stepToValid(delta > 0 ? -1 : 1)
                    wheelThrottle.start()
                }
                w.accepted = true
            }
        }

        // Animacion cuando aparecen items nuevos
        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 350 }
            NumberAnimation { property: "scale"; from: 0.6; to: 1; duration: 350; easing.type: Easing.OutBack }
        }

        // ==================================================================
        //  DELEGATE  --  una tarjeta
        // ==================================================================
        delegate: Item {
            id: card

            readonly property string fName:   model.fileName   !== undefined ? String(model.fileName) : ""
            readonly property string fPath:   model.filePath   !== undefined ? String(model.filePath) : ""
            readonly property string fFolder: model.folderName !== undefined ? String(model.folderName) : ""
            readonly property url    fThumb:  model.thumbUrl   !== undefined ? model.thumbUrl : ""
            readonly property bool   isVideo: model.isVideo === true
            readonly property bool   thumbReady: model.thumbReady === true
            readonly property bool   isCurrent: ListView.isCurrentItem

            readonly property bool matches: root.itemMatches(
                fName, fFolder, isVideo, root.currentFilter, root.searchQuery)

            // Fuente de las imagenes de la tarjeta: la MINIATURA, nunca el
            // original. Vacia mientras la miniatura no exista (si no, Image
            // llenaria el log de "Cannot open file"), y tambien cuando la
            // tarjeta TERMINO de cerrarse por el filtro (width 0), para no
            // decodificar las 160 fotos que quedan fuera. Se usa `width` y no
            // `matches` para que la que se esta cerrando no parpadee.
            readonly property url imgSource: (!thumbReady || (!matches && width < 1))
                ? "" : fThumb

            // El item central es 3x mas ancho que los laterales.
            readonly property real targetWidth:  isCurrent ? root.itemWidth * 1.5 : root.itemWidth * 0.5
            readonly property real targetHeight: isCurrent ? root.itemHeight + root.s(30) : root.itemHeight

            // Si no pasa el filtro, colapsa a ancho 0 (se "cierra" con animacion).
            width:   matches ? targetWidth + root.spacing : 0
            height:  matches ? targetHeight : 0
            opacity: matches ? (isCurrent ? 1.0 : 0.55) : 0.0
            scale:   matches ? 1.0 : 0.5
            visible: width > 0.5 || opacity > 0.01
            z: isCurrent ? 10 : 1

            // El delegate existe un instante antes de tener parent, de ahi el guard.
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            // width/height se animan salvo mientras se esta centrando la vista
            // en el wallpaper actual (ver root.positioning).
            Behavior on width   { enabled: !root.positioning; NumberAnimation { duration: 420; easing.type: Easing.InOutQuad } }
            Behavior on height  { enabled: !root.positioning; NumberAnimation { duration: 420; easing.type: Easing.InOutQuad } }
            Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.InOutQuad } }
            Behavior on scale   { NumberAnimation { duration: 420; easing.type: Easing.InOutQuad } }

            // --------------------------------------------------------------
            //  EL PARALELOGRAMO
            // --------------------------------------------------------------
            Item {
                id: shape
                anchors.centerIn: parent
                // Compensa el desplazamiento lateral que introduce la cizalla,
                // para que los items de distinta altura queden alineados.
                anchors.horizontalCenterOffset: ((root.itemHeight - height) / 2) * root.skew

                width: parent.width > 0
                    ? parent.width * (card.targetWidth / (card.targetWidth + root.spacing))
                    : 0
                height: parent.height

                // CIZALLA:  x' = x + k*y
                transform: Matrix4x4 {
                    property real k: root.skew
                    matrix: Qt.matrix4x4(1, k, 0, 0,
                                         0, 1, 0, 0,
                                         0, 0, 1, 0,
                                         0, 0, 0, 1)
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: card.matches && !root.isApplying
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!card.isCurrent) { view.currentIndex = index; return }
                        root.applyWallpaper(card.fPath, card.fName, card.isVideo)
                    }
                }

                // BORDE: la miniatura cargada a 2x2 px = su color promedio.
                // Truco barato y bonito: cada tarjeta se enmarca con su propio tono.
                // (los videos van con el color de acento, para distinguirlos)
                //
                // 2x2 y no 1x1: con fillMode Stretch, Qt decodifica a
                // original * min(anchoPedido/ancho, altoPedido/alto). Pidiendo
                // 1x1 sobre una miniatura de 1037x500 el alto da 500/1037 =
                // 0.48, que REDONDEA A 0, y QImageReader falla entero ("Unable
                // to read image data"). Con eso, todo wallpaper de 2:1 o mas
                // -panoramicas, ultrawide- se quedaba sin borde de color y sin
                // placeholder. Pidiendo 2x2 aguanta hasta 4:1.
                Rectangle {
                    anchors.fill: parent
                    color: card.isVideo ? Theme.acento : Theme.bordeChip
                }
                Image {
                    anchors.fill: parent
                    source: card.isVideo ? "" : card.imgSource
                    sourceSize: Qt.size(2, 2)
                    fillMode: Image.Stretch
                    asynchronous: true
                    visible: !card.isVideo
                }

                // INTERIOR (recortado al paralelogramo)
                Item {
                    anchors.fill: parent
                    anchors.margins: root.borderWidth
                    clip: true

                    Rectangle { anchors.fill: parent; color: Theme.fondoTarjeta }

                    // PLACEHOLDER: la miniatura a 2x2 px estirada, o sea su color
                    // promedio. Tapa el instante entre que la miniatura esta
                    // lista y que termina de decodificarse a tamaño completo.
                    // (el porque de 2x2 y no 1x1, en el borde de arriba)
                    Image {
                        anchors.fill: parent
                        source: card.isVideo ? "" : card.imgSource
                        sourceSize: Qt.size(2, 2)
                        fillMode: Image.Stretch
                        asynchronous: true
                        visible: !card.isVideo && foto.status !== Image.Ready
                    }

                    // Fallback para videos sin miniatura (si ffmpeg no pudo saca
                    // el frame): al menos que se distingan por el nombre.
                    Text {
                        visible: card.isVideo && !card.thumbReady
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: root.s(-20)
                        width: parent.width * 0.7
                        text: card.fName
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.textoSuave
                        font.family: Theme.fuente
                        font.pixelSize: root.s(13)

                        transform: Matrix4x4 {
                            property real k: -root.skew
                            matrix: Qt.matrix4x4(1, k, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }

                    // CONTRA-CIZALLA: la foto vuelve a estar recta.
                    // Se hace mas ancha de lo necesario para que al inclinarse
                    // no queden esquinas vacias.
                    Image {
                        id: foto
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: root.s(-50)
                        width: (root.itemWidth * 1.5)
                             + ((root.itemHeight + root.s(30)) * Math.abs(root.skew))
                             + root.s(50)
                        height: root.itemHeight + root.s(30)
                        fillMode: Image.PreserveAspectCrop
                        source: card.imgSource
                        // Limita la resolucion en memoria: sin esto, 20 fotos 4K
                        // se comen varios GB de RAM.
                        //
                        // Ojo con este numero: con fillMode PreserveAspectCrop,
                        // sourceSize NO es un tope, es el tamaño al que Qt deja
                        // la imagen al decodificarla, y ESCALA HACIA ARRIBA si
                        // le pides mas de lo que mide el archivo. Pidiendo 1.6x
                        // itemHeight se agrandaba la miniatura de 500 px al
                        // decodificarla para despues dibujarla a ~320: el doble
                        // de pixeles por tarjeta, para nada. Ahora se pide lo
                        // que de verdad se dibuja (con un 10% de aire por el
                        // recorte lateral), y nunca mas alto que la miniatura.
                        sourceSize.height: Math.min(
                            WallpaperConfig.thumbHeight,
                            Math.round((root.itemHeight + root.s(30)) * 1.1))
                        asynchronous: true
                        cache: true

                        transform: Matrix4x4 {
                            property real k: -root.skew
                            matrix: Qt.matrix4x4(1, k, 0, 0,
                                                 0, 1, 0, 0,
                                                 0, 0, 1, 0,
                                                 0, 0, 0, 1)
                        }
                    }

                    // Badge de video
                    Rectangle {
                        visible: card.isVideo
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: root.s(12)
                        width: root.s(34); height: root.s(34)
                        radius: root.s(8)
                        color: Theme.fondoBadge
                        transform: Matrix4x4 {
                            property real k: -root.skew
                            matrix: Qt.matrix4x4(1, k, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                        Canvas {
                            anchors.centerIn: parent
                            width: root.s(14); height: root.s(16)
                            onPaint: {
                                const ctx = getContext("2d"); ctx.reset()
                                ctx.fillStyle = Theme.texto
                                ctx.beginPath()
                                ctx.moveTo(0, 0); ctx.lineTo(width, height / 2); ctx.lineTo(0, height)
                                ctx.closePath(); ctx.fill()
                            }
                        }
                    }

                    // Nombre de la carpeta (solo en la tarjeta central)
                    Rectangle {
                        visible: card.isCurrent && card.fFolder !== ""
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.margins: root.s(14)
                        height: root.s(28)
                        width: carpetaTxt.implicitWidth + root.s(20)
                        radius: root.s(8)
                        color: Theme.fondoBadge
                        transform: Matrix4x4 {
                            property real k: -root.skew
                            matrix: Qt.matrix4x4(1, k, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                        Text {
                            id: carpetaTxt
                            anchors.centerIn: parent
                            text: card.fFolder
                            color: Theme.texto
                            font.family: Theme.fuente
                            font.pixelSize: root.s(12)
                        }
                    }
                }
            }
        }
    }

    // Mensajes de "aqui no hay nada"
    Text {
        anchors.centerIn: parent
        visible: root.ready && entries.count === 0
        text: "No hay wallpapers en\n" + WallpaperConfig.wallpaperDir
        horizontalAlignment: Text.AlignHCenter
        color: Theme.textoSuave
        font.family: Theme.fuente
        font.pixelSize: root.s(18)
    }
    Text {
        anchors.centerIn: parent
        visible: root.ready && entries.count > 0 && root.visibleCount === 0
        text: "Nada coincide con este filtro"
        color: Theme.textoSuave
        font.family: Theme.fuente
        font.pixelSize: root.s(18)
    }

    // ======================================================================
    //  11. BARRA SUPERIOR
    // ======================================================================
    Rectangle {
        id: bar
        z: 20
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.ready ? root.s(40) : root.s(-120)
        opacity: root.ready ? 1 : 0

        Behavior on anchors.topMargin { NumberAnimation { duration: 550; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: 400 } }

        height: root.s(56)
        // Con muchas subcarpetas la fila puede pasarse de ancho: la barra se
        // corta antes de salirse de la pantalla.
        width: Math.min(barRow.width + root.s(24), root.width - root.s(40))
        radius: root.s(14)
        clip: true
        color: Theme.fondoBarra
        border.color: Theme.superficieAlta
        border.width: 1

        Row {
            id: barRow
            anchors.centerIn: parent
            spacing: root.s(10)

            // --- etiqueta de estado / filtro actual ---
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                height: root.s(38)
                width: label.implicitWidth + root.s(24)
                radius: root.s(10)
                color: Theme.superficie
                Text {
                    id: label
                    anchors.centerIn: parent
                    text: root.statusText !== ""
                        ? root.statusText
                        : root.currentFilter + "  " + root.visibleCount
                    elide: Text.ElideRight
                    color: Theme.texto
                    font.family: Theme.fuente
                    font.pixelSize: root.s(13)
                }
                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
            }

            // --- chips de filtro: Todos / Video / una por subcarpeta ---
            Repeater {
                model: root.filterData

                delegate: Item {
                    required property var modelData
                    readonly property bool active: root.currentFilter === modelData.nombre

                    width: modelData.icono !== "" ? root.s(44)
                                                  : chipTxt.implicitWidth + root.s(22)
                    height: root.s(36)
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: root.s(10)
                        color: parent.active ? Theme.superficieAlta : "transparent"
                        border.color: parent.active ? Theme.texto : Theme.bordeChip
                        border.width: parent.active ? root.s(2) : 1
                        scale: parent.active ? 1.08 : (mouse.containsMouse ? 1.05 : 1.0)

                        Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                        Behavior on border.color { ColorAnimation { duration: 250 } }
                        Behavior on color { ColorAnimation { duration: 250 } }

                        // nombre de la carpeta
                        Text {
                            id: chipTxt
                            visible: modelData.icono === ""
                            anchors.centerIn: parent
                            text: modelData.etiqueta
                            elide: Text.ElideRight
                            color: parent.parent.active ? Theme.texto : Theme.textoSuave
                            font.family: Theme.fuente
                            font.pixelSize: root.s(13)
                        }

                        // icono "grid" (4 cuadritos) para Todos
                        Canvas {
                            visible: modelData.icono === "grid"
                            anchors.centerIn: parent
                            width: root.s(14); height: root.s(14)
                            property color c: parent.parent.active ? Theme.texto : Theme.textoSuave
                            onCChanged: requestPaint()
                            onPaint: {
                                const ctx = getContext("2d"); ctx.reset()
                                const u = root.s(6), g = root.s(8)
                                ctx.fillStyle = c
                                ctx.fillRect(0, 0, u, u); ctx.fillRect(g, 0, u, u)
                                ctx.fillRect(0, g, u, u); ctx.fillRect(g, g, u, u)
                            }
                        }

                        // icono "play" para Video
                        Canvas {
                            visible: modelData.icono === "play"
                            anchors.centerIn: parent
                            width: root.s(14); height: root.s(16)
                            property color c: parent.parent.active ? Theme.texto : Theme.textoSuave
                            onCChanged: requestPaint()
                            onPaint: {
                                const ctx = getContext("2d"); ctx.reset()
                                ctx.fillStyle = c
                                ctx.beginPath()
                                ctx.moveTo(0, 0); ctx.lineTo(width, height / 2); ctx.lineTo(0, height)
                                ctx.closePath(); ctx.fill()
                            }
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentFilter = modelData.nombre
                    }
                }
            }

            // --- buscador ---
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                height: root.s(36)
                width: root.searchOpen ? root.s(190) : root.s(40)
                radius: root.s(10)
                color: root.searchOpen ? Theme.superficie : "transparent"
                border.color: root.searchOpen ? Theme.texto : Theme.bordeChip
                border.width: 1
                clip: true

                Behavior on width { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

                Canvas {
                    id: lens
                    anchors.left: parent.left
                    anchors.leftMargin: root.s(12)
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.s(16); height: root.s(16)
                    onPaint: {
                        const ctx = getContext("2d"); ctx.reset()
                        ctx.strokeStyle = Theme.textoSuave
                        ctx.lineWidth = Math.max(1.5, root.s(1.6))
                        ctx.beginPath()
                        ctx.arc(width * 0.4, height * 0.4, width * 0.33, 0, Math.PI * 2)
                        ctx.moveTo(width * 0.66, height * 0.66)
                        ctx.lineTo(width, height)
                        ctx.stroke()
                    }
                }

                TextInput {
                    id: searchInput
                    visible: root.searchOpen
                    anchors.left: lens.right
                    anchors.leftMargin: root.s(8)
                    anchors.right: parent.right
                    anchors.rightMargin: root.s(10)
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.texto
                    font.family: Theme.fuente
                    font.pixelSize: root.s(13)
                    onTextChanged: root.searchQuery = text
                    Keys.onEscapePressed: {
                        text = ""
                        root.searchOpen = false
                        view.forceActiveFocus()
                    }
                    Keys.onReturnPressed: {
                        root.searchOpen = false
                        view.forceActiveFocus()
                        root.applyCurrent()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.searchOpen
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.searchOpen = true
                        searchInput.forceActiveFocus()
                    }
                }
            }
        }
    }
}
