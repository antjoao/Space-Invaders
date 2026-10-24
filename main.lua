local Player = require("src.player")
local Alien = require("src.alien")
local utils = require("src.utils")
local network = require("src.network")
local Particle = require("src.particle")
local Powerup = require("src.powerup")
local FloatingText = require("src.floatingtext")
local Achievements = require("src.achievements")
local Menu = require("src.menu")
local Shop = require("src.shop")
local Dialogue = require("src.boss_dialogue")

local game = {
    player = nil, aliens = {}, enemyBullets = {}, particles = {}, powerups = {}, floatingTexts = {}, coins = {},
    defeated = 0, spawnTimer = 0, spawnRate = 1.5, font = nil, smallFont = nil, bigFont = nil,
    stars = {}, state = "menu", score = 0, soundExplosion = nil,
    wave = 1, aliensKilledThisWave = 0, aliensPerWave = 15, bossActive = false, waveTransitionTimer = 0,
    screenShakeTimer = 0, screenShakeIntensity = 0, hitStopTimer = 0, damageFlashTimer = 0,
    sessionKills = 0, sessionBossKills = 0,
    playerName = "", topScores = {}, scoresLoaded = false, nameSubmitted = false,
    crtShader = nil, canvas = nil,

    -- NOVO: Transição e Hardcore
    fadeAlpha = 0, -- 0 (transparente) a 1 (preto)
    fadeState = "none", -- "none", "out", "in", "wait"
    fadeCallback = nil,
    isHardcore = false,
    localScores = {} -- NOVO: Leaderboard Local
}

local function createStars()
    game.stars = {}
    for i = 1, 40 do table.insert(game.stars, { x = math.random(0, love.graphics.getWidth()), y = math.random(0, love.graphics.getHeight()), speed = math.random(10, 30), size = 1, layer = 1 }) end
    for i = 1, 40 do table.insert(game.stars, { x = math.random(0, love.graphics.getWidth()), y = math.random(0, love.graphics.getHeight()), speed = math.random(40, 80), size = 2, layer = 2 }) end
    for i = 1, 20 do table.insert(game.stars, { x = math.random(0, love.graphics.getWidth()), y = math.random(0, love.graphics.getHeight()), speed = math.random(90, 150), size = 3, layer = 3 }) end
end

local function spawnExplosion(x, y, color) for i = 1, 15 do table.insert(game.particles, Particle.new(x, y, color)) end end
local function triggerScreenShake(intensity, duration) game.screenShakeIntensity = intensity; game.screenShakeTimer = duration end
local function triggerHitStop(duration) game.hitStopTimer = duration end
local function triggerDamageFlash() game.damageFlashTimer = 0.15 end

