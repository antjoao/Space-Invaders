# Space Invaders — Fan Remake em Lua + LÖVE

> Um remake jogável do clássico **Space Invaders**, escrito em **Lua puro** com o framework **LÖVE 2D**.
> Foco em código limpo, legibilidade e um loop de jogo estável com colisão, spawn dinâmico e IA de tiro.

![Lua](https://img.shields.io/badge/lua-5.1%2B-blue)
![LÖVE](https://img.shields.io/badge/L%C3%96VE-11.5-pink)
![License](https://img.shields.io/badge/license-MIT-green)
![Dependencies](https://img.shields.io/badge/dependencies-love2d%20only-success)

---

## Sobre

Este projeto é uma reimplementação do **Space Invaders** feita do zero em Lua, utilizando apenas a API do **LÖVE 2D**. Não há engine externa, ECS, nem bibliotecas de terceiros — o loop principal, o sistema de colisão AABB, a geração procedural de inimigos e o gerenciamento de projéteis foram todos escritos à mão.

O objetivo é servir como:

- **Referência de estudo** para quem está aprendendo LÖVE e quer ver um jogo completo (não só um "hello world" gráfico)
- **Base extensível** para experimentar variantes do gênero shooter vertical
- **Exemplo de arquitetura simples** — um único `main.lua` organizado em seções claras: estado, load, update, draw, input

O jogo roda em qualquer máquina que tenha o runtime do LÖVE instalado. Sem compilação, sem build step, sem dependências.

---

## Features

| Feature | Status |
|---|---|
| Movimento omnidirecional do jogador (WASD / setas) | ✅ |
| Normalização vetorial (diagonal não acelera) | ✅ |
| Tiro do jogador com `space` | ✅ |
| Spawn procedural de aliens em intervalos regulares | ✅ |
| IA de tiro dos aliens com timer global | ✅ |
| Colisão AABB (bala × alien) | ✅ |
| Colisão bala × borda com cleanup | ✅ |
| Wrapping horizontal do jogador (sai à direita, entra à esquerda) | ✅ |
| Clamping vertical do jogador | ✅ |
| Contador de aliens derrotados em tempo real | ✅ |
| Sprites carregados via `love.graphics.newImage` | ✅ |
| Vetores de bala com cor própria (verde = player, vermelho = alien) | ✅ |
| Remoção segura de entidades durante iteração (reverse-safe via `table.remove`) | ⚠️ parcial |
| Delta-time consistente em toda a física | ✅ |
| Pausa / menu / game over | ❌ |
| Som / música | ❌ |
| Power-ups | ❌ |

---

## Como rodar

### Pré-requisitos

- **LÖVE 2D 11.x** (ou superior) — [download oficial](https://love2d.org/)
- Nenhuma dependência Lua adicional

### Passo a passo

1. **Baixe o LÖVE** para seu sistema operacional em https://love2d.org/
2. **Clone ou baixe este repositório** e coloque os arquivos em uma pasta, por exemplo `space-invaders/`
3. **Confirme que os sprites estão presentes** na mesma pasta do `main.lua`:
   - `ship.png` (jogador)
   - `alien.png` (inimigo)
4. **Execute** arrastando a pasta do projeto em cima do executável do LÖVE:

   ```bash
   # Linux / macOS
   love /caminho/para/space-invaders

   # Windows (via PowerShell ou cmd)
   "C:\Program Files\LOVE\love.exe" "C:\caminho\para\space-invaders"
   ```

Também é possível empacotar tudo num `.love` (que nada mais é que um zip renomeado) e rodar direto:

```bash
zip -9 -r space-invaders.love . -x "*.git*" "*.md"
love space-invaders.love
```

---

## Controles

| Tecla | Ação |
|---|---|
| `←` / `→` | Move horizontalmente |
| `↑` / `↓` | Move verticalmente |
| `Space` | Atira |
| `Esc` | Fecha o jogo (comportamento padrão do LÖVE) |

> O movimento é **omnidirecional** e normalizado — pressionar duas direções ao mesmo tempo (ex.: `←` + `↑`) move o jogador na diagonal com a **mesma velocidade escalar**, sem o clássico bug de "diagonal mais rápida".

---

## Mecânicas implementadas

### Movimento com normalização vetorial

O jogador não se move diretamente com `+1`/`-1` por tecla. Em vez disso, o código acumula as direções num vetor `(moveX, moveY)` e normaliza antes de aplicar velocidade:

```lua
local moveLength = math.sqrt(moveX * moveX + moveY * moveY)
if moveLength > 0 then
    moveX = moveX / moveLength
    moveY = moveY / moveLength
end

player.x = player.x + player.velocidade    * moveX * dt
player.y = player.y + player.velocidadevert * moveY * dt
```

**Por quê:** sem isso, mover na diagonal resulta em velocidade `√2 × v`, o que dá vantagem injusta ao jogador e quebra o *game feel*. A normalização garante velocidade escalar constante em qualquer direção.

### Wrapping horizontal + clamping vertical

O jogador **atravessa as bordas laterais** (sai pela direita, entra pela esquerda) mas é **contido nas bordas superior e inferior**. Isso é intencional — dá sensação de espaço infinito horizontal, mantendo o combate confinado verticalmente.

```lua
if player.x > love.graphics.getWidth() then
    player.x = 0
elseif player.x + player.width < 0 then
    player.x = love.graphics.getWidth()
end

if player.y < 0 then
    player.y = 0
elseif player.y + player.height > love.graphics.getHeight() then
    player.y = love.graphics.getHeight() - player.height
end
```

### Spawn procedural de aliens

Aliens surgem numa taxa fixa (`spawnRate = 2s`) em posições X aleatórias, sempre acima da tela (`y = -altura_aliens`), e descem com velocidade constante. Ao ultrapassar a borda inferior, são removidos silenciosamente:

```lua
spawnTimer = spawnTimer + dt
if spawnTimer > spawnRate then
    spawnEnemy(math.random(0, love.graphics.getWidth() - largura_aliens), -altura_aliens)
    spawnTimer = 0
end
```

### IA de tiro dos aliens

Um **timer global** (`alienShootTimer`) dispara uma rajada coordenada: **todos os aliens vivos atiram ao mesmo tempo**, a cada `alienShootInterval` segundos.

```lua
alienShootTimer = alienShootTimer + dt
if alienShootTimer >= alienShootInterval then
    alienshoot()
end
```

Cada alien mantém **sua própria lista de balas** (`alien.balasaliens`), o que permite rastrear a origem de cada projétil — útil se você quiser, por exemplo, dar scores diferentes por alien.

### Colisão AABB (bala × alien)

A colisão é feita por **Axis-Aligned Bounding Box** — comparação simples de coordenadas, sem física:

```lua
if bala.x > enemy.x and bala.x < enemy.x + largura_aliens and
   bala.y > enemy.y and bala.y < enemy.y + altura_aliens then
    table.remove(player.balas, i)
    table.remove(aliens, j)
    defeatedaliens = defeatedaliens + 1
end
```

Como as balas são pequenas (2×5 px) e os aliens têm 40×20 px, o teste funciona bem. Para sprites muito menores ou muito rápidos, seria necessário *swept AABB* (verificar o segmento de trajetória, não só o ponto atual).

---

## Arquitetura

### Estrutura de arquivos

```
space-invaders/
├── main.lua        # todo o jogo (load / update / draw / input)
├── ship.png        # sprite do jogador
├── alien.png       # sprite do inimigo
└── README.md
```

### Fluxo de execução

```
1. love.load()      → configura janela, fontes, carrega sprites
2. love.update(dt)  → lê input, move player, move aliens,
                      processa timers, checa colisões, faz spawn
3. love.draw()      → desenha player, aliens, balas, HUD
4. love.keypressed  → dispara shoot() quando space é pressionado
```

O LÖVE chama esse ciclo automaticamente em ~60 FPS (ou o que o vsync permitir). Todo movimento é multiplicado por `dt`, então a velocidade é **independente de framerate**.

## Limitações conhecidas

- **`table.remove` durante `ipairs` pula elementos** — em listas com múltiplas remoções no mesmo frame, algumas entidades podem "escapar" da checagem. Solução: iterar em ordem reversa.
- **Sem sistema de vidas** — o jogador não morre nem perde ao ser atingido por bala alienígena. A colisão bala-alien × player **não está implementada**.
- **Sem condição de vitória/derrota** — o jogo é infinito por design atual.
- **Sem menu, pausa ou game over** — não há estados de jogo além de "rodando".
- **Sem áudio** — nem efeitos, nem música.
- **Sprites rígidos** — não há animação (frames), rotação ou escala dinâmica.
- **Colisão por ponto, não por polígono** — balas são tratadas como pontos (2×5), não como retângulos rotacionados.
- **Sem pool de objetos** — cada bala é uma tabela nova criada a cada tiro. Para dezenas de balas simultâneas isso é irrelevante; para centenas, um pool reduziria pressão no GC.
- **Sem threading ou job system** — tudo roda na thread principal do LÖVE.
- **Resolução fixa 400×600** — sem scaling adaptativo para outras janelas.

---

## Roadmap

- [x] Movimento omnidirecional do jogador
- [x] Normalização vetorial
- [x] Tiro do jogador
- [x] Spawn procedural de aliens
- [x] IA de tiro dos aliens
- [x] Colisão bala × alien
- [x] Contador de derrotados
- [ ] Sistema de vidas + colisão bala alien × player
- [ ] Menu inicial e game over
- [ ] Pausa (`p` ou `Esc`)
- [ ] Efeitos sonoros (tiro, explosão) via `love.audio`
- [ ] Waves progressivas (dificuldade crescente)
- [ ] Power-ups (tiro triplo, escudo, velocidade)
- [ ] Animação de sprites (2+ frames por alien)
- [ ] Pool de objetos para balas
- [ ] Refatorar em módulos (`player.lua`, `alien.lua`, `bullet.lua`)
- [ ] Empacotamento automatizado como `.love`

---

## Aviso legal

Space Invaders é uma marca registrada da **Taito Corporation**. Este projeto é um **fan remake sem fins comerciais**, feito para estudo de LÖVE 2D e Lua. Nenhum asset original da Taito é utilizado — os sprites são placeholders próprios.

Se você é detentor dos direitos e deseja remoção, abra uma issue.

---

## Licença

The MIT License
