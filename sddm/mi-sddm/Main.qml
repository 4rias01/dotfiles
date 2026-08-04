// ════════════════════════════════════════════════════════════════
//  Main.qml — punto de entrada. SDDM carga SOLO este archivo.
//
//  Objetos globales que SDDM inyecta (no los importas, ya estan ahi):
//
//    config       → lo que escribiste en theme.conf. Todo string.
//    sddm         → login(user, pass, sessionIndex), powerOff(), reboot(),
//                   suspend(), hibernate(), canPowerOff, canReboot,
//                   canSuspend, canHibernate. Senales: loginSucceeded,
//                   loginFailed.
//    userModel    → usuarios del sistema. userModel.lastUser
//    sessionModel → sesiones disponibles. sessionModel.lastIndex
//    keyboard     → keyboard.capsLock, keyboard.numLock, layouts
// ════════════════════════════════════════════════════════════════

import QtQuick
import Qt5Compat.GraphicalEffects
import "Components"

Item {
    id: root

    // SDDM fija el tamano real al arrancar. Estos valores solo actuan
    // como fallback cuando corres --test-mode.
    width: 1920
    height: 1080

    // ══ 0. Escala ═══════════════════════════════════════════════
    // El tema se diseno UNA sola vez contra designWidth x designHeight.
    // Todas las medidas de theme.conf estan en "pixeles de diseno" y se
    // multiplican por uiScale antes de usarse, asi la misma config se ve
    // igual en 1366x768, en 1080p y en 4K sin tocar un numero.
    //
    // Se usa min() de las dos razones (escalado "fit"): con la misma
    // relacion de aspecto da proporcion exacta, y con una distinta manda
    // el eje mas ajustado, asi el formulario nunca se sale de pantalla.
    //
    // Ojo: width/height estan en pixeles LOGICOS. Si Qt ya esta aplicando
    // su propio factor HiDPI, este se multiplica encima sin duplicarlo.
    //
    // SDDM instancia el tema una vez POR PANTALLA, asi que en multimonitor
    // cada una calcula su propia escala sola.
    readonly property real designWidth: num(config.designWidth, 1366)
    readonly property real designHeight: num(config.designHeight, 768)

    readonly property real uiScale: Math.min(width / designWidth,
                                             height / designHeight)
                                    * num(config.uiScale, 1)

    // config.x llega siempre como string, y una clave ausente llega como
    // undefined. num() tapa los dos casos: nunca devuelve NaN.
    function num(v, fallback) {
        var n = parseFloat(v)
        return isNaN(n) ? fallback : n
    }

    // Pixel de diseno → pixel real de esta pantalla.
    function dp(v, fallback) {
        return Math.round(num(v, fallback) * root.uiScale)
    }

    // Igual que dp(), pero ademas acepta porcentajes: "48%" se resuelve
    // como fraccion de `basis` (el ancho o el alto de la pantalla). Es
    // para las medidas que conceptualmente son "una porcion de pantalla"
    // y no un tamano fijo.
    function span(v, basis, fallback) {
        if (typeof v === "string" && v.indexOf("%") !== -1)
            return Math.round(basis * num(v, 0) / 100)
        return dp(v, fallback)
    }

    // FastBlur clampea su radio a 64: mas alla de ahi el numero se ignora.
    // Por eso el radio no puede escalar sin techo como el resto.
    function blurPx(v, fallback) {
        return Math.min(64, dp(v, fallback))
    }

    // ── Tokens ──────────────────────────────────────────────────
    // Leidos una sola vez del config. Centralizarlos aca evita
    // repetir config.xxx en cada componente.
    readonly property string uiFont: config.font
    readonly property string iconFont: config.iconFont

    readonly property color cText: config.textColor
    readonly property color cAccent: config.accentColor
    readonly property color cField: config.fieldColor
    readonly property color cFieldText: config.fieldTextColor
    readonly property color cPlaceholder: config.placeholderColor
    readonly property color cButton: config.buttonColor
    readonly property color cButtonText: config.buttonTextColor
    readonly property color cIcon: config.iconColor
    readonly property color cWarning: config.warningColor

    readonly property int formWidth: dp(config.formWidth, 340)
    readonly property int formPadding: span(config.formPadding, width, 160)

    // ══ 1. Wallpaper ════════════════════════════════════════════
    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop // recorta para llenar
        cache: true
    }

    // Capa de oscurecido encima del wallpaper.
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.num(config.dimBackground, 0.15)
    }

    // ══ 2. Zona del formulario ══════════════════════════════════
    // Este Item es INVISIBLE. Su unico trabajo es calcular DONDE va
    // la columna de login. Todo lo demas se ancla a el, asi cambiar
    // formPosition en el config mueve el formulario Y el blur juntos.
    Item {
        id: formArea
        width: root.formWidth
        height: parent.height
        y: 0
        x: {
            if (config.formPosition === "center")
                return (parent.width - width) / 2
            if (config.formPosition === "right")
                return parent.width - width - root.formPadding
            return root.formPadding // "left" es el default
        }
    }

    // ══ 3. Blur parcial ═════════════════════════════════════════
    // El truco: difuminar una copia del wallpaper A PANTALLA COMPLETA
    // y despues recortarla con una mascara rectangular centrada en formArea.
    //
    // Podria hacerse difuminando solo un recorte, pero entonces hay que
    // pelearse con ShaderEffectSource y sourceRect. Trabajando a pantalla
    // completa las coordenadas de la mascara y del blur ya coinciden.
    //
    // Los tres items intermedios llevan visible: false. En Qt Quick un
    // item invisible SIGUE sirviendo como fuente de un efecto: se
    // renderiza a textura pero no se dibuja en pantalla.
    Item {
        anchors.fill: parent
        visible: config.partialBlur === "true"

        // 3a. Segunda copia del wallpaper (la fuente del blur).
        Image {
            id: blurSource
            anchors.fill: parent
            source: config.background
            fillMode: Image.PreserveAspectCrop
            visible: false
        }

        // 3b. La version difuminada, todavia rectangular.
        FastBlur {
            id: blurred
            anchors.fill: parent
            source: blurSource
            radius: root.blurPx(config.blurRadius, 56)
            visible: false
        }

        // 3c. La FORMA de la mascara: donde hay blanco se ve el blur,
        //     donde no hay nada se recorta.
        //
        //     El Item exterior ocupa toda la pantalla aunque el rectangulo
        //     sea chico. Eso es a proposito: FastBlur estira su source para
        //     llenar su propia geometria, asi que si el source midiera
        //     520x760 y el blur fuera pantalla completa, la mascara saldria
        //     deformada. Con las dos cajas del mismo tamano hay
        //     correspondencia 1:1 de pixeles.
        Item {
            id: maskShape
            anchors.fill: parent
            visible: false

            Rectangle {
                id: maskRect
                color: "white"
                radius: root.dp(config.blurCorner, 0)

                // "Sangrado": cuanto sobresale el rectangulo por fuera de
                // la pantalla. Si el desvanecido ocurre en zona no visible,
                // el blur llega pegado al canto sin degradado a la vista.
                // x3 porque FastBlur difumina hacia ambos lados del borde.
                readonly property int bleed: (config.blurFlush === "true"
                                              && config.formPosition !== "center")
                                             ? root.blurPx(config.blurEdgeSoftness, 48) * 3
                                             : 0

                width: root.span(config.blurWidth, root.width, 660) + bleed
                height: root.span(config.blurHeight, root.height, 900)

                // Si blurHeight > alto de pantalla, y queda negativo y la
                // banda se sale por arriba y abajo: borde a borde.
                y: (parent.height - height) / 2

                // Se pega al lado donde este el formulario.
                x: {
                    if (config.formPosition === "right")
                        return parent.width - width + maskRect.bleed
                    if (config.formPosition === "center")
                        return (parent.width - width) / 2
                    return -maskRect.bleed // left
                }
            }
        }

        // 3d. Se difumina LA MASCARA, no el wallpaper. Ese es todo el
        //     secreto del borde suave: un rectangulo blanco borroso, usado
        //     como mascara, produce un recorte que se desvanece en los
        //     bordes en vez de cortar en seco.
        //     blurEdgeSoftness="0" desactiva esto y deja el canto nitido.
        FastBlur {
            id: softMask
            anchors.fill: parent
            source: maskShape
            radius: root.blurPx(config.blurEdgeSoftness, 48)
            visible: false
        }

        // 3e. Aplica la mascara al wallpaper difuminado. Esto SI se ve.
        OpacityMask {
            anchors.fill: parent
            source: blurred
            maskSource: softMask
        }
    }

    // ══ 4. Contenido ════════════════════════════════════════════
    // Nota sobre anchors dentro de un Column: podes usar
    // horizontalCenter (Column no controla el eje X) pero NO
    // verticalCenter ni centerIn. Qt tira un warning y los ignora.
    Column {
        anchors.centerIn: formArea
        width: formArea.width
        spacing: 0

        Clock {
            width: parent.width
            textColor: root.cText
            fontFamily: root.uiFont
            hourFormat: config.hourFormat
            dateFormat: config.dateFormat
            timeSize: root.dp(config.clockSize, 75)
            dateSize: root.dp(config.dateSize, 20)
        }

        Item { width: 1; height: root.dp(config.gapClockForm, 80) }

        LoginForm {
            width: parent.width
            uiScale: root.uiScale
            fontFamily: root.uiFont
            iconFont: root.iconFont
            fieldColor: root.cField
            fieldTextColor: root.cFieldText
            placeholderColor: root.cPlaceholder
            buttonColor: root.cButton
            buttonTextColor: root.cButtonText
            warningColor: root.cWarning
            accentColor: root.cAccent
            textSize: root.dp(config.fontSize, 13)
            iconSize: root.dp(config.fieldIconSize, 16)
            fieldHeight: root.dp(config.fieldHeight, 42)
        }

        Item { width: 1; height: root.dp(config.gapFormSystem, 56) }

        SystemButtons {
            width: parent.width
            uiScale: root.uiScale
            iconColor: root.cIcon
            hoverColor: root.cAccent
            fontFamily: root.uiFont
            iconFont: root.iconFont
            iconSize: root.dp(config.sysIconSize, 21)
            labelSize: root.dp(config.sysLabelSize, 12)
            forceVisible: config.forceSystemButtons === "true"
        }
    }
}