-- NOVO: Salva o score local e carrega
local function saveLocalScore(name, score)
    local file = "local_scores.txt"
    local content = love.filesystem.getInfo(file) and love.filesystem.read(file) or ""
    local scores = {}
    for n, s in content:gmatch("(.-);(%d+)") do
        table.insert(scores, {name = n, score = tonumber(s)})
    end
    table.insert(scores, {name = name, score = score})
    table.sort(scores, function(a, b) return a.score > b.score end)
    
    local newContent = ""
    for i = 1, math.min(5, #scores) do
        newContent = newContent .. scores[i].name .. ";" .. scores[i].score .. "\n"
    end
    love.filesystem.write(file, newContent)
end

local function loadLocalScores()
    local file = "local_scores.txt"
    game.localScores = {}
    if love.filesystem.getInfo(file) then
        for n, s in love.filesystem.read(file):gmatch("(.-);(%d+)") do
            table.insert(game.localScores, {name = n, score = tonumber(s)})
        end
    end
end

-- NOVO: Função para iniciar o Fade
local function startFade(callback)
    game.fadeState = "out"
    game.fadeCallback = callback
end

local function startWave(waveNumber)
    game.wave = waveNumber; game.aliensKilledThisWave = 0; game.spawnTimer = 0; game.aliens = {}; game.enemyBullets = {}
    
    local speedMult = game.isHardcore and 1.5 or 1.0
    
    if game.wave % 3 == 0 then
        game.bossActive = true; game.spawnRate = 999
        local boss = Alien.new((love.graphics.getWidth() - 120) / 2, -150, true)
        if game.isHardcore then boss.hp = 300; boss.maxHp = 300 end
        table.insert(game.aliens, boss)
        for i = 1, 4 do 
            local a = Alien.new(math.random(50, love.graphics.getWidth() - 90), -50 - (i * 30), false)
            a.speed = a.speed * speedMult
            table.insert(game.aliens, a) 
        end
        Dialogue.say(game.isHardcore and "MODO PESADELO ATIVADO!" or "TERRAQUEO... VOCE NAO DEVERIA ESTAR AQUI.", 3.5)
        triggerScreenShake(15, 1.0)
    else
        game.bossActive = false
        game.spawnRate = math.max(0.5, 1.5 - (game.wave * 0.1))
        game.aliensPerWave = 10 + (game.wave * 2)
    end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.audio.setVolume(0.5)
    game.player = Player.new()
    game.font = love.graphics.newFont(16); game.smallFont = love.graphics.newFont(12); game.bigFont = love.graphics.newFont(24)
    game.soundExplosion = utils.generateSound("noise", 0, 0.3, 0.5)
    network.onScoresReceived = function(scores) game.topScores = scores; game.scoresLoaded = true end
    network.fetchScores(); createStars(); Achievements.load(); Shop.load(); loadLocalScores()

    game.canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
    game.canvas:setFilter("nearest", "nearest")
    local success, shader = pcall(love.graphics.newShader, "shaders/crt.fs")
    if success then game.crtShader = shader; game.crtShader:send("screenSize", {love.graphics.getWidth(), love.graphics.getHeight()}) end
end

local function resetGame()
    game.player = Player.new()
    if game.isHardcore then game.player.lives = 1 end -- Hardcore = 1 vida
    game.aliens = {}; game.enemyBullets = {}; game.particles = {}; game.powerups = {}; game.floatingTexts = {}; game.coins = {}
    game.defeated = 0; game.score = 0; game.state = "playing"; game.nameSubmitted = false; game.sessionKills = 0; game.sessionBossKills = 0
    startWave(1)
end

local function backToMenu() 
    game.player:stopSounds(); 
    game.state = "menu"; 
    Menu.reset(); 
    game.score = 0; 
    game.aliens = {}; game.enemyBullets = {}; game.particles = {}; game.powerups = {}; game.floatingTexts = {}; game.coins = {}
    game.isHardcore = false
end

local function playerDied()
    game.state = "enteringName"
    game.playerName = ""
    game.player:stopSounds()
    Achievements.updateStats(game.sessionKills, game.wave, game.sessionBossKills, game.score)
end

function love.update(dt)
    network.update(); Achievements.update(dt); Dialogue.update(dt); Shop.update(dt)
    
    -- NOVO: Lógica do Fade
    if game.fadeState == "out" then
        game.fadeAlpha = game.fadeAlpha + dt * 2
        if game.fadeAlpha >= 1 then
            game.fadeAlpha = 1
            game.fadeState = "wait"
            if game.fadeCallback then game.fadeCallback(); game.fadeCallback = nil end
            game.fadeState = "in"
        end
    elseif game.fadeState == "in" then
        game.fadeAlpha = game.fadeAlpha - dt * 2
        if game.fadeAlpha <= 0 then
            game.fadeAlpha = 0
            game.fadeState = "none"
        end
    end
    
    if game.state == "menu" then Menu.update(dt); return end
    if game.hitStopTimer > 0 then game.hitStopTimer = game.hitStopTimer - dt; return end
    if game.screenShakeTimer > 0 then game.screenShakeTimer = game.screenShakeTimer - dt end
    if game.damageFlashTimer > 0 then game.damageFlashTimer = game.damageFlashTimer - dt end
    if game.state ~= "playing" then return end

    if game.waveTransitionTimer > 0 then game.waveTransitionTimer = game.waveTransitionTimer - dt; if game.waveTransitionTimer <= 0 then startWave(game.wave + 1) end; return end

    game.player:update(dt, game.particles)
    for _, star in ipairs(game.stars) do star.y = star.y + star.speed * dt; if star.y > love.graphics.getHeight() then star.y = 0; star.x = math.random(0, love.graphics.getWidth()) end end
    for i = #game.particles, 1, -1 do local p = game.particles[i]; p:update(dt); if p.dead then table.remove(game.particles, i) end end
    for i = #game.floatingTexts, 1, -1 do local ft = game.floatingTexts[i]; ft:update(dt); if ft.dead then table.remove(game.floatingTexts, i) end end
    
    for i = #game.coins, 1, -1 do
        local c = game.coins[i]; c.y = c.y + 150 * dt
        local px, py = game.player.x, game.player.y
        if utils.checkCollision(c.x, c.y, 16, 16, px, py, game.player.width, game.player.height) then Shop.addCoins(1); table.remove(game.coins, i)
        elseif c.y > love.graphics.getHeight() then table.remove(game.coins, i) end
    end

    if not game.bossActive then
        game.spawnTimer = game.spawnTimer + dt
        if game.spawnTimer >= game.spawnRate then
            local x = math.random(0, love.graphics.getWidth() - 40); local alien = Alien.new(x, -20, false)
            if game.wave > 3 then alien.hp = 2 end
            if game.isHardcore then alien.speed = alien.speed * 1.5 end -- Hardcore = aliens mais rápidos
            table.insert(game.aliens, alien); game.spawnTimer = 0
        end
    end

    for i = #game.aliens, 1, -1 do
        local alien = game.aliens[i]; local wantsToShoot, wantsToSummon = alien:update(dt)
        if wantsToShoot then local newBullets = alien:spawnBullet(); for _, b in ipairs(newBullets) do table.insert(game.enemyBullets, b) end end
        if wantsToSummon then for j = 1, 3 do table.insert(game.aliens, Alien.new(math.random(0, love.graphics.getWidth() - 40), -20, false)) end; triggerScreenShake(5, 0.2) end
        if alien.y > love.graphics.getHeight() then table.remove(game.aliens, i); if not alien.isBoss then game.aliensKilledThisWave = game.aliensKilledThisWave + 1 end end
    end

    for i = #game.enemyBullets, 1, -1 do local b = game.enemyBullets[i]; b:update(dt); if b.dead then table.remove(game.enemyBullets, i) end end

    for i = #game.powerups, 1, -1 do
        local p = game.powerups[i]; p:update(dt)
        local px, py = game.player.x, game.player.y
        if utils.checkCollision(p.x, p.y, p.width, p.height, px, py, game.player.width, game.player.height) then
            if p.type == "triple_shot" then game.player.tripleShotTimer = 7
            elseif p.type == "shield" then game.player.shieldTimer = 7
            elseif p.type == "heal" then if game.player.lives < game.player.maxLives then game.player.lives = game.player.lives + 1 end
            elseif p.type == "heavy_shot" then game.player.heavyShotTimer = 7 end
            table.remove(game.powerups, i)
        elseif p.dead then table.remove(game.powerups, i) end
    end

    for i = #game.aliens, 1, -1 do
        local alien = game.aliens[i]; local alienHit = false
        local alienCx, alienCy = alien.x + alien.width/2, alien.y + alien.height/2; local alienRadius = alien.width / 2
        for j = #game.player.bullets, 1, -1 do
            local bullet = game.player.bullets[j]; local bulletCx, bulletCy = bullet.x + bullet.width/2, bullet.y + bullet.height/2
            if utils.checkCircleCollision(bulletCx, bulletCy, bullet.width/2 + 2, alienCx, alienCy, alienRadius) then
                local dmg = bullet.damage or 1; table.remove(game.player.bullets, j); alienHit = true; triggerHitStop(0.02)
                if alien:takeDamage(dmg) then
                    spawnExplosion(alienCx, alienCy, {0, 1, 1, 1}); table.remove(game.aliens, i); game.defeated = game.defeated + 1
                    game.score = game.score + alien.scoreValue; game.soundExplosion:clone():play()
                    table.insert(game.floatingTexts, FloatingText.new(alienCx, alienCy, "+" .. alien.scoreValue, {0, 1, 1, 1}))
                    if alien.hp <= 0 then game.sessionKills = game.sessionKills + 1 end
                    if math.random() < 0.5 then table.insert(game.coins, {x = alienCx - 8, y = alienCy - 8}) end
                    if alien.isBoss then
                        triggerScreenShake(20, 1.5); table.insert(game.powerups, Powerup.new(alienCx - 30, alienCy, "heal")); table.insert(game.powerups, Powerup.new(alienCx, alienCy, "shield")); table.insert(game.powerups, Powerup.new(alienCx + 30, alienCy, "heavy_shot"))
                        game.sessionBossKills = game.sessionBossKills + 1
                        Dialogue.say("IMPOSSIVEL... EU ERA... INEVITAVEL...", 4.0)
                        for k = 1, 10 do table.insert(game.coins, {x = alienCx - 8 + math.random(-30, 30), y = alienCy - 8}) end
                    else
                        triggerScreenShake(3, 0.15); if math.random() < 0.25 then table.insert(game.powerups, Powerup.new(alienCx - 10, alienCy - 10)) end; game.aliensKilledThisWave = game.aliensKilledThisWave + 1
                    end
                else spawnExplosion(bulletCx, bulletCy, {1, 0, 0, 1}) end
                break
            end
        end
    end

    local px, py = game.player.x + game.player.width/2, game.player.y + game.player.height/2
    for i = #game.enemyBullets, 1, -1 do
        local b = game.enemyBullets[i]; local bx, by = b.x + b.width/2, b.y + b.height/2
        if utils.checkCircleCollision(bx, by, 2, px, py, game.player.width/2 - 5) then
            table.remove(game.enemyBullets, i)
            if game.player:takeDamage() then triggerScreenShake(8, 0.3); triggerDamageFlash(); if game.player.lives <= 0 then startFade(playerDied) end end
        end
    end

    for i = #game.aliens, 1, -1 do
        local alien = game.aliens[i]; local alienCx, alienCy = alien.x + alien.width/2, alien.y + alien.height/2
        if utils.checkCircleCollision(px, py, game.player.width/2 - 5, alienCx, alienCy, alien.width/2) then
            spawnExplosion(alienCx, alienCy, {0, 1, 1, 1})
            if alien:takeDamage(999) then table.remove(game.aliens, i); if not alien.isBoss then game.aliensKilledThisWave = game.aliensKilledThisWave + 1 end end
            game.soundExplosion:clone():play()
            if game.player:takeDamage() then triggerScreenShake(8, 0.3); triggerDamageFlash(); if game.player.lives <= 0 then startFade(playerDied) end end
        end
    end

    if game.waveTransitionTimer <= 0 then
        if not game.bossActive and game.aliensKilledThisWave >= game.aliensPerWave and #game.aliens == 0 then game.waveTransitionTimer = 2.0
        elseif game.bossActive and #game.aliens == 0 then game.waveTransitionTimer = 2.0 end
    end
end

local function drawHUD()
    utils.drawPixelText("SCORE:" .. string.format("%04d", game.score), 10, 10, 3, {0, 1, 1, 1})
    utils.drawPixelText("WAVE:" .. game.wave, 10, 35, 2, {1, 1, 1, 1})
    utils.drawPixelText("VIDAS:", 10, 55, 2, {1, 1, 1, 1})
    for i = 1, game.player.lives do love.graphics.setColor(0, 1, 0, 1); love.graphics.rectangle("fill", 70 + (i * 15), 57, 10, 10) end
    utils.drawPixelText("DASH:", 10, 80, 2, {1, 1, 1, 1})
    local dashBarW = 100; local dashBarH = 10; local dashBarX = 60; local dashBarY = 81
    love.graphics.setColor(0.2, 0.2, 0.2, 1); love.graphics.rectangle("fill", dashBarX, dashBarY, dashBarW, dashBarH, 2)
    if game.player.dashTimer <= 0 then love.graphics.setColor(0, 1, 1, 1); love.graphics.rectangle("fill", dashBarX, dashBarY, dashBarW, dashBarH, 2)
    else local cooldownPercent = 1 - (game.player.dashTimer / game.player.dashCooldown); love.graphics.setColor(0.5, 0.5, 0.5, 1); love.graphics.rectangle("fill", dashBarX, dashBarY, dashBarW * cooldownPercent, dashBarH, 2) end
    if game.player.tripleShotTimer > 0 then utils.drawPixelText("TRIPLE:" .. math.ceil(game.player.tripleShotTimer), 10, 100, 1, {1, 0.8, 0, 1}) end
    if game.player.shieldTimer > 0 then utils.drawPixelText("SHIELD:" .. math.ceil(game.player.shieldTimer), 10, 115, 1, {0, 1, 1, 1}) end
    if game.player.heavyShotTimer > 0 then utils.drawPixelText("HEAVY:" .. math.ceil(game.player.heavyShotTimer), 10, 130, 1, {1, 0, 1, 1}) end
    
    if game.isHardcore then
        utils.drawPixelText("HARDCORE", love.graphics.getWidth() - 70, 10, 2, {1, 0, 0, 1})
    end

    if game.bossActive and #game.aliens > 0 then
        local boss = nil; for _, a in ipairs(game.aliens) do if a.isBoss then boss = a break end end
        if boss then
            local barW = 300; local barH = 15; local barX = (love.graphics.getWidth() - barW) / 2; local barY = 20
            love.graphics.setColor(0.2, 0.2, 0.2, 1); love.graphics.rectangle("fill", barX, barY, barW, barH, 4)
            local hpPercent = math.max(0, boss.hp / boss.maxHp); love.graphics.setColor(1, 0, 0, 1); love.graphics.rectangle("fill", barX, barY, barW * hpPercent, barH, 4)
            utils.drawPixelText("BOSS:" .. math.floor(boss.hp), (love.graphics.getWidth() - 80) / 2, barY + 22, 2, {1, 0, 0, 1})
        end
    end

    if game.waveTransitionTimer > 0 then local text = "WAVE " .. (game.wave + 1); local tw = #text * 4 * 5; utils.drawPixelText(text, (love.graphics.getWidth() - tw) / 2, 250, 5, {1, 1, 0, 1}) end
end

local function drawOverlay() love.graphics.setColor(0, 0, 0, 0.75); love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight()) end

