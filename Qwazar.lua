--// ============================================
--//  LUNIE HUB v2.0 • Blox
--//  UI: Lunie Hub | Features: META
--// ============================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

if CoreGui:FindFirstChild("LunieHubUI") then
    CoreGui.LunieHubUI:Destroy()
end

--// ============================================
--//  PALETTE
--// ============================================
local C = {
    Bg        = Color3.fromRGB(13, 13, 18),
    BgSoft    = Color3.fromRGB(18, 18, 24),
    Sidebar   = Color3.fromRGB(18, 18, 24),
    Panel     = Color3.fromRGB(26, 22, 38),
    PanelSoft = Color3.fromRGB(32, 26, 48),
    TabIdle   = Color3.fromRGB(24, 20, 34),
    TabHover  = Color3.fromRGB(40, 30, 62),
    Accent    = Color3.fromRGB(138, 92, 255),
    Accent2   = Color3.fromRGB(180, 110, 255),
    AccentD   = Color3.fromRGB(90, 55, 190),
    AccentL   = Color3.fromRGB(200, 160, 255),
    Text      = Color3.fromRGB(242, 242, 248),
    SubText   = Color3.fromRGB(150, 150, 168),
    Divider   = Color3.fromRGB(40, 40, 54),
    Stroke    = Color3.fromRGB(52, 52, 68),
}

--// ============================================
--//  SOUND ENGINE
--// ============================================
local SoundFolder = SoundService:FindFirstChild("LunieHubSounds")
if not SoundFolder then
    SoundFolder = Instance.new("Folder")
    SoundFolder.Name = "LunieHubSounds"
    SoundFolder.Parent = SoundService
end

local function PlaySound(id, vol, pitch)
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. id
    s.Volume = vol or 0.4
    s.PlaybackSpeed = pitch or 1
    s.Parent = SoundFolder
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

local SFX = {
    Hover   = function() PlaySound(91188231033060, 0.10, 1.7) end,
    Click   = function() PlaySound(91188231033060, 0.28, 1.0) end,
    TabOpen = function() PlaySound(6042053626,     0.32, 1.15) end,
    Open    = function() PlaySound(6042053626,     0.42, 0.9)  end,
    Close   = function() PlaySound(6042053626,     0.32, 0.7)  end,
    Pop     = function() PlaySound(6042053626,     0.35, 1.4)  end,
}

--// ============================================
--//  SCREEN GUI
--// ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunieHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

local function HideFromScanner(gui)
    pcall(function()
        sethiddenproperty(gui, "RobloxLocked", true)
        sethiddenproperty(gui, "Archivable", false)
    end)
end
HideFromScanner(ScreenGui)

--// ============================================
--//  ANTI-CHEAT BYPASS
--// ============================================
local function SetupAntiCheatBypass()
    pcall(function()
        local Network = require(ReplicatedStorage.Database.Security.Network)
        local OriginalCreatePacket = Network.CreatePacket
        Network.CreatePacket = function(namespace, packetName, schema, options)
            local packet = OriginalCreatePacket(namespace, packetName, schema, options)
            if packet and packet.Send then
                local OriginalSend = packet.Send
                packet.Send = function(data)
                    local success, result = pcall(function()
                        local BufferCodec = require(ReplicatedStorage.Database.Security.Network.BufferCodec)
                        local encoded, instances = BufferCodec.Encode(data)
                        local remote = ReplicatedStorage:FindFirstChild("NetworkRemotes")
                        local folder = remote and remote:FindFirstChild(namespace)
                        local event = folder and folder:FindFirstChild(packetName)
                        if event then event:FireServer(encoded, instances) return true end
                        return false
                    end)
                    if success and result then return true end
                    return OriginalSend(data)
                end
            end
            return packet
        end
    end)
end
SetupAntiCheatBypass()

--// ============================================
--//  GLOBAL CONFIG
--// ============================================
_G.CurrentLang = "EN"
_G.MenuOpacity = 12
_G.MenuScale   = 45
_G.MenuThemeColor = Color3.fromRGB(255, 255, 255)
_G.CustomThemeEnabled = false
_G.RainbowEnabled = false
_G.FlyingDots = false

_G.ChamsEnabled = false
_G.ESPEnabled = false
_G.SkeletonEnabled = false
_G.HealthBarEnabled = false
_G.ParticleEffectGuiEnabled = false
_G.FpsBoostEnabled = false
_G.ChamsColor = Color3.fromRGB(110, 60, 170)
_G.SkeletonColor = Color3.fromRGB(255, 255, 255)

_G.SilentAimEnabled = false
_G.OffCircleEnabled = false
_G.SilentAimFOV = 200
_G.SelectedPart = "Head"
_G.NoRecoilEnabled = false
_G.NoSpreadEnabled = false

--// ============================================
--//  ENEMY CHECK
--// ============================================
local function IsEnemy(p)
    if not p or p == LocalPlayer then return false end
    if p.Team and LocalPlayer.Team then
        if p.Team ~= LocalPlayer.Team then return true end
        if p.Team.Name ~= LocalPlayer.Team.Name then return true end
    end
    if p.TeamColor and LocalPlayer.TeamColor then
        if p.TeamColor ~= LocalPlayer.TeamColor then return true end
    end
    local mySide = LocalPlayer:GetAttribute("Team") or LocalPlayer:GetAttribute("Side") or ""
    local enemySide = p:GetAttribute("Team") or p:GetAttribute("Side") or ""
    if mySide ~= "" and enemySide ~= "" then return mySide ~= enemySide end
    return false
end

--// ============================================
--//  CHAMS
--// ============================================
local ChamsConnections = {}

local function PaintCharacter(character, p)
    if not character or not p then return end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Highlight") and child:GetAttribute("LUNIE_Chams") then child:Destroy() end
    end
    if IsEnemy(p) then
        local highlight = Instance.new("Highlight")
        highlight.Name = "Highlight"
        highlight:SetAttribute("LUNIE_Chams", true)
        highlight.FillColor = _G.ChamsColor
        highlight.OutlineColor = _G.ChamsColor
        highlight.FillTransparency = 0.65
        highlight.OutlineTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = character
        highlight.Parent = character
        HideFromScanner(highlight)
    end
end

local function SetupPlayer(p)
    if p == LocalPlayer then return end
    if ChamsConnections[p] then ChamsConnections[p]:Disconnect() end
    ChamsConnections[p] = p.CharacterAdded:Connect(function(char)
        task.wait(0.6)
        PaintCharacter(char, p)
    end)
    if p.Character then task.wait(0.2) PaintCharacter(p.Character, p) end
end

local function ApplyChams()
    if _G.UnloadChams then _G.UnloadChams() end
    _G.ChamsEnabled = true
    for _, p in ipairs(Players:GetPlayers()) do SetupPlayer(p) end
    ChamsConnections.PlayerAdded = Players.PlayerAdded:Connect(SetupPlayer)
    _G.UnloadChams = function()
        _G.ChamsEnabled = false
        if ChamsConnections.PlayerAdded then ChamsConnections.PlayerAdded:Disconnect() end
        for _, p in ipairs(Players:GetPlayers()) do
            if ChamsConnections[p] then ChamsConnections[p]:Disconnect() end
            if p.Character then
                for _, child in ipairs(p.Character:GetChildren()) do
                    if child:IsA("Highlight") and child:GetAttribute("LUNIE_Chams") then child:Destroy() end
                end
            end
        end
    end
end

local function RemoveChams()
    if _G.UnloadChams then _G.UnloadChams() end
end

--// ============================================
--//  ESP
--// ============================================
local ESPConnections = {}

local function SetupESP()
    local function NewLine()
        local line = Drawing.new("Line")
        line.Visible = false
        line.From = Vector2.new(0, 0)
        line.To = Vector2.new(1, 1)
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Thickness = 1.4
        line.Transparency = 1
        return line
    end

    local function CreateESP(target)
        local lines = {}
        for i = 1, 12 do lines[i] = NewLine() end
        lines.Tracer = NewLine()
        local conn = RunService.RenderStepped:Connect(function()
            if not _G.ESPEnabled then for _, l in pairs(lines) do l.Visible = false end return end
            local char = target.Character
            if not char then for _, l in pairs(lines) do l.Visible = false end return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChild("Humanoid")
            if not hrp or not head or not hum or hum.Health <= 0 then for _, l in pairs(lines) do l.Visible = false end return end
            if target == LocalPlayer or not IsEnemy(target) then for _, l in pairs(lines) do l.Visible = false end return end
            local rootVisible = Camera:WorldToViewportPoint(hrp.Position)
            if not rootVisible then for _, l in pairs(lines) do l.Visible = false end return end
            local scale = head.Size.Y / 2
            local boxSize = Vector3.new(2, 3, 1.5) * (scale * 2)
            local cf = hrp.CFrame
            local c = {}
            c[1] = Camera:WorldToViewportPoint((cf * CFrame.new(-boxSize.X, boxSize.Y, -boxSize.Z)).Position)
            c[2] = Camera:WorldToViewportPoint((cf * CFrame.new(-boxSize.X, boxSize.Y, boxSize.Z)).Position)
            c[3] = Camera:WorldToViewportPoint((cf * CFrame.new(boxSize.X, boxSize.Y, boxSize.Z)).Position)
            c[4] = Camera:WorldToViewportPoint((cf * CFrame.new(boxSize.X, boxSize.Y, -boxSize.Z)).Position)
            c[5] = Camera:WorldToViewportPoint((cf * CFrame.new(-boxSize.X, -boxSize.Y, -boxSize.Z)).Position)
            c[6] = Camera:WorldToViewportPoint((cf * CFrame.new(-boxSize.X, -boxSize.Y, boxSize.Z)).Position)
            c[7] = Camera:WorldToViewportPoint((cf * CFrame.new(boxSize.X, -boxSize.Y, boxSize.Z)).Position)
            c[8] = Camera:WorldToViewportPoint((cf * CFrame.new(boxSize.X, -boxSize.Y, -boxSize.Z)).Position)
            local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
            for i, e in ipairs(edges) do
                lines[i].From = Vector2.new(c[e[1]].X, c[e[1]].Y)
                lines[i].To = Vector2.new(c[e[2]].X, c[e[2]].Y)
                lines[i].Visible = true
            end
            local bottomPos = Camera:WorldToViewportPoint((cf * CFrame.new(0, -boxSize.Y, 0)).Position)
            lines.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            lines.Tracer.To = Vector2.new(bottomPos.X, bottomPos.Y)
            lines.Tracer.Visible = true
        end)
        ESPConnections[target] = conn
    end

    local function ApplyESP()
        if _G.UnloadESP then _G.UnloadESP() end
        _G.ESPEnabled = true
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then CreateESP(p) end
        end
        ESPConnections.PlayerAdded = Players.PlayerAdded:Connect(function(p)
            task.wait(1)
            if p ~= LocalPlayer and _G.ESPEnabled then CreateESP(p) end
        end)
        _G.UnloadESP = function()
            _G.ESPEnabled = false
            if ESPConnections.PlayerAdded then ESPConnections.PlayerAdded:Disconnect() end
            for _, conn in pairs(ESPConnections) do
                if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
            end
            ESPConnections = {}
        end
    end

    local function RemoveESP()
        if _G.UnloadESP then _G.UnloadESP() end
    end

    return ApplyESP, RemoveESP
