local Shop = {}
local utils = require("src.utils")

-- Definição dos itens da loja
local ITEMS = {
    { id = "extra_life", title = "Vida Extra", desc = "Comece com +1 vida", cost = 50 },
    { id = "fast_dash", title = "Dash Rápido", desc = "Recarga do Dash pela metade", cost = 30 },
    { id = "perma_triple", title = "Tiro Triplo Permanente", desc = "Tiro base vira triplo", cost = 100 },
}

local state = {
    coins = 0,
    purchased = {} -- Tabela com IDs comprados
}

local saveFile = "shop.json"

-- Salva as moedas e compras no disco
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

-- Carrega as moedas e compras do disco
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

-- Adiciona moedas (chamado quando o jogador coleta)
function Shop.addCoins(amount)
    state.coins = state.coins + amount
    save()
end

-- Retorna as moedas atuais
function Shop.getCoins()
    return state.coins
end

-- Verifica se o item foi comprado
function Shop.isPurchased(id)
    return state.purchased[id] == true
end

-- Tenta comprar um item. Retorna true se deu certo.
function Shop.buy(id)
    for _, item in ipairs(ITEMS) do
        if item.id == id and not state.purchased[id] then
            if state.coins >= item.cost then
                state.coins = state.coins - item.cost
                state.purchased[id] = true
                save()
                return true
            end
        end
    end
    return false
end

-- Desenha a tela da loja
function Shop.draw()
    -- Fundo escuro
    love.graphics.setColor(0.02, 0.02, 0.08)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Título
    local title = "LOJA DE MELHORIAS"
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print(title, (love.graphics.getWidth() - love.graphics.getFont():getWidth(title)) / 2, 40)

    -- Moedas do jogador
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.setFont(love.graphics.newFont(18))
    local coinText = "Moedas: " .. state.coins
    love.graphics.print(coinText, (love.graphics.getWidth() - love.graphics.getFont():getWidth(coinText)) / 2, 80)

    -- Lista de itens
    love.graphics.setFont(love.graphics.newFont(14))
    local y = 150
    for _, item in ipairs(ITEMS) do
        local purchased = state.purchased[item.id]
        
        if purchased then
            love.graphics.setColor(0, 1, 0, 1) -- Verde se comprado
        else
            love.graphics.setColor(1, 1, 1, 1) -- Branco se não comprado
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
        
        y = y + 60
    end

    -- Instruções
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("Pressione ESC para voltar ao menu", 20, 550)
end

-- Processa o input na loja. Retorna "buy" se comprou algo, ou "back" se quer sair.
function Shop.keypressed(key)
    if key == "escape" then return "back" end
    
    -- Atalhos para comprar
    if key == "1" then Shop.buy("extra_life") end
    if key == "2" then Shop.buy("fast_dash") end
    if key == "3" then Shop.buy("perma_triple") end
    
    return nil
end

return Shop
