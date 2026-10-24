local Bullet = require("src.bullet")
local utils = require("src.utils")

local Alien = {}
Alien.__index = Alien

function Alien.new(x, y, isBoss)
    local self = setmetatable({}, Alien)
    self.x = x
    self.y = y
    self.isBoss = isBoss or false
    
    if self.isBoss then
        self.width = 120
        self.height = 60
        self.speed = 20
        self.hp = 150 -- REDUZIDO: De 300 para 150
        self.maxHp = 150
        self.scoreValue = 1000
        self.shootTimer = 1.0
        self.stopY = 200
        self.summonTimer = 4.0
    else
        self.width = 40
        self.height = 20
        self.speed = 100
        self.hp = 1
        self.maxHp = 1
        self.scoreValue = 10
        self.shootTimer = math.random(5, 20) / 10
    end

    self.image = love.graphics.newImage("assets/alien.png")
    self.soundShoot = utils.generateSound("square", 220, 0.1, 0.2)

    return self
end

function Alien:update(dt)
    if self.isBoss and self.y >= self.stopY then
        self.y = self.stopY
    else
        self.y = self.y + self.speed * dt
    end

    self.shootTimer = self.shootTimer - dt
    
    if self.shootTimer <= 0 then
        if self.isBoss then
            self.shootTimer = 1.5 -- Aumentado de 1.2 para 1.5 (atira um pouco mais devagar)
        else
            self.shootTimer = math.random(10, 25) / 10
        end
        return true, false
    end

    if self.isBoss then
        self.summonTimer = self.summonTimer - dt
        if self.summonTimer <= 0 then
            self.summonTimer = 6.0 -- Aumentado de 5 para 6 (invoca menos)
            return false, true
        end
    end

    return false, false
end

function Alien:spawnBullet()
    if self.isBoss then
        local bullets = {}
        local centerX = self.x + self.width / 2
        local bottomY = self.y + self.height
        
        -- Reduzido para 3 balas (antes eram 5)
        for i = -1, 1 do
            local b = Bullet.new(centerX + (i * 25), bottomY, 200, {1, 0, 0, 1}, true)
            b.vx = i * 100
            table.insert(bullets, b)
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
    if self.hp <= 0 then
        return true
    end
    return false
end

function Alien:draw()
    if self.isBoss then
        love.graphics.setColor(1, 0.2, 0.2, 1)
        love.graphics.draw(self.image, self.x, self.y, 0, 3, 3)
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.draw(self.image, self.x, self.y)
    end
end

return Alien