end

local ApplyESP, RemoveESP = SetupESP()

task.spawn(function()
    while true do
        task.wait(1)
        if _G.ESPEnabled then RemoveESP() ApplyESP() end
    end
end)

--// ============================================
--//  SKELETON
--// ============================================
local SkeletonLines = {}
local SkeletonEnemiesList = {}
local SkeletonCacheTime = 0

local function CreateSkeletonLine()
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Visible = false
    line.Color = _G.SkeletonColor or Color3.fromRGB(255, 255, 255)
    line.Transparency = 1
    return line
end

local function GetSkeletonPos(part)
    if not part or not part:IsA("BasePart") then return nil end
    local pos = Camera:WorldToViewportPoint(part.Position)
    if pos.Z > 0 then return Vector2.new(pos.X, pos.Y) end
    return nil
end

local function RemoveSkeletonData(target)
    local data = SkeletonLines[target]
    if data then
        pcall(function()
            for _, line in pairs(data) do
                line.Visible = false
                line:Remove()
            end
        end)
        SkeletonLines[target] = nil
    end
end

local function GetSkeletonHealth(character)
    if not character then return nil, nil end
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health and humanoid.MaxHealth then
        if humanoid.Health > 0 then return humanoid.Health, humanoid.MaxHealth end
        return nil, nil
    end
    local healthAttr = character:GetAttribute("Health")
    local maxHealthAttr = character:GetAttribute("MaxHealth")
    if healthAttr and maxHealthAttr and healthAttr > 0 then return healthAttr, maxHealthAttr end
    return nil, nil
end

local function UpdateSkeletonEnemies()
    if tick() - SkeletonCacheTime < 0.5 then return end
    SkeletonCacheTime = tick()
    SkeletonEnemiesList = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character.Parent then
            if IsEnemy(player) then
                local health, maxHealth = GetSkeletonHealth(player.Character)
                if health and health > 0 then
                    SkeletonEnemiesList[player] = {char = player.Character, health = health, maxHealth = maxHealth}
                else
                    RemoveSkeletonData(player)
                end
            else
                RemoveSkeletonData(player)
            end
        else
            RemoveSkeletonData(player)
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not _G.SkeletonEnabled then
        for _, data in pairs(SkeletonLines) do
            for _, line in pairs(data) do line.Visible = false end
        end
        return
    end

    UpdateSkeletonEnemies()

    for player, data in pairs(SkeletonEnemiesList) do
        if not player or not player.Character or not player.Character.Parent then
            RemoveSkeletonData(player)
            continue
        end

        local char = player.Character
        local health, maxHealth = GetSkeletonHealth(char)
        if not health or health <= 0 then
            RemoveSkeletonData(player)
            continue
        end

        local head = char:FindFirstChild("Head")
        local upperTorso = char:FindFirstChild("UpperTorso")
        local lowerTorso = char:FindFirstChild("LowerTorso")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local torso = char:FindFirstChild("Torso")

        if not head or (not upperTorso and not torso) then
            RemoveSkeletonData(player)
            continue
        end

        local headPos = GetSkeletonPos(head)
        local upperTorsoPos = GetSkeletonPos(upperTorso or torso)
        local lowerTorsoPos = GetSkeletonPos(lowerTorso)
        local hrpPos = GetSkeletonPos(hrp)

        if not headPos or not upperTorsoPos then
            RemoveSkeletonData(player)
            continue
        end

        if not SkeletonLines[player] then
            SkeletonLines[player] = {}
            for i = 1, 15 do table.insert(SkeletonLines[player], CreateSkeletonLine()) end
        end

        local lines = SkeletonLines[player]
        local idx = 1

        local function setLine(from, to, show)
            if from and to and show then
                lines[idx].From = from
                lines[idx].To = to
                lines[idx].Visible = true
                lines[idx].Thickness = 2
                lines[idx].Color = _G.SkeletonColor or Color3.fromRGB(255, 255, 255)
            else
                lines[idx].Visible = false
            end
            idx = idx + 1
        end

        local leftUpperArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
        local leftLowerArm = char:FindFirstChild("LeftLowerArm")
        local leftHand = char:FindFirstChild("LeftHand")
        local rightUpperArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
        local rightLowerArm = char:FindFirstChild("RightLowerArm")
        local rightHand = char:FindFirstChild("RightHand")
        local leftUpperLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
        local leftLowerLeg = char:FindFirstChild("LeftLowerLeg")
        local leftFoot = char:FindFirstChild("LeftFoot")
        local rightUpperLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
        local rightLowerLeg = char:FindFirstChild("RightLowerLeg")
        local rightFoot = char:FindFirstChild("RightFoot")

        setLine(headPos, upperTorsoPos, true)
        setLine(upperTorsoPos, lowerTorsoPos, lowerTorsoPos ~= nil)
        setLine(upperTorsoPos, hrpPos, hrpPos ~= nil)
        setLine(upperTorsoPos, leftUpperArm and GetSkeletonPos(leftUpperArm), leftUpperArm ~= nil)
        setLine(leftUpperArm and GetSkeletonPos(leftUpperArm), leftLowerArm and GetSkeletonPos(leftLowerArm), leftUpperArm ~= nil and leftLowerArm ~= nil)
        setLine(leftLowerArm and GetSkeletonPos(leftLowerArm), leftHand and GetSkeletonPos(leftHand), leftLowerArm ~= nil and leftHand ~= nil)
        setLine(upperTorsoPos, rightUpperArm and GetSkeletonPos(rightUpperArm), rightUpperArm ~= nil)
        setLine(rightUpperArm and GetSkeletonPos(rightUpperArm), rightLowerArm and GetSkeletonPos(rightLowerArm), rightUpperArm ~= nil and rightLowerArm ~= nil)
        setLine(rightLowerArm and GetSkeletonPos(rightLowerArm), rightHand and GetSkeletonPos(rightHand), rightLowerArm ~= nil and rightHand ~= nil)

        if lowerTorsoPos then
            setLine(lowerTorsoPos, leftUpperLeg and GetSkeletonPos(leftUpperLeg), leftUpperLeg ~= nil)
            setLine(lowerTorsoPos, rightUpperLeg and GetSkeletonPos(rightUpperLeg), rightUpperLeg ~= nil)
        elseif hrpPos then
            setLine(hrpPos, leftUpperLeg and GetSkeletonPos(leftUpperLeg), leftUpperLeg ~= nil)
            setLine(hrpPos, rightUpperLeg and GetSkeletonPos(rightUpperLeg), rightUpperLeg ~= nil)
        else
            setLine(upperTorsoPos, leftUpperLeg and GetSkeletonPos(leftUpperLeg), leftUpperLeg ~= nil)
            setLine(upperTorsoPos, rightUpperLeg and GetSkeletonPos(rightUpperLeg), rightUpperLeg ~= nil)
        end

        setLine(leftUpperLeg and GetSkeletonPos(leftUpperLeg), leftLowerLeg and GetSkeletonPos(leftLowerLeg), leftUpperLeg ~= nil and leftLowerLeg ~= nil)
        setLine(rightUpperLeg and GetSkeletonPos(rightUpperLeg), rightLowerLeg and GetSkeletonPos(rightLowerLeg), rightUpperLeg ~= nil and rightLowerLeg ~= nil)
        setLine(leftLowerLeg and GetSkeletonPos(leftLowerLeg), leftFoot and GetSkeletonPos(leftFoot), leftLowerLeg ~= nil and leftFoot ~= nil)
        setLine(rightLowerLeg and GetSkeletonPos(rightLowerLeg), rightFoot and GetSkeletonPos(rightFoot), rightLowerLeg ~= nil and rightFoot ~= nil)

        while idx <= #lines do
            lines[idx].Visible = false
            idx = idx + 1
        end
    end

    for player, _ in pairs(SkeletonLines) do
        if not SkeletonEnemiesList[player] then RemoveSkeletonData(player) end
    end
end)

local function ApplySkeleton() _G.SkeletonEnabled = true end
local function RemoveSkeleton()
    _G.SkeletonEnabled = false
    for player, _ in pairs(SkeletonLines) do RemoveSkeletonData(player) end
    SkeletonEnemiesList = {}
end

--// ============================================
--//  HEALTH BAR
--// ============================================
local HealthBars = {}
local HealthEnemiesList = {}
local HealthCacheTime = 0
local HealthHistoryData = {}

local function CreateHealthBar()
    local bg = Drawing.new("Square")
    bg.Thickness = 0 bg.Filled = true bg.Visible = false
    bg.Color = Color3.fromRGB(15, 17, 25) bg.Transparency = 0.7 bg.ZIndex = 0
    local bar = Drawing.new("Square")
    bar.Thickness = 0 bar.Filled = true bar.Visible = false
    bar.Transparency = 0.85 bar.ZIndex = 1
    local border = Drawing.new("Square")
    border.Thickness = 1.2 border.Filled = false border.Visible = false
    border.Color = Color3.fromRGB(80, 90, 120) border.Transparency = 0.5 border.ZIndex = 2
    return {Bg = bg, Bar = bar, Border = border}
end

local function GetHealthValue(character)
    if not character then return nil, nil end
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health and humanoid.MaxHealth then
        if humanoid.Health > 0 then return humanoid.Health, humanoid.MaxHealth end
        return nil, nil
    end
    local healthAttr = character:GetAttribute("Health")
    local maxHealthAttr = character:GetAttribute("MaxHealth")
    if healthAttr and maxHealthAttr and healthAttr > 0 then return healthAttr, maxHealthAttr end
    return nil, nil
