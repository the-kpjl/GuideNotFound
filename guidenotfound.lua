--// Dragon Ball Rage - Egg ESP + Safe Teleport (with fail-safety) 

-- Features: 

-- - ESP for Egg entities (rescans every 1s) 

-- - Shows "Egg" + distance in studs (white text, black outline) 

-- - Teleport toggle: 

--      * normally pauses when within 10 studs 

--      * if >1 egg inside 10 studs, inner pause radius = 5 studs 

--      * will not skip the closest egg while it exists inside the pause radius 

-- - GUI with ESP/Teleport toggles, draggable, close button 

-- - Mobile-friendly sizing 

-- - Safety checks to avoid origin/placeholder parts 

 

-- Services 

local Players = game:GetService("Players") 

local RunService = game:GetService("RunService") 

local workspace = game:GetService("Workspace") 

 

local player = Players.LocalPlayer 

 

-- Config 

local TELEPORT_RANGE = 10      -- main pause radius (studs) 

local INNER_RANGE = 5          -- reduced pause radius when cluster present 

local RESCAN_SEC = 1           -- rescan frequency (seconds) 

local TP_TICK = 0.45           -- teleport check frequency (seconds) 

local DEBUG = false            -- set true to print teleport decisions 

 

-- State 

local espEnabled = false 

local teleportEnabled = false 

local espObjects = {} -- [model] = {billboard=..., title=..., distanceLabel=..., part=...} 

 

-- UI (mobile-friendly, small) 

local ScreenGui = Instance.new("ScreenGui") 

ScreenGui.Parent = game:GetService("CoreGui") 

 

local Frame = Instance.new("Frame") 

Frame.Size = UDim2.new(0, 170, 0, 86) 

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

Title.Text = "Egg ESP Menu" 

Title.TextColor3 = Color3.new(1,1,1) 

Title.Font = Enum.Font.SourceSansBold 

Title.TextScaled = true 

Title.Parent = Frame 

 

local ESPButton = Instance.new("TextButton") 

ESPButton.Size = UDim2.new(0.46, 0, 0, 24) 

ESPButton.Position = UDim2.new(0.03, 0, 0.28, 0) 

ESPButton.BackgroundColor3 = Color3.fromRGB(70,70,70) 

ESPButton.Text = "ESP: OFF" 

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

 

-- Helper functions 

local function getTargetPart(model) 

    if not model then return nil end 

    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then 

        return model.PrimaryPart 

    end 

    local hrp = model:FindFirstChild("HumanoidRootPart") 

    if hrp and hrp:IsA("BasePart") then return hrp end 

    return model:FindFirstChildWhichIsA("BasePart") 

end 

 

local function isValidPart(part) 

    if not part then return false end 

    if not part.Parent then return false end 

    if not part:IsDescendantOf(workspace) then return false end 

    local p = part.Position 

    -- Avoid origin/placeholder and absurd coords 

    if math.abs(p.X) < 0.01 and math.abs(p.Y) < 0.01 and math.abs(p.Z) < 0.01 then 

        return false 

    end 

    if math.abs(p.X) > 1e6 or math.abs(p.Y) > 1e6 or math.abs(p.Z) > 1e6 then 

        return false 

    end 

    return true 

end 

 

local function removeESP(model) 

    if espObjects[model] then 

        local d = espObjects[model] 

        if d.billboard and d.billboard.Parent then 

            d.billboard:Destroy() 

        end 

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

    espObjects[model] = {billboard = billboard, title = title, distanceLabel = distanceLabel, part = part} 

end 

 

-- Rescan loop (every RESCAN_SEC) - clears old and finds new eggs 

task.spawn(function() 

    while true do 

        task.wait(RESCAN_SEC) 

        -- cleanup removed/invalid models 

        for model, _ in pairs(espObjects) do 

            if not model or not model.Parent then 

                removeESP(model) 

            end 

        end 

        -- scan for eggs 

        for _, obj in ipairs(workspace:GetDescendants()) do 

            if obj:IsA("Model") and obj.Name:lower():find("egg") then 

                if not espObjects[obj] then 

                    createESP(obj) 

                else 

                    -- refresh part if it became invalid 

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

    end 

end) 

 

-- Update ESP text + visibility 

