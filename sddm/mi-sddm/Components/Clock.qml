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
    // Los tamanos llegan en PIXELES ya escalados por Main.qml. Ver la nota
    // sobre pixelSize vs pointSize al pie de este archivo.
    property color textColor: "#ffffff"
    property string fontFamily: "Sans"
    property string hourFormat: "HH:mm"
    property string dateFormat: "dddd d MMMM"
    property int timeSize: 75
    property int dateSize: 20

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
        font.pixelSize: clock.timeSize
        font.bold: true
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.now, clock.dateFormat)
        color: clock.textColor
        font.family: clock.fontFamily
        font.pixelSize: clock.dateSize
        font.bold: true
    }
}

// ── pixelSize y no pointSize ────────────────────────────────────
// Un "point" es una medida FISICA: Qt lo convierte a pixeles usando los
// DPI que reporta la pantalla. Como el tema ya escala sus medidas contra
// la resolucion, usar pointSize haria que el DPI se cuente dos veces y el
// texto saldria desproporcionado en un panel denso (un 1080p de 15" tiene
// ~40% mas DPI que un 1366x768 del mismo tamano).
//
// Con pixelSize el tamano depende de una sola cosa: el factor de escala.

