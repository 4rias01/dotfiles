// ---------------------------------------------------------------------------
//  Grafica.qml  --  grafica de lineas del panel de sistema.
//
//  series: lista de { datos: [numeros], color: "#rrggbb", relleno: bool,
//                     max: numero (0 = escala automatica compartida) }
//  La muestra mas nueva queda a la derecha; si todavia hay menos de
//  `puntos` muestras la linea arranca desde la mitad, como en noctalia.
//  Las series con max = 0 comparten una escala automatica (la red: bajada y
//  subida en la misma escala), con piso `minAuto`.
// ---------------------------------------------------------------------------
import QtQuick
import qs.bar

Canvas {
    id: root

    property var  series: []
    property int  puntos: BarConfig.puntosHistorial
    property real minAuto: 1
    property real grosor: 2

    implicitHeight: 64
    antialiasing: true
    renderStrategy: Canvas.Cooperative

    onSeriesChanged: requestPaint()
    onWidthChanged:  requestPaint()
    onHeightChanged: requestPaint()

    function conAlfa(c: string, a: real): string {
        // string CSS: el Canvas no entiende el #AARRGGBB de Qt
        const col = Qt.color(c)
        return "rgba(" + Math.round(col.r * 255) + "," + Math.round(col.g * 255) + ","
             + Math.round(col.b * 255) + "," + a + ")"
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width, h = height
        if (w <= 0 || h <= 0) return

        // escala automatica compartida
        let auto = root.minAuto
        for (const s of root.series)
            if (!s.max) for (const v of (s.datos || [])) auto = Math.max(auto, v)

        const paso = w / Math.max(1, root.puntos - 1)
        const margen = root.grosor + 1

        for (const s of root.series) {
            const d = s.datos || []
            if (d.length < 2) continue
            const max = s.max || auto
            const x0 = w - (d.length - 1) * paso
            const yDe = v => h - margen - Math.min(1, Math.max(0, v / max)) * (h - 2 * margen)

            ctx.beginPath()
            ctx.moveTo(x0, yDe(d[0]))
            for (let i = 1; i < d.length; i++) ctx.lineTo(x0 + i * paso, yDe(d[i]))

            if (s.relleno) {
                ctx.save()
                ctx.lineTo(x0 + (d.length - 1) * paso, h)
                ctx.lineTo(x0, h)
                ctx.closePath()
                const g = ctx.createLinearGradient(0, 0, 0, h)
                g.addColorStop(0, root.conAlfa(s.color, 0.28))
                g.addColorStop(1, root.conAlfa(s.color, 0.02))
                ctx.fillStyle = g
                ctx.fill()
                ctx.restore()
                // rehacer el trazo sin el cierre del relleno
                ctx.beginPath()
                ctx.moveTo(x0, yDe(d[0]))
                for (let i = 1; i < d.length; i++) ctx.lineTo(x0 + i * paso, yDe(d[i]))
            }

            ctx.lineWidth = root.grosor
            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            ctx.strokeStyle = root.conAlfa(s.color, 1)
            ctx.stroke()
        }
    }
}
