// ════════════════════════════════════════════════════════════════
//  SystemButtons.qml — Shutdown / Reboot / Suspend / Hibernate.
//
//  Ejemplo de Repeater: en vez de escribir cuatro bloques casi iguales,
//  se define UN delegate y se lo instancia una vez por elemento del
//  model. Es el patron que vas a usar constantemente en Quickshell.
//
//  La raiz es un Item (no un Row) porque este componente se usa dentro
//  de un Column, y dentro de un Column no se puede centrar
//  verticalmente con anchors. El Item da una caja de alto fijo y el Row
//  se centra libremente dentro de ella.
// ════════════════════════════════════════════════════════════════

import QtQuick

Item {
    id: bar

    // Factor de escala global, para las medidas propias del componente.
    property real uiScale: 1.0

    property color iconColor: "#f8f8f2"
    property color hoverColor: "#b7cef1"
    property string fontFamily: "Sans"
    property string iconFont: "Sans"
    property int iconSize: 21
    property int labelSize: 12

    // sddm.canPowerOff y compania son false en --test-mode, asi que sin
    // esto los botones no aparecen mientras desarrollas.
    property bool forceVisible: false

    function dp(v) { return Math.round(v * bar.uiScale) }

    // La altura sale del contenido en vez de ser un numero fijo: asi
    // acompana sola a iconSize/labelSize y a la escala de la pantalla.
    // (anchors.centerIn solo posiciona, no dimensiona: no hay loop.)
    implicitHeight: row.implicitHeight
    height: implicitHeight

    function trigger(i) {
        if (i === 0)
            sddm.powerOff()
        else if (i === 1)
            sddm.reboot()
        else if (i === 2)
            sddm.suspend()
        else if (i === 3)
            sddm.hibernate()
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: bar.dp(14)

        Repeater {
            // Un array de JS sirve perfectamente como model. Dentro del
            // delegate cada objeto esta disponible como `modelData`, y su
            // posicion como `index`.
            model: [
                { glyph: "\uf011", label: "Shutdown",  ok: sddm.canPowerOff },
                { glyph: "\uf021", label: "Reboot",    ok: sddm.canReboot },
                { glyph: "\uf04c", label: "Suspend",   ok: sddm.canSuspend },
                { glyph: "\uf186", label: "Hibernate", ok: sddm.canHibernate }
            ]

            delegate: Item {
                // La caja se ajusta al contenido mas un margen. Antes era
                // 66x50 fijo, medido a ojo para el tamano de fuente de
                // 1366x768: con otra escala el label se salia o sobraba aire.
                width: content.implicitWidth + bar.dp(8)
                height: content.implicitHeight + bar.dp(6)
                visible: bar.forceVisible || modelData.ok

                // El MouseArea cubre toda la caja, no solo el icono:
                // el label tambien es clickeable.
                MouseArea {
                    id: hit
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.trigger(index)
                }

                Column {
                    id: content
                    anchors.centerIn: parent
                    spacing: bar.dp(5)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.glyph
                        color: hit.containsMouse ? bar.hoverColor : bar.iconColor
                        font.family: bar.iconFont
                        font.pixelSize: bar.iconSize
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: hit.containsMouse ? bar.hoverColor : bar.iconColor
                        font.family: bar.fontFamily
                        font.pixelSize: bar.labelSize
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
            }
        }
    }
}
