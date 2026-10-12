-- ILLEGAL SOCCER HUB V3.4 | experimental client script
-- P: alternar mouse real | RightShift: minimizar
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local VIM = game:GetService('VirtualInputManager')
local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')
local env = (getgenv and getgenv()) or _G
if type(env.ISH_Stop) == 'function' then pcall(env.ISH_Stop) end
local connections, alive = {}, true
local flags = {AutoPlay=false,AutoSave=false,AutoSprint=false}
local function bind(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections,c)
    return c
end
local function characterInfo()
    local ch = player.Character
    if not ch then return end
    return ch,ch:FindFirstChildOfClass('Humanoid'),ch:FindFirstChild('HumanoidRootPart')
end
local function getData()
    local map = workspace:FindFirstChild('Map')
    return map and map:FindFirstChild('Data')
end
-- Find match AND practice balls. Choose closest moving/visible ball.
local ballHistory = {}
local trackedBall, nextBallScan = nil, 0
local function scanBalls(root)
    local now=os.clock()
    if now < nextBallScan and trackedBall and trackedBall.Parent then return trackedBall end
    nextBallScan=now+.4
    local best,bestScore=nil,math.huge
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA('BasePart') and obj.Name:lower():find('ball') then
            local name=obj.Name:lower()
            if not name:find('basket') and not name:find('volley') then
                local distance=(obj.Position-root.Position).Magnitude
                local speed=obj.AssemblyLinearVelocity.Magnitude
                local score=distance - math.min(speed,60)*.2
                if not obj:IsDescendantOf(workspace.CurrentCamera or workspace) and score<bestScore then
                    best,bestScore=obj,score
                end
            end
        end
    end
    trackedBall=best
    return best
end
local function ballPos(root)
    local ball=scanBalls(root)
    return ball and ball.Position
end
local function moveTo(hum,root,pos)
    local delta = Vector3.new(pos.X-root.Position.X,0,pos.Z-root.Position.Z)
    hum:Move(delta.Magnitude > 2 and delta.Unit or Vector3.zero,false)
end
-- Finds goal parts in both match and practice areas.
local function goalCandidates(root)
    local list, seen={},{}
    for _,goal in ipairs(workspace:GetDescendants()) do
        if goal:IsA('BasePart') and goal.Name:lower()=='goal' then
            local container=goal.Parent
            local positions=container and container:FindFirstChild('Positions')
            local keeper=positions and positions:FindFirstChild('Goalkeeper')
            local keeperPos=(keeper and keeper:IsA('BasePart')) and keeper.Position
                or goal.Position + Vector3.new(0,0,goal.Position.Z>=0 and -9 or 9)
            local occupied=false
            for _,other in ipairs(Players:GetPlayers()) do
                if other~=player and other.Character then
                    local r=other.Character:FindFirstChild('HumanoidRootPart')
                    local h=other.Character:FindFirstChildOfClass('Humanoid')
                    if r and h and h.Health>0 and (r.Position-keeperPos).Magnitude<12 then
                        occupied=true
                        break
                    end
                end
            end
            if not seen[goal] then
                seen[goal]=true
                table.insert(list,{name=goal:GetFullName(),goal=goal,keeper=keeperPos,
                    occupied=occupied,distance=(root.Position-keeperPos).Magnitude})
            end
        end
    end
    table.sort(list,function(a,b) return a.distance<b.distance end)
    return list
end
local function chooseGoal(root)
    local list=goalCandidates(root)
    for _,g in ipairs(list) do if not g.occupied then return g end end
    return list[1]
end
local gui = Instance.new('ScreenGui')
gui.Name='IllegalSoccerHubV34'
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.Parent=playerGui
local function round(obj,n)
    local c=Instance.new('UICorner') c.CornerRadius=UDim.new(0,n or 10) c.Parent=obj
end
local main=Instance.new('Frame')
main.Size=UDim2.fromOffset(340,352)
main.Position=UDim2.new(.5,-170,.5,-176)
main.BackgroundColor3=Color3.fromRGB(19,18,29)
main.BorderSizePixel=0
main.Active=true
main.Draggable=true
main.Parent=gui
round(main,14)
local border=Instance.new('UIStroke')
border.Color=Color3.fromRGB(132,83,222)
border.Thickness=1.5
border.Parent=main
local header=Instance.new('TextLabel')
header.BackgroundTransparency=1
header.Position=UDim2.fromOffset(16,4)
header.Size=UDim2.new(1,-100,0,50)
header.Font=Enum.Font.GothamBold
header.Text='ILLEGAL SOCCER  •  V3.4'
header.TextSize=16
header.TextColor3=Color3.fromRGB(236,226,255)
header.TextXAlignment=Enum.TextXAlignment.Left
header.Parent=main
local function headerButton(txt,x,color)
    local b=Instance.new('TextButton')
    b.Size=UDim2.fromOffset(30,30)
    b.Position=UDim2.new(1,x,0,13)
    b.BackgroundColor3=color
    b.Text=txt
    b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold
    b.TextSize=17
    b.Parent=main
    round(b,7)
    return b
