local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local TELEPORT_RANGE = 10
local INNER_RANGE = 5
local RESCAN_SEC = 1
local TP_TICK = 0.45

local espEnabled = true  -- ESP ON by default
local teleportEnabled = false
local espObjects = {}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 204, 0, 100)
Frame.Position = UDim2.new(0.05, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.BackgroundTransparency = 0.15
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 18)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "DBR Event Script"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextScaled = true
Title.Parent = Frame

local ESPButton = Instance.new("TextButton")
ESPButton.Size = UDim2.new(0.46, 0, 0, 24)
ESPButton.Position = UDim2.new(0.03, 0, 0.28, 0)
ESPButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
ESPButton.Text = "ESP: ON"  -- reflects default state
ESPButton.TextColor3 = Color3.new(1,1,1)
ESPButton.Font = Enum.Font.SourceSansBold
ESPButton.TextScaled = true
ESPButton.Parent = Frame

local TPButton = Instance.new("TextButton")
TPButton.Size = UDim2.new(0.46, 0, 0, 24)
TPButton.Position = UDim2.new(0.51, 0, 0.28, 0)
TPButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
TPButton.Text = "TP: OFF"
TPButton.TextColor3 = Color3.new(1,1,1)
TPButton.Font = Enum.Font.SourceSansBold
TPButton.TextScaled = true
TPButton.Parent = Frame

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Position = UDim2.new(1, -24, 0, 3)
CloseButton.BackgroundColor3 = Color3.fromRGB(200,50,50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.new(1,1,1)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextScaled = true
CloseButton.Parent = Frame

local EggCounter = Instance.new("TextLabel")
EggCounter.Size = UDim2.new(0.6, 0, 0, 18)
EggCounter.Position = UDim2.new(0.03, 0, 1, -22)
EggCounter.BackgroundTransparency = 1
EggCounter.Text = "Eggs: 0"
EggCounter.TextColor3 = Color3.new(1,1,1)
EggCounter.Font = Enum.Font.SourceSansBold
EggCounter.TextScaled = true
EggCounter.TextXAlignment = Enum.TextXAlignment.Left
EggCounter.Parent = Frame

local function getTargetPart(model)
    if not model then return nil end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp end
    return model:FindFirstChildWhichIsA("BasePart")
end

local function isValidPart(part)
    if not part or not part.Parent or not part:IsDescendantOf(workspace) then return false end
    local p = part.Position
    if math.abs(p.X) < 0.01 and math.abs(p.Y) < 0.01 and math.abs(p.Z) < 0.01 then return false end
    if math.abs(p.X) > 1e6 or math.abs(p.Y) > 1e6 or math.abs(p.Z) > 1e6 then return false end
    return true
end

local function removeESP(model)
    if espObjects[model] then
        local d = espObjects[model]
        if d.billboard and d.billboard.Parent then d.billboard:Destroy() end
        espObjects[model] = nil
    end
end

local function createESP(model)
    if espObjects[model] then return end
    local part = getTargetPart(model)
    if not isValidPart(part) then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EggESP"
    billboard.Size = UDim2.new(0, 80, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.5, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Egg"
    title.TextColor3 = Color3.new(1,1,1)
    title.TextStrokeColor3 = Color3.new(0,0,0)
    title.TextStrokeTransparency = 0
    title.Font = Enum.Font.SourceSansBold
    title.TextScaled = true
    title.Parent = billboard

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "[0 studs]"
    distanceLabel.TextColor3 = Color3.new(1,1,1)
    distanceLabel.TextStrokeColor3 = Color3.new(0,0,0)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.Font = Enum.Font.SourceSans
    distanceLabel.TextScaled = true
    distanceLabel.Parent = billboard

    billboard.Parent = part
    billboard.Enabled = espEnabled -- ensure active immediately
    espObjects[model] = {billboard = billboard, title = title, distanceLabel = distanceLabel, part = part}
end

task.spawn(function()
    while true do
        task.wait(RESCAN_SEC)
        for model, _ in pairs(espObjects) do if not model or not model.Parent then removeESP(model) end end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find("egg") then
                if not espObjects[obj] then createESP(obj) else
                    local data = espObjects[obj]
                    if not isValidPart(data.part) then
                        local np = getTargetPart(obj)
                        if isValidPart(np) then
                            data.part = np
                            if data.billboard then data.billboard.Parent = np end
                        else
                            removeESP(obj)
                        end
                    end
                end
            end
        end
        local count = 0
        for _, _ in pairs(espObjects) do count += 1 end
        EggCounter.Text = "Eggs: " .. tostring(count)
    end
end)

RunService.RenderStepped:Connect(function()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        for _, d in pairs(espObjects) do if d.billboard then d.billboard.Enabled = false end end
        return
    end
    for model, d in pairs(espObjects) do
        if model and model.Parent and isValidPart(d.part) then
            local dist = (hrp.Position - d.part.Position).Magnitude
            d.title.Text = "Egg"
            d.distanceLabel.Text = string.format("[%.0f studs]", dist)
            d.billboard.Enabled = espEnabled
        else
            removeESP(model)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(TP_TICK)
        if teleportEnabled then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local candidates = {}
                for model, d in pairs(espObjects) do
                    if model and model.Parent and isValidPart(d.part) then
                        table.insert(candidates, {model = model, part = d.part, dist = (hrp.Position - d.part.Position).Magnitude})
                    end
                end
                if #candidates > 0 then
                    table.sort(candidates, function(a,b) return a.dist < b.dist end)
                    local closest = candidates[1]
                    if closest and isValidPart(closest.part) then
                        if closest.dist > TELEPORT_RANGE then
                            hrp.CFrame = CFrame.new(closest.part.Position + Vector3.new(0,5,0))
                        else
                            local numClose = 0
                            for _, c in ipairs(candidates) do if c.dist <= TELEPORT_RANGE then numClose += 1 end end
                            if numClose > 1 then
                                if closest.dist > INNER_RANGE then
                                    local target
                                    for _, c in ipairs(candidates) do
                                        if c.dist > INNER_RANGE then
                                            target = c
                                            break
                                        end
                                    end
                                    if target and isValidPart(target.part) then
                                        hrp.CFrame = CFrame.new(target.part.Position + Vector3.new(0,5,0))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

ESPButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ESPButton.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    for _, d in pairs(espObjects) do if d.billboard then d.billboard.Enabled = espEnabled end end
end)

TPButton.MouseButton1Click:Connect(function()
    teleportEnabled = not teleportEnabled
    TPButton.Text = teleportEnabled and "TP: ON" or "TP: OFF"
end)

CloseButton.MouseButton1Click:Connect(function()
    espEnabled = false
    teleportEnabled = false
    for _, d in pairs(espObjects) do if d.billboard then d.billboard:Destroy() end end
    espObjects = {}
    ScreenGui:Destroy()
end)
