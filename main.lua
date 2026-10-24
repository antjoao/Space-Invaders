local Player = require("src.player")
local Alien = require("src.alien")
local utils = require("src.utils")
local network = require("src.network")
local Particle = require("src.particle")
local Powerup = require("src.powerup")
local FloatingText = require("src.floatingtext")
local Achievements = require("src.achievements")
local Menu = require("src.menu")
local Shop = require("src.shop") -- NOVO

local game = {
    player = nil, aliens = {}, enemyBullets = {}, particles = {}, powerups = {}, floatingTexts = {}, coins = {},
    defeated = 0, spawnTimer = 0, spawnRate = 1.5, font = nil, smallFont = nil, bigFont = nil,
    stars = {}, state = "menu", score = 0, soundExplosion = nil,
    wave = 1, aliensKilledThisWave = 0, aliensPerWave = 15, bossActive = false, waveTransitionTimer = 0,
    screenShakeTimer = 0, screenShakeIntensity = 0, hitStopTimer = 0, damageFlashTimer = 0,
    
    sessionKills = 0, sessionBossKills = 0,
    playerName = "", topScores = {}, scoresLoaded = false, nameSubmitted = false,
    crtShader = nil, canvas = nil
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

local function startWave(waveNumber)
    game.wave = waveNumber
    game.aliensKilledThisWave = 0
    game.spawnTimer = 0
    game.aliens = {}
    game.enemyBullets = {}
    
    if game.wave % 3 == 0 then
        game.bossActive = true
        game.spawnRate = 999
        table.insert(game.aliens, Alien.new((love.graphics.getWidth() - 120) / 2, -150, true))
        for i = 1, 4 do
            local x = math.random(50, love.graphics.getWidth() - 90)
            table.insert(game.aliens, Alien.new(x, -50 - (i * 30), false))
        end
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
    game.font = love.graphics.newFont(16)
    game.smallFont = love.graphics.newFont(12)
    game.bigFont = love.graphics.newFont(24)
    game.soundExplosion = utils.generateSound("noise", 0, 0.3, 0.5)
    network.onScoresReceived = function(scores) game.topScores = scores; game.scoresLoaded = true end
    network.fetchScores()
    createStars()
    Achievements.load()
    Shop.load() -- NOVO: Carrega as moedas e upgrades

    game.canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
    game.canvas:setFilter("nearest", "nearest")
    local success, shader = pcall(love.graphics.newShader, "shaders/crt.fs")
    if success then
        game.crtShader = shader
        game.crtShader:send("screenSize", {love.graphics.getWidth(), love.graphics.getHeight()})
    end
end

local function resetGame()
    game.player = Player.new()
    game.aliens = {}; game.enemyBullets = {}; game.particles = {}; game.powerups = {}; game.floatingTexts = {}; game.coins = {}
    game.defeated = 0; game.score = 0; game.state = "playing"; game.nameSubmitted = false
    game.sessionKills = 0; game.sessionBossKills = 0
    startWave(1)
end

local function playerDied()
    game.state = "enteringName"
    game.playerName = ""
    game.player:stopSounds()
    Achievements.updateStats(game.sessionKills, game.wave, game.sessionBossKills, game.score)
end

function love.update(dt)
    network.update()
    Achievements.update(dt)
    
    if game.state == "menu" then
        Menu.update(dt)
        return
    end
    
    if game.hitStopTimer > 0 then game.hitStopTimer = game.hitStopTimer - dt; return end
    if game.screenShakeTimer > 0 then game.screenShakeTimer = game.screenShakeTimer - dt end
    if game.damageFlashTimer > 0 then game.damageFlashTimer = game.damageFlashTimer - dt end
    if game.state ~= "playing" then return end

    if game.waveTransitionTimer > 0 then
        game.waveTransitionTimer = game.waveTransitionTimer - dt
        if game.waveTransitionTimer <= 0 then startWave(game.wave + 1) end
        return
    end

    game.player:update(dt, game.particles)

    for _, star in ipairs(game.stars) do
        star.y = star.y + star.speed * dt
        if star.y > love.graphics.getHeight() then star.y = 0; star.x = math.random(0, love.graphics.getWidth()) end
    end

    for i = #game.particles, 1, -1 do local p = game.particles[i]; p:update(dt); if p.dead then table.remove(game.particles, i) end end
    for i = #game.floatingTexts, 1, -1 do local ft = game.floatingTexts[i]; ft:update(dt); if ft.dead then table.remove(game.floatingTexts, i) end end
    
    -- NOVO: Update das Moedas
    for i = #game.coins, 1, -1 do
        local c = game.coins[i]
        c.y = c.y + 150 * dt -- Cai para baixo
        
        -- Colisão com o player
        local px, py = game.player.x, game.player.y
        if utils.checkCollision(c.x, c.y, 16, 16, px, py, game.player.width, game.player.height) then
            Shop.addCoins(1) -- Adiciona 1 moeda
            table.remove(game.coins, i)
        elseif c.y > love.graphics.getHeight() then
            table.remove(game.coins, i)
        end
    end

    if not game.bossActive then
        game.spawnTimer = game.spawnTimer + dt
        if game.spawnTimer >= game.spawnRate then
            local x = math.random(0, love.graphics.getWidth() - 40)
            local alien = Alien.new(x, -20, false)
            if game.wave > 3 then alien.hp = 2 end
            table.insert(game.aliens, alien)
            game.spawnTimer = 0
        end
    end

    for i = #game.aliens, 1, -1 do
        local alien = game.aliens[i]
        local wantsToShoot, wantsToSummon = alien:update(dt)
        if wantsToShoot then 
            local newBullets = alien:spawnBullet()
            for _, b in ipairs(newBullets) do table.insert(game.enemyBullets, b) end
        end
        if wantsToSummon then
            for j = 1, 3 do
                local sx = math.random(0, love.graphics.getWidth() - 40)
                table.insert(game.aliens, Alien.new(sx, -20, false))
            end
            triggerScreenShake(5, 0.2)
        end
        if alien.y > love.graphics.getHeight() then 
            table.remove(game.aliens, i) 
            if not alien.isBoss then game.aliensKilledThisWave = game.aliensKilledThisWave + 1 end
        end
    end

    for i = #game.enemyBullets, 1, -1 do local b = game.enemyBullets[i]; b:update(dt); if b.dead then table.remove(game.enemyBullets, i) end end

    for i = #game.powerups, 1, -1 do
        local p = game.powerups[i]
        p:update(dt)
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
        local alien = game.aliens[i]
        local alienHit = false
        local alienCx, alienCy = alien.x + alien.width/2, alien.y + alien.height/2
        local alienRadius = alien.width / 2

        for j = #game.player.bullets, 1, -1 do
            local bullet = game.player.bullets[j]
            local bulletCx, bulletCy = bullet.x + bullet.width/2, bullet.y + bullet.height/2
            if utils.checkCircleCollision(bulletCx, bulletCy, bullet.width/2 + 2, alienCx, alienCy, alienRadius) then
                local dmg = bullet.damage or 1
                table.remove(game.player.bullets, j)
                alienHit = true
                triggerHitStop(0.02)
                
                if alien:takeDamage(dmg) then
                    spawnExplosion(alienCx, alienCy, {0, 1, 1, 1})
                    table.remove(game.aliens, i)
                    game.defeated = game.defeated + 1
                    game.score = game.score + alien.scoreValue
                    game.soundExplosion:clone():play()
                    table.insert(game.floatingTexts, FloatingText.new(alienCx, alienCy, "+" .. alien.scoreValue, {0, 1, 1, 1}))
                    
                    if alien.hp <= 0 then game.sessionKills = game.sessionKills + 1 end
                    
                    -- NOVO: Drop de Moeda (50% de chance)
                    if math.random() < 0.5 then
                        table.insert(game.coins, {x = alienCx - 8, y = alienCy - 8})
                    end

                    if alien.isBoss then
                        triggerScreenShake(20, 1.5)
                        table.insert(game.powerups, Powerup.new(alienCx - 30, alienCy, "heal"))
                        table.insert(game.powerups, Powerup.new(alienCx, alienCy, "shield"))
                        table.insert(game.powerups, Powerup.new(alienCx + 30, alienCy, "heavy_shot"))
                        game.sessionBossKills = game.sessionBossKills + 1
                        -- Boss dropa 10 moedas
                        for k = 1, 10 do
                            table.insert(game.coins, {x = alienCx - 8 + math.random(-30, 30), y = alienCy - 8})
                        end
                    else
                        triggerScreenShake(3, 0.15)
                        if math.random() < 0.25 then table.insert(game.powerups, Powerup.new(alienCx - 10, alienCy - 10)) end
                        game.aliensKilledThisWave = game.aliensKilledThisWave + 1
                    end
                else
                    spawnExplosion(bulletCx, bulletCy, {1, 0, 0, 1})
                end
                break
            end
        end
    end

    local px, py = game.player.x + game.player.width/2, game.player.y + game.player.height/2

    for i = #game.enemyBullets, 1, -1 do
        local b = game.enemyBullets[i]
        local bx, by = b.x + b.width/2, b.y + b.height/2
        if utils.checkCircleCollision(bx, by, 2, px, py, game.player.width/2 - 5) then
            table.remove(game.enemyBullets, i)
            if game.player:takeDamage() then
                triggerScreenShake(8, 0.3)
                triggerDamageFlash()
                if game.player.lives <= 0 then playerDied() end
            end
        end
    end

    for i = #game.aliens, 1, -1 do
        local alien = game.aliens[i]
        local alienCx, alienCy = alien.x + alien.width/2, alien.y + alien.height/2
        if utils.checkCircleCollision(px, py, game.player.width/2 - 5, alienCx, alienCy, alien.width/2) then
            spawnExplosion(alienCx, alienCy, {0, 1, 1, 1})
            if alien:takeDamage(999) then
                table.remove(game.aliens, i)
                if not alien.isBoss then game.aliensKilledThisWave = game.aliensKilledThisWave + 1 end
            end
            game.soundExplosion:clone():play()
            if game.player:takeDamage() then
                triggerScreenShake(8, 0.3)
                triggerDamageFlash()
                if game.player.lives <= 0 then playerDied() end
            end
        end
    end

    if game.waveTransitionTimer <= 0 then
        if not game.bossActive and game.aliensKilledThisWave >= game.aliensPerWave and #game.aliens == 0 then
            game.waveTransitionTimer = 2.0
        elseif game.bossActive and #game.aliens == 0 then
            game.waveTransitionTimer = 2.0
        end
    end
end

-- (Funções drawHUD, drawOverlay, drawNameEntry, drawLeaderboard mantidas)
local function drawHUD()
    love.graphics.setColor(1, 1, 1, 1); love.graphics.setFont(game.font); love.graphics.print("Score: " .. game.score, 10, 10)
    love.graphics.setFont(game.smallFont); love.graphics.print("Wave: " .. game.wave, 10, 30); love.graphics.print("Vidas: ", 10, 50)
    for i = 1, game.player.lives do love.graphics.setColor(0, 1, 0, 1); love.graphics.rectangle("fill", 60 + (i * 15), 51, 10, 10) end
    love.graphics.setColor(1, 1, 1, 1); love.graphics.print("Dash (Shift): ", 10, 70)
    local dashBarW = 100; local dashBarH = 10; local dashBarX = 85; local dashBarY = 71
    love.graphics.setColor(0.2, 0.2, 0.2, 1); love.graphics.rectangle("fill", dashBarX, dashBarY, dashBarW, dashBarH, 2)
    if game.player.dashTimer <= 0 then love.graphics.setColor(0, 1, 1, 1); love.graphics.rectangle("fill", dashBarX, dashBarY, dashBarW, dashBarH, 2)
    else local cooldownPercent = 1 - (game.player.dashTimer / game.player.dashCooldown); love.graphics.setColor(0.5, 0.5, 0.5, 1); love.graphics.rectangle("fill", dashBarX, dashBarY, dashBarW * cooldownPercent, dashBarH, 2) end
    local buffY = 90
    if game.player.tripleShotTimer > 0 then love.graphics.setColor(1, 0.8, 0, 1); love.graphics.print("Tiro Triplo: " .. math.ceil(game.player.tripleShotTimer) .. "s", 10, buffY); buffY = buffY + 15 end
    if game.player.shieldTimer > 0 then love.graphics.setColor(0, 1, 1, 1); love.graphics.print("Escudo: " .. math.ceil(game.player.shieldTimer) .. "s", 10, buffY); buffY = buffY + 15 end
    if game.player.heavyShotTimer > 0 then love.graphics.setColor(1, 0, 1, 1); love.graphics.print("Arma Pesada: " .. math.ceil(game.player.heavyShotTimer) .. "s", 10, buffY) end
    love.graphics.setColor(1, 1, 1, 1)
    if game.bossActive and #game.aliens > 0 then
        local boss = nil; for _, a in ipairs(game.aliens) do if a.isBoss then boss = a break end end
        if boss then
            local barW = 300; local barH = 15; local barX = (love.graphics.getWidth() - barW) / 2; local barY = 20
            love.graphics.setColor(0.2, 0.2, 0.2, 1); love.graphics.rectangle("fill", barX, barY, barW, barH, 4)
            local hpPercent = math.max(0, boss.hp / boss.maxHp); love.graphics.setColor(1, 0, 0, 1); love.graphics.rectangle("fill", barX, barY, barW * hpPercent, barH, 4)
            love.graphics.setColor(1, 1, 1, 1); love.graphics.setFont(game.font); local text = "BOSS - " .. math.floor(boss.hp) .. " HP"
            love.graphics.print(text, (love.graphics.getWidth() - game.font:getWidth(text)) / 2, barY - 18)
        end
    end
    if game.waveTransitionTimer > 0 then
        love.graphics.setColor(1, 1, 0, 1); love.graphics.setFont(game.bigFont); local text = "WAVE " .. (game.wave + 1)
        local textW = game.bigFont:getWidth(text); love.graphics.print(text, (love.graphics.getWidth() - textW) / 2, 250)
    end
end
local function drawOverlay() love.graphics.setColor(0, 0, 0, 0.75); love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight()) end
local function drawNameEntry()
    drawOverlay()
    love.graphics.setColor(1, 1, 0, 1); love.graphics.setFont(game.bigFont)
    local t1 = "GAME OVER"; love.graphics.print(t1, (love.graphics.getWidth() - game.bigFont:getWidth(t1)) / 2, 180)
    love.graphics.setColor(1, 1, 1, 1); love.graphics.setFont(game.font)
    local t2 = "Score final: " .. game.score; love.graphics.print(t2, (love.graphics.getWidth() - game.font:getWidth(t2)) / 2, 230)
    local t3 = "Digite seu nome e ENTER:"; love.graphics.print(t3, (love.graphics.getWidth() - game.font:getWidth(t3)) / 2, 280)
    local boxW, boxH = 240, 40; local boxX = (love.graphics.getWidth() - boxW) / 2; local boxY = 320
    love.graphics.setColor(0.1, 0.1, 0.2, 1); love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 4)
    love.graphics.setColor(0, 1, 1, 1); love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 4)
    love.graphics.setColor(1, 1, 1, 1); love.graphics.setFont(game.bigFont)
    local nameText = game.playerName .. (math.floor(love.timer.getTime() * 2) % 2 == 0 and "|" or "")
    love.graphics.print(nameText, boxX + 15, boxY + 6)