end
local minBtn=headerButton('−',-76,Color3.fromRGB(83,62,133))
local closeBtn=headerButton('×',-39,Color3.fromRGB(163,51,74))
local content=Instance.new('Frame')
content.BackgroundTransparency=1
content.Position=UDim2.fromOffset(12,56)
content.Size=UDim2.new(1,-24,1,-68)
content.Parent=main
local status=Instance.new('TextLabel')
status.Size=UDim2.new(1,0,0,54)
status.Position=UDim2.fromOffset(0,220)
status.BackgroundColor3=Color3.fromRGB(34,31,49)
status.TextColor3=Color3.fromRGB(210,198,238)
status.TextWrapped=true
status.TextSize=12
status.Font=Enum.Font.Gotham
status.Text='Pronto • P: mouse livre • RightShift: menu'
status.Parent=content
round(status,9)
local redraw={}
local function toggle(label,key,y)
    local b=Instance.new('TextButton')
    b.Size=UDim2.new(1,0,0,58)
    b.Position=UDim2.fromOffset(0,y)
    b.Font=Enum.Font.GothamBold
    b.TextSize=15
    b.TextColor3=Color3.new(1,1,1)
    b.Parent=content
    round(b,9)
    local function update()
        b.Text=label..(flags[key] and '     [ ON ]' or '     [ OFF ]')
        b.BackgroundColor3=flags[key] and Color3.fromRGB(77,54,130) or Color3.fromRGB(39,35,56)
    end
    redraw[key]=update
    local function performToggle()
        flags[key]=not flags[key]
        if key=='AutoPlay' and flags[key] then flags.AutoSave=false end
        if key=='AutoSave' and flags[key] then flags.AutoPlay=false end
        for _,fn in pairs(redraw) do fn() end
        status.Text=label..(flags[key] and ' ligado' or ' desligado')
    end
    bind(b.MouseButton1Click,performToggle)
    update()
end
toggle('AUTO PLAY','AutoPlay',0)
toggle('AUTO SAVE','AutoSave',68)
toggle('CORRIDA AUTOMÁTICA','AutoSprint',136)
local minimized=false
local function setMinimized(value)
    minimized=value
    content.Visible=not value
    main.Size=value and UDim2.fromOffset(340,54) or UDim2.fromOffset(340,352)
    minBtn.Text=value and '+' or '−'
end
bind(minBtn.MouseButton1Click,function() setMinimized(not minimized) end)
-- Mouse nativo: evita discrepancia entre cursor desenhado e clique real.
-- Jogos que travam o mouse a cada frame podem sobrepor essa opcao.
local freeMouse=false
local function setFreeMouse(value)
    freeMouse=value
    if value then
        RunService:BindToRenderStep('ISH_MouseFree',
            Enum.RenderPriority.Camera.Value+5,function()
                UIS.MouseBehavior=Enum.MouseBehavior.Default
                UIS.MouseIconEnabled=true
            end)
    else
        RunService:UnbindFromRenderStep('ISH_MouseFree')
        UIS.MouseBehavior=Enum.MouseBehavior.Default
        UIS.MouseIconEnabled=true
    end
    status.Text=value and 'Mouse livre: ON | P para alternar' or 'Mouse livre: OFF'
end
bind(UIS.InputBegan,function(input,processed)
    if UIS:GetFocusedTextBox() then return end
    if input.KeyCode==Enum.KeyCode.P then
        setFreeMouse(not freeMouse)
    elseif input.KeyCode==Enum.KeyCode.RightShift then
        setMinimized(not minimized)
    end
end)
local lastBall=nil
local ballVelocity=Vector3.zero
local lastSample=os.clock()
local selectedGoal=nil
local nextGoalCheck=0
local lastDive=0
local lastDribble=0
local lastShot=0
local function tap(key)
    pcall(function()
        VIM:SendKeyEvent(true,key,false,game)
        task.delay(.09,function()
            pcall(function() VIM:SendKeyEvent(false,key,false,game) end)
        end)
    end)
end
local function shoot()
    pcall(function()
        local p=UIS:GetMouseLocation()
        VIM:SendMouseButtonEvent(p.X,p.Y,0,true,game,0)
        task.delay(.12,function()
            pcall(function() VIM:SendMouseButtonEvent(p.X,p.Y,0,false,game,0) end)
        end)
    end)
