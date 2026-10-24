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

-- Gerador de som procedural
function utils.generateSound(type, freq, duration, volume)
    local sampleRate = 44100
    local samples = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)

    for i = 0, samples - 1 do
        local t = i / sampleRate
        -- Envelope: sobe rápido, cai exponencialmente (som de arcade)
        local env = math.exp(-t * 8) 
        local value = 0

        if type == "square" then
            -- Tiro laser (Onda quadrada com queda de tom)
            value = math.sin(2 * math.pi * (freq - 400 * t) * t) > 0 and 1 or -1
            value = value * env

        elseif type == "sine" then
            -- Dano (Grave e curto)
            value = math.sin(2 * math.pi * freq * t) * env

        elseif type == "noise" then
            -- Explosão (Ruído misturado com grave)
            local noise = (math.random() * 2 - 1)
            local bass = math.sin(2 * math.pi * 80 * t)
            value = (noise * 0.5 + bass * 0.5) * env

        elseif type == "thruster" then
            -- Motor de nave (Ruído filtrado contínuo)
            value = (math.random() * 2 - 1) * 0.3
            local alpha = 0.05
            if i > 0 then
                local prev = soundData:getSample(i - 1)
                value = prev + alpha * (value - prev)
            end
            -- Fade in/out (para não estalar no loop)
            if t < 0.1 then value = value * (t / 0.1)
            elseif t > duration - 0.1 then value = value * ((duration - t) / 0.1) end
        end

        -- Clamp para garantir que não estoure (distorção)
        if value > 1 then value = 1 elseif value < -1 then value = -1 end
        
        soundData:setSample(i, value * volume)
    end

    return love.audio.newSource(soundData, "static")
end

return utils
