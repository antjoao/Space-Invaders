local Particle = {}
Particle.__index = Particle

function Particle.new(x, y, color, isTrail)
    local self = setmetatable({}, Particle)
    self.x = x
    self.y = y
    
    if isTrail then
        -- Partícula de rastro (vai para trás e é menor)
        self.vx = (math.random() - 0.5) * 20
        self.vy = math.random(50, 100)
        self.life = 0.3
        self.size = math.random(1, 3)
    else
        -- Partícula de explosão
        local angle = math.random() * math.pi * 2
        local speed = math.random(50, 200)
        self.vx = math.cos(angle) * speed
        self.vy = math.sin(angle) * speed
        self.life = 0.5
        self.size = math.random(2, 4)
    end
    
    self.maxLife = self.life
    self.color = color or {1, 0.5, 0, 1}
    self.dead = false
    return self
end

function Particle:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.life = self.life - dt
    self.vx = self.vx * 0.95
    self.vy = self.vy * 0.95
    
    if self.life <= 0 then
        self.dead = true
    end
end

function Particle:draw()
    local alpha = self.life / self.maxLife
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
    love.graphics.rectangle("fill", self.x, self.y, self.size, self.size)
end

return Particle
