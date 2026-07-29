// Theme.qml
pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    // Superficie
    property color velo:            "#cc11111b"     // RECTANGULO OVERLAY
    property color colorBoton:      "#002c3f"       // Color del boton normal
    property color colorBotonHover: "#22516c"       // Color del boton en hover
    property color colorBorde:      "#313244"       // Color del borde normal
    property color colorBordeHover: "#89b4fa"       // Color del borde en hover

    // Texto
    property color texto:      "#cdd6f4"            // Color del comando e iconos
    property color textoSuave: "#bac2de"            // Color apagado del icono
    property color textoTenue: "#6c7086"            // Texto de atajo de los botones


    // Wallpaper picker
    property color veloWallpaper:   "#8c11111b"     // VELO DE FONDO DEL PICKER (mas claro que el del logout)
    property color fondoTarjeta:    "#1e1e2e"       // Relleno que se ve detras de la foto
    property color fondoBarra:      "#eb181825"     // Barra superior de filtros
    property color fondoBadge:      "#b311111b"     // Cuadrito del icono de video
    property color superficie:      "#313244"       // Chip inactivo y etiqueta de estado
    property color superficieAlta:  "#585b70"       // Chip activo y borde de la barra
    property color bordeChip:       "#45475a"       // Borde del chip inactivo
    property color acento:          "#cba6f7"       // Marco de las tarjetas de video

    // Tipografía y geometría
    property string fuente: "JetBrainsMono Nerd Font"
    property int duracionColor:  120                  // Duracion de transicion del color
    property int duracionScale: 160                   // Duracion de transicion del scale
}