end

local function GetHealthBarColor(health, maxHealth, prevHealth)
    local percent = health / maxHealth
    local isDamaged = prevHealth and prevHealth > health and (prevHealth - health) > 5
    if isDamaged then return Color3.fromRGB(255, 255, 255) end
    if percent <= 0.20 then return Color3.fromRGB(255, 50, 50)
    elseif percent <= 0.40 then return Color3.fromRGB(255, 170, 50)
    elseif percent <= 0.60 then return Color3.fromRGB(255, 220, 50)
    elseif percent <= 0.80 then return Color3.fromRGB(150, 255, 50)
    else return Color3.fromRGB(50, 255, 150) end
end

local function RemoveHealthBarData(target)
    local data = HealthBars[target]
    if data then
        pcall(function()
            data.Bg.Visible = false data.Bar.Visible = false data.Border.Visible = false
            data.Bg:Remove() data.Bar:Remove() data.Border:Remove()
        end)
        HealthBars[target] = nil
    end
    HealthHistoryData[target] = nil
end

local function UpdateHealthEnemiesList()
    if tick() - HealthCacheTime < 0.5 then return end
    HealthCacheTime = tick()
    HealthEnemiesList = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character.Parent then
            if IsEnemy(player) then
                local health, maxHealth = GetHealthValue(player.Character)
                if health and health > 0 then
                    HealthEnemiesList[player] = {char = player.Character, health = health, maxHealth = maxHealth}
                else
                    RemoveHealthBarData(player)
                end
            else
                RemoveHealthBarData(player)
            end
        else
            RemoveHealthBarData(player)
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not _G.HealthBarEnabled then
        for _, data in pairs(HealthBars) do
            data.Bg.Visible = false data.Bar.Visible = false data.Border.Visible = false
        end
        return
    end

    UpdateHealthEnemiesList()

    for player, data in pairs(HealthEnemiesList) do
        if not player or not player.Character or not player.Character.Parent then
            RemoveHealthBarData(player)
            continue
        end

        local char = player.Character
        local health, maxHealth = GetHealthValue(char)
        if not health or health <= 0 then
            RemoveHealthBarData(player)
            continue
        end

        local prevHealth = HealthHistoryData[player]
        HealthHistoryData[player] = health

        local head = char:FindFirstChild("Head")
        if not head then RemoveHealthBarData(player) continue end

        local headPos, headVis = Camera:WorldToViewportPoint(head.Position)
        local distance = (Camera.CFrame.Position - head.Position).Magnitude

        if headVis and headPos.Z > 0 and distance <= 1000 then
            local barWidth = 50
            local barHeight = 5
            local scale = 1 / (headPos.Z * 0.015 + 0.5)
            if scale > 1.5 then scale = 1.5 end
            if scale < 0.4 then scale = 0.4 end

            local finalWidth = barWidth * scale
            local finalHeight = barHeight * scale
            local offsetY = 4 * scale
            local barX = headPos.X - finalWidth / 2
            local barY = headPos.Y - finalHeight - offsetY

            if barX < 5 then barX = 5 end
            if barX + finalWidth > Camera.ViewportSize.X - 5 then barX = Camera.ViewportSize.X - finalWidth - 5 end
            if barY < 5 then barY = 5 end

            if not HealthBars[player] then HealthBars[player] = CreateHealthBar() end

            local barData = HealthBars[player]
            local hpPercent = health / maxHealth
            local filledWidth = finalWidth * hpPercent

            barData.Bg.Size = Vector2.new(finalWidth, finalHeight)
            barData.Bg.Position = Vector2.new(barX, barY)
            barData.Bg.Visible = true
            barData.Bg.Transparency = 0.7
            barData.Bg.Color = Color3.fromRGB(15, 17, 25)
            barData.Bg.Thickness = 0

            barData.Bar.Size = Vector2.new(math.max(filledWidth, 0.5), finalHeight)
            barData.Bar.Position = Vector2.new(barX, barY)
            barData.Bar.Visible = true
            barData.Bar.Transparency = 0.85
            barData.Bar.Thickness = 0
            barData.Bar.Color = GetHealthBarColor(health, maxHealth, prevHealth)

            if prevHealth and prevHealth > health and (prevHealth - health) > 5 then
                barData.Bar.Color = Color3.fromRGB(255, 255, 255)
                barData.Bar.Transparency = 0.7
            end

            barData.Border.Size = Vector2.new(finalWidth, finalHeight)
            barData.Border.Position = Vector2.new(barX, barY)
            barData.Border.Visible = true
            barData.Border.Transparency = 0.5
            barData.Border.Color = Color3.fromRGB(80, 90, 120)
            barData.Border.Thickness = 1.2
        else
            if HealthBars[player] then
                HealthBars[player].Bg.Visible = false
                HealthBars[player].Bar.Visible = false
                HealthBars[player].Border.Visible = false
            end
        end
    end

    for player, _ in pairs(HealthBars) do
        if not HealthEnemiesList[player] then RemoveHealthBarData(player) end
    end
end)

local function ApplyHealthBar() _G.HealthBarEnabled = true end
local function RemoveHealthBar()
    _G.HealthBarEnabled = false
    for player, _ in pairs(HealthBars) do RemoveHealthBarData(player) end
    HealthEnemiesList = {}
    HealthHistoryData = {}
end

--// ============================================
--//  PARTICLE EFFECT GUI
--// ============================================
local ParticleGuiContainer = nil
local ParticleGuiConnection = nil

local function CreateParticleGui()
    if ParticleGuiContainer then ParticleGuiContainer:Destroy() end
    if ParticleGuiConnection then ParticleGuiConnection:Disconnect() end

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    ParticleGuiContainer = Instance.new("ScreenGui")
    ParticleGuiContainer.Name = "LUNIE_ParticleEffectGui"
    ParticleGuiContainer.ResetOnSpawn = false
    ParticleGuiContainer.IgnoreGuiInset = true
    ParticleGuiContainer.DisplayOrder = 999999
    ParticleGuiContainer.Parent = PlayerGui
    HideFromScanner(ParticleGuiContainer)

    local particles = {}
    local lastSpawnTime = tick()

    local function SpawnParticle()
        local dot = Instance.new("Frame", ParticleGuiContainer)
        local size = math.random(2, 5)
        dot.Size = UDim2.new(0, size, 0, size)
        dot.Position = UDim2.new(math.random(0, 100) / 100, 0, 1, 10)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.BackgroundTransparency = 0.3
        dot.BorderSizePixel = 0
        dot.ZIndex = 999999
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local data = {
            Frame = dot,
            SpeedY = math.random(20, 50) / 10,
            SpeedX = (math.random() - 0.5) * 2,
            Angle = math.random() * math.pi * 2,
            RotSpeed = (math.random() - 0.5) * 2,
            PosX = dot.Position.X.Scale,
            PosY = 1
        }
        table.insert(particles, data)

        task.delay(5, function()
            if dot and dot.Parent then dot:Destroy() end
            for i, p in pairs(particles) do
                if p == data then table.remove(particles, i) break end
            end
        end)
    end

    for i = 1, 50 do
        task.delay(math.random(0, 50) / 10, function()
            if ParticleGuiContainer then SpawnParticle() end
        end)
    end

    ParticleGuiConnection = RunService.Heartbeat:Connect(function()
        if not ParticleGuiContainer then return end
        for _, data in pairs(particles) do
            if data and data.Frame and data.Frame.Parent then
                data.PosY = data.PosY - data.SpeedY / 200
                data.PosX = data.PosX + data.SpeedX / 200
                data.Angle = data.Angle + data.RotSpeed / 30
                if data.PosY < -0.05 then
                    data.PosY = 1
                    data.PosX = math.random(0, 100) / 100
                end
                if data.PosX < -0.05 then data.PosX = 1.05 end
                if data.PosX > 1.05 then data.PosX = -0.05 end
                data.Frame.Position = UDim2.new(data.PosX, 0, data.PosY, 0)
                data.Frame.Rotation = math.deg(data.Angle)
            end
        end
        if tick() - lastSpawnTime > 0.3 then
            lastSpawnTime = tick()
            SpawnParticle()
        end
    end)
end

local function ApplyParticleGui()
    _G.ParticleEffectGuiEnabled = true
    CreateParticleGui()
end

local function RemoveParticleGui()
    _G.ParticleEffectGuiEnabled = false
    if ParticleGuiConnection then ParticleGuiConnection:Disconnect() ParticleGuiConnection = nil end
    if ParticleGuiContainer then ParticleGuiContainer:Destroy() ParticleGuiContainer = nil end
end

--// ============================================
--//  FPS BOOST
--// ============================================
local function ApplyFpsBoost()
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
            obj:Destroy()
        elseif obj:IsA("BasePart") then
            obj.CastShadow = false
            obj.Material = Enum.Material.Plastic
        elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Shadows = false
        end
    end
end

--// ============================================
--//  SILENT AIM
--// ============================================
local SilentAimEnabled = false
local OffCircleEnabled = false
local MaxFOV = 200

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2.5
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64
FOVCircle.Visible = false

local CurrentTarget = nil

local function GetTargetPart(character)
    if not character then return nil end
    if _G.SelectedPart == "Torso" then
        return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    elseif _G.SelectedPart == "HumanoidRootPart" then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild("Head")
end

local function UpdateClosestTarget()
    if not SilentAimEnabled then CurrentTarget = nil return end
    local closestTarget = nil
    local shortestDistance = MaxFOV
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local targetPart = GetTargetPart(character)
                if targetPart then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if (humanoid and humanoid.Health > 0) or not humanoid then
                        local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                            if distance < shortestDistance then
                                closestTarget = targetPart
                                shortestDistance = distance
                            end
                        end
                    end
                end
            end
        end
    end
    CurrentTarget = closestTarget
end

RunService.RenderStepped:Connect(function()
    UpdateClosestTarget()
    if FOVCircle then
        if OffCircleEnabled then
            FOVCircle.Visible = false
        else
            FOVCircle.Visible = SilentAimEnabled
        end
        FOVCircle.Radius = MaxFOV
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Color = CurrentTarget and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
    end
end)

