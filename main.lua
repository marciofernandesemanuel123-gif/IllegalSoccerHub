
-- ILLEGAL SOCCER HUB V3
-- Interface personalizada
-- AutoPlay experimental + AutoSave
-- P = alternar camera
-- RightShift = minimizar/restaurar

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

-- Encerrar instancia anterior
if getgenv and getgenv().ISH_Stop then
    pcall(getgenv().ISH_Stop)
end

local running = true
local connections = {}
local flags = {
    AutoPlay = false,
    AutoSave = false,
    AutoSprint = false
}

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

local function characterInfo()
    local char = player.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    return char, hum, root
end

local data = workspace:WaitForChild("Map")
    :WaitForChild("Data")

local ballData = data:WaitForChild("Ball")

local visuals = workspace:WaitForChild("Misc")
    :WaitForChild("Visuals")

local visualBall = visuals
    :WaitForChild("ClientBall_MainMatch")

local function ballPosition()
    -- O objeto visual pode ser apenas uma referencia.
    -- A validacao da bola ativa ainda e necessaria.
    return visualBall.Position
end

local function getGoals()
    local t1 = data:FindFirstChild("Team1")
    local t2 = data:FindFirstChild("Team2")
    if not t1 or not t2 then return end

    return t1:FindFirstChild("Goal"),
           t2:FindFirstChild("Goal")
end

local function nearestGoal(root)
    local g1, g2 = getGoals()
    if not g1 or not g2 then return end

    if (root.Position - g1.Position).Magnitude <
       (root.Position - g2.Position).Magnitude then
        return g1, g2
    end

    return g2, g1
end

local function moveTo(hum, root, position)
    local delta = position - root.Position
    local flat = Vector3.new(delta.X, 0, delta.Z)

    if flat.Magnitude < 2 then
        hum:Move(Vector3.zero, false)
    else
        hum:Move(flat.Unit, false)
    end
end

-- Interface

local gui = Instance.new("ScreenGui")
gui.Name = "IllegalSoccerHubV3"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = pg

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(330, 355)
main.Position = UDim2.new(0.5, -165, 0.5, -177)
main.BackgroundColor3 = Color3.fromRGB(19, 18, 28)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = obj
end

corner(main, 14)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(122, 76, 220)
stroke.Thickness = 1.5
stroke.Parent = main

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -90, 0, 52)
header.Position = UDim2.fromOffset(16, 4)
header.BackgroundTransparency = 1
header.Text = "ILLEGAL SOCCER  |  V3"
header.TextColor3 = Color3.fromRGB(235, 226, 255)
header.TextSize = 17
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = main

local function smallButton(text, x, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(30, 30)
    b.Position = UDim2.new(1, x, 0, 15)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 17
    b.Parent = main
    corner(b, 7)
    return b
end

local minimize = smallButton("-", -76,
    Color3.fromRGB(85, 65, 130))

local close = smallButton("X", -39,
    Color3.fromRGB(175, 54, 75))

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(12, 58)
content.Size = UDim2.new(1, -24, 1, -70)
content.BackgroundTransparency = 1
content.Parent = main

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 48)
status.Position = UDim2.fromOffset(0, 224)
status.BackgroundColor3 = Color3.fromRGB(34, 31, 49)
status.TextColor3 = Color3.fromRGB(199, 187, 235)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextWrapped = true
status.Text = "Pronto | P: camera | RightShift: menu"
status.Parent = content
corner(status, 8)

local function makeToggle(label, y, key)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 59)
    b.Position = UDim2.fromOffset(0, y)
    b.BackgroundColor3 = Color3.fromRGB(39, 35, 56)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.Parent = content
    corner(b, 9)

    local function refresh()
        b.Text = label .. "     " ..
            (flags[key] and "[ ON ]" or "[ OFF ]")

        b.BackgroundColor3 = flags[key]
            and Color3.fromRGB(71, 52, 119)
            or Color3.fromRGB(39, 35, 56)
    end

    connect(b.MouseButton1Click, function()
        flags[key] = not flags[key]

        if key == "AutoPlay" and flags.AutoPlay then
            flags.AutoSave = false
        elseif key == "AutoSave" and flags.AutoSave then
            flags.AutoPlay = false
        end

        refresh()
        status.Text = label .. (
            flags[key] and " ativado" or " desativado"
        )
    end)

    refresh()
    return refresh
end

local refreshPlay = makeToggle(
    "AUTO PLAY", 0, "AutoPlay")

local refreshSave = makeToggle(
    "AUTO SAVE", 70, "AutoSave")

local refreshSprint = makeToggle(
    "CORRIDA AUTOMATICA", 140, "AutoSprint")

local minimized = false

local function setMinimized(value)
    minimized = value
    content.Visible = not value
    main.Size = value
        and UDim2.fromOffset(330, 55)
        or UDim2.fromOffset(330, 355)
    minimize.Text = value and "+" or "-"
end

connect(minimize.MouseButton1Click, function()
    setMinimized(not minimized)
end)

-- Camera tipo shift lock simplificado.
-- Nao altera as configuracoes internas do jogo.
local cameraLocked = false

local function toggleCamera()
    cameraLocked = not cameraLocked

    UIS.MouseBehavior = cameraLocked
        and Enum.MouseBehavior.LockCenter
        or Enum.MouseBehavior.Default

    status.Text = cameraLocked
        and "Camera centralizada"
        or "Camera normal"
end

connect(UIS.InputBegan, function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.P then
        toggleCamera()
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        setMinimized(not minimized)
    end
end)

