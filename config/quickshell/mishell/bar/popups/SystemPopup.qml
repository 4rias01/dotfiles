// ---------------------------------------------------------------------------
//  SystemPopup.qml  --  panel "Sistema" (inspirado en el de noctalia).
//
//  Seis tarjetas en dos columnas:
//      CPU (uso + temperatura)   | Memoria
//      GPU (uso + temperatura)   | Red (bajada + subida)
//      Sistema (CPU, GPU, SO, kernel, compositor, encendido) | Recursos
//
//  Las graficas salen del historial de SysStats y GpuStats (se muestrea
//  siempre, asi que al abrir el panel ya hay datos). La tarjeta de GPU se
//  oculta si no hay grafica que medir.
//
//  Se abre con clic en CPU / RAM / temperatura / GPU de la barra, o con
//      qs ipc -c mishell call bar popup sistema
// ---------------------------------------------------------------------------
import QtQuick
import Quickshell
import qs.bar
import qs.bar.services

Column {
    id: root
    spacing: 12

    readonly property int anchoTarjeta: 250
    readonly property int sep: 10
    width: 2 * root.anchoTarjeta + root.sep

    // --- cabecera ------------------------------------------------------------
    Item {
        width: parent.width
        height: 30

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Sistema"
            color: BarConfig.colorPanelTitulo
            font.family: BarConfig.fuente
            font.pixelSize: 20
            font.bold: true
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            BotonCabecera {
                icono: "󰆍"
                tip: "btop"
                onActivado: { BarState.cerrarPopup(); Quickshell.execDetached(BarConfig.cmdCpu) }
            }
            BotonCabecera {
                icono: "󰅖"
                tip: "cerrar"
                onActivado: BarState.cerrarPopup()
            }
        }
    }

    Grid {
        columns: 2
        columnSpacing: root.sep
        rowSpacing: root.sep

        // ---------------- CPU ----------------
        Tarjeta {
            titulo: "CPU"
            Grafica {
                width: parent.width
                series: [
                    { datos: SysStats.histTemp, color: BarConfig.colorGraficaTemp, max: 100 },
                    { datos: SysStats.histCpu,  color: BarConfig.colorGraficaUso,  max: 100 }
                ]
            }
            Pie {
                Valor { icono: "󰓅"; texto: SysStats.cpu + "%"; color: BarConfig.colorGraficaUso }
                Valor { icono: "󰈸"; texto: SysStats.temp + "°C"; color: BarConfig.colorGraficaTemp; visible: SysStats.temp > 0 }
            }
        }

        // ---------------- Memoria ----------------
        Tarjeta {
            titulo: "Memoria"
            Grafica {
                width: parent.width
                series: [ { datos: SysStats.histMem, color: BarConfig.colorGraficaUso, max: 100 } ]
            }
            Pie {
                Valor {
                    icono: "󰍛"
                    texto: SysStats.gib(SysStats.memUsadaKiB) + " GiB · " + SysStats.mem + "%"
                    color: BarConfig.colorGraficaUso
                }
            }
        }

        // ---------------- GPU ----------------
        Tarjeta {
            titulo: "GPU"
            visible: GpuStats.disponible
            Grafica {
                width: parent.width
                series: [
                    { datos: GpuStats.histTemp, color: BarConfig.colorGraficaTemp, max: 100 },
                    { datos: GpuStats.histUso,  color: BarConfig.colorGraficaUso,  max: 100, relleno: true }
                ]
            }
            Pie {
                Valor { icono: "󰍹"; texto: GpuStats.suspendida ? "reposo" : GpuStats.uso + "%"; color: BarConfig.colorGraficaUso }
                Valor { icono: "󰍛"; texto: (GpuStats.vramUsadaMiB / 1024).toFixed(1) + " GiB"; color: BarConfig.colorGraficaUso; visible: !GpuStats.suspendida }
                Valor { icono: "󰔏"; texto: GpuStats.temp + "°C"; color: BarConfig.colorGraficaTemp; visible: !GpuStats.suspendida }
            }
        }

        // ---------------- Red ----------------
        Tarjeta {
            titulo: "Red"
            Grafica {
                width: parent.width
                minAuto: 4096          // 4 kB/s: que el ruido no llene la grafica
                series: [
                    { datos: SysStats.histTx, color: BarConfig.colorGraficaSubida },
                    { datos: SysStats.histRx, color: BarConfig.colorGraficaBajada }
                ]
            }
            Pie {
                Valor { icono: "󰇚"; texto: SysStats.velocidad(SysStats.rxBps); color: BarConfig.colorGraficaBajada }
                Valor { icono: "󰕒"; texto: SysStats.velocidad(SysStats.txBps); color: BarConfig.colorGraficaSubida }
            }
        }

        // ---------------- Sistema ----------------
        Tarjeta {
            titulo: "Sistema"
            alto: 178
            Fila { icono: "󰓅"; texto: SysStats.cpuModelo }
            Fila { icono: "󰢮"; texto: GpuStats.nombre; visible: GpuStats.nombre !== "" }
            Fila { icono: "󰌽"; texto: SysStats.so }
            Fila { icono: "󰘚"; texto: "Linux " + SysStats.kernel }
            Fila { icono: "󰖯"; texto: "Hyprland" }
            Fila { icono: "󰥔"; texto: "Encendido " + SysStats.duracion(SysStats.uptimeSeg) }
        }

        // ---------------- Recursos ----------------
        Tarjeta {
            titulo: "Recursos"
            alto: 178
            Dato { icono: "󰗶"; etiqueta: "Carga CPU"; valor: SysStats.carga }
            Dato {
                icono: "󰍛"; etiqueta: "RAM"
                valor: SysStats.gib(SysStats.memUsadaKiB) + " / " + SysStats.gib(SysStats.memTotalKiB) + " GiB"
            }
            Dato {
                icono: "󰓡"; etiqueta: "Swap"
                valor: SysStats.gib(SysStats.swapUsadaKiB) + " / " + SysStats.gib(SysStats.swapTotalKiB) + " GiB"
            }
            Dato {
                icono: "󰋊"; etiqueta: "/"
                valor: SysStats.discoTotal > 0
                       ? (SysStats.discoUsado / 1e9).toFixed(1) + " / " + (SysStats.discoTotal / 1e9).toFixed(1)
                         + " GB (" + Math.round(100 * SysStats.discoUsado / SysStats.discoTotal) + "%)"
                       : "—"
            }
        }
    }

    // =======================================================================
    //  Componentes internos
    // =======================================================================

    // Tarjeta: titulo + contenido apilado. Todas miden lo mismo por fila.
    component Tarjeta: Rectangle {
        id: tarjeta
        property string titulo: ""
        property int alto: 140      // las de graficas; las de texto usan 178
        default property alias contenido: col.data
        width: root.anchoTarjeta
        height: tarjeta.alto
        radius: 12
        color: BarConfig.tarjetaFondo
        border.width: 1
        border.color: BarConfig.popupBorde

        Column {
            id: col
            x: 12; y: 10
            width: parent.width - 24
            spacing: 6

            Text {
                text: tarjeta.titulo
                color: BarConfig.texto
                font.family: BarConfig.fuente
                font.pixelSize: 16
                font.bold: true
            }
        }
    }

    // Pie de las tarjetas con grafica: valores centrados
    component Pie: Item {
        default property alias contenido: filaPie.data
        width: parent ? parent.width : 0
        height: 20
        Row {
            id: filaPie
            anchors.centerIn: parent
            spacing: 14
        }
    }

    component Valor: Row {
        property string icono: ""
        property string texto: ""
        property color  color: BarConfig.texto
        spacing: 5
        Text {
            text: parent.icono
            color: parent.color
            font.family: BarConfig.fuente
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: parent.texto
            color: parent.color
            font.family: BarConfig.fuente
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Fila de la tarjeta "Sistema": icono + texto que se corta con …
    component Fila: Row {
        property string icono: ""
        property string texto: ""
        width: parent ? parent.width : 0
        spacing: 7
        Text {
            id: ic
            text: parent.icono
            color: BarConfig.textoTenue
            font.family: BarConfig.fuente
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            width: parent.width - ic.width - parent.spacing
            text: parent.texto
            elide: Text.ElideRight
            color: BarConfig.texto
            font.family: BarConfig.fuente
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Fila de "Recursos": icono + etiqueta a la izquierda, valor a la derecha
    component Dato: Item {
        property string icono: ""
        property string etiqueta: ""
        property string valor: ""
        width: parent ? parent.width : 0
        height: 22
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            Text {
                text: parent.parent.icono
                color: BarConfig.textoTenue
                font.family: BarConfig.fuente
                font.pixelSize: 12
            }
            Text {
                text: parent.parent.etiqueta
                color: BarConfig.texto
                font.family: BarConfig.fuente
                font.pixelSize: 12
            }
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: parent.valor
            color: BarConfig.texto
            font.family: BarConfig.fuente
            font.pixelSize: 12
        }
    }

    component BotonCabecera: Rectangle {
        id: boton
        property string icono: ""
        property string tip: ""
        signal activado()
        width: 30; height: 30
        radius: 8
        color: ma.containsMouse ? BarConfig.hover : "transparent"
        border.width: 1
        border.color: BarConfig.popupBorde
        scale: ma.pressed ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 2 } }
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: boton.icono
            color: BarConfig.texto
            font.family: BarConfig.fuente
            font.pixelSize: 15
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: boton.activado()
        }
    }
}