task.spawn(function()
    local gmt = getrawmetatable(game)
    setreadonly(gmt, false)
    local oldIndex = gmt.__index
    local oldNamecall = gmt.__namecall

    gmt.__index = newcclosure(function(self, key)
        if SilentAimEnabled and CurrentTarget then
            if key == "Hit" then return CurrentTarget.CFrame
            elseif key == "Target" then return CurrentTarget end
        end
        return oldIndex(self, key)
    end)

    gmt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if SilentAimEnabled and CurrentTarget then
            if method == "Raycast" and self == workspace then
                local origin = args[1]
                if typeof(origin) == "Vector3" then
                    args[2] = (CurrentTarget.Position - origin).Unit * 5000
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(gmt, true)
end)

task.spawn(function()
    local NetworkPath = ReplicatedStorage:WaitForChild("Database", 5)
    if NetworkPath then
        NetworkPath = NetworkPath:WaitForChild("Security", 5)
        if NetworkPath then
            NetworkPath = NetworkPath:WaitForChild("Network", 5)
        end
    end
    if NetworkPath then
        local Network = require(NetworkPath)
        if Network and Network.CreatePacket then
            local oldCreatePacket = Network.CreatePacket
            Network.CreatePacket = newcclosure(function(p6, p7, p_u_3, v_u_5)
                if SilentAimEnabled and CurrentTarget then
                    local function modifyTable(t)
                        for k, v in pairs(t) do
                            if typeof(v) == "Vector3" then
                                t[k] = CurrentTarget.Position
                            elseif type(v) == "table" then
                                modifyTable(v)
                            end
                        end
                    end
                    if type(p6) == "table" then modifyTable(p6) end
                    if type(p7) == "table" then modifyTable(p7) end
                end
                return oldCreatePacket(p6, p7, p_u_3, v_u_5)
            end)
        end
    end
end)

--// ============================================
--//  NO RECOIL / NO SPREAD
--// ============================================
local function ApplyNoRecoil()
    pcall(function()
        local CameraController = require(ReplicatedStorage.Controllers.CameraController)
        CameraController.weaponKick = function() end
        CameraController.setWeaponRecoil = function() end
    end)
end

local function ApplyNoSpread()
    pcall(function()
        local Bullet = require(ReplicatedStorage.Components.Weapon.Classes.Bullet)
        Bullet.getTrueSpread = function() return 0 end
        Bullet.getBaseSpread = function() return 0 end
        Bullet.getSpreadForConfig = function() return 0 end
        local OldCreate = Bullet.create
        Bullet.create = function(self, aimingOptions, isAiming)
            if self.Spread then
                self.Spread:setPosition(0)
                self.Spread:setGoal(0)
            end
            return OldCreate(self, aimingOptions, isAiming)
        end
    end)
end

--// ============================================
--//  SKY SYSTEM
--// ============================================
local skyConnection = nil
local function ResetSky()
    if skyConnection then skyConnection:Disconnect() skyConnection = nil end
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj.Name == "LuniePurpleFilter" or obj.Name == "LunieOrangeFilter" or obj.Name == "LunieBlackSkyFilter" or obj.Name == "LunieVibeBloom" or obj.Name == "LunieVibeAtmosphere" then obj:Destroy() end
    end
    Lighting.TimeOfDay = "14:00:00"
    Lighting.Brightness = 1
    Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    Lighting.GlobalShadows = false
end

local function StartPurpleSky()
    ResetSky()
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "LuniePurpleFilter"
    cc.Brightness = 0.02 cc.Contrast = 0.15 cc.Saturation = 0.5
    cc.TintColor = Color3.fromRGB(190, 130, 255) cc.Parent = Lighting
    local atm = Instance.new("Atmosphere")
    atm.Name = "LunieVibeAtmosphere"
    atm.Density = 0.3 atm.Color = Color3.fromRGB(140, 70, 200)
    atm.Decay = Color3.fromRGB(80, 30, 120) atm.Glare = 0.4 atm.Haze = 1.5
    atm.Parent = Lighting
    skyConnection = RunService.RenderStepped:Connect(function()
        if not cc or not cc.Parent then skyConnection:Disconnect() return end
        for _, object in ipairs(Lighting:GetChildren()) do
            if object:IsA("Sky") or (object:IsA("Atmosphere") and object.Name ~= "LunieVibeAtmosphere") or object:IsA("Clouds") then object:Destroy() end
        end
        local wave = (math.sin(tick() * 0.6) + 1) / 2
        cc.TintColor = Color3.fromRGB(160 + wave * 40, 100 + wave * 35, 255)
        Lighting.TimeOfDay = "19:10:00"
        Lighting.Brightness = 1.0
        Lighting.OutdoorAmbient = Color3.fromRGB(75, 55, 95)
        Lighting.Ambient = Color3.fromRGB(50, 45, 60)
    end)
end

local function StartNightSky()
    ResetSky()
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "LunieBlackSkyFilter"
    cc.Brightness = 0.03 cc.Contrast = 0.12 cc.Saturation = 0.15
    cc.TintColor = Color3.fromRGB(220, 225, 245) cc.Parent = Lighting
    for _, object in ipairs(Lighting:GetChildren()) do
        if object:IsA("Sky") or object:IsA("Atmosphere") or object:IsA("Clouds") then object:Destroy() end
    end
    local bloom = Instance.new("BloomEffect")
    bloom.Name = "LunieVibeBloom"
    bloom.Intensity = 1.4 bloom.Size = 22 bloom.Threshold = 0.08
    bloom.Parent = Lighting
    skyConnection = RunService.RenderStepped:Connect(function()
        if not cc or not cc.Parent then skyConnection:Disconnect() return end
        Lighting.TimeOfDay = "00:00:00"
        Lighting.Brightness = 1.0
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(115, 125, 145)
        Lighting.Ambient = Color3.fromRGB(90, 95, 105)
    end)
end

local function StartEveningSky()
    ResetSky()
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "LunieOrangeFilter"
    cc.Brightness = 0.02 cc.Contrast = 0.05 cc.Saturation = 0.15
    cc.TintColor = Color3.fromRGB(245, 195, 150) cc.Parent = Lighting
    local atm = Instance.new("Atmosphere")
    atm.Name = "LunieVibeAtmosphere"
    atm.Density = 0.25 atm.Color = Color3.fromRGB(230, 180, 140)
    atm.Decay = Color3.fromRGB(160, 110, 90) atm.Glare = 0.15 atm.Haze = 0.8
    atm.Parent = Lighting
    local bloom = Instance.new("BloomEffect")
    bloom.Name = "LunieVibeBloom"
    bloom.Intensity = 1.0 bloom.Size = 18 bloom.Threshold = 0.2
    bloom.Parent = Lighting
    skyConnection = RunService.RenderStepped:Connect(function()
        if not cc or not cc.Parent then skyConnection:Disconnect() return end
        local wave = (math.sin(tick() * 0.3) + 1) / 2
        cc.TintColor = Color3.fromRGB(240 + wave * 15, 185 + wave * 20, 140 + wave * 25)
        Lighting.TimeOfDay = "17:45:00"
        Lighting.Brightness = 1.4
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(135, 120, 105)
        Lighting.Ambient = Color3.fromRGB(100, 90, 85)
    end)
end

--// ============================================
--//  SOUND SYSTEM
--// ============================================
local fireInputBegan, fireInputEnded, muteConnection, guiMuteConnection = nil, nil, nil, nil

local function StopSoundSystem()
    if fireInputBegan then fireInputBegan:Disconnect() fireInputBegan = nil end
    if fireInputEnded then fireInputEnded:Disconnect() fireInputEnded = nil end
    if muteConnection then muteConnection:Disconnect() muteConnection = nil end
    if guiMuteConnection then guiMuteConnection:Disconnect() guiMuteConnection = nil end
end

local function StartSoundSystem(soundId, volume)
    StopSoundSystem()
    local MY_CUSTOM_SOUND = "rbxassetid://" .. soundId
    local holdSound, isHolding, pressTime = nil, false, 0

    muteConnection = Workspace.DescendantAdded:Connect(function(child)
        if child:IsA("Sound") then
            local parent = child.Parent
            if parent and parent.Name == "Sound" and parent.Parent and parent.Parent.Name == "Debris" then
                child.Volume = 0
                child:Stop()
            end
        end
    end)
    guiMuteConnection = LocalPlayer:WaitForChild("PlayerGui").DescendantAdded:Connect(function(child)
        if child:IsA("Sound") then
            child.Volume = 0
            child:Stop()
        end
    end)

    local function FindFireButton()
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        for _, child in ipairs(PlayerGui:GetDescendants()) do
            if child:IsA("TextButton") or child:IsA("ImageButton") then
                local name = child.Name:lower()
                if name:find("fire") or name:find("shoot") or name:find("attack") then
                    return child
                end
            end
        end
        return nil
    end

    local fireButton = FindFireButton()
    if fireButton then
        fireInputBegan = fireButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isHolding = true
                pressTime = tick()
                task.spawn(function()
                    task.wait(0.2)
                    if isHolding then
                        if holdSound then holdSound:Stop() holdSound:Destroy() end
                        holdSound = Instance.new("Sound")
                        holdSound.Name = "LUNIE_GunSound"
                        holdSound.SoundId = MY_CUSTOM_SOUND
                        holdSound.Volume = volume
                        holdSound.Looped = true
                        holdSound.Parent = SoundService
                        holdSound:Play()
                    end
                end)
            end
        end)
        fireInputEnded = fireButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isHolding = false
                if tick() - pressTime < 0.2 then
                    local singleSound = Instance.new("Sound")
                    singleSound.Name = "LUNIE_GunSound"
                    singleSound.SoundId = MY_CUSTOM_SOUND
                    singleSound.Volume = volume
                    singleSound.Parent = SoundService
                    singleSound:Play()
                    singleSound.Ended:Connect(function() singleSound:Destroy() end)
                end
                if holdSound then holdSound:Stop() holdSound:Destroy() holdSound = nil end
            end
        end)
    end
end

--// ============================================
--//  FLYING DOTS STATE
--// ============================================
local Dots = {}
local DotConnection = nil
local MainFrameRef = nil
local IconRef = nil

--// ============================================
--//  MINIBAR
--// ============================================
local MiniBar = Instance.new("TextButton")
MiniBar.Name = "MiniBar"
MiniBar.Size = UDim2.new(0, 180, 0, 28)
MiniBar.Position = UDim2.new(0.5, -90, 0, 10)
MiniBar.BackgroundColor3 = C.BgSoft
MiniBar.BorderSizePixel = 0
MiniBar.Text = ""
MiniBar.AutoButtonColor = false
MiniBar.Visible = false
MiniBar.Parent = ScreenGui

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(1, 0)
MiniCorner.Parent = MiniBar

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Color = C.Accent
MiniStroke.Thickness = 1.2
MiniStroke.Transparency = 0.3
MiniStroke.Parent = MiniBar

