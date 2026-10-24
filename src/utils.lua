local utils = {}

function utils.checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end

function utils.checkCircleCollision(x1, y1, r1, x2, y2, r2)
    local dx = x1 - x2
    local dy = y1 - y2
    local dist = math.sqrt(dx * dx + dy * dy)
    return dist < (r1 + r2)
end

function utils.normalize(x, y)
    local length = math.sqrt(x * x + y * y)
    if length > 0 then return x / length, y / length end
    return 0, 0
end

-- Função de desenhar texto em "Pixel Art" (blocos) para o HUD
function utils.drawPixelText(text, x, y, scale, color)
    love.graphics.setColor(color or {1, 1, 1, 1})
    -- Tabela de fontes 3x5 mínima
    local font = {
        ["0"] = {"111","101","101","101","111"}, ["1"] = {"010","110","010","010","111"},
        ["2"] = {"111","001","111","100","111"}, ["3"] = {"111","001","111","001","111"},
        ["4"] = {"101","101","111","001","001"}, ["5"] = {"111","100","111","001","111"},
        ["6"] = {"111","100","111","101","111"}, ["7"] = {"111","001","001","001","001"},
        ["8"] = {"111","101","111","101","111"}, ["9"] = {"111","101","111","001","111"},
        ["A"] = {"010","101","111","101","101"}, ["B"] = {"110","101","110","101","110"},
        ["C"] = {"111","100","100","100","111"}, ["D"] = {"110","101","101","101","110"},
        ["E"] = {"111","100","110","100","111"}, ["F"] = {"111","100","110","100","100"},
        ["G"] = {"111","100","101","101","111"}, ["H"] = {"101","101","111","101","101"},
        ["I"] = {"111","010","010","010","111"}, ["J"] = {"001","001","001","101","111"},
        ["K"] = {"101","101","110","101","101"}, ["L"] = {"100","100","100","100","111"},
        ["M"] = {"101","111","111","101","101"}, ["N"] = {"110","101","101","101","101"},
        ["O"] = {"111","101","101","101","111"}, ["P"] = {"111","101","111","100","100"},
        ["Q"] = {"111","101","101","111","001"}, ["R"] = {"111","101","110","101","101"},
        ["S"] = {"111","100","111","001","111"}, ["T"] = {"111","010","010","010","010"},
        ["U"] = {"101","101","101","101","111"}, ["V"] = {"101","101","101","101","010"},
        ["W"] = {"101","101","111","111","101"}, ["X"] = {"101","101","010","101","101"},
        ["Y"] = {"101","101","010","010","010"}, ["Z"] = {"111","001","010","100","111"},
        [" "] = {"000","000","000","000","000"}, [":"] = {"000","010","000","010","000"},
        ["-"] = {"000","000","111","000","000"}
    }

    local cursorX = x
    for i = 1, #text do
        local char = text:sub(i, i):upper()
        local glyph = font[char] or font[" "]
        
        for row = 1, 5 do
            for col = 1, 3 do
                if glyph[row]:sub(col, col) == "1" then
                    love.graphics.rectangle("fill", cursorX + (col - 1) * scale, y + (row - 1) * scale, scale, scale)
                end
            end
        end
        cursorX = cursorX + 4 * scale
    end
end

-- Gerador de som procedural
function utils.generateSound(type, freq, duration, volume)
    local sampleRate = 44100
    local samples = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)

    for i = 0, samples - 1 do
        local t = i / sampleRate
        local value = 0
        if type == "square" then
            value = math.sin(2 * math.pi * freq * t) > 0 and 1 or -1
            value = value * (1 - (i / samples))
        elseif type == "sine" then
            value = math.sin(2 * math.pi * freq * t) * (1 - (i / samples))
        elseif type == "noise" then
            value = (math.random() * 2 - 1) * math.exp(-10 * t)
        elseif type == "thruster" then
            value = (math.random() * 2 - 1) * 0.3
            local alpha = 0.05
            if i > 0 then value = soundData:getSample(i - 1) + alpha * (value - soundData:getSample(i - 1)) end
            if t < 0.1 then value = value * (t / 0.1) elseif t > duration - 0.1 then value = value * ((duration - t) / 0.1) end
        end
        soundData:setSample(i, value * volume)
    end
    return love.audio.newSource(soundData, "static")
end

return utils
