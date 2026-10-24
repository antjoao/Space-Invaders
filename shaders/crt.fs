extern vec2 screenSize;
extern number time;

// Função para gerar a curvatura da tela de tubo
vec2 curve(vec2 uv) {
    uv = (uv - 0.5) * 2.0;
    uv *= 1.1;
    uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
    uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
    uv = (uv / 2.0) + 0.5;
    uv = uv * 0.92 + 0.04;
    return uv;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Aplica a curvatura
    vec2 uv = curve(texture_coords);

    // Se a coordenada ficar fora da tela (por causa da curva), pinta de preto
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }

    // Pega a cor original
    vec4 texcolor = Texel(texture, uv);

    // Efeito de Scanlines (linhas horizontais)
    float scanline = sin(uv.y * screenSize.y * 1.5) * 0.04;
    texcolor.rgb -= scanline;

    // Máscara de fósforo (pontinhos RGB)
    float mask = sin(uv.x * screenSize.x * 3.14159);
    texcolor.rgb *= (0.9 + 0.1 * mask);

    // Efeito de Vinheta (bordas escuras)
    float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
    vignette = clamp(pow(16.0 * vignette, 0.25), 0.0, 1.0);
    texcolor.rgb *= vignette;

    // Leve brilho nas cores (opcional, tira um pouco do "escuro")
    texcolor.rgb *= 1.1;

    return texcolor;
}