local MiniDot = Instance.new("Frame")
MiniDot.Size = UDim2.new(0, 8, 0, 8)
MiniDot.Position = UDim2.new(0, 14, 0.5, -4)
MiniDot.BackgroundColor3 = C.Accent
MiniDot.BorderSizePixel = 0
MiniDot.Parent = MiniBar

local MiniDotCorner = Instance.new("UICorner")
MiniDotCorner.CornerRadius = UDim.new(1, 0)
MiniDotCorner.Parent = MiniDot

local MiniText = Instance.new("TextLabel")
MiniText.Size = UDim2.new(1, -34, 1, 0)
MiniText.Position = UDim2.new(0, 30, 0, 0)
MiniText.BackgroundTransparency = 1
MiniText.Text = "Lunie Hub"
MiniText.TextColor3 = C.Text
MiniText.Font = Enum.Font.GothamBold
MiniText.TextSize = 12
MiniText.TextXAlignment = Enum.TextXAlignment.Left
MiniText.Parent = MiniBar

--// ============================================
--//  MAIN WINDOW
--// ============================================
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0.5, -340, 0.5, -260)
Main.BackgroundColor3 = C.Bg
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Main.Parent = ScreenGui
MainFrameRef = Main

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = C.Stroke
MainStroke.Thickness = 1
MainStroke.Parent = Main

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 175, 1, 0)
Sidebar.BackgroundColor3 = C.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 16)
SidebarCorner.Parent = Sidebar

local SidebarFix = Instance.new("Frame")
SidebarFix.Size = UDim2.new(0, 16, 1, 0)
SidebarFix.Position = UDim2.new(1, -16, 0, 0)
SidebarFix.BackgroundColor3 = C.Sidebar
SidebarFix.BorderSizePixel = 0
SidebarFix.ZIndex = 1
SidebarFix.Parent = Sidebar

local LogoHolder = Instance.new("Frame")
LogoHolder.Size = UDim2.new(0, 36, 0, 36)
LogoHolder.Position = UDim2.new(0, 18, 0, 18)
LogoHolder.BackgroundTransparency = 1
LogoHolder.ZIndex = 3
LogoHolder.Parent = Sidebar

local LogoFrame = Instance.new("Frame")
LogoFrame.Size = UDim2.new(1, 0, 1, 0)
LogoFrame.BackgroundColor3 = C.Accent
LogoFrame.BorderSizePixel = 0
LogoFrame.Parent = LogoHolder

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 10)
LogoCorner.Parent = LogoFrame

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "L"
LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoText.Font = Enum.Font.GothamBold
LogoText.TextSize = 20
LogoText.Parent = LogoFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -66, 0, 20)
Title.Position = UDim2.new(0, 62, 0, 18)
Title.BackgroundTransparency = 1
Title.Text = "Lunie Hub"
Title.TextColor3 = C.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Parent = Sidebar

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -66, 0, 14)
SubTitle.Position = UDim2.new(0, 62, 0, 37)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Blox • v2.0"
SubTitle.TextColor3 = C.AccentL
SubTitle.Font = Enum.Font.GothamMedium
SubTitle.TextSize = 11
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.ZIndex = 3
SubTitle.Parent = Sidebar

local ModulesLabel = Instance.new("TextLabel")
ModulesLabel.Size = UDim2.new(1, -36, 0, 12)
ModulesLabel.Position = UDim2.new(0, 20, 0, 84)
ModulesLabel.BackgroundTransparency = 1
ModulesLabel.Text = "M O D U L E S"
ModulesLabel.TextColor3 = C.SubText
ModulesLabel.Font = Enum.Font.GothamBold
ModulesLabel.TextSize = 9
ModulesLabel.TextXAlignment = Enum.TextXAlignment.Left
ModulesLabel.ZIndex = 3
ModulesLabel.Parent = Sidebar

local TabHolder = Instance.new("Frame")
TabHolder.Size = UDim2.new(1, -24, 0, 320)
TabHolder.Position = UDim2.new(0, 12, 0, 106)
TabHolder.BackgroundTransparency = 1
TabHolder.ZIndex = 3
TabHolder.Parent = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 8)
TabLayout.Parent = TabHolder

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -197, 1, -30)
ContentArea.Position = UDim2.new(0, 185, 0, 15)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = Main

local Tabs = {}
local ContentPages = {}
local ActiveTab = nil

--// ============================================
--//  LANGUAGE
--// ============================================
local LANG = {
    RU = {
        Tabs = {"Аимбот", "Визуал", "Разное", "Скай", "Звук", "Настройки"},
        Texts = {
            SilentAim = {"Silent Aim", "Автоматически целится во врагов в FOV"},
            OffCircle = {"Off Circle", "Скрывает круг FOV но оставляет аим"},
            FOV = "Размер FOV",
            Part = "Часть тела",
            NoRecoil = {"No Recoil", "Антиотдача"},
            NoSpread = {"No Spread", "Анти разброс пуль"},
            Chams = {"Чамсы", "Делает противников фиолетовыми"},
            ESP = {"Линии и 3D Боксы", "Линии с боксами к противникам"},
            Skeleton = {"Скелетон", "Скелетон для противников"},
            HealthBar = {"Здоровье", "Полоска здоровья над головой"},
            ParticleGui = {"Эффект частиц GUI", "Точки летающие по экрану"},
            FpsBoost = {"FPS Boost", "Делает карту безлаганной"},
            Opacity = {"Прозрачность", "Прозрачность меню (0-50%)"},
            Scale = {"Масштаб меню", "Масштабирование (60-140%)"},
            Rainbow = {"Радужная обводка", "Радужное свечение интерфейса"},
            UIColor = {"Цвет интерфейса", "Кастомизация цвета UI"},
            FlyingDots = {"Летающие точки", "Точки летающие по меню"},
            Reset = {"Сброс настроек", "Вернуть всё к стандартным"},
            ChamsColor = "Цвет чамсов",
            SkeletonColor = "Цвет скелета",
            Sky_Night = "Ночное небо",
            Sky_Evening = "Вечернее небо",
            Sky_Purple = "Фиолетовое небо",
            Sky_Reset = "Сброс",
            Sound_N1 = "Звук N1",
            Sound_N2 = "Звук N2",
            Sound_Reset = "Сброс",
        }
    },
    EN = {
        Tabs = {"Aimbot", "Visuals", "Misc", "Sky", "Sound", "Settings"},
        Texts = {
            SilentAim = {"Silent Aim", "Automatically aims at enemies in FOV"},
            OffCircle = {"Off Circle", "Hides FOV circle but keeps aim"},
            FOV = "FOV Size",
            Part = "Target Part",
            NoRecoil = {"No Recoil", "Removes weapon recoil"},
            NoSpread = {"No Spread", "Removes bullet spread"},
            Chams = {"Chams", "Makes enemies purple"},
            ESP = {"Tracers and 3D Box", "Lines with boxes leading to enemies"},
            Skeleton = {"Skeleton", "Skeleton for enemies"},
            HealthBar = {"Health Bar", "Health bar above enemies"},
            ParticleGui = {"Particle Effect GUI", "Floating dots on screen"},
            FpsBoost = {"FPS Boost", "Makes the map lag-free"},
            Opacity = {"Opacity", "Menu transparency (0-50%)"},
            Scale = {"Menu Scale", "Menu scaling (60-140%)"},
            Rainbow = {"UI Rainbow Color", "Rainbow menu outline"},
            UIColor = {"UI Color", "Interface color customization"},
            FlyingDots = {"Flying Dots", "Floating dots on the menu"},
            Reset = {"Reset Settings", "Return all settings to default"},
            ChamsColor = "Chams Color",
            SkeletonColor = "Skeleton Color",
            Sky_Night = "Night Sky",
            Sky_Evening = "Evening Sky",
            Sky_Purple = "Purple Sky",
            Sky_Reset = "Reset",
            Sound_N1 = "Sound N1",
            Sound_N2 = "Sound N2",
            Sound_Reset = "Reset",
        }
    }
}
local function GetLang() return _G.CurrentLang == "RU" and LANG.RU or LANG.EN end
local langUpdateCallbacks = {}
local function RegisterLang(cb) table.insert(langUpdateCallbacks, cb) end
local function UpdateAllTexts()
    for _, cb in ipairs(langUpdateCallbacks) do pcall(cb) end
end

--// ============================================
--//  RIPPLE
--// ============================================
local function CreateRipple(parent, x, y)
    local ripple = Instance.new("Frame")
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0, x, 0, y)
    ripple.BackgroundColor3 = C.AccentL
    ripple.BackgroundTransparency = 0.78
    ripple.BorderSizePixel = 0
    ripple.ZIndex = 8
    ripple.Parent = parent
    Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
    TweenService:Create(ripple, TweenInfo.new(0.7, Enum.EasingStyle.Quart), {
        Size = UDim2.new(1, 60, 1, 60),
        BackgroundTransparency = 1,
    }):Play()
    task.delay(0.75, function() ripple:Destroy() end)
end