-- Leitura da bola
local previousPosition = ballPosition()
local previousTime = os.clock()
local ballVelocity = Vector3.zero

local function updateBall()
    local now = os.clock()
    local dt = now - previousTime

    if dt < 0.06 then return end

    local pos = ballPosition()
    local measured = (pos - previousPosition) / dt

    ballVelocity = ballVelocity:Lerp(measured, 0.4)
    previousPosition = pos
    previousTime = now
end

-- Jogadores proximos
local function nearbyPlayers(root, radius)
    local found = {}

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local char = other.Character

            if char then
                local otherRoot =
                    char:FindFirstChild("HumanoidRootPart")

                if otherRoot then
                    local distance =
                        (otherRoot.Position -
                         root.Position).Magnitude

                    if distance <= radius then
                        table.insert(found, {
                            player = other,
                            root = otherRoot,
                            distance = distance
                        })
                    end
                end
            end
        end
    end

    return found
end

-- Teclas de acao
-- Dependem do jogo reconhecer as entradas.
local lastAction = {}

local function keyTap(key, cooldown)
    local now = os.clock()

    if now - (lastAction[key] or 0) <
        (cooldown or 1) then
        return
    end

    lastAction[key] = now

    pcall(function()
        VIM:SendKeyEvent(true, key, false, game)
        task.delay(0.09, function()
            pcall(function()
                VIM:SendKeyEvent(
                    false, key, false, game)
            end)
        end)
    end)
end

local function clickMouse(button, cooldown)
    local now = os.clock()
    local id = "Mouse" .. tostring(button)

    if now - (lastAction[id] or 0) <
        (cooldown or 1) then
        return
    end

    lastAction[id] = now

    pcall(function()
        local mouse = UIS:GetMouseLocation()

        VIM:SendMouseButtonEvent(
            mouse.X, mouse.Y,
            button, true, game, 0
        )

        task.delay(0.12, function()
            pcall(function()
                VIM:SendMouseButtonEvent(
                    mouse.X, mouse.Y,
                    button, false, game, 0
                )
            end)
        end)
    end)
end

-- AutoSave: previsao lateral
local function doAutoSave(hum, root)
    local ownGoal = nearestGoal(root)
    if not ownGoal then return end

    local pos = ballPosition()
    local vel = ballVelocity

    local sign = ownGoal.Position.Z > 0
        and -1 or 1

    local targetZ = ownGoal.Position.Z + sign * 9
    local targetX = ownGoal.Position.X

    if math.abs(vel.Z) > 2 then
        local t = (targetZ - pos.Z) / vel.Z

        if t > 0 and t < 3 then
            targetX = pos.X + vel.X * t
        end
    end

    targetX = math.clamp(
        targetX,
        ownGoal.Position.X - 12,
        ownGoal.Position.X + 12
    )

    local target = Vector3.new(
        targetX, root.Position.Y, targetZ
    )

    moveTo(hum, root, target)

    if (pos - root.Position).Magnitude < 12
        and vel.Magnitude > 15 then
        keyTap(Enum.KeyCode.E, 1.5)
    end

    status.Text = "AutoSave: protegendo o gol"
end

-- AutoPlay: maquina de estados simplificada
local function doAutoPlay(hum, root)
    local pos = ballPosition()
    local distance = (pos - root.Position).Magnitude

    local ownGoal, enemyGoal = nearestGoal(root)
    if not enemyGoal then return end

    local others = nearbyPlayers(root, 16)

    -- Ainda nao distingue times de forma confiavel.
    local closePlayer = nil

    for _, entry in ipairs(others) do
        if not closePlayer or
            entry.distance < closePlayer.distance then
            closePlayer = entry
        end
    end

    if distance > 8 then
        -- Aproximar da bola
        local predicted = pos + ballVelocity * 0.18

        moveTo(hum, root, predicted)
        status.Text = "AutoPlay: buscando bola"

        if flags.AutoSprint then
            keyTap(Enum.KeyCode.LeftShift, 0.5)
        end

    else
        -- Movimento na direcao do gol adversario
        local goalPos = enemyGoal.Position

        moveTo(hum, root, goalPos)

        local goalDistance =
            (goalPos - root.Position).Magnitude

        if closePlayer and closePlayer.distance < 7 then
            -- Tentar drible
            keyTap(Enum.KeyCode.Space, 1.8)
            status.Text = "AutoPlay: tentando drible"

        elseif goalDistance < 55 then
            -- Tentar chute
            clickMouse(0, 2)
            status.Text = "AutoPlay: tentando chute"

        else
            status.Text = "AutoPlay: avancando"
        end
    end
end

local accumulated = 0

connect(RunService.RenderStepped, function(dt)
    if not running then return end

    updateBall()

    local char, hum, root = characterInfo()
    if not hum or not root or hum.Health <= 0 then
        return
    end

    if flags.AutoSave then
        doAutoSave(hum, root)
    elseif flags.AutoPlay then
        doAutoPlay(hum, root)
    end
end)

local function stop()
    if not running then return end
    running = false

    flags.AutoPlay = false
    flags.AutoSave = false
    flags.AutoSprint = false

    local _, hum = characterInfo()
    if hum then
        hum:Move(Vector3.zero, false)
    end

    UIS.MouseBehavior = Enum.MouseBehavior.Default

    for _, c in ipairs(connections) do
        c:Disconnect()
    end

    gui:Destroy()
end

connect(close.MouseButton1Click, stop)

if getgenv then
    getgenv().ISH_Stop = stop
end

refreshPlay()
refreshSave()
refreshSprint()

print("Illegal Soccer Hub V3 iniciado")
