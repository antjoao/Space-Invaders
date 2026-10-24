# 🚀 Space Invaders — Remake Arcade

Um remake moderno e turbinado do clássico **Space Invaders**, construído do zero em **Lua** com o framework **LÖVE 2D**. 

Esqueça o jogo lento dos anos 70. Aqui você tem dash, boss fights, explosões de partículas, efeito de tela de tubo (CRT), loja de melhorias e um placar online global.

---

## 🎮 Como Jogar

### Instalação Rápida
1. Baixe e instale o [LÖVE 2D (versão 11.5+)](https://love2d.org/).
2. Clone este repositório:
   ```bash
   git clone https://github.com/antjoao/Space-Invaders.git
   cd Space-Invaders
   ```
3. Rode o jogo:
   ```bash
   love .
   ```

### Requisitos do Placar Online (Opcional)
Para o placar online funcionar, você precisa rodar o servidor Python que acompanha o projeto:
```bash
# Em outro terminal
python3 server.py
```

---

## 🕹️ Controles

| Ação | Tecla |
| :--- | :--- |
| **Mover** | `W` `A` `S` `D` ou Setas Direcionais |
| **Atirar** | `Espaço` |
| **Dash (Esquiva)** | `Shift` (Esquerdo ou Direito) |
| **Pausar / Voltar ao Menu** | `Esc` |

---

## ✨ O que tem no jogo?

- **Movimentação Fluida:** Mova-se em todas as direções com velocidade consistente (sem vantagem na diagonal).
- **Dash Tático:** Aperte Shift para dar um impulso rápido. Durante o dash, você fica **invencível**! Use para atravessar as balas do Boss. Tem um tempo de recarga (cooldown).
- **Waves (Ondas):** Enfrente hordas de aliens. A cada 3 waves, um **Boss gigante** desce à tela.
- **Boss Fight:** O Boss tem uma barra de HP enorme, atira em leque e invoca legiões de aliens menores. Derrote-o para ganhar recompensas massivas.
- **Power-ups:** Aliens derrotados podem soltar itens:
  - 🟡 **Tiro Triplo:** Dispara três balas em leque.
  - 🟦 **Escudo:** Absorve um tiro de dano.
  - 🟩 **Cura:** Recupera 1 vida.
  - 🟪 **Arma Pesada:** Um laser grosso que causa dano massivo.
- **Moedas e Loja:** Colete moedas douradas que caem dos aliens. Use-as no Menu Inicial para comprar melhorias permanentes:
  - Vida Extra (começa com 4 vidas).
  - Dash Rápido (recarga pela metade).
  - Tiro Triplo Permanente (seu tiro base já vira o triplo).
- **Conquistas:** Desbloqueie 7 conquistas (ex: "Mate 100 aliens", "Derrote o Boss") que ficam salvas no seu perfil.
- **Game Feel:** A tela treme, os tiros congelam o tempo por microssegundos (hit stop) e explosões de partículas deixam o combate com peso.
- **Visual Retrô:** Filtro CRT (linhas de TV antiga, vinheta e curvatura de tela) que pode ser ligado/desligado.

---

## 🛠️ Feito com

- **Lua + LÖVE 2D** — Lógica do jogo e renderização.
- **Python (Flask + SQLite)** — Backend para o placar online global.
- **GLSL** — Shader customizado para o efeito CRT.

---

## 📜 Licença e Créditos

Space Invaders é uma marca registrada da **Taito Corporation**. Este é um **fan remake sem fins comerciais**, feito para estudo de LÖVE 2D e Lua. Nenhum asset original da Taito foi utilizado. Os sprites são placeholders próprios.

Este projeto está sob a licença MIT.