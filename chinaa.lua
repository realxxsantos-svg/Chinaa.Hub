--[[
    ═══════════════════════════════════════════════════
        CHINAA HUB - RIVALS EDITION v7
        GitHub Loadstring Version
        Botão preto redondo com "CH"
    ═══════════════════════════════════════════════════
]]

local BG_IMAGE_URL = "https://i.postimg.cc/9FXpJbn3/09747df31407d6cc698d3d52af36b492.jpg"
local FALLBACK_COLOR = Color3.fromRGB(0, 0, 0)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-------------------------------------------------
-- DETECTOR DE ESTADO
-------------------------------------------------
local GameState = { InMatch = false, IsAlive = false, HasWeapon = false }

local function checkGameState()
    GameState.IsAlive = false
    GameState.HasWeapon = false
    local char = LocalPlayer.Character
    if not char then GameState.InMatch = false return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then GameState.InMatch = false return end
    GameState.IsAlive = true
    local hasTool = char:FindFirstChildOfClass("Tool") ~= nil
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack and #backpack:GetChildren() > 0 then hasTool = true end
    GameState.HasWeapon = hasTool
    local enemiesAlive = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then enemiesAlive = enemiesAlive + 1 end
        end
    end
    GameState.InMatch = GameState.IsAlive and GameState.HasWeapon and enemiesAlive > 0
end

task.spawn(function()
    while true do
        pcall(checkGameState)
        task.wait(0.3)
    end
end)

-------------------------------------------------
-- ANTI-DETECÇÃO
-------------------------------------------------
local function applyAntiBan()
    pcall(function()
        if getgenv then
            getgenv().detected = false
            getgenv().IsUsingExecutor = false
        end
        if syn and syn.protect_gui then syn.protect_gui = true end
        if protect_gui then pcall(protect_gui, game.CoreGui) end
        if gethui then
            local hui = gethui()
            if hui then
                for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do
                    pcall(function() v.Parent = hui end)
                end
            end
        end
        local mt = getrawmetatable and getrawmetatable(game)
        if mt and setreadonly then
            setreadonly(mt, false)
            local oldNamecall = mt.__namecall
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod and getnamecallmethod() or ""
                if method == "Kick" and self == LocalPlayer then return nil end
                return oldNamecall(self, ...)
            end)
            setreadonly(mt, true)
        end
    end)
end

applyAntiBan()
LocalPlayer.OnTeleport:Connect(function()
    task.wait(2)
    applyAntiBan()
end)

-------------------------------------------------
-- ANTI-CRASH
-------------------------------------------------
local AntiCrash = { Enabled = true, AntiSleep = true, FrameLimit = 60, MemoryLimitMB = 900, HeatLevel = 0 }

task.spawn(function()
    while AntiCrash.Enabled and AntiCrash.AntiSleep do
        pcall(function()
            if setfpscap then setfpscap(60) end
            if game:GetService("GuiService") then
                pcall(function() game:GetService("GuiService"):GetGuiInset() end)
            end
        end)
        task.wait(20)
    end
end)

task.spawn(function()
    while AntiCrash.Enabled do
        pcall(function() if setfpscap then setfpscap(AntiCrash.FrameLimit) end end)
        task.wait(5)
    end
end)

task.spawn(function()
    while AntiCrash.Enabled do
        task.wait(10)
        local ok, mem = pcall(function() return gcinfo() / 1024 end)
        if ok and mem and mem > AntiCrash.MemoryLimitMB then
            pcall(function() if collectgarbage then collectgarbage("collect") end end)
            AntiCrash.FrameLimit = 30
        else
            if AntiCrash.FrameLimit < 60 and AntiCrash.HeatLevel < 2 then
                AntiCrash.FrameLimit = 60
            end
        end
    end
end)

task.spawn(function()
    while AntiCrash.Enabled do
        task.wait(30)
        pcall(function() if collectgarbage then collectgarbage("collect") end end)
    end
end)

-------------------------------------------------
-- ESP
-------------------------------------------------
local ESP_Folder = Instance.new("Folder")
ESP_Folder.Name = "ChinaaESP"
ESP_Folder.Parent = game:GetService("CoreGui")

local activeESP = {}
local espEnabled = false
local espOnlyInMatch = true

