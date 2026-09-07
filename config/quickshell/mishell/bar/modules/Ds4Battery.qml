// Mando de PS4 (custom/ds4-battery). Oculto si no hay mando conectado.
import QtQuick
import qs.bar
import qs.bar.services

Module {
    visible: Ds4.presente
    icono: {
        if (Ds4.estado === "Charging") return "󰨢"
        if (Ds4.estado === "Full")     return "󰝍"
        if (Ds4.capacidad >= 66)       return "󰝏"
        if (Ds4.capacidad >= 33)       return "󰝎"
        return "󰝋"
    }
    texto: Ds4.capacidad + "%"
    color: Ds4.estado === "Charging" ? BarConfig.verde
         : Ds4.capacidad < 20 ? BarConfig.rojo : BarConfig.texto
    tooltip: "DualShock 4: " + Ds4.capacidad + "% (" + Ds4.estado + ")"
}
