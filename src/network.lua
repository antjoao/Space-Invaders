-- src/network.lua
local network = {}

local SERVER_URL = "http://127.0.0.1:8080"

-- Thread pool simples: 1 thread por requisição (ok para este caso)
local activeThreads = {}

-- Callback global que a main.lua registra
network.onScoresReceived = nil

-- Lê os scores (GET /scores) em background
function network.fetchScores()
    local thread = love.thread.newThread([[
        local url = ...
        local p = io.popen("curl -s --max-time 3 '" .. url .. "/scores'")
        local body = p:read("*a")
        p:close()
        love.thread.getChannel("scores_response"):push(body)
    ]])
    thread:start(SERVER_URL)
    table.insert(activeThreads, thread)
end

-- Envia um score (POST /scores) em background
function network.postScore(name, score)
    local thread = love.thread.newThread([[
        local url, name, score = ...
        -- Escapa aspas simples (já que estamos num shell com aspas simples)
        name = name:gsub("'", "")
        local payload = string.format('{"name":"%s","score":%d}', name, score)
        -- -d @- envia via stdin (evita escapar aspas no shell)
        local cmd = string.format(
            "curl -s --max-time 3 -X POST -H 'Content-Type: application/json' -d @- '%s/scores'",
            url
        )
        local p = io.popen(cmd, "w")
        p:write(payload)
        p:close()
        love.thread.getChannel("post_done"):push("ok")
    ]])
    thread:start(SERVER_URL, name, score)
    table.insert(activeThreads, thread)
end

-- Chamado no love.update. Processa respostas das threads.
function network.update()
    -- Verifica respostas de GET /scores
    local ch = love.thread.getChannel("scores_response")
    local msg = ch:pop()
    while msg do
        if network.onScoresReceived then
            -- Parser JSON mínimo (sem dependências)
            local scores = {}
            for name, score, date in msg:gmatch('"name":"([^"]*)","score":(%d+),"date":"([^"]*)"') do
                table.insert(scores, {name = name, score = tonumber(score), date = date})
            end
            network.onScoresReceived(scores)
        end
        msg = ch:pop()
    end

    -- Limpa threads mortas
    for i = #activeThreads, 1, -1 do
        if not activeThreads[i]:isRunning() then
            table.remove(activeThreads, i)
        end
    end
end

return network