local function createBox(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    if activeESP[character] then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ChinaaBox"
    box.Size = Vector3.new(hrp.Size.X * 1.5, hrp.Size.Y * 6, hrp.Size.Z * 1.5)
    box.Adornee = hrp
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.35
    box.Color3 = Color3.fromRGB(255, 0, 0)
    box.Parent = ESP_Folder
    activeESP[character] = box
    humanoid.Died:Connect(function()
        if activeESP[character] then
            activeESP[character]:Destroy()
            activeESP[character] = nil
        end
    end)
end

local function clearAllESP()
    for _, box in pairs(activeESP) do pcall(function() box:Destroy() end) end
    activeESP = {}
end

local function updateESP()
    if not espEnabled or AntiCrash.HeatLevel == 2 then return end
    if espOnlyInMatch and not GameState.InMatch then
        if next(activeESP) then clearAllESP() end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                if activeESP[char] then
                    activeESP[char].Adornee = char.HumanoidRootPart
                else
                    createBox(char)
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        pcall(updateESP)
        task.wait(0.05)
    end
end)

-------------------------------------------------
-- AIMBOT
-------------------------------------------------
local aimbotEnabled = false
local aimbotFOV = 200
local aimbotSmooth = 1
local aimbotTarget = nil
local aimbotTeamCheck = true
local aimbotOnlyInMatch = true
local aimbotStatus = "Aguardando..."

local function getTeam(plr)
    local char = plr.Character
    if not char then return nil end
    return plr.Team or (char:FindFirstChild("Team") and char.Team.Value)
end

local function isEnemy(plr)
    if not aimbotTeamCheck then return true end
    local myTeam = getTeam(LocalPlayer)
    local theirTeam = getTeam(plr)
    if not myTeam or not theirTeam then return true end
    return myTeam ~= theirTeam
end

local function isInFOV(worldPos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen then return false, math.huge end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    return dist <= aimbotFOV, dist
end

local function isValidTarget(plr)
    if not plr or plr == LocalPlayer then return false end
    if not isEnemy(plr) then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    if not hum or not head or hum.Health <= 0 then return false end
    return true
end

local function findBestTarget()
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if isValidTarget(plr) then
            local head = plr.Character:FindFirstChild("Head")
            local inFov, dist = isInFOV(head.Position)
            if inFov and dist < bestDist then
                bestDist = dist
                best = plr
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end
    if aimbotOnlyInMatch and not GameState.InMatch then
        aimbotTarget = nil
        aimbotStatus = "⏸️ Fora de partida"
        return
    end
    if AntiCrash.HeatLevel == 2 then return end
    if not LocalPlayer.Character then return end
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        aimbotTarget = nil
        aimbotStatus = "💀 Morto"
        return
    end
    if not isValidTarget(aimbotTarget) then
        aimbotTarget = findBestTarget()
    end
    if aimbotTarget and aimbotTarget.Character then
        local head = aimbotTarget.Character:FindFirstChild("Head")
        if head then
            local camPos = Camera.CFrame.Position
            local targetCF = CFrame.new(camPos, head.Position)
            if aimbotSmooth <= 1 then
                Camera.CFrame = targetCF
            else
                Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / aimbotSmooth)
            end
            aimbotStatus = "🎯 " .. aimbotTarget.Name
        end
    else
        aimbotStatus = "🔍 Procurando..."
    end
end)

-------------------------------------------------
-- AUTO KILL
-------------------------------------------------
local autoKill = false
local autoKillRange = 300
local autoKillOnlyInMatch = true

local function getClosestEnemy()
    local closest, dist = nil, math.huge
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isEnemy(plr) and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - myHrp.Position).Magnitude
                if d < dist and d <= autoKillRange then
                    dist = d
                    closest = plr
                end
            end
        end
    end
    return closest
end

local function shootAt(targetHead)
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local tool = myChar:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end
    pcall(function()
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local n = obj.Name:lower()
                if n:find("hit") or n:find("shoot") or n:find("fire")
                   or n:find("damage") or n:find("bullet") or n:find("attack") then
                    pcall(function() obj:FireServer(targetHead, targetHead.Position) end)
                    pcall(function() obj:FireServer(targetHead) end)
                end
            end
        end
    end)
end

task.spawn(function()
    while true do
        if autoKill then
            if not autoKillOnlyInMatch or GameState.InMatch then
                local target = getClosestEnemy()
                if target and target.Character then
                    local myChar = LocalPlayer.Character
                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local tgtHrp = target.Character:FindFirstChild("HumanoidRootPart")
                    local tgtHead = target.Character:FindFirstChild("Head")
                    if myHrp and tgtHrp and tgtHead then
                        myHrp.CFrame = tgtHrp.CFrame * CFrame.new(0, 0, 2)
                        local aimDir = (tgtHead.Position - Camera.CFrame.Position).Unit
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + aimDir)
                        shootAt(tgtHead)
                    end
                end
            end
            task.wait(0.08)
        else
            task.wait(0.2)
        end
    end
