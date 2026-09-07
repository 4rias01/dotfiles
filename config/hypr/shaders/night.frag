// night.frag  --  "modo noche": filtro calido para la pantalla.
// Lo activa el boton de la luna del centro de swaync (swaync/scripts/night.sh)
// via  decoration:screen_shader; hypr/modules/night.lua lo vuelve a poner al
// recargar Hyprland si quedo encendido.
//
// Para ajustarlo: CALIDEZ (0 = sin cambio, 1 = muy naranja) y BRILLO.
#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float CALIDEZ = 0.55;
const float BRILLO  = 0.92;

void main() {
    vec4 c = texture(tex, v_texcoord);
    // ~3400 K: se quita azul sobre todo, algo de verde, el rojo se queda
    vec3 calido = vec3(1.0, 0.80, 0.58);
    vec3 filtro = mix(vec3(1.0), calido, CALIDEZ);
    fragColor = vec4(c.rgb * filtro * BRILLO, c.a);
}