end
local function drawLeaderboard()
    drawOverlay()
    love.graphics.setColor(0, 1, 0, 1); love.graphics.setFont(game.bigFont)
    local title = "TOP 10"; love.graphics.print(title, (love.graphics.getWidth() - game.bigFont:getWidth(title)) / 2, 100)
    love.graphics.setFont(game.font)
    if not game.scoresLoaded then love.graphics.setColor(1, 1, 1, 1); love.graphics.print("Carregando...", 140, 200)
    else for i, entry in ipairs(game.topScores) do
        local color = (i == 1) and {1, 0.8, 0} or {1, 1, 1}
        love.graphics.setColor(color); local line = string.format("%2d. %-15s %6d", i, entry.name, entry.score); love.graphics.print(line, 80, 140 + (i - 1) * 28)
    end end
    love.graphics.setColor(1, 1, 1, 1); love.graphics.setFont(game.smallFont)
    local hint = "Pressione R para jogar de novo"; love.graphics.print(hint, (love.graphics.getWidth() - game.smallFont:getWidth(hint)) / 2, 520)
end

local function drawGame()
    love.graphics.setColor(0.02, 0.02, 0.08); love.graphics.rectangle("fill", -20, -20, love.graphics.getWidth() + 40, love.graphics.getHeight() + 40)
    for _, star in ipairs(game.stars) do
        if star.layer == 1 then love.graphics.setColor(0.5, 0.5, 0.5, 0.8) elseif star.layer == 2 then love.graphics.setColor(0.8, 0.8, 0.8, 0.9) else love.graphics.setColor(1, 1, 1, 1) end
        love.graphics.rectangle("fill", star.x, star.y, star.size, star.size)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("add"); for _, p in ipairs(game.particles) do p:draw() end; love.graphics.setBlendMode("alpha")
    
    -- NOVO: Desenha as moedas
    love.graphics.setColor(1, 0.8, 0, 1) -- Dourado
    for _, c in ipairs(game.coins) do
        love.graphics.circle("fill", c.x + 8, c.y + 8, 6)
    end
    love.graphics.setColor(1, 1, 1, 1)

    for _, p in ipairs(game.powerups) do p:draw() end
    game.player:draw(); for _, alien in ipairs(game.aliens) do alien:draw() end
    love.graphics.setBlendMode("add"); for _, b in ipairs(game.enemyBullets) do b:draw() end; love.graphics.setBlendMode("alpha")
    for _, ft in ipairs(game.floatingTexts) do ft:draw() end
