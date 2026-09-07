pragma Singleton
// ---------------------------------------------------------------------------
//  BarColors.qml  --  los colores de la barra que SIGUEN AL WALLPAPER.
//
//  Este archivo existe para ucs: es el unico de bar/ que entra en su lista
//  de archivos, asi solo escanea (y reescribe) los colores que de verdad
//  queremos que cambien con el fondo. El resto de la paleta, fija, vive en
//  BarConfig.qml. Para que un color siga al wallpaper: se define aqui, se
//  usa desde el modulo como BarColors.<nombre> y se agrega el archivo al
//  config.json de ucs (el mapeo lo maneja ucs).
// ---------------------------------------------------------------------------
import Quickshell
import QtQuick

Singleton {
    property color logo: "#e93a5b"     // icono de CachyOS del launcher
}
