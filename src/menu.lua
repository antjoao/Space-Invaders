local Menu = require("src.menu")

local options = { "Jogar", "Loja", "Conquistas", "Sair" }
local selected = 1
local state = "main" -- "main", "achievements", "shop"

function Menu.reset()
    state = "main"
    selected = 1
end

function Menu.update(dt)
end

function Menu.draw()
    love.graphics.setColor(0.02, 0.02, 0.08)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

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
        local sub = "Remake em Lua + LÖVE"
        love.graphics.print(sub, (love.graphics.getWidth() - love.graphics.getFont():getWidth(sub)) / 2, 140)

        -- Mostra as moedas na tela do menu
        local coins = require("src.shop").getCoins()
        love.graphics.setColor(1, 0.8, 0, 1)
        love.graphics.setFont(love.graphics.newFont(14))
        local coinText = "Moedas: " .. coins
        love.graphics.print(coinText, (love.graphics.getWidth() - love.graphics.getFont():getWidth(coinText)) / 2, 180)

        love.graphics.setFont(love.graphics.newFont(18))
        local startY = 260
        for i, opt in ipairs(options) do
            local color = (i == selected) and {0, 1, 1, 1} or {0.5, 0.5, 0.5, 1}
            love.graphics.setColor(color)
            local ow = love.graphics.getFont():getWidth(opt)
            love.graphics.print(opt, (love.graphics.getWidth() - ow) / 2, startY + (i - 1) * 40)
            if i == selected then
                love.graphics.setColor(0, 1, 1, 1)
                love.graphics.print(">", (love.graphics.getWidth() - ow) / 2 - 30, startY + (i - 1) * 40)
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
                return "play"
            elseif selected == 2 then
                state = "shop"
            elseif selected == 3 then
                state = "achievements"
            elseif selected == 4 then
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