end)

-------------------------------------------------
-- BOTÃO FLUTUANTE (Preto, redondo, com "CH")
-------------------------------------------------
local FloatingGui = Instance.new("ScreenGui")
FloatingGui.Name = "ChinaaFloating"
FloatingGui.ResetOnSpawn = false
FloatingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() FloatingGui.Parent = game:GetService("CoreGui") end)
if not FloatingGui.Parent then FloatingGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "ChinaaIcon"
FloatingBtn.Size = UDim2.new(0, 75, 0, 75)
FloatingBtn.Position = UDim2.new(0, 20, 0.4, 0)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Text = "CH"
FloatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingBtn.TextScaled = true
FloatingBtn.Font = Enum.Font.GothamBlack
FloatingBtn.AutoButtonColor = false
FloatingBtn.ZIndex = 999
FloatingBtn.Parent = FloatingGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = FloatingBtn

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.3
stroke.Parent = FloatingBtn

local padText = Instance.new("UIPadding")
padText.PaddingTop = UDim.new(0, 12)
padText.PaddingBottom = UDim.new(0, 12)
padText.PaddingLeft = UDim.new(0, 12)
padText.PaddingRight = UDim.new(0, 12)
padText.Parent = FloatingBtn

-------------------------------------------------
-- ABRIR/FECHAR PAINEL
-------------------------------------------------
local panelVisible = true

local function setPanelVisible(visible)
    panelVisible = visible
    pcall(function()
        local rayfieldGui = game:GetService("CoreGui"):FindFirstChild("Rayfield")
        if not rayfieldGui then rayfieldGui = LocalPlayer.PlayerGui:FindFirstChild("Rayfield") end
        if rayfieldGui then
            for _, obj in ipairs(rayfieldGui:GetDescendants()) do
                if obj:IsA("Frame") and obj.Name:lower():find("main") then
                    obj.Visible = visible
                end
            end
        end
    end)
end

-------------------------------------------------
-- RESIZE
-------------------------------------------------
local ResizeFrame = Instance.new("Frame")
ResizeFrame.Size = UDim2.new(0, 100, 0, 160)
ResizeFrame.Position = UDim2.new(0, 20, 0.4, -175)
ResizeFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ResizeFrame.BorderSizePixel = 0
ResizeFrame.Visible = false
ResizeFrame.ZIndex = 999
ResizeFrame.Parent = FloatingGui

local cornerR = Instance.new("UICorner")
cornerR.CornerRadius = UDim.new(0, 12)
cornerR.Parent = ResizeFrame

local strokeR = Instance.new("UIStroke")
strokeR.Color = Color3.fromRGB(220, 30, 30)
strokeR.Thickness = 1.5
strokeR.Parent = ResizeFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Parent = ResizeFrame

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.Parent = ResizeFrame

local function makeSmallBtn(text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 26)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Parent = ResizeFrame
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    return btn
end

local ScaleValue = 1.0
local ScaleLabel = Instance.new("TextLabel")
ScaleLabel.Size = UDim2.new(1, -16, 0, 20)
ScaleLabel.BackgroundTransparency = 1
ScaleLabel.Text = "Escala: 1.0x"
ScaleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ScaleLabel.TextSize = 12
ScaleLabel.Font = Enum.Font.GothamBold
ScaleLabel.Parent = ResizeFrame

local btnUp = makeSmallBtn("➕ Aumentar", Color3.fromRGB(50, 130, 50))
local btnDown = makeSmallBtn("➖ Diminuir", Color3.fromRGB(140, 60, 60))
local btnReset = makeSmallBtn("↺ Resetar", Color3.fromRGB(60, 60, 90))
local btnClose = makeSmallBtn("✕ Fechar", Color3.fromRGB(90, 30, 30))

local function applyScale(scale)
    ScaleValue = math.clamp(scale, 0.5, 2.0)
    ScaleLabel.Text = string.format("Escala: %.1fx", ScaleValue)
    pcall(function()
        local rayfieldGui = game:GetService("CoreGui"):FindFirstChild("Rayfield")
        if not rayfieldGui then rayfieldGui = LocalPlayer.PlayerGui:FindFirstChild("Rayfield") end
        if rayfieldGui then
            for _, obj in ipairs(rayfieldGui:GetDescendants()) do
                if obj:IsA("Frame") and (obj.Name:lower():find("main") or obj.Name == "Main") then
                    local baseSize = obj:GetAttribute("BaseSize")
                    if not baseSize then
                        baseSize = obj.AbsoluteSize
                        obj:SetAttribute("BaseSize", baseSize)
                    end
                    obj.Size = UDim2.new(0, baseSize.X * ScaleValue, 0, baseSize.Y * ScaleValue)
                end
            end
        end
    end)
