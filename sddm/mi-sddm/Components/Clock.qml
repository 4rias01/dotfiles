// ════════════════════════════════════════════════════════════════
//  Clock.qml — hora grande + fecha debajo.
//
//  Un archivo .qml cuyo nombre empieza en mayuscula ES un componente
//  reutilizable. El tipo raiz (aca Column) define que es el componente,
//  y las `property` que declares son sus parametros de entrada.
// ════════════════════════════════════════════════════════════════

import QtQuick

Column {
    id: clock

    // ── Parametros (los setea quien use <Clock ... />) ──
    property color textColor: "#ffffff"
    property string fontFamily: "Sans"
    property string hourFormat: "HH:mm"
    property string dateFormat: "dddd d MMMM"
    property int timeSize: 56
    property int dateSize: 15

    // ── Estado interno ──
    // Los dos Text de abajo estan BINDEADOS a esta propiedad: cuando el
    // Timer la cambia, se redibujan solos. Eso es reactividad en QML,
    // no hace falta llamar a ningun "update()".
    property date now: new Date()

    spacing: 0

    // Timer no es un Item, asi que Column lo ignora al posicionar.
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: clock.now = new Date()
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.now, clock.hourFormat)
        color: clock.textColor
        font.family: clock.fontFamily
        font.pointSize: clock.timeSize
        font.bold: true
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.now, clock.dateFormat)
        color: clock.textColor
        font.family: clock.fontFamily
        font.pointSize: clock.dateSize
        font.bold: true
    }
}