local function drawNameEntry()
    drawOverlay(); utils.drawPixelText("GAME OVER", (love.graphics.getWidth() - 9*4*5)/2, 150, 5, {1, 0, 0, 1})
    
    -- NOVO: Leaderboard Local no Game Over
    utils.drawPixelText("MELHORES LOCAIS:", (love.graphics.getWidth() - 15*4*2)/2, 210, 2, {0, 1, 1, 1})
    for i = 1, math.min(3, #game.localScores) do
        local entry = game.localScores[i]
        utils.drawPixelText(string.format("%d. %s - %d", i, entry.name:upper(), entry.score), (love.graphics.getWidth() - 20*4*1.5)/2, 240 + (i-1)*20, 1.5, {0.8, 0.8, 0.8, 1})
    end
    
    utils.drawPixelText("SEU SCORE: " .. game.score, (love.graphics.getWidth() - 16*4*2)/2, 320, 2, {1, 1, 0, 1})
    utils.drawPixelText("DIGITE SEU NOME E ENTER:", (love.graphics.getWidth() - 24*4*1.5)/2, 370, 1.5, {1, 1, 1, 1})
    local boxW, boxH = 240, 40; local boxX = (love.graphics.getWidth() - boxW) / 2; local boxY = 400
    love.graphics.setColor(0.1, 0.1, 0.2, 1); love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 4)
    love.graphics.setColor(0, 1, 1, 1); love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 4)
    love.graphics.setFont(love.graphics.newFont(24)); love.graphics.setColor(1, 1, 1, 1)
    local nameText = game.playerName .. (math.floor(love.timer.getTime() * 2) % 2 == 0 and "|" or ""); love.graphics.print(nameText, boxX + 15, boxY + 6)
