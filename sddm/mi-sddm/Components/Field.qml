// ════════════════════════════════════════════════════════════════
//  Field.qml — input redondeado con icono a la izquierda.
//
//  Hereda de TextField (Qt Quick Controls). "Heredar" en QML significa
//  poner ese tipo como raiz: automaticamente tenes todas sus propiedades
//  (text, placeholderText, echoMode, onAccepted...) mas las que agregues.
//
//  Los Controls se estilan reemplazando sus items internos:
//    background  → lo que se dibuja detras
//    contentItem → donde se dibuja el texto
//  Aca solo reemplazamos background; el contentItem por defecto sirve.
// ════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Controls

TextField {
    id: field

    property string glyph: "" // caracter del icono (Nerd Font)
    property string iconFont: "Sans"
    property string fontFamily: "Sans"
    property int textSize: 13
    property int iconSize: 16
    property color bgColor: "#2a2d3a"
    property color fgColor: "#ffffff"
    property color phColor: "#a0a4b8"

    height: 42

    // Los paddings y la sangria del icono salen de la ALTURA del campo,
    // que ya viene escalada. Asi la pastilla mantiene sus proporciones en
    // cualquier resolucion sin que este componente sepa nada de la escala.
    // (El eje horizontal no realimenta la altura, no hay binding loop.)
    readonly property int hPadding: Math.round(height * 1.15)
    readonly property int iconInset: Math.round(height * 0.52)

    // Los dos paddings iguales. Si fueran distintos, el texto centrado
    // quedaria corrido hacia el lado del padding mas chico: se centra
    // dentro del area util, no dentro del campo.
    leftPadding: field.hPadding
    rightPadding: field.hPadding

    horizontalAlignment: TextInput.AlignHCenter
    verticalAlignment: TextInput.AlignVCenter

    color: field.fgColor
    placeholderTextColor: field.phColor
    font.family: field.fontFamily
    font.pixelSize: field.textSize
    font.bold: true
    selectByMouse: true

    background: Rectangle {
        color: field.bgColor
        radius: height / 2 // pastilla perfecta

        // Un borde que aparece solo cuando el campo tiene el foco.
        // Behavior anima cualquier cambio de la propiedad que envuelve.
        border.width: field.activeFocus ? Math.max(1, Math.round(height / 21)) : 0
        border.color: Qt.lighter(field.bgColor, 1.8)
        Behavior on border.width { NumberAnimation { duration: 120 } }
    }

    // El icono. Al ser hijo del TextField se dibuja encima del background.
    Text {
        text: field.glyph
        color: field.fgColor
        font.family: field.iconFont
        font.pixelSize: field.iconSize
        x: field.iconInset
        anchors.verticalCenter: parent.verticalCenter
    }
}