end

btnUp.MouseButton1Click:Connect(function() applyScale(ScaleValue + 0.1) end)
btnDown.MouseButton1Click:Connect(function() applyScale(ScaleValue - 0.1) end)
btnReset.MouseButton1Click:Connect(function() applyScale(1.0) end)
btnClose.MouseButton1Click:Connect(function() ResizeFrame.Visible = false end)

-------------------------------------------------
-- TOQUE NO BOTÃO (CURTO = abrir/fechar | LONGO = resize)
-------------------------------------------------
local touchStartTime = 0
local isDraggingBtn = false

FloatingBtn.MouseButton1Down:Connect(function()
    touchStartTime = tick()
    isDraggingBtn = false
end)

FloatingBtn.MouseButton1Up:Connect(function()
    local held = tick() - touchStartTime
    if isDraggingBtn then return end
    if held >= 0.5 then
        ResizeFrame.Visible = not ResizeFrame.Visible
    else
        setPanelVisible(not panelVisible)
    end
end)

-------------------------------------------------
-- ARRASTAR BOTÃO
-------------------------------------------------
local dragging = false
local dragStart, startPos
local dragThreshold = 8

FloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = FloatingBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or
                     input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        if delta.Magnitude > dragThreshold then isDraggingBtn = true end
        FloatingBtn.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        ResizeFrame.Position = UDim2.new(
            FloatingBtn.Position.X.Scale, FloatingBtn.Position.X.Offset,
            FloatingBtn.Position.Y.Scale, FloatingBtn.Position.Y.Offset - 175
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        task.wait(0.1)
        isDraggingBtn = false
    end
end)

-------------------------------------------------
-- UI RAYFIELD
-------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Chinaa Hub",
    LoadingTitle = "Chinaa Hub",
    LoadingSubtitle = "RIVALS v7 | Mobile",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- Fundo customizado
task.spawn(function()
    task.wait(1.5)
    local rayfieldGui = game:GetService("CoreGui"):FindFirstChild("Rayfield")
    if not rayfieldGui then rayfieldGui = LocalPlayer.PlayerGui:FindFirstChild("Rayfield") end
    if not rayfieldGui then return end
    local mainFrame
    for _, obj in ipairs(rayfieldGui:GetDescendants()) do
        if obj:IsA("Frame") and (obj.Name == "Main" or obj.Name:lower():find("main")) then
            mainFrame = obj
            break
        end
    end
    if not mainFrame then return end
    local bgImage = Instance.new("ImageLabel")
    bgImage.Size = UDim2.new(1, 0, 1, 0)
    bgImage.BackgroundTransparency = 1
    bgImage.Image = BG_IMAGE_URL
    bgImage.ImageTransparency = 0.3
    bgImage.ScaleType = Enum.ScaleType.Crop
    bgImage.ZIndex = 0
    bgImage.Parent = mainFrame
    bgImage.ImageFailed:Connect(function()
        bgImage.Image = ""
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 0)),
        })
        gradient.Rotation = 45
        gradient.Parent = bgImage
        bgImage.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
        bgImage.BackgroundTransparency = 0.2
    end)
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 10)
    bgCorner.Parent = bgImage
    for _, obj in ipairs(mainFrame:GetDescendants()) do
        if obj:IsA("Frame") and obj.BackgroundTransparency < 1 and obj ~= bgImage then
            obj.BackgroundTransparency = math.min(obj.BackgroundTransparency + 0.4, 0.85)
        end
    end
    mainFrame.BackgroundTransparency = 0.3
end)

local MainTab = Window:CreateTab("Principal", 4483362458)

MainTab:CreateSection("📊 Status")
local statusLabel = MainTab:CreateLabel("🔍 Verificando...")

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local matchStr = GameState.InMatch and "✅ EM PARTIDA" or "⏸️ Fora"
            local statusStr = aimbotEnabled and aimbotStatus or "Aimbot OFF"
            statusLabel:Set("🎮 " .. matchStr .. "\n🎯 " .. statusStr)
        end)
    end
end)

