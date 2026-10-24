local utils = require("src.utils")

local Powerup = {}
Powerup.__index = Powerup

local TYPES = {
    "triple_shot",
    "shield",
    "heal",
    "heavy_shot" -- NOVO
}

function Powerup.new(x, y, forceType)
    local self = setmetatable({}, Powerup)
    self.x = x
    self.y = y
    self.width = 20
    self.height = 20
    self.speed = 80
    self.type = forceType or TYPES[math.random(#TYPES)]
    self.dead = false
    self.rotation = 0
    
    if self.type == "triple_shot" then self.color = {1, 0.8, 0, 1}
    elseif self.type == "shield" then self.color = {0, 1, 1, 1}
    elseif self.type == "heal" then self.color = {0, 1, 0, 1}
    elseif self.type == "heavy_shot" then self.color = {1, 0, 1, 1} -- Rosa/Magenta para Heavy
    end
    
    return self
end

function Powerup:update(dt)
    self.y = self.y + self.speed * dt
    self.rotation = self.rotation + dt * 2
    if self.y > love.graphics.getHeight() then
        self.dead = true
    end
end

function Powerup:draw()
    love.graphics.setBlendMode("add")
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.4)
    love.graphics.circle("fill", self.x + self.width/2, self.y + self.height/2, 18)
    love.graphics.setBlendMode("alpha")
    
    love.graphics.push()
    love.graphics.translate(self.x + self.width/2, self.y + self.height/2)
    love.graphics.rotate(self.rotation)
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", -self.width/2, -self.height/2, self.width, self.height)
    love.graphics.pop()
    
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    local letter = "?"
    if self.type == "triple_shot" then letter = "T"
    elseif self.type == "shield" then letter = "S"
    elseif self.type == "heal" then letter = "+"
    elseif self.type == "heavy_shot" then letter = "H" end
    
    love.graphics.print(letter, self.x + 6, self.y + 3)
    love.graphics.setColor(1, 1, 1, 1)
end

return Powerup
