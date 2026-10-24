local FloatingText = {}
FloatingText.__index = FloatingText

function FloatingText.new(x, y, text, color)
    local self = setmetatable({}, FloatingText)
    self.x = x
    self.y = y
    self.text = text
    self.color = color or {1, 1, 1, 1}
    self.life = 0.8 -- Dura 0.8 segundos
    self.maxLife = self.life
    self.vy = -50 -- Sobe flutuando
    self.dead = false
    return self
end

function FloatingText:update(dt)
    self.y = self.y + self.vy * dt
    self.life = self.life - dt
    if self.life <= 0 then
        self.dead = true
    end
end

function FloatingText:draw()
    local alpha = self.life / self.maxLife
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print(self.text, self.x, self.y)
    love.graphics.setColor(1, 1, 1, 1)
end

return FloatingText
