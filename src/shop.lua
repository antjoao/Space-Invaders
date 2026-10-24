local Shop = {}
local utils = require("src.utils")

local ITEMS = {
    { id = "extra_life", title = "Vida Extra", desc = "Comece com +1 vida", cost = 50 },
    { id = "fast_dash", title = "Dash Rapido", desc = "Recarga do Dash pela metade", cost = 30 },
    { id = "perma_triple", title = "Tiro Triplo Permanente", desc = "Tiro base vira triplo", cost = 100 },
}

local state = {
    coins = 0,
    purchased = {}
}

local saveFile = "shop.json"
local selected = 1
local errorTimer = 0
local errorMessage = ""

local function save()
    local f = love.filesystem.newFile(saveFile)
    f:open("w")
    local str = "{\n"
    str = str .. '  "coins": ' .. state.coins .. ',\n'
    str = str .. '  "purchased": {'
    local first = true
    for id, val in pairs(state.purchased) do
        if not first then str = str .. "," end
        str = str .. '"' .. id .. '": true'
        first = false
    end
    str = str .. "}\n}"
    f:write(str)
    f:close()
end

function Shop.load()
    if love.filesystem.getInfo(saveFile) then
        local content = love.filesystem.read(saveFile)
        local coins = content:match('"coins": (%d+)')
        if coins then state.coins = tonumber(coins) end
        for id in content:gmatch('"([%w_]+)": true') do
            state.purchased[id] = true
        end
    end
end

function Shop.addCoins(amount)
    state.coins = state.coins + amount
    save()
end

function Shop.getCoins()
    return state.coins
end

function Shop.isPurchased(id)
    return state.purchased[id] == true
end

-- NOVO: Função de compra com feedback
function Shop.buy(id)
    for _, item in ipairs(ITEMS) do
        if item.id == id then
            if state.purchased[id] then
                errorMessage = "Voce ja comprou este item!"
                errorTimer = 2.0
                return false
            end
            
            if state.coins >= item.cost then
                state.coins = state.coins - item.cost
                state.purchased[id] = true
                save()
                return true
            else
                errorMessage = "Moedas insuficientes!"
                errorTimer = 2.0
                return false
            end
        end
    end
    return false
end

function Shop.update(dt)
    if errorTimer > 0 then
        errorTimer = errorTimer - dt
    end
end

function Shop.draw()
    love.graphics.clear(0.02, 0.02, 0.08, 1)

    -- Título
    local title = "LOJA DE MELHORIAS"
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print(title, (love.graphics.getWidth() - love.graphics.getFont():getWidth(title)) / 2, 40)

    -- Moedas
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.setFont(love.graphics.newFont(18))
    local coinText = "Moedas: " .. state.coins
    love.graphics.print(coinText, (love.graphics.getWidth() - love.graphics.getFont():getWidth(coinText)) / 2, 80)

    -- Lista de itens
    love.graphics.setFont(love.graphics.newFont(14))
    local startY = 150
    for i, item in ipairs(ITEMS) do
        local purchased = state.purchased[item.id]
        local isSelected = (i == selected)
        
        -- Lógica de cor: selecionado fica ciano/verde, senão branco
        if purchased then
            love.graphics.setColor(0, 1, 0, 1) -- Verde se comprado
        elseif isSelected then
            love.graphics.setColor(0, 1, 1, 1) -- Ciano se selecionado
        else
            love.graphics.setColor(1, 1, 1, 1) -- Branco normal
        end
        
        local y = startY + (i - 1) * 60
        
        -- Desenha o indicador de seleção
        if isSelected then
            love.graphics.print(">", 40, y)
        end
        
        love.graphics.print(item.title, 60, y)
        
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.print(item.desc, 60, y + 20)
        
        love.graphics.setFont(love.graphics.newFont(14))
        
        if purchased then
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.print("[COMPRADO]", 300, y + 5)
        else
            love.graphics.setColor(1, 0.8, 0, 1)
            love.graphics.print(item.cost .. " moedas", 300, y + 5)
        end
    end

    -- Mensagem de erro
    if errorTimer > 0 then
        love.graphics.setColor(1, 0, 0, math.min(1, errorTimer))
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.print(errorMessage, (love.graphics.getWidth() - love.graphics.getFont():getWidth(errorMessage)) / 2, 420)
    end

    -- Instruções
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("Setas: Navegar | Enter: Comprar | ESC: Voltar", 20, 550)
end

function Shop.keypressed(key)
    if key == "escape" then return "back" end
    
    if key == "up" then
        selected = selected - 1
        if selected < 1 then selected = #ITEMS end
    elseif key == "down" then
        selected = selected + 1
        if selected > #ITEMS then selected = 1 end
    elseif key == "return" or key == "space" then
        local item = ITEMS[selected]
        Shop.buy(item.id)
    end
    
    return nil
end

return Shop
