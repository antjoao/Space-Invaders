local Bullet = require("src.bullet")
local utils = require("src.utils")

local Alien = {}
Alien.__index = Alien

function Alien.new(x, y, isBoss)
    local self = setmetatable({}, Alien)
    self.x, self.y = x, y
    self.isBoss = isBoss or false
    
    if self.isBoss then
        self.width, self.height = 120, 60
        self.speed = 20
        self.hp, self.maxHp = 150, 150
        self.scoreValue = 1000
        self.shootTimer = 1.0
        self.stopY = 200
        self.summonTimer = 4.0
        self.lastPhase = 1 -- NOVO: Controle de fases do diálogo
    else
        self.width, self.height = 40, 20
        self.speed = 100
        self.hp, self.maxHp = 1, 1
        self.scoreValue = 10
        self.shootTimer = math.random(5, 20) / 10
    end

    self.image = love.graphics.newImage("assets/alien.png")
    self.soundShoot = utils.generateSound("square", 220, 0.1, 0.2)

    return self
end

function Alien:update(dt)
    if self.isBoss and self.y >= self.stopY then self.y = self.stopY else self.y = self.y + self.speed * dt end
    self.shootTimer = self.shootTimer - dt
    if self.shootTimer <= 0 then
        if self.isBoss then self.shootTimer = 1.5 else self.shootTimer = math.random(10, 25) / 10 end
        return true, false
    end
    if self.isBoss then
        self.summonTimer = self.summonTimer - dt
        if self.summonTimer <= 0 then self.summonTimer = 6.0; return false, true end
    end
    return false, false
end

function Alien:spawnBullet()
    if self.isBoss then
        local bullets = {}
        local centerX = self.x + self.width / 2; local bottomY = self.y + self.height
        for i = -1, 1 do
            local b = Bullet.new(centerX + (i * 25), bottomY, 200, {1, 0, 0, 1}, true)
            b.vx = i * 100; table.insert(bullets, b)
        end
        self.soundShoot:clone():play()
        return bullets
    else
        self.soundShoot:clone():play()
        return { Bullet.new(self.x + self.width / 2, self.y + self.height, 250, {1, 0, 0, 1}, true) }
    end
end

function Alien:takeDamage(amount)
    self.hp = self.hp - amount
    
    -- NOVO: Verifica se o Boss mudou de fase para falar
    if self.isBoss then
        local hpPercent = self.hp / self.maxHp
        local Dialogue = require("src.boss_dialogue")
        
        if hpPercent <= 0.5 and self.lastPhase == 1 then
            self.lastPhase = 2
            Dialogue.say("IMPOSSIVEL! COMO OUSA?", 3.0)
        elseif hpPercent <= 0.25 and self.lastPhase == 2 then
            self.lastPhase = 3
            Dialogue.say("VOCE VAI SE ARREPENDER!", 3.0)
        end
    end
    
    return self.hp <= 0
end

function Alien:draw()
    love.graphics.setBlendMode("add")
    if self.isBoss then
        love.graphics.setColor(1, 0, 0, 0.4)
        for i = 1, 4 do love.graphics.draw(self.image, self.x - i*2, self.y - i*2, 0, 3 + i*0.1, 3 + i*0.1) end
    else
        love.graphics.setColor(0.8, 0, 1, 0.4)
        for i = 1, 3 do love.graphics.draw(self.image, self.x - i, self.y - i, 0, 1 + i*0.1, 1 + i*0.1) end
    end
    love.graphics.setBlendMode("alpha")

    if self.isBoss then
        love.graphics.setColor(1, 0.2, 0.2, 1)
        love.graphics.draw(self.image, self.x, self.y, 0, 3, 3)
    else
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.image, self.x, self.y)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Alien
