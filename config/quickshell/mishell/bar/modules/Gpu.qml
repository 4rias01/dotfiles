// ---------------------------------------------------------------------------
//  Gpu.qml  --  temperatura de la grafica (NVIDIA o AMD, ver GpuStats).
//  Se oculta solo si no hay GPU que medir. Clic: panel de sistema.
// ---------------------------------------------------------------------------
import QtQuick
import qs.bar
import qs.bar.services

Module {
    id: root

    required property string pantalla

    readonly property bool caliente: GpuStats.temp >= BarConfig.gpuTempAviso
    visible: GpuStats.disponible && GpuStats.listo
    icono: "󰢮"
    texto: GpuStats.suspendida ? "zz" : GpuStats.temp + "°C"
    color: root.caliente ? BarConfig.rojo : BarConfig.texto
    activo: BarState.popupActivo("sistema", root.pantalla)
    tooltip: GpuStats.nombre
           + (GpuStats.suspendida ? "\nEn reposo (no se despierta para medirla)"
              : "\nUso " + GpuStats.uso + "% · VRAM "
                + (GpuStats.vramUsadaMiB / 1024).toFixed(1) + " / "
                + (GpuStats.vramTotalMiB / 1024).toFixed(1) + " GiB")

    onClic: BarState.alternarPopup("sistema", root.pantalla)
}
