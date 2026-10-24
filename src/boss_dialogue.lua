local Dialogue = {}

local queue = {}
local active = false
local currentText = ""
local timer = 0
local textSpeed = 0.03 -- Tempo entre cada letra
local displayedChars = 0

-- Função para adicionar uma fala na fila
function Dialogue.say(text, duration)
    table.insert(queue, { text = text, duration = duration or 3.0 })
end

function Dialogue.update(dt)
    if not active and #queue > 0 then
        -- Puxa a próxima fala
        local nextMsg = table.remove(queue, 1)
        currentText = nextMsg.text
        timer = nextMsg.duration
        displayedChars = 0
        active = true
    end

    if active then
        -- Efeito de máquina de escrever
        if displayedChars < #currentText then
            displayedChars = displayedChars + (dt / textSpeed)
            if displayedChars > #currentText then displayedChars = #currentText end
        else
            -- Já mostrou tudo, começa a contar o tempo para sumir
            timer = timer - dt
            if timer <= 0 then
                active = false
            end
        end
    end
end

function Dialogue.draw()
    if not active then return end

    -- Caixa de texto estilo Arcade
    local boxW = 340
    local boxH = 60
    local boxX = (love.graphics.getWidth() - boxW) / 2
    local boxY = love.graphics.getHeight() - 120 -- Perto do fundo, mas acima do player

    -- Fundo preto semi-transparente
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 4)

    -- Borda Vermelha (estilo Boss)
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 4)

    -- Texto
    local utils = require("src.utils")
    local visibleText = currentText:sub(1, math.floor(displayedChars))
    
    -- Desenha o texto em Pixel Art (usando a escala 2 para ficar legível)
    utils.drawPixelText(visibleText, boxX + 15, boxY + 20, 2, {1, 1, 1, 1})

    -- Indicador de "continuar" piscando se o texto acabou
    if displayedChars >= #currentText and math.floor(love.timer.getTime() * 4) % 2 == 0 then
        utils.drawPixelText(">", boxX + boxW - 20, boxY + boxH - 15, 2, {1, 1, 0, 1})
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Dialogue.isActive()
    return active
end

return Dialogue