RunService.RenderStepped:Connect(function() 

    local char = player.Character 

    local hrp = char and char:FindFirstChild("HumanoidRootPart") 

    if not hrp then 

        for _, d in pairs(espObjects) do 

            if d.billboard then d.billboard.Enabled = false end 

        end 

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

 

-- Teleport worker (safe, with cluster fail-safety) 

task.spawn(function() 

    while true do 

        task.wait(TP_TICK) 

        if not teleportEnabled then 

            task.wait(0) 

        else 

            local char = player.Character 

            local hrp = char and char:FindFirstChild("HumanoidRootPart") 

            if not hrp then 

                -- cannot teleport without hrp 

            else 

                -- gather valid candidates 

                local candidates = {} 

                for model, d in pairs(espObjects) do 

                    if model and model.Parent and isValidPart(d.part) then 

                        local dist = (hrp.Position - d.part.Position).Magnitude 

                        table.insert(candidates, {model = model, part = d.part, dist = dist}) 

                    end 

                end 

 

                if #candidates == 0 then 

                    -- no eggs -> teleport silently does nothing (auto-resume when eggs spawn) 

                    if DEBUG then print("[TP] No candidates found.") end 

                else 

                    table.sort(candidates, function(a,b) return a.dist < b.dist end) 

                    local closest = candidates[1] 

                    -- if closest is invalid, skip it 

                    if not closest or not isValidPart(closest.part) then 

                        if DEBUG then print("[TP] Closest invalid, skipping.") end 

                    else 

                        if DEBUG then 

                            -- debug info 

                            --print(string.format("[TP] Closest: dist=%.2f pos=(%.1f,%.1f,%.1f)", closest.dist, closest.part.Position.X, closest.part.Position.Y, closest.part.Position.Z)) 

                        end 

 

                        if closest.dist > TELEPORT_RANGE then 

                            -- closest is far enough -> teleport to it 

                            if DEBUG then print("[TP] Teleporting to closest (farther than TELEPORT_RANGE).") end 

                            hrp.CFrame = CFrame.new(closest.part.Position + Vector3.new(0,5,0)) 

                        else 

                            -- closest is within TELEPORT_RANGE 

                            -- count how many eggs are within TELEPORT_RANGE 

                            local numClose = 0 

                            for _, c in ipairs(candidates) do 

                                if c.dist <= TELEPORT_RANGE then numClose = numClose + 1 end 

                            end 

 

                            if numClose == 1 then 

                                -- only the closest egg is within TELEPORT_RANGE -> pause teleporting (do nothing) 

                                if DEBUG then print("[TP] Paused: single egg inside TELEPORT_RANGE.") end 

                            else 

                                -- cluster: more than one egg within TELEPORT_RANGE 

                                -- use INNER_RANGE rules: 

                                if closest.dist <= INNER_RANGE then 

                                    -- if the closest is inside INNER_RANGE, pause until it disappears 

                                    if DEBUG then print("[TP] Paused: closest inside INNER_RANGE while cluster present.") end 

                                else 

                                    -- closest is between INNER_RANGE and TELEPORT_RANGE -> allowed to teleport (reduced pause) 

                                    -- pick the nearest candidate that is > INNER_RANGE (prefer closest itself if it fits) 

                                    local target = nil 

                                    for _, c in ipairs(candidates) do 

                                        if c.dist > INNER_RANGE then 

                                            target = c 

                                            break 

                                        end 

                                    end 

                                    if target and isValidPart(target.part) then 

                                        if DEBUG then print("[TP] Teleporting to cluster target (dist > INNER_RANGE).") end 

                                        hrp.CFrame = CFrame.new(target.part.Position + Vector3.new(0,5,0)) 

                                    else 

                                        if DEBUG then print("[TP] No cluster target found > INNER_RANGE; paused.") end 

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

 

-- Button behaviour 

ESPButton.MouseButton1Click:Connect(function() 

    espEnabled = not espEnabled 

    ESPButton.Text = espEnabled and "ESP: ON" or "ESP: OFF" 

    -- apply toggled visibility immediately 

    for _, d in pairs(espObjects) do 

        if d.billboard then d.billboard.Enabled = espEnabled end 

    end 

end) 

 

TPButton.MouseButton1Click:Connect(function() 

    teleportEnabled = not teleportEnabled 

    TPButton.Text = teleportEnabled and "TP: ON" or "TP: OFF" 

end) 

 

CloseButton.MouseButton1Click:Connect(function() 

    espEnabled = false 

    teleportEnabled = false 

    for model, d in pairs(espObjects) do 

        if d.billboard then d.billboard:Destroy() end 

    end 

    espObjects = {} 

    ScreenGui:Destroy() 

end) 

 

-- initial state (set espEnabled = true below if you want ESP on by default) 

-- espEnabled = true 