end
local keeperBall=nil
local nextKeeperBallScan=0
local function autosave(hum,root,pos)
    local now=os.clock()
    -- Evita alternar gols a cada movimento. So reconsidera quando
    -- o gol atual desaparece ou quando o modo e reativado.
    if not selectedGoal or not selectedGoal.goal.Parent then
        selectedGoal=chooseGoal(root)
    end
    local goal=selectedGoal
    if not goal then
        hum:Move(Vector3.zero,false)
        status.Text='AutoSave: nenhum gol encontrado'
        return
    end
    local base=goal.keeper
    local defendBall=nil
    local nearest=math.huge
    -- Bola mais proxima do gol defendido, nao do jogador.
    if now>=nextKeeperBallScan or not keeperBall or not keeperBall.Parent then
        nextKeeperBallScan=now+0.3
        keeperBall=nil
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA('BasePart') and obj.Name:lower():find('ball') then
                local d=(obj.Position-base).Magnitude
                if d<nearest and d<105 then
                    nearest=d
                    keeperBall=obj
                end
            end
        end
    end
    defendBall=keeperBall
    if defendBall then nearest=(defendBall.Position-base).Magnitude end
    local bp=defendBall and defendBall.Position or nil
    local bv=defendBall and defendBall.AssemblyLinearVelocity or Vector3.zero
    local x=base.X
    local z=base.Z
    local approaching=false
    if bp then
        local toLine=base.Z-bp.Z
        approaching=math.abs(bv.Z)>4 and toLine/bv.Z>0
        if approaching then
            local t=toLine/bv.Z
            if t<2.5 then x=bp.X+bv.X*t end
        elseif nearest<30 then
            x=bp.X
        end
    end
    x=math.clamp(x,base.X-10,base.X+10)
    -- Nunca perseguir a bola para tras da linha do goleiro.
    -- Move para o ponto fixo da defesa e so ajusta lateralmente.
    local target=Vector3.new(x,root.Position.Y,z)
    moveTo(hum,root,target)
    if bp and approaching and nearest<32 and now-lastDive>1.4 then
        local t=(z-bp.Z)/bv.Z
        if t>0 and t<0.9 and math.abs(bp.X+bv.X*t-base.X)<13 then
            lastDive=now
            tap(Enum.KeyCode.E)
        end
    end
    status.Text='AutoSave: '..goal.name:match('([^%.]+)$')..' | '..
        (bp and ('bola a '..math.floor(nearest)..' studs') or 'sem bola proxima')
end
local function autoplay(hum,root,pos)
    if not pos then
        hum:Move(Vector3.zero,false)
        status.Text='AutoPlay: bola não localizada'
        return
    end
    local distance=(pos-root.Position).Magnitude
    local goals=goalCandidates(root)
    local enemyGoal=goals[#goals] and goals[#goals].goal or nil
    if distance>8 then
        moveTo(hum,root,pos+ballVelocity*.18)
        status.Text='AutoPlay: buscando a bola'
    elseif enemyGoal then
        moveTo(hum,root,enemyGoal.Position)
        local nearOther=false
        for _,other in ipairs(Players:GetPlayers()) do
            if other~=player and other.Character then
                local r=other.Character:FindFirstChild('HumanoidRootPart')
                if r and (r.Position-root.Position).Magnitude<7 then nearOther=true break end
            end
        end
        local now=os.clock()
        if nearOther and now-lastDribble>1.8 then
            lastDribble=now
            tap(Enum.KeyCode.Space)
            status.Text='AutoPlay: tentativa de drible'
        elseif (enemyGoal.Position-root.Position).Magnitude<55 and now-lastShot>2 then
            lastShot=now
            shoot()
            status.Text='AutoPlay: tentativa de chute'
        else
            status.Text='AutoPlay: avançando'
        end
    end
end
bind(RunService.RenderStepped,function(dt)
    if not alive then return end
    local _,hum,root=characterInfo()
    local now=os.clock()
    local pos=(root and flags.AutoPlay) and ballPos(root) or nil
    if pos and now-lastSample>=.06 then
        if lastBall then ballVelocity=ballVelocity:Lerp((pos-lastBall)/(now-lastSample),.4) end
        lastBall=pos
        lastSample=now
    end
    if not hum or not root or hum.Health<=0 then return end
    if flags.AutoSave then
        autosave(hum,root,pos)
    elseif flags.AutoPlay then
        autoplay(hum,root,pos)
    end
end)
local function stop()
    if not alive then return end
    alive=false
    RunService:UnbindFromRenderStep('ISH_MouseFree')
    UIS.MouseBehavior=Enum.MouseBehavior.Default
    UIS.MouseIconEnabled=true
    local _,hum=characterInfo()
    if hum then hum:Move(Vector3.zero,false) end
    for _,c in ipairs(connections) do c:Disconnect() end
    gui:Destroy()
    if env.ISH_Stop==stop then env.ISH_Stop=nil end
end
bind(closeBtn.MouseButton1Click,stop)
env.ISH_Stop=stop
print('Illegal Soccer Hub V3.4 carregado')