--// ============================================
--//  TAB CREATOR
--// ============================================
local function CreateTab(name, order)
    local Btn = Instance.new("TextButton")
    Btn.Name = name .. "Tab"
    Btn.Size = UDim2.new(1, 0, 0, 44)
    Btn.BackgroundTransparency = 1
    Btn.BorderSizePixel = 0
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Btn.LayoutOrder = order
    Btn.ZIndex = 4
    Btn.Parent = TabHolder

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 14)
    BtnCorner.Parent = Btn

    local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(1, 0, 1, 0)
    Bg.BackgroundColor3 = C.TabIdle
    Bg.BackgroundTransparency = 1
    Bg.BorderSizePixel = 0
    Bg.ZIndex = 0
    Bg.Parent = Btn

    local BgCorner = Instance.new("UICorner")
    BgCorner.CornerRadius = UDim.new(0, 14)
    BgCorner.Parent = Bg

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -28, 1, 0)
    Label.Position = UDim2.new(0, 20, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = C.SubText
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 2
    Label.Parent = Btn

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 6, 0, 6)
    Dot.Position = UDim2.new(1, -20, 0.5, -3)
    Dot.BackgroundColor3 = C.AccentL
    Dot.BorderSizePixel = 0
    Dot.BackgroundTransparency = 1
    Dot.ZIndex = 2
    Dot.Parent = Btn

    local DotCorner = Instance.new("UICorner")
    DotCorner.CornerRadius = UDim.new(1, 0)
    DotCorner.Parent = Dot

    local PageGroup = Instance.new("CanvasGroup")
    PageGroup.Size = UDim2.new(1, 0, 1, 0)
    PageGroup.BackgroundTransparency = 1
    PageGroup.Visible = false
    PageGroup.Parent = ContentArea

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = C.Accent
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Parent = PageGroup

    local PLayout = Instance.new("UIListLayout")
    PLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PLayout.Padding = UDim.new(0, 10)
    PLayout.Parent = Page

    local PPadding = Instance.new("UIPadding")
    PPadding.PaddingTop = UDim.new(0, 6)
    PPadding.PaddingBottom = UDim.new(0, 6)
    PPadding.PaddingRight = UDim.new(0, 8)
    PPadding.Parent = Page

    local PageHeader = Instance.new("Frame")
    PageHeader.Size = UDim2.new(1, -8, 0, 36)
    PageHeader.BackgroundTransparency = 1
    PageHeader.LayoutOrder = 1
    PageHeader.Parent = Page

    local PageTitle = Instance.new("TextLabel")
    PageTitle.Size = UDim2.new(1, 0, 0, 22)
    PageTitle.BackgroundTransparency = 1
    PageTitle.Text = name
    PageTitle.TextColor3 = C.Text
    PageTitle.Font = Enum.Font.GothamBold
    PageTitle.TextSize = 20
    PageTitle.TextXAlignment = Enum.TextXAlignment.Left
    PageTitle.Parent = PageHeader

    local PageAccent = Instance.new("Frame")
    PageAccent.Size = UDim2.new(0, 30, 0, 2)
    PageAccent.Position = UDim2.new(0, 0, 0, 28)
    PageAccent.BackgroundColor3 = C.Accent
    PageAccent.BorderSizePixel = 0
    PageAccent.Parent = PageHeader

    local PageAccentCorner = Instance.new("UICorner")
    PageAccentCorner.CornerRadius = UDim.new(1, 0)
    PageAccentCorner.Parent = PageAccent

    ContentPages[name] = { Page = Page, Group = PageGroup, Header = PageHeader, Title = PageTitle }

    Btn.MouseButton1Click:Connect(function()
        SFX.TabOpen()
        CreateRipple(Btn, Btn.AbsoluteSize.X / 2, Btn.AbsoluteSize.Y / 2)
        for tabName, tabData in pairs(Tabs) do
            TweenService:Create(tabData.Bg, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
            TweenService:Create(tabData.Dot, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            tabData.Label.TextColor3 = C.SubText
            ContentPages[tabName].Group.Visible = false
        end
        TweenService:Create(Bg, TweenInfo.new(0.3), {BackgroundTransparency = 0.15}):Play()
        TweenService:Create(Dot, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
        Label.TextColor3 = C.Text
        PageGroup.Visible = true
        ActiveTab = name
    end)

    Btn.MouseEnter:Connect(function()
        if ActiveTab ~= name then
            SFX.Hover()
            Bg.BackgroundColor3 = C.TabHover
            TweenService:Create(Bg, TweenInfo.new(0.25), {BackgroundTransparency = 0.5}):Play()
            Label.TextColor3 = C.Text
        end
    end)
    Btn.MouseLeave:Connect(function()
        if ActiveTab ~= name then
            TweenService:Create(Bg, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
            Label.TextColor3 = C.SubText
        end
    end)

    Tabs[name] = { Button = Btn, Bg = Bg, Label = Label, Dot = Dot, Page = Page, PageGroup = PageGroup, Name = name }
    return Page
end

local function SelectTab(name)
    local tabData = Tabs[name]
    if not tabData then return end
    for tabName, t in pairs(Tabs) do
        TweenService:Create(t.Bg, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
        TweenService:Create(t.Dot, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        t.Label.TextColor3 = C.SubText
        ContentPages[tabName].Group.Visible = false
    end
    TweenService:Create(tabData.Bg, TweenInfo.new(0.3), {BackgroundTransparency = 0.15}):Play()
    TweenService:Create(tabData.Dot, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
    tabData.Label.TextColor3 = C.Text
    ContentPages[name].Group.Visible = true
    ActiveTab = name
end

--// ============================================
--//  UI COMPONENTS
--// ============================================
local function CreateToggle(parent, text, order, default, callback)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -8, 0, 46)
    Card.BackgroundColor3 = C.Panel
    Card.BorderSizePixel = 0
    Card.LayoutOrder = order
    Card.Parent = parent

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 12)
    cc.Parent = Card

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Stroke
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = Card

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -100, 1, 0)
    lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Card

    local state = default or false
    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 50, 0, 26)
    Toggle.Position = UDim2.new(1, -66, 0.5, -13)
    Toggle.BackgroundColor3 = state and C.Accent or Color3.fromRGB(45, 45, 55)
    Toggle.Text = ""
    Toggle.AutoButtonColor = false
    Toggle.Parent = Card

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1, 0)
    tc.Parent = Toggle

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = Toggle

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob

    local function SetState(value, fireCallback)
        state = value
        TweenService:Create(Toggle, TweenInfo.new(0.2), {BackgroundColor3 = state and C.Accent or Color3.fromRGB(45, 45, 55)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
        }):Play()
        if fireCallback ~= false and callback then callback(state) end
    end

    Toggle.MouseButton1Click:Connect(function()
        SFX.Click()
        SetState(not state)
    end)

    Card.GetState = function() return state end
    Card.SetState = SetState
    Card.Label = lbl
    return Card, SetState, lbl
end

local function CreateSlider(parent, text, order, minVal, maxVal, default, callback)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -8, 0, 66)
    Card.BackgroundColor3 = C.Panel
    Card.BorderSizePixel = 0
    Card.LayoutOrder = order
    Card.Parent = parent

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 12)
    cc.Parent = Card

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Stroke
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = Card

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -100, 0, 22)
    lbl.Position = UDim2.new(0, 16, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Card

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 60, 0, 22)
    valLbl.Position = UDim2.new(1, -76, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = C.AccentL
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = Card

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -32, 0, 8)
    Bar.Position = UDim2.new(0, 16, 1, -22)
    Bar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    Bar.BorderSizePixel = 0
    Bar.Parent = Card

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = Bar

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - minVal) / (maxVal - minVal), 0, 1, 0)
    Fill.BackgroundColor3 = C.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = Fill

    local dragging = false

    local function UpdateValue(x)
        local rel = math.clamp((x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + (maxVal - minVal) * rel)
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        valLbl.Text = tostring(val)
        if callback then callback(val) end
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdateValue(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateValue(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return Card
end

local function CreateColorPicker(parent, text, order, defaultColor, callback)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -8, 0, 180)
    Card.BackgroundColor3 = C.Panel
    Card.BorderSizePixel = 0
    Card.LayoutOrder = order
    Card.Parent = parent

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 12)
    cc.Parent = Card

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Stroke
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = Card

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -32, 0, 22)
    lbl.Position = UDim2.new(0, 16, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Card

    local wheel = Instance.new("ImageLabel")
    wheel.Size = UDim2.new(0, 120, 0, 120)
    wheel.Position = UDim2.new(0.5, -60, 0, 36)
    wheel.BackgroundTransparency = 1
    wheel.Image = "rbxassetid://7393858625"
    wheel.Parent = Card

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0.5, -5, 0.5, -5)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.Parent = wheel

    local dotC = Instance.new("UICorner")
    dotC.CornerRadius = UDim.new(1, 0)
    dotC.Parent = dot

    local dragArea = Instance.new("TextButton")
    dragArea.Size = UDim2.new(1, 0, 1, 0)
    dragArea.BackgroundTransparency = 1
    dragArea.Text = ""
    dragArea.Parent = wheel

    local isDragging = false
    local function UpdateColor(inputPosition)
        local wheelCenter = wheel.AbsolutePosition + (wheel.AbsoluteSize / 2)
        local delta = Vector2.new(inputPosition.X, inputPosition.Y) - wheelCenter
        local distance = delta.Magnitude
        local radius = wheel.AbsoluteSize.X / 2
        local clampedDistance = math.clamp(distance, 0, radius)
        local angle = math.atan2(delta.Y, delta.X)
        local xPos = clampedDistance * math.cos(angle)
        local yPos = clampedDistance * math.sin(angle)
        dot.Position = UDim2.new(0, xPos + radius - 5, 0, yPos + radius - 5)
        if angle < 0 then angle = angle + (math.pi * 2) end
        local hue = angle / (math.pi * 2)
        local saturation = clampedDistance / radius
        local pickedColor = Color3.fromHSV(hue, saturation, 1)
        if callback then callback(pickedColor) end
    end

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            UpdateColor(input.Position)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            UpdateColor(input.Position)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)

    Card.Label = lbl
    return Card
end

local function CreateButton(parent, text, order, callback, accent)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -8, 0, 44)
    Btn.BackgroundColor3 = accent or C.Panel
    Btn.BorderSizePixel = 0
    Btn.Text = text
    Btn.TextColor3 = C.Text
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 14
    Btn.AutoButtonColor = false
    Btn.LayoutOrder = order
    Btn.Parent = parent

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 12)
    bc.Parent = Btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Stroke
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = Btn

    Btn.MouseEnter:Connect(function()
        SFX.Hover()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = C.PanelSoft}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = accent or C.Panel}):Play()
    end)
    Btn.MouseButton1Click:Connect(function()
        SFX.Click()
        if callback then callback() end
    end)

    Btn.Label = Btn
    return Btn
end

