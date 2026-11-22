// ---------------------------------------------------------------------------
//  Idioma.qml  --  distribucion activa: ES / EN.
//  Clic o rueda: pasa a la siguiente (latam <-> us). Tambien SUPER + K.
//  Las distribuciones se eligen en hypr/modules/input.lua (kb_layout).
// ---------------------------------------------------------------------------
import QtQuick
import qs.bar
import qs.bar.services as S

Module {
    id: root

    icono: "󰌌"
    texto: S.Teclado.corto
    negrita: true
    popAlCambiar: true
    color: S.Teclado.corto === "EN" ? BarConfig.azul : BarConfig.texto
    tooltip: "Teclado: " + S.Teclado.legible(S.Teclado.nombre)
           + "\nClic: cambiar (SUPER + K)"

    onClic:        { root.pulso(); S.Teclado.siguiente() }
    onClicDerecho: { root.pulso(); S.Teclado.siguiente() }
    onRueda:       S.Teclado.siguiente()
}