MainTab:CreateSection("Visual")
MainTab:CreateToggle({
    Name = "ESP Players (Box Vermelha 3D)",
    CurrentValue = false, Flag = "ESPPlayers",
    Callback = function(value)
        espEnabled = value
        if value then
            if not espOnlyInMatch or GameState.InMatch then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then createBox(plr.Character) end
                end
            end
        else clearAllESP() end
    end,
})
MainTab:CreateToggle({
    Name = "ESP: Só mostrar em partida",
    CurrentValue = true, Flag = "ESPOnlyMatch",
    Callback = function(value) espOnlyInMatch = value end,
})

MainTab:CreateSection("Combate")
MainTab:CreateToggle({
    Name = "Aimbot (Mira travada na cabeça)",
    CurrentValue = false, Flag = "Aimbot",
    Callback = function(value) aimbotEnabled = value; aimbotTarget = nil end,
})
MainTab:CreateToggle({
    Name = "🎯 Aimbot: Só funcionar em partida",
    CurrentValue = true, Flag = "AimbotOnlyMatch",
    Callback = function(value) aimbotOnlyInMatch = value end,
})
MainTab:CreateToggle({
    Name = "Aimbot: Team Check",
    CurrentValue = true, Flag = "AimbotTeam",
    Callback = function(value) aimbotTeamCheck = value; aimbotTarget = nil end,
})
MainTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = { 30, 600 }, Increment = 10, Suffix = "px",
    CurrentValue = 200, Flag = "AimbotFOV",
    Callback = function(value) aimbotFOV = value end,
})
MainTab:CreateSlider({
    Name = "Aimbot Suavidade (1 = travado)",
    Range = { 1, 10 }, Increment = 1, Suffix = "x",
    CurrentValue = 1, Flag = "AimbotSmooth",
    Callback = function(value) aimbotSmooth = value end,
})
MainTab:CreateToggle({
    Name = "Auto Kill (Teleporte + Headshot)",
    CurrentValue = false, Flag = "AutoKill",
    Callback = function(value) autoKill = value end,
})
MainTab:CreateToggle({
    Name = "💥 Auto Kill: Só em partida",
    CurrentValue = true, Flag = "AutoKillOnlyMatch",
    Callback = function(value) autoKillOnlyInMatch = value end,
})
MainTab:CreateSlider({
    Name = "Auto Kill: Alcance",
    Range = { 50, 1000 }, Increment = 50, Suffix = "studs",
    CurrentValue = 300, Flag = "AutoKillRange",
    Callback = function(value) autoKillRange = value end,
})

MainTab:CreateSection("🎨 Interface")
MainTab:CreateSlider({
    Name = "Escala do Painel",
    Range = { 50, 200 }, Increment = 10, Suffix = "%",
    CurrentValue = 100, Flag = "PanelScale",
    Callback = function(value) applyScale(value / 100) end,
})
MainTab:CreateButton({
    Name = "🔄 Resetar Escala",
    Callback = function()
        applyScale(1.0)
        Rayfield:Notify({ Title = "Chinaa Hub", Content = "Escala resetada", Duration = 2 })
    end,
})
MainTab:CreateButton({
    Name = "👁️ Esconder Painel",
    Callback = function()
        setPanelVisible(false)
        Rayfield:Notify({
            Title = "Chinaa Hub",
            Content = "Painel escondido — clique no CH",
            Duration = 3,
        })
    end,
})

MainTab:CreateSection("🛡️ Anti-Crash")
MainTab:CreateToggle({
    Name = "Anti-Crash Completo",
    CurrentValue = true, Flag = "AntiCrash",
    Callback = function(value) AntiCrash.Enabled = value end,
})
MainTab:CreateToggle({
    Name = "Anti-Sleep",
    CurrentValue = true, Flag = "AntiSleep",
    Callback = function(value) AntiCrash.AntiSleep = value end,
})
MainTab:CreateSlider({
    Name = "Limite de FPS",
    Range = { 30, 120 }, Increment = 10, Suffix = "fps",
    CurrentValue = 60, Flag = "FPSLimit",
    Callback = function(value) AntiCrash.FrameLimit = value end,
})

MainTab:CreateSection("Segurança")
MainTab:CreateToggle({
    Name = "Anti-Ban (Anti-Detecção)",
    CurrentValue = true, Flag = "AntiBan",
    Callback = function(value) if value then applyAntiBan() end end,
})

Rayfield:Notify({
    Title = "Chinaa Hub",
    Content = "v7 carregado! Clique no CH preto 🖤",
    Duration = 5,
})
