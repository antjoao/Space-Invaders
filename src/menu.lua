local Menu = {}

local options = { "Jogar (Normal)", "Jogar (Hardcore)", "Loja", "Conquistas", "Sair" }
local selected = 1
local state = "main" -- "main", "achievements", "shop"

function Menu.reset()
    state = "main"
    selected = 1
end

function Menu.update(dt)
end

function Menu.draw()
    love.graphics.clear(0.02, 0.02, 0.08, 1)

    if state == "main" then
        local title = "SPACE INVADERS"
        love.graphics.setFont(love.graphics.newFont(30))
        local tw = love.graphics.getFont():getWidth(title)
        love.graphics.setBlendMode("add")
        love.graphics.setColor(0, 1, 1, 0.5)
        love.graphics.print(title, (love.graphics.getWidth() - tw) / 2, 98)
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(title, (love.graphics.getWidth() - tw) / 2, 100)
        
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        local sub = "Remake em Lua + LOVE"
        love.graphics.print(sub, (love.graphics.getWidth() - love.graphics.getFont():getWidth(sub)) / 2, 140)

        -- Mostra as moedas
        local coins = require("src.shop").getCoins()
        love.graphics.setColor(1, 0.8, 0, 1)
        love.graphics.setFont(love.graphics.newFont(14))
        local coinText = "Moedas: " .. coins
        love.graphics.print(coinText, (love.graphics.getWidth() - love.graphics.getFont():getWidth(coinText)) / 2, 180)

        love.graphics.setFont(love.graphics.newFont(16))
        local startY = 240
        for i, opt in ipairs(options) do
            local color = (i == selected) and {0, 1, 1, 1} or {0.5, 0.5, 0.5, 1}
            love.graphics.setColor(color)
            local ow = love.graphics.getFont():getWidth(opt)
            love.graphics.print(opt, (love.graphics.getWidth() - ow) / 2, startY + (i - 1) * 35)
            if i == selected then
                love.graphics.setColor(0, 1, 1, 1)
                love.graphics.print(">", (love.graphics.getWidth() - ow) / 2 - 30, startY + (i - 1) * 35)
            end
        end
        
        love.graphics.setColor(0.4, 0.4, 0.4, 1)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.print("Use as setas e Enter", 20, 560)

    elseif state == "achievements" then
        require("src.achievements").drawList()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.print("Pressione ESC ou Enter para voltar", 20, 560)

    elseif state == "shop" then
        require("src.shop").draw()
    end
end

function Menu.keypressed(key)
    if state == "main" then
        if key == "up" then
            selected = selected - 1
            if selected < 1 then selected = #options end
        elseif key == "down" then
            selected = selected + 1
            if selected > #options then selected = 1 end
        elseif key == "return" or key == "space" then
            if selected == 1 then
                return "play_normal"
            elseif selected == 2 then
                return "play_hardcore"
            elseif selected == 3 then
                state = "shop"
            elseif selected == 4 then
                state = "achievements"
            elseif selected == 5 then
                love.event.quit()
            end
        end
    elseif state == "achievements" then
        if key == "escape" or key == "return" or key == "backspace" then
            state = "main"
        end
    elseif state == "shop" then
        local action = require("src.shop").keypressed(key)
        if action == "back" then
            state = "main"
        end
    end
end

return Menu