end

local function drawLeaderboard()
    drawOverlay(); utils.drawPixelText("TOP 10", (love.graphics.getWidth() - 6*4*5)/2, 80, 5, {0, 1, 0, 1})
    if not game.scoresLoaded then utils.drawPixelText("CARREGANDO...", 140, 200, 2, {1, 1, 1, 1})
    else for i, entry in ipairs(game.topScores) do
        local color = (i == 1) and {1, 0.8, 0} or {1, 1, 1}
        utils.drawPixelText(string.format("%02d.%s", i, entry.name:upper()), 80, 140 + (i - 1) * 28, 2, color)
        utils.drawPixelText(string.format("%06d", entry.score), 260, 140 + (i - 1) * 28, 2, color)
    end end
    utils.drawPixelText("R PARA JOGAR DE NOVO", (love.graphics.getWidth() - 20*4*1.5)/2, 500, 1.5, {1, 1, 1, 1})
    utils.drawPixelText("ESC PARA VOLTAR AO MENU", (love.graphics.getWidth() - 22*4*1.5)/2, 520, 1.5, {0.7, 0.7, 0.7, 1})
end

local function drawGame()
    love.graphics.clear(0.02, 0.02, 0.08, 1)
    love.graphics.setBlendMode("add")
    local time = love.timer.getTime()
    for i = 1, 3 do
        local r = 150 + math.sin(time * 0.5 + i) * 50; local g = 50 + math.cos(time * 0.3 + i) * 30; local b = 150 + math.sin(time * 0.7 + i) * 50
        love.graphics.setColor(r/255, g/255, b/255, 0.05)
        love.graphics.circle("fill", love.graphics.getWidth()/2 + math.sin(time + i)*100, love.graphics.getHeight()/2 + math.cos(time*0.5 + i)*100, 200)
    end
    love.graphics.setBlendMode("alpha")

    for _, star in ipairs(game.stars) do
        if star.layer == 1 then love.graphics.setColor(0.5, 0.5, 0.5, 0.8) elseif star.layer == 2 then love.graphics.setColor(0.8, 0.8, 0.8, 0.9) else love.graphics.setColor(1, 1, 1, 1) end
        love.graphics.rectangle("fill", star.x, star.y, star.size, star.size)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("add"); for _, p in ipairs(game.particles) do p:draw() end; love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 0.8, 0, 1); for _, c in ipairs(game.coins) do love.graphics.circle("fill", c.x + 8, c.y + 8, 6) end
    love.graphics.setColor(1, 1, 1, 1); for _, p in ipairs(game.powerups) do p:draw() end
    game.player:draw(); for _, alien in ipairs(game.aliens) do alien:draw() end
    love.graphics.setBlendMode("add"); for _, b in ipairs(game.enemyBullets) do b:draw() end; love.graphics.setBlendMode("alpha")
    for _, ft in ipairs(game.floatingTexts) do ft:draw() end