end

function love.draw()
    if game.state == "menu" then
        Menu.draw()
        return
    end
    
    love.graphics.setCanvas(game.canvas)
    love.graphics.clear()
    love.graphics.push()
    if game.screenShakeTimer > 0 then
        local shakeX = (math.random() - 0.5) * 2 * game.screenShakeIntensity
        local shakeY = (math.random() - 0.5) * 2 * game.screenShakeIntensity        love.graphics.translate(shakeX, shakeY)
    end
    drawGame()
    love.graphics.pop()
    if game.damageFlashTimer > 0 then
        local alpha = game.damageFlashTimer / 0.15 * 0.4
        love.graphics.setColor(1, 0, 0, alpha); love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight()); love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.setCanvas()
    if game.crtShader then
        love.graphics.setShader(game.crtShader); love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(game.canvas, 0, 0); love.graphics.setShader()
    else
        love.graphics.draw(game.canvas, 0, 0)
    end
    drawHUD()
    Achievements.draw()
    if game.state == "enteringName" then drawNameEntry() elseif game.state == "gameOver" then drawLeaderboard() end
end

function love.keypressed(key)
    if game.state == "menu" then
        local action = Menu.keypressed(key)
        if action == "play" then resetGame() end
        return
    end
    
    if game.state == "playing" then
        if key == "space" then game.player:shoot()
        elseif key == "lshift" or key == "rshift" then game.player:dash()
        elseif key == "escape" then game.state = "menu"; Menu.reset() end
    elseif game.state == "enteringName" then
        if key == "return" then
            if #game.playerName > 0 and not game.nameSubmitted then
                game.nameSubmitted = true
                network.postScore(game.playerName, game.score)
                network.fetchScores()
                game.state = "gameOver"
            end
        elseif key == "backspace" then game.playerName = game.playerName:sub(1, -2)
        elseif key == "escape" then game.state = "gameOver" end
    elseif game.state == "gameOver" then
        if key == "r" then resetGame() 
        elseif key == "escape" then game.state = "menu"; Menu.reset() end
    end
end

function love.textinput(text)
    if game.state == "enteringName" and #game.playerName < 15 then
        if text:match("^[%w ]$") then game.playerName = game.playerName .. text end
    end
end