local function CreateDropdown(parent, text, order, options, default, callback)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -8, 0, 46)
    Card.BackgroundColor3 = C.Panel
    Card.BorderSizePixel = 0
    Card.LayoutOrder = order
    Card.Parent = parent

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 12)
    cc.Parent = Card

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Stroke
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = Card

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -160, 1, 0)
    lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Card

    local selected = default or options[1]
    local DropBtn = Instance.new("TextButton")
    DropBtn.Size = UDim2.new(0, 120, 0, 30)
    DropBtn.Position = UDim2.new(1, -136, 0.5, -15)
    DropBtn.BackgroundColor3 = C.PanelSoft
    DropBtn.Text = selected
    DropBtn.TextColor3 = C.AccentL
    DropBtn.Font = Enum.Font.GothamBold
    DropBtn.TextSize = 12
    DropBtn.AutoButtonColor = false
    DropBtn.Parent = Card

    local dbc = Instance.new("UICorner")
    dbc.CornerRadius = UDim.new(0, 8)
    dbc.Parent = DropBtn

    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(0, 120, 0, 0)
    menu.Position = UDim2.new(1, -136, 1, 4)
    menu.BackgroundColor3 = C.PanelSoft
    menu.BorderSizePixel = 0
    menu.ClipsDescendants = true
    menu.ZIndex = 50
    menu.Visible = false
    menu.Parent = Card

    local mc = Instance.new("UICorner")
    mc.CornerRadius = UDim.new(0, 8)
    mc.Parent = menu

    local mLayout = Instance.new("UIListLayout")
    mLayout.Padding = UDim.new(0, 2)
    mLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mLayout.Parent = menu

    local mPad = Instance.new("UIPadding")
    mPad.PaddingTop = UDim.new(0, 4)
    mPad.PaddingBottom = UDim.new(0, 4)
    mPad.Parent = menu

    local isOpen = false
    local function CloseMenu()
        isOpen = false
        TweenService:Create(menu, TweenInfo.new(0.2), {Size = UDim2.new(0, 120, 0, 0)}):Play()
        task.delay(0.2, function()
            if not isOpen then menu.Visible = false end
        end)
    end

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 28)
        optBtn.BackgroundColor3 = C.Panel
        optBtn.Text = opt
        optBtn.TextColor3 = C.Text
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 12
        optBtn.AutoButtonColor = false
        optBtn.LayoutOrder = i
        optBtn.ZIndex = 51
        optBtn.Parent = menu

        local obc = Instance.new("UICorner")
        obc.CornerRadius = UDim.new(0, 6)
        obc.Parent = optBtn

        optBtn.MouseButton1Click:Connect(function()
            SFX.Click()
            selected = opt
            DropBtn.Text = opt
            CloseMenu()
            if callback then callback(opt) end
        end)
    end

    DropBtn.MouseButton1Click:Connect(function()
        SFX.Click()
        if isOpen then
            CloseMenu()
        else
            isOpen = true
            menu.Visible = true
            menu.Size = UDim2.new(0, 120, 0, 0)
            local targetH = (#options * 30) + 8
            TweenService:Create(menu, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 120, 0, targetH)}):Play()
        end
    end)

    Card.GetValue = function() return selected end
    Card.Label = lbl
    return Card
end

--// ============================================
--//  CREATE TABS
--// ============================================
local CombatPage  = CreateTab("Combat", 1)
local VisualsPage = CreateTab("Visuals", 2)
local MiscPage    = CreateTab("Misc", 3)
local SkyPage     = CreateTab("Sky", 4)
local SoundPage   = CreateTab("Sound", 5)
local SettingsPage = CreateTab("Settings", 6)

--// ============================================
--//  COMBAT TAB
--// ============================================
local silentToggle, setSilentState, silentLabel = CreateToggle(CombatPage, "Silent Aim", 2, false, function(state)
    SilentAimEnabled = state
    _G.SilentAimEnabled = state
    if not state then CurrentTarget = nil end
end)

local offCircleToggle, setOffCircleState, offCircleLabel = CreateToggle(CombatPage, "Off Circle", 3, false, function(state)
    OffCircleEnabled = state
    _G.OffCircleEnabled = state
end)

local fovSlider = CreateSlider(CombatPage, "FOV Radius", 4, 50, 600, 200, function(val)
    MaxFOV = val
    _G.SilentAimFOV = val
end)

local partDropdown = CreateDropdown(CombatPage, "Target Part", 5, {"Head", "Torso", "HumanoidRootPart"}, "Head", function(val)
    _G.SelectedPart = val
end)

local noRecoilToggle, setNoRecoilState, noRecoilLabel = CreateToggle(CombatPage, "No Recoil", 6, false, function(state)
    _G.NoRecoilEnabled = state
    if state then ApplyNoRecoil() end
end)

local noSpreadToggle, setNoSpreadState, noSpreadLabel = CreateToggle(CombatPage, "No Spread", 7, false, function(state)
    _G.NoSpreadEnabled = state
    if state then ApplyNoSpread() end
end)

--// ============================================
--//  VISUALS TAB
--// ============================================
local chamsToggle, setChamsState, chamsLabel = CreateToggle(VisualsPage, "Chams", 2, false, function(state)
    _G.ChamsEnabled = state
    if state then ApplyChams() else RemoveChams() end
end)

local chamsColorPicker = CreateColorPicker(VisualsPage, "Chams Color", 3, _G.ChamsColor, function(color)
    _G.ChamsColor = color
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            for _, child in ipairs(p.Character:GetChildren()) do
                if child:IsA("Highlight") and child:GetAttribute("LUNIE_Chams") then
                    child.FillColor = color
                    child.OutlineColor = color
                end
            end
        end
    end
end)

local espToggle, setEspState, espLabel = CreateToggle(VisualsPage, "Tracers and 3D Box", 4, false, function(state)
    _G.ESPEnabled = state
    if state then ApplyESP() else RemoveESP() end
end)

local skeletonToggle, setSkeletonState, skeletonLabel = CreateToggle(VisualsPage, "Skeleton", 5, false, function(state)
    _G.SkeletonEnabled = state
    if state then ApplySkeleton() else RemoveSkeleton() end
end)

local skeletonColorPicker = CreateColorPicker(VisualsPage, "Skeleton Color", 6, _G.SkeletonColor, function(color)
    _G.SkeletonColor = color
    for _, player in ipairs(Players:GetPlayers()) do
        if SkeletonLines[player] then
            for _, line in pairs(SkeletonLines[player]) do
                line.Color = color
            end
        end
    end
end)

local healthBarToggle, setHealthState, healthLabel = CreateToggle(VisualsPage, "Health Bar", 7, false, function(state)
    _G.HealthBarEnabled = state
    if state then ApplyHealthBar() else RemoveHealthBar() end
end)

local particleGuiToggle, setParticleGuiState, particleGuiLabel = CreateToggle(VisualsPage, "Particle Effect GUI", 8, false, function(state)
    _G.ParticleEffectGuiEnabled = state
    if state then ApplyParticleGui() else RemoveParticleGui() end
end)

local fpsToggle, setFpsState, fpsLabel = CreateToggle(VisualsPage, "FPS Boost", 9, false, function(state)
    _G.FpsBoostEnabled = state
    if state then ApplyFpsBoost() end
end)

--// ============================================
--//  MISC TAB
--// ============================================
local miscInfo = Instance.new("TextLabel")
miscInfo.Size = UDim2.new(1, -8, 0, 60)
miscInfo.BackgroundColor3 = C.Panel
miscInfo.BorderSizePixel = 0
miscInfo.Text = "⚙️  Anti-cheat bypass active\n🛡️  Hidden from scanner"
miscInfo.TextColor3 = C.SubText
miscInfo.Font = Enum.Font.Gotham
miscInfo.TextSize = 12
miscInfo.TextWrapped = true
miscInfo.LayoutOrder = 2
miscInfo.Parent = MiscPage

local mic = Instance.new("UICorner")
mic.CornerRadius = UDim.new(0, 12)
mic.Parent = miscInfo

--// ============================================
--//  SKY TAB
--// ============================================
local skyBtnNight = CreateButton(SkyPage, "Night Sky", 2, function()
    StartNightSky()
end)

local skyBtnEvening = CreateButton(SkyPage, "Evening Sky", 3, function()
    StartEveningSky()
end)

local skyBtnPurple = CreateButton(SkyPage, "Purple Sky", 4, function()
    StartPurpleSky()
end)

local skyBtnReset = CreateButton(SkyPage, "Reset Sky", 5, function()
    ResetSky()
end)

--// ============================================
--//  SOUND TAB
--// ============================================
local soundBtnN1 = CreateButton(SoundPage, "Sound N1", 2, function()
    StartSoundSystem("135201580846609", 3)
end)

local soundBtnN2 = CreateButton(SoundPage, "Sound N2", 3, function()
    StartSoundSystem("93446662377809", 10)
end)

local soundBtnReset = CreateButton(SoundPage, "Stop Sound", 4, function()
    StopSoundSystem()
end)

--// ============================================
--//  SETTINGS TAB
--// ============================================
-- Language
local langRow = Instance.new("Frame")
langRow.Size = UDim2.new(1, -8, 0, 46)
langRow.BackgroundColor3 = C.Panel
langRow.BorderSizePixel = 0
langRow.LayoutOrder = 2
langRow.Parent = SettingsPage

local lrc = Instance.new("UICorner")
lrc.CornerRadius = UDim.new(0, 12)
lrc.Parent = langRow

local lrStroke = Instance.new("UIStroke")
lrStroke.Color = C.Stroke
lrStroke.Thickness = 1
lrStroke.Transparency = 0.5
lrStroke.Parent = langRow

local langLbl = Instance.new("TextLabel")
langLbl.Size = UDim2.new(1, -200, 1, 0)
langLbl.Position = UDim2.new(0, 16, 0, 0)
langLbl.BackgroundTransparency = 1
langLbl.Text = "Language / Язык"
langLbl.TextColor3 = C.Text
langLbl.Font = Enum.Font.GothamMedium
langLbl.TextSize = 14
langLbl.TextXAlignment = Enum.TextXAlignment.Left
langLbl.Parent = langRow

local langBtnEN = Instance.new("TextButton")
langBtnEN.Size = UDim2.new(0, 60, 0, 28)
langBtnEN.Position = UDim2.new(1, -152, 0.5, -14)
langBtnEN.BackgroundColor3 = C.Accent
langBtnEN.Text = "EN"
langBtnEN.TextColor3 = Color3.fromRGB(255, 255, 255)
langBtnEN.Font = Enum.Font.GothamBold
langBtnEN.TextSize = 12
langBtnEN.AutoButtonColor = false
langBtnEN.Parent = langRow

local lbeC = Instance.new("UICorner")
lbeC.CornerRadius = UDim.new(0, 8)
lbeC.Parent = langBtnEN

