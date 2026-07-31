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

    property color iconColor: "#f8f8f2"
    property color hoverColor: "#b7cef1"
    property string fontFamily: "Sans"
    property string iconFont: "Sans"
    property int iconSize: 16
    property int labelSize: 9

    // sddm.canPowerOff y compania son false en --test-mode, asi que sin
    // esto los botones no aparecen mientras desarrollas.
    property bool forceVisible: false

    implicitHeight: 54
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
        anchors.centerIn: parent
        spacing: 14

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
                width: 66
                height: 50
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
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.glyph
                        color: hit.containsMouse ? bar.hoverColor : bar.iconColor
                        font.family: bar.iconFont
                        font.pointSize: bar.iconSize
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: hit.containsMouse ? bar.hoverColor : bar.iconColor
                        font.family: bar.fontFamily
                        font.pointSize: bar.labelSize
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
            }
        }
    }
}
