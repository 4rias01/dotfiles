import QtQuick
import qs.bar
import qs.bar.services

Module {
    readonly property bool critica: SysStats.temp >= BarConfig.tempCritica
    visible: SysStats.temp > 0
    icono: critica ? "" : ""
    texto: SysStats.temp + "°C"
    color: critica ? BarConfig.rojo : BarConfig.texto
    tooltip: "Temperatura del CPU"
}
