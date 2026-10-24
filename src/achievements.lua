local Achievements = {}
local utils = require("src.utils")

local DEFS = {
    first_blood = { title = "Primeiro Sangue", desc = "Mate seu primeiro alien.", target = 1, stat = "total_kills" },
    killer_100 = { title = "Exterminador", desc = "Mate 100 aliens no total (acumulativo).", target = 100, stat = "total_kills" },
    wave_5 = { title = "Sobrevivente", desc = "Alcance a Wave 5.", target = 5, stat = "max_wave" },
    boss_slayer = { title = "Matador de Boss", desc = "Derrote o Boss pela primeira vez.", target = 1, stat = "boss_kills" },
    rich = { title = "Milionário", desc = "Alcance 1000 pontos em uma partida.", target = 1000, stat = "max_score" },
}

local state = {
    unlocked = {}, 
    stats = { total_kills = 0, max_wave = 1, boss_kills = 0, max_score = 0 }
}

local saveFile = "achievements.json"
local popupQueue = {}
local popupTimer = 0
local currentPopup = nil
local soundAchievement = nil

local function save()
    local f = love.filesystem.newFile(saveFile)
    f:open("w")
    local str = "{\n"
    str = str .. '  "unlocked": {'
    local first = true
    for id, val in pairs(state.unlocked) do
        if not first then str = str .. "," end
        str = str .. '"' .. id .. '": true'
        first = false
    end
    str = str .. "},\n"
    str = str .. '  "stats": {\n'
    str = str .. '    "total_kills": ' .. state.stats.total_kills .. ',\n'
    str = str .. '    "max_wave": ' .. state.stats.max_wave .. ',\n'
    str = str .. '    "boss_kills": ' .. state.stats.boss_kills .. ',\n'
    str = str .. '    "max_score": ' .. state.stats.max_score .. '\n'
    str = str .. "  }\n}"
    f:write(str)
    f:close()
end

local function load()
    if love.filesystem.getInfo(saveFile) then
        local content = love.filesystem.read(saveFile)
        for id in content:gmatch('"([%w_]+)": true') do
            state.unlocked[id] = true
        end
        local tk = content:match('"total_kills": (%d+)')
        local mw = content:match('"max_wave": (%d+)')
        local bk = content:match('"boss_kills": (%d+)')
        local ms = content:match('"max_score": (%d+)')
        if tk then state.stats.total_kills = tonumber(tk) end
        if mw then state.stats.max_wave = tonumber(mw) end
        if bk then state.stats.boss_kills = tonumber(bk) end
        if ms then state.stats.max_score = tonumber(ms) end
    end
end

function Achievements.load()
    load()
    soundAchievement = utils.generateSound("square", 880, 0.4, 0.4)
end

function Achievements.updateStats(kills, wave, bossKills, score)
    state.stats.total_kills = state.stats.total_kills + kills
    if wave > state.stats.max_wave then state.stats.max_wave = wave end
    state.stats.boss_kills = state.stats.boss_kills + bossKills
    if score > state.stats.max_score then state.stats.max_score = score end
    
    for id, def in pairs(DEFS) do
        if not state.unlocked[id] then
            local currentVal = state.stats[def.stat]
            if currentVal >= def.target then
                state.unlocked[id] = true
                table.insert(popupQueue, def)
            end
        end
    end
    save()
end

function Achievements.update(dt)
    if popupTimer > 0 then
        popupTimer = popupTimer - dt
        if popupTimer <= 0 then currentPopup = nil end
    elseif #popupQueue > 0 then
        currentPopup = table.remove(popupQueue, 1)
        popupTimer = 3.0 
        if soundAchievement then soundAchievement:clone():play() end
    end
end

function Achievements.draw()
    if currentPopup then
        local w = 280; local h = 60; local x = love.graphics.getWidth() - w - 10; local y = 10
        love.graphics.setColor(0.1, 0.1, 0.1, 0.9); love.graphics.rectangle("fill", x, y, w, h, 4)
        love.graphics.setColor(0, 1, 0, 1); love.graphics.rectangle("line", x, y, w, h, 4)
        love.graphics.setColor(1, 1, 1, 1); love.graphics.setFont(love.graphics.newFont(14)); love.graphics.print("CONQUISTA DESBLOQUEADA!", x + 10, y + 8)
        love.graphics.setColor(0, 1, 0, 1); love.graphics.setFont(love.graphics.newFont(16)); love.graphics.print(currentPopup.title, x + 10, y + 26)
        love.graphics.setColor(0.8, 0.8, 0.8, 1); love.graphics.setFont(love.graphics.newFont(12)); love.graphics.print(currentPopup.desc, x + 10, y + 44)
    end
end

function Achievements.drawList()
    local title = "CONQUISTAS"
    love.graphics.setColor(1, 1, 0, 1); love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print(title, (love.graphics.getWidth() - love.graphics.getFont():getWidth(title)) / 2, 50)

    love.graphics.setFont(love.graphics.newFont(14))
    local y = 120
    for id, def in pairs(DEFS) do
        local unlocked = state.unlocked[id]
        if unlocked then love.graphics.setColor(0, 1, 0, 1) else love.graphics.setColor(0.5, 0.5, 0.5, 1) end
        
        local status = unlocked and "[X]" or "[ ]"
        love.graphics.print(status .. " " .. def.title, 60, y)
        
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.print(def.desc, 90, y + 16)
        love.graphics.setFont(love.graphics.newFont(14))
        y = y + 50
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Achievements