local langBtnRU = Instance.new("TextButton")
langBtnRU.Size = UDim2.new(0, 60, 0, 28)
langBtnRU.Position = UDim2.new(1, -86, 0.5, -14)
langBtnRU.BackgroundColor3 = C.PanelSoft
langBtnRU.Text = "RU"
langBtnRU.TextColor3 = C.SubText
langBtnRU.Font = Enum.Font.GothamBold
langBtnRU.TextSize = 12
langBtnRU.AutoButtonColor = false
langBtnRU.Parent = langRow

local lbrC = Instance.new("UICorner")
lbrC.CornerRadius = UDim.new(0, 8)
lbrC.Parent = langBtnRU

langBtnEN.MouseButton1Click:Connect(function()
    SFX.Click()
    _G.CurrentLang = "EN"
    langBtnEN.BackgroundColor3 = C.Accent
    langBtnEN.TextColor3 = Color3.fromRGB(255, 255, 255)
    langBtnRU.BackgroundColor3 = C.PanelSoft
    langBtnRU.TextColor3 = C.SubText
    UpdateAllTexts()
end)

langBtnRU.MouseButton1Click:Connect(function()
    SFX.Click()
    _G.CurrentLang = "RU"
    langBtnRU.BackgroundColor3 = C.Accent
    langBtnRU.TextColor3 = Color3.fromRGB(255, 255, 255)
    langBtnEN.BackgroundColor3 = C.PanelSoft
    langBtnEN.TextColor3 = C.SubText
    UpdateAllTexts()
end)

-- Opacity slider
local opacitySlider = CreateSlider(SettingsPage, "Opacity", 3, 0, 50, 12, function(val)
    _G.MenuOpacity = val
    Main.BackgroundTransparency = val / 100
end)

-- Scale slider
local scaleSlider = CreateSlider(SettingsPage, "Menu Scale", 4, 27, 63, 45, function(val)
    _G.MenuScale = val
    local s = val / 45
    local size = UDim2.new(0, 680 * s, 0, 520 * s)
    TweenService:Create(Main, TweenInfo.new(0.2), {Size = size}):Play()
end)

-- Rainbow toggle
local rainbowToggle, setRainbowState, rainbowLabel = CreateToggle(SettingsPage, "UI Rainbow Color", 5, false, function(state)
    _G.RainbowEnabled = state
    if state then
        if _G.RainbowConn then _G.RainbowConn:Disconnect() end
        _G.RainbowConn = RunService.Heartbeat:Connect(function()
            local hue = (tick() * 0.1) % 1
            local color = Color3.fromHSV(hue, 1, 1)
            MainStroke.Color = color
            MiniStroke.Color = color
        end)
    else
        if _G.RainbowConn then _G.RainbowConn:Disconnect() _G.RainbowConn = nil end
        MainStroke.Color = _G.MenuThemeColor
        MiniStroke.Color = C.Accent
    end
end)

-- UI Color picker
local uiColorToggle, setUiColorState, uiColorLabel = CreateToggle(SettingsPage, "Custom UI Color", 6, false, function(state)
    _G.CustomThemeEnabled = state
end)

local uiColorPicker = CreateColorPicker(SettingsPage, "UI Color", 7, _G.MenuThemeColor, function(color)
    if not _G.CustomThemeEnabled or _G.RainbowEnabled then return end
    _G.MenuThemeColor = color
    MainStroke.Color = color
end)

-- Flying dots toggle
local flyingToggle, setFlyingState, flyingLabel = CreateToggle(SettingsPage, "Flying Dots", 8, false, function(state)
    _G.FlyingDots = state
    if state then
        if DotConnection then DotConnection:Disconnect() end
        DotConnection = RunService.Heartbeat:Connect(function()
            local w = Main.AbsoluteSize.X
            local h = Main.AbsoluteSize.Y
            if w <= 0 or h <= 0 then return end
            for _, data in ipairs(Dots) do
                if data and data.Frame and data.Frame.Parent then
                    data.PosX = data.PosX + data.SpeedX
                    data.PosY = data.PosY + data.SpeedY
                    data.Angle = data.Angle + data.RotSpeed
                    if data.PosX < 0 then data.PosX = w end
                    if data.PosX > w then data.PosX = 0 end
                    if data.PosY > h then data.PosY = 0 data.PosX = math.random(0, w) end
                    data.Frame.Position = UDim2.new(0, data.PosX, 0, data.PosY)
                    data.Frame.Rotation = math.deg(data.Angle)
                end
            end
        end)
        for i = 1, 60 do
            local dot = Instance.new("Frame")
            local size = math.random(20, 35) / 10
            dot.Size = UDim2.new(0, size, 0, size)
            dot.Position = UDim2.new(0, math.random(0, 500), 0, math.random(0, 400))
            dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            dot.BackgroundTransparency = 0.2
            dot.BorderSizePixel = 0
            dot.ZIndex = 101
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            dot.Parent = Main
            table.insert(Dots, {
                Frame = dot,
                SpeedX = (math.random() - 0.5) * 1.2,
                SpeedY = math.random() * 0.8 + 0.4,
                RotSpeed = (math.random() - 0.5) * 0.03,
                Angle = math.random() * math.pi * 2,
                PosX = math.random(0, 500),
                PosY = math.random(0, 400)
            })
        end
    else
        if DotConnection then DotConnection:Disconnect() DotConnection = nil end
        for _, data in ipairs(Dots) do
            if data and data.Frame then data.Frame:Destroy() end
        end
        Dots = {}
    end
end)

-- Reset button
local resetBtn = CreateButton(SettingsPage, "Reset Settings", 9, function()
    _G.MenuThemeColor = Color3.fromRGB(255, 255, 255)
    _G.MenuOpacity = 12
    _G.MenuScale = 45
    _G.CustomThemeEnabled = false
    _G.RainbowEnabled = false
    _G.FlyingDots = false

    Main.BackgroundTransparency = 0.12
    Main.Size = UDim2.new(0, 680, 0, 520)
    MainStroke.Color = _G.MenuThemeColor
    MiniStroke.Color = C.Accent

    setSilentState(false)
    setOffCircleState(false)
    setNoRecoilState(false)
    setNoSpreadState(false)
    setChamsState(false)
    setEspState(false)
    setSkeletonState(false)
    setHealthState(false)
    setParticleGuiState(false)
    setFpsState(false)
    setRainbowState(false)
    setUiColorState(false)
    setFlyingState(false)

    RemoveChams() RemoveESP() RemoveSkeleton() RemoveHealthBar()
    RemoveParticleGui() ResetSky() StopSoundSystem()
end)

--// ============================================
--//  LANGUAGE UPDATER
--// ============================================
RegisterLang(function()
    local L = GetLang()
    -- Tabs
    if Tabs["Combat"] then Tabs["Combat"].Label.Text = L.Tabs[1] end
    if Tabs["Visuals"] then Tabs["Visuals"].Label.Text = L.Tabs[2] end
    if Tabs["Misc"] then Tabs["Misc"].Label.Text = L.Tabs[3] end
    if Tabs["Sky"] then Tabs["Sky"].Label.Text = L.Tabs[4] end
    if Tabs["Sound"] then Tabs["Sound"].Label.Text = L.Tabs[5] end
    if Tabs["Settings"] then Tabs["Settings"].Label.Text = L.Tabs[6] end

    -- Combat
    silentLabel.Text = L.Texts.SilentAim[1]
    offCircleLabel.Text = L.Texts.OffCircle[1]
    noRecoilLabel.Text = L.Texts.NoRecoil[1]
    noSpreadLabel.Text = L.Texts.NoSpread[1]

    -- Visuals
    chamsLabel.Text = L.Texts.Chams[1]
    espLabel.Text = L.Texts.ESP[1]
    skeletonLabel.Text = L.Texts.Skeleton[1]
    healthLabel.Text = L.Texts.HealthBar[1]
    particleGuiLabel.Text = L.Texts.ParticleGui[1]
    fpsLabel.Text = L.Texts.FpsBoost[1]
    chamsColorPicker.Label.Text = L.Texts.ChamsColor
    skeletonColorPicker.Label.Text = L.Texts.SkeletonColor

    -- Sky
    skyBtnNight.Text = L.Texts.Sky_Night
    skyBtnEvening.Text = L.Texts.Sky_Evening
    skyBtnPurple.Text = L.Texts.Sky_Purple
    skyBtnReset.Text = L.Texts.Sky_Reset

    -- Sound
    soundBtnN1.Text = L.Texts.Sound_N1
    soundBtnN2.Text = L.Texts.Sound_N2
    soundBtnReset.Text = L.Texts.Sound_Reset

    -- Settings
    rainbowLabel.Text = L.Texts.Rainbow[1]
    uiColorLabel.Text = L.Texts.UIColor[1]
    flyingLabel.Text = L.Texts.FlyingDots[1]
end)

--// ============================================
--//  MINIMIZE
--// ============================================
local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.new(0, 30, 0, 30)
Minimize.Position = UDim2.new(1, -46, 0, 16)
Minimize.BackgroundTransparency = 1
Minimize.Text = "—"
Minimize.TextColor3 = C.SubText
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 16
Minimize.AutoButtonColor = false
Minimize.ZIndex = 5
Minimize.Parent = Main

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = Minimize

Minimize.MouseButton1Click:Connect(function()
    SFX.Click()
    Main.Visible = false
    Main.Active = false
    MiniBar.Visible = true
end)

MiniBar.MouseButton1Click:Connect(function()
    SFX.Open()
    MiniBar.Visible = false
    Main.Visible = true
    Main.Active = true
end)

--// ============================================
--//  DRAG MAIN
--// ============================================
local dragging, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
Main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

--// ============================================
--//  RIGHT CONTROL
--// ============================================
local uiVisible = true
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        uiVisible = not uiVisible
        Main.Visible = uiVisible
        Main.Active = uiVisible
        if uiVisible then SFX.Open() else SFX.Close() end
    end
    if input.KeyCode == Enum.KeyCode.Insert then
        uiVisible = not uiVisible
        Main.Visible = uiVisible
        Main.Active = uiVisible
    end
end)

--// ============================================
--//  STARTUP
--// ============================================
SFX.Open()
Main.Size = UDim2.new(0, 680, 0, 520)
task.wait(0.3)
SFX.Pop()
SelectTab("Combat")
UpdateAllTexts()

print("[LUNIE] Lunie Hub v2.0 loaded • Anti-cheat bypass + scanner hide active")
