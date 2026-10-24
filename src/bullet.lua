local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(x, y, speed, color, isEnemy)
    local self = setmetatable({}, Bullet)
    self.x = x
    self.y = y
    self.width = 4
    self.height = 10
    self.speed = speed
    self.color = color
    self.isEnemy = isEnemy or false
    self.dead = false
    self.vx = 0 -- Velocidade horizontal (para tiro triplo)
    return self
end

function Bullet:update(dt)
    if self.isEnemy then
        self.y = self.y + self.speed * dt
    else
        self.y = self.y - self.speed * dt
    end
    
    self.x = self.x + self.vx * dt

    if self.y < -self.height or self.y > love.graphics.getHeight() or self.x < 0 or self.x > love.graphics.getWidth() then
        self.dead = true
    end
end

function Bullet:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.3)
    love.graphics.rectangle("fill", self.x - 2, self.y - 2, self.width + 4, self.height + 4)
    love.graphics.setColor(1, 1, 1, 1)
end

return Bullet
