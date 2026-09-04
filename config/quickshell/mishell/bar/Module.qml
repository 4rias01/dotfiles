// ---------------------------------------------------------------------------
//  Module.qml  --  base de todos los modulos de la barra.
//
//  Icono + texto (+ un sufijo chico opcional) con:
//    - fondo de hover que aparece en fade,
//    - rebote de escala al pasar el mouse y "aplastado" al hacer clic
//      (la animacion "burbuja": Easing.OutBack con overshoot),
//    - parpadeo opcional (bateria baja),
//    - puntito rojo opcional sobre el icono (notificaciones pendientes),
//    - rebote del texto cuando cambia (volumen, brillo),
//    - tooltip: se registra en la ventana de la barra (Bar.qml) tras 650 ms.
//
//  Senales: clic, clicDerecho, clicMedio, rueda(+1 arriba / -1 abajo).
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell
import qs.bar

Item {
    id: root

    property string icono: ""
    property string texto: ""
    property string sufijo: ""
    property color  color: BarConfig.texto
    property color  colorIcono: root.color
    property color  colorSufijo: BarConfig.textoTenue
    property bool   negrita: false
    property string tooltip: ""
    property bool   activo: false          // mantiene el fondo de hover (popup abierto)
    property bool   parpadeo: false
    property bool   punto: false
    property color  colorPunto: BarConfig.rojo
    property bool   popAlCambiar: false
    property int    separacion: 5
    property int    tamIcono: BarConfig.tamIcono
    // Contenido extra despues del texto (el marquee de Media lo usa)
    property alias  extra: extraCont.data

    signal clic()
    signal clicDerecho()
    signal clicMedio()
    signal rueda(int direccion)

    // El hover sale de un HoverHandler y no de MouseArea.containsMouse: el
    // segundo se quedaba a veces sin actualizar (modulo con fondo de hover y
    // tooltip pero sin crecer), el handler recibe los eventos de puntero
    // directo del compositor.
    readonly property bool hovered: hover.hovered

    height: parent ? parent.height : BarConfig.alto
    implicitWidth: fila.implicitWidth + 2 * BarConfig.paddingModulo
    width: implicitWidth
    z: root.hovered ? 1 : 0

    Behavior on width {
        NumberAnimation { duration: BarConfig.durAncho; easing.type: Easing.OutCubic }
    }

    // --- burbuja: escala con rebote -----------------------------------------
    //  Animacion explicita (no un Behavior sobre un binding): cada cambio de
    //  hover/pulsado relanza la animacion hacia el objetivo desde donde este.
    transformOrigin: Item.Center
    readonly property real escalaObjetivo: mouse.pressed ? BarConfig.escalaClic
                                         : (root.hovered ? BarConfig.escalaHover : 1)
    onEscalaObjetivoChanged: {
        escalaAnim.stop()
        escalaAnim.to = root.escalaObjetivo
        escalaAnim.start()
    }
    NumberAnimation {
        id: escalaAnim
        target: root
        property: "scale"
        duration: BarConfig.durPop
        easing.type: Easing.OutBack
        easing.overshoot: BarConfig.overshoot
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        radius: BarConfig.radioModulo
        color: BarConfig.hover
        opacity: (root.hovered || root.activo) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: BarConfig.durHover } }
    }

    Row {
        id: fila
        anchors.centerIn: parent
        spacing: root.separacion
        transformOrigin: Item.Center

        Item {
            visible: root.icono !== ""
            width: iconoTxt.implicitWidth
            height: iconoTxt.implicitHeight
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: iconoTxt
                text: root.icono
                color: root.colorIcono
                font.family: BarConfig.fuente
                font.pixelSize: root.tamIcono
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Rectangle {
                visible: root.punto
                width: 6; height: 6; radius: 3
                color: root.colorPunto
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: -3
                anchors.topMargin: -1
                scale: root.punto ? 1 : 0
                Behavior on scale {
                    NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
                }
            }
        }

        Text {
            visible: root.texto !== ""
            text: root.texto
            color: root.color
            font.family: BarConfig.fuente
            font.pixelSize: BarConfig.tamFuente
            font.bold: root.negrita
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Text {
            visible: root.sufijo !== ""
            text: root.sufijo
            color: root.colorSufijo
            font.family: BarConfig.fuente
            font.pixelSize: BarConfig.tamFuente - 3
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Item {
            id: extraCont
            visible: children.length > 0
            width: childrenRect.width
            height: root.height
        }
    }

    // --- parpadeo (bateria baja) ---------------------------------------------
    SequentialAnimation {
        running: root.parpadeo
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "opacity"; to: 0.3; duration: 450; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "opacity"; to: 1;   duration: 450; easing.type: Easing.InOutSine }
        onRunningChanged: if (!running) root.opacity = 1
    }

    // --- pulso: rebote de todo el modulo (clics que abren algo externo) ------
    function pulso(): void { pulsoAnim.restart() }
    SequentialAnimation {
        id: pulsoAnim
        NumberAnimation { target: fila; property: "scale"; to: 0.7;  duration: 70;  easing.type: Easing.InQuad }
        NumberAnimation { target: fila; property: "scale"; to: 1.35; duration: 160; easing.type: Easing.OutQuad }
        NumberAnimation { target: fila; property: "scale"; to: 1;    duration: 320; easing.type: Easing.OutBack; easing.overshoot: 3 }
    }

    // --- rebote del texto al cambiar --------------------------------------
    property bool _listo: false
    Component.onCompleted: _listo = true
    onTextoChanged: if (root.popAlCambiar && root._listo) pop.restart()
    SequentialAnimation {
        id: pop
        NumberAnimation { target: fila; property: "scale"; to: 1.22; duration: 80;  easing.type: Easing.OutQuad }
        NumberAnimation { target: fila; property: "scale"; to: 1;    duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
    }

    // --- mouse ---------------------------------------------------------------
    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    onHoveredChanged: {
        if (root.hovered) {
            tooltipTimer.restart()
        } else {
            tooltipTimer.stop()
            root.quitarTooltip()
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: e => {
            if (e.button === Qt.LeftButton)       root.clic()
            else if (e.button === Qt.RightButton) root.clicDerecho()
            else                                  root.clicMedio()
        }
        onWheel: e => root.rueda(e.angleDelta.y > 0 ? 1 : -1)
    }

    // --- tooltip -----------------------------------------------------------
    //  La ventana de la barra (Bar.qml) tiene `tooltipItem` y `tooltipTexto`;
    //  aqui solo se registran. QsWindow.window es la PanelWindow que nos
    //  contiene.
    Timer {
        id: tooltipTimer
        interval: 650
        onTriggered: {
            const w = root.QsWindow.window
            if (w && root.tooltip !== "" && root.hovered) {
                w.tooltipItem = root
                w.tooltipTexto = root.tooltip
            }
        }
    }
    onTooltipChanged: {
        const w = root.QsWindow.window
        if (w && w.tooltipItem === root) {
            if (root.tooltip === "") root.quitarTooltip()
            else w.tooltipTexto = root.tooltip
        }
    }
    function quitarTooltip(): void {
        const w = root.QsWindow.window
        if (w && w.tooltipItem === root) {
            w.tooltipItem = null
            w.tooltipTexto = ""
        }
    }
}