end

function love.draw()
    if game.state == "menu" then Menu.draw(); return end
    love.graphics.setCanvas(game.canvas); love.graphics.clear()
    love.graphics.push()
    if game.screenShakeTimer > 0 then
        local shakeX = (math.random() - 0.5) * 2 * game.screenShakeIntensity; local shakeY = (math.random() - 0.5) * 2 * game.screenShakeIntensity
        love.graphics.translate(shakeX, shakeY)
    end
    drawGame()
    love.graphics.pop()
    if game.damageFlashTimer > 0 then local alpha = game.damageFlashTimer / 0.15 * 0.4; love.graphics.setColor(1, 0, 0, alpha); love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight()); love.graphics.setColor(1, 1, 1, 1) end
    love.graphics.setCanvas()
    if game.crtShader then love.graphics.setShader(game.crtShader); love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(game.canvas, 0, 0); love.graphics.setShader()
    else love.graphics.draw(game.canvas, 0, 0) end
    
    -- NOVO: Desenha o véu do Fade
    if game.fadeAlpha > 0 then
        love.graphics.setColor(0, 0, 0, game.fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end

    drawHUD(); Achievements.draw(); Dialogue.draw()
    if game.state == "enteringName" then drawNameEntry() elseif game.state == "gameOver" then drawLeaderboard() end
end

function love.keypressed(key)
    if game.state == "menu" then 
        local action = Menu.keypressed(key)
        if action == "play_normal" then
            game.isHardcore = false
            startFade(resetGame)
        elseif action == "play_hardcore" then
            game.isHardcore = true
            startFade(resetGame)
        end
        return 
    end
    
    if game.state == "playing" then
        if key == "space" then game.player:shoot() elseif key == "lshift" or key == "rshift" then game.player:dash() elseif key == "escape" then startFade(backToMenu) end
    elseif game.state == "enteringName" then
        if key == "return" then 
            if #game.playerName > 0 and not game.nameSubmitted then 
                game.nameSubmitted = true
                network.postScore(game.playerName, game.score)
                saveLocalScore(game.playerName, game.score)
                loadLocalScores()
                network.fetchScores()
                game.state = "gameOver" 
            end
        elseif key == "backspace" then game.playerName = game.playerName:sub(1, -2)
        elseif key == "escape" then startFade(backToMenu) end
    elseif game.state == "gameOver" then
        if key == "r" then startFade(resetGame) elseif key == "escape" then startFade(backToMenu) end
    end
end

function love.textinput(text)
    if game.state == "enteringName" and #game.playerName < 15 then if text:match("^[%w ]$") then game.playerName = game.playerName .. text end end
end
