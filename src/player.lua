local Bullet = require("src.bullet")
local utils = require("src.utils")
local Particle = require("src.particle")
local Shop = require("src.shop") -- NOVO

local Player = {}
Player.__index = Player

function Player.new()
    local self = setmetatable({}, Player)
    self.x = 200
    self.y = 500
    self.speed = 250
    self.width = 40
    self.height = 20
    self.image = love.graphics.newImage("assets/ship.png")
    self.bullets = {}

    self.maxLives = 3
    if Shop.isPurchased("extra_life") then self.maxLives = 4 end -- NOVO: Upgrade de vida
    self.lives = self.maxLives
    
    self.invulnerableTimer = 0
    self.shootCooldown = 0.2
    self.shootTimer = 0

    self.tripleShotTimer = 0
    self.shieldTimer = 0
    self.heavyShotTimer = 0

    self.dashCooldown = 2.0
    if Shop.isPurchased("fast_dash") then self.dashCooldown = 1.0 end -- NOVO: Upgrade de dash
    self.dashTimer = 0
    self.dashActiveTimer = 0
    self.dashVx = 0
    self.dashVy = 0

    self.soundShoot = utils.generateSound("square", 600, 0.15, 0.4)
    self.soundHurt = utils.generateSound("sine", 100, 0.4, 0.6)
    self.soundThruster = utils.generateSound("thruster", 0, 0.5, 0.5)
    self.soundThruster:setLooping(true)

    return self
end

function Player:update(dt, particles)
    if self.invulnerableTimer > 0 then self.invulnerableTimer = self.invulnerableTimer - dt end
    if self.tripleShotTimer > 0 then self.tripleShotTimer = self.tripleShotTimer - dt end
    if self.shieldTimer > 0 then self.shieldTimer = self.shieldTimer - dt end
    if self.heavyShotTimer > 0 then self.heavyShotTimer = self.heavyShotTimer - dt end

    if self.dashTimer > 0 then self.dashTimer = self.dashTimer - dt end
    if self.dashActiveTimer > 0 then
        self.dashActiveTimer = self.dashActiveTimer - dt
        self.x = self.x + self.dashVx * dt
        self.y = self.y + self.dashVy * dt
        table.insert(particles, Particle.new(self.x + self.width/2, self.y + self.height/2, {0, 1, 1, 1}, true))
    else
        local moveX, moveY = 0, 0
        if love.keyboard.isDown("left", "a") then moveX = moveX - 1 end
        if love.keyboard.isDown("right", "d") then moveX = moveX + 1 end
        if love.keyboard.isDown("up", "w") then moveY = moveY - 1 end
        if love.keyboard.isDown("down", "s") then moveY = moveY + 1 end

        if moveX ~= 0 or moveY ~= 0 then
            if not self.soundThruster:isPlaying() then self.soundThruster:play() end
            if math.random() < 0.3 then
                table.insert(particles, Particle.new(self.x + self.width/2, self.y + self.height, {0, 0.5, 1, 1}, true))
            end
        else
            if self.soundThruster:isPlaying() then self.soundThruster:pause() end
        end

        moveX, moveY = utils.normalize(moveX, moveY)
        self.x = self.x + self.speed * moveX * dt
        self.y = self.y + self.speed * moveY * dt
    end

    if self.x > love.graphics.getWidth() then self.x = -self.width end
    if self.x + self.width < 0 then self.x = love.graphics.getWidth() end
    if self.y < 0 then self.y = 0 end
    if self.y + self.height > love.graphics.getHeight() then self.y = love.graphics.getHeight() - self.height end

    self.shootTimer = self.shootTimer - dt

    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b:update(dt)
        if b.dead then table.remove(self.bullets, i) end
    end
end

function Player:dash()
    if self.dashTimer <= 0 then
        local moveX, moveY = 0, 0
        if love.keyboard.isDown("left", "a") then moveX = moveX - 1 end
        if love.keyboard.isDown("right", "d") then moveX = moveX + 1 end
        if love.keyboard.isDown("up", "w") then moveY = moveY - 1 end
        if love.keyboard.isDown("down", "s") then moveY = moveY + 1 end

        moveX, moveY = utils.normalize(moveX, moveY)
        if moveX == 0 and moveY == 0 then moveY = -1 end

        self.dashVx = moveX * 800
        self.dashVy = moveY * 800
        self.dashActiveTimer = 0.15
        self.dashTimer = self.dashCooldown
        self.invulnerableTimer = 0.2
    end
end

function Player:shoot()
    if self.shootTimer <= 0 then
        -- NOVO: Verifica se tem o upgrade de tiro triplo permanente
        local isPermaTriple = Shop.isPurchased("perma_triple")

        if self.heavyShotTimer > 0 then
            local b = Bullet.new(self.x + self.width/2 - 4, self.y, 800, {1, 0, 1, 1}, false)
            b.width = 8; b.height = 20; b.damage = 3
            table.insert(self.bullets, b)
            self.shootTimer = 0.3
        elseif self.tripleShotTimer > 0 or isPermaTriple then
            local b1 = Bullet.new(self.x + self.width/2 - 2, self.y, 600, {1, 0.8, 0, 1}, false)
            local b2 = Bullet.new(self.x + 5, self.y, 600, {1, 0.8, 0, 1}, false)
            local b3 = Bullet.new(self.x + self.width - 9, self.y, 600, {1, 0.8, 0, 1}, false)
            b2.vx = -150; b3.vx = 150
            table.insert(self.bullets, b1); table.insert(self.bullets, b2); table.insert(self.bullets, b3)
            self.shootTimer = self.shootCooldown
        else
            local b1 = Bullet.new(self.x + 5, self.y, 600, {0, 1, 1, 1}, false)
            local b2 = Bullet.new(self.x + self.width - 9, self.y, 600, {0, 1, 1, 1}, false)
            table.insert(self.bullets, b1); table.insert(self.bullets, b2)
            self.shootTimer = self.shootCooldown
        end
        self.soundShoot:clone():play()
    end
end

function Player:takeDamage()
    if self.invulnerableTimer > 0 then return false end
    if self.shieldTimer > 0 then
        self.shieldTimer = 0
        self.invulnerableTimer = 1.0
        self.soundHurt:clone():play()
        return false
    end
    self.lives = self.lives - 1
    self.invulnerableTimer = 1.5
    self.soundHurt:clone():play()
    return true
end

function Player:stopSounds()
    if self.soundThruster:isPlaying() then self.soundThruster:stop() end
end

function Player:draw()
    if self.invulnerableTimer > 0 then
        if math.floor(self.invulnerableTimer * 10) % 2 == 0 then love.graphics.setColor(1, 1, 1, 0.3) end
    end
    love.graphics.draw(self.image, self.x, self.y)
    love.graphics.setColor(1, 1, 1, 1)

    if self.shieldTimer > 0 then
        love.graphics.setColor(0, 1, 1, 0.5)
        love.graphics.circle("line", self.x + self.width/2, self.y + self.height/2, 30)
        love.graphics.setColor(0, 1, 1, 0.1)
        love.graphics.circle("fill", self.x + self.width/2, self.y + self.height/2, 30)
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.setBlendMode("add")
    for _, b in ipairs(self.bullets) do b:draw() end
    love.graphics.setBlendMode("alpha")
end

return Player
