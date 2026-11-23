-- Dark Side Rotation - Delta Android-friendly client preview
-- Paste into Delta only in a game you are authorized to modify.
-- Changes are local previews; the game may not replicate them to the server.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
assert(player, "Run this from a Roblox client")

local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("DarkSideRotation")
if oldGui then oldGui:Destroy() end

local COLORS = {
    bg = Color3.fromRGB(24, 25, 34),
    panel = Color3.fromRGB(38, 40, 52),
    line = Color3.fromRGB(72, 74, 92),
    text = Color3.fromRGB(245, 244, 250),
    muted = Color3.fromRGB(174, 173, 190),
    accent = Color3.fromRGB(139, 108, 232),
}

local gui = Instance.new("ScreenGui")
gui.Name = "DarkSideRotation"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(310, 470)
frame.Position = UDim2.new(0, 12, 0.5, -235)
frame.BackgroundColor3 = COLORS.bg
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.line
stroke.Parent = frame

local scale = Instance.new("UIScale")
scale.Parent = frame

local function makeLabel(parent, text, pos, size, fontSize, color, bold)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = pos
    label.Size = size
    label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.Text = text
    label.TextSize = fontSize
    label.TextColor3 = color or COLORS.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function makeButton(parent, text, pos, size, color)
    local button = Instance.new("TextButton")
    button.Position = pos
    button.Size = size
    button.BackgroundColor3 = color or COLORS.panel
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = COLORS.text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.AutoButtonColor = true
    button.Parent = parent
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
    return button
end

makeLabel(frame, "DARK SIDE", UDim2.fromOffset(16, 10), UDim2.fromOffset(190, 24), 17, COLORS.text, true)
makeLabel(frame, "STRUCTURE ROTATION • MOBILE", UDim2.fromOffset(16, 34), UDim2.fromOffset(240, 18), 10, COLORS.muted, true)

local dragButton = makeButton(frame, "MOVE", UDim2.new(1, -112, 0, 12), UDim2.fromOffset(56, 30), COLORS.accent)
local closeButton = makeButton(frame, "X", UDim2.new(1, -48, 0, 12), UDim2.fromOffset(34, 30))

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ControlsScroll"
scroll.Position = UDim2.fromOffset(0, 54)
scroll.Size = UDim2.new(1, 0, 1, -62)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = COLORS.accent
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.CanvasSize = UDim2.fromOffset(0, 1060)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
scroll.Parent = frame

-- Drag the panel using the MOVE handle (works with touch on Android).
local dragging = false
local dragTouch = nil
local dragStart = nil
local panelStart = nil

dragButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragTouch = input
        dragStart = input.Position
        panelStart = frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    local isMouseMove = input.UserInputType == Enum.UserInputType.MouseMovement
    local isTouchMove = input.UserInputType == Enum.UserInputType.Touch
        and dragTouch ~= nil and input == dragTouch
    if not isMouseMove and not isTouchMove then return end

    local delta = input.Position - dragStart
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local width = frame.AbsoluteSize.X
    local height = frame.AbsoluteSize.Y
    local x = math.clamp(panelStart.X.Offset + delta.X, 0, math.max(0, viewport.X - width))
    local y = math.clamp(panelStart.Y.Offset + delta.Y, 0, math.max(0, viewport.Y - height))
    frame.Position = UDim2.fromOffset(x, y)
end)

UserInputService.InputEnded:Connect(function(input)
    if input == dragTouch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        dragTouch = nil
    end
end)
local selectButton = makeButton(scroll, "SELECT STRUCTURE", UDim2.fromOffset(14, 10), UDim2.fromOffset(282, 36), COLORS.accent)

local selectedLabel = makeLabel(scroll, "Target: none", UDim2.fromOffset(16, 54), UDim2.fromOffset(278, 24), 12, COLORS.text, true)
local statusLabel = makeLabel(scroll, "Tap Select, then tap a placed structure.", UDim2.fromOffset(16, 78), UDim2.fromOffset(278, 34), 10, COLORS.muted, false)
statusLabel.TextWrapped = true

makeLabel(scroll, "Rotation step (degrees)", UDim2.fromOffset(16, 120), UDim2.fromOffset(170, 24), 12, COLORS.text, true)
local rotationBox = Instance.new("TextBox")
rotationBox.Position = UDim2.fromOffset(206, 116)
rotationBox.Size = UDim2.fromOffset(88, 30)
rotationBox.BackgroundColor3 = COLORS.panel
rotationBox.BorderSizePixel = 0
rotationBox.TextColor3 = COLORS.text
rotationBox.Font = Enum.Font.GothamBold
rotationBox.TextSize = 14
rotationBox.Text = "15"
rotationBox.ClearTextOnFocus = false
rotationBox.Parent = scroll
Instance.new("UICorner", rotationBox).CornerRadius = UDim.new(0, 6)

makeLabel(scroll, "Move step (studs)", UDim2.fromOffset(16, 160), UDim2.fromOffset(170, 24), 12, COLORS.text, true)
local moveBox = Instance.new("TextBox")
moveBox.Position = UDim2.fromOffset(206, 156)
moveBox.Size = UDim2.fromOffset(88, 30)
moveBox.BackgroundColor3 = COLORS.panel
moveBox.BorderSizePixel = 0
moveBox.TextColor3 = COLORS.text
moveBox.Font = Enum.Font.GothamBold
moveBox.TextSize = 14
moveBox.Text = "1"
moveBox.ClearTextOnFocus = false
moveBox.Parent = scroll
Instance.new("UICorner", moveBox).CornerRadius = UDim.new(0, 6)

makeLabel(scroll, "ROTATE", UDim2.fromOffset(16, 198), UDim2.fromOffset(100, 20), 10, COLORS.muted, true)
local axisColors = {
    X = Color3.fromRGB(232, 111, 120),
    Y = Color3.fromRGB(112, 202, 157),
    Z = Color3.fromRGB(111, 158, 235),
}
local selectedModel = nil
local selecting = false
local highlight = Instance.new("Highlight")
highlight.Name = "DarkSideRotationHighlight"
highlight.FillTransparency = 0.82
highlight.OutlineColor = COLORS.accent
highlight.Enabled = false
highlight.Parent = workspace

local function isValidStructure(model)
    if not model or not model:IsA("Model") then return false end
    local folder = workspace:FindFirstChild("PlayerModels")
    if not folder or not model:IsDescendantOf(folder) then return false end
    local typeValue = model:FindFirstChild("Type")
    return typeValue and typeValue:IsA("StringValue") and typeValue.Value == "Structure"
        and not model:FindFirstChild("PurchasedBoxItemName")
        and not model:FindFirstChild("BoxItemName")
end

local function setStatus(message)
    statusLabel.Text = message
end

local function clearSelection()
    selectedModel = nil
    highlight.Adornee = nil
    highlight.Enabled = false
    selectedLabel.Text = "Target: none"
end

local function selectFromScreen(position)
    local camera = workspace.CurrentCamera
    if not camera then
        setStatus("Camera not ready. Try again.")
        return
    end

    local ray = camera:ScreenPointToRay(position.X, position.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = player.Character and {player.Character} or {}

    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if not result then
        setStatus("Nothing hit. Tap directly on the structure.")
        return
    end

    local folder = workspace:FindFirstChild("PlayerModels")
    local candidate = result.Instance
    while candidate and candidate.Parent ~= folder do
        candidate = candidate.Parent
    end

    if not isValidStructure(candidate) then
        setStatus("That is not a selectable placed structure.")
        return
    end

    selectedModel = candidate
    highlight.Adornee = candidate
    highlight.Enabled = true
    selectedLabel.Text = "Target: " .. candidate.Name
    setStatus("Selected. Rotation and movement are local previews.")
    selecting = false
    selectButton.Text = "SELECT STRUCTURE"
end

selectButton.Activated:Connect(function()
    selecting = not selecting
    selectButton.Text = selecting and "TAP A STRUCTURE..." or "SELECT STRUCTURE"
    setStatus(selecting and "Now tap the structure in the game." or "Selection cancelled.")
end)

local inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not selecting then return end
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        selectFromScreen(input.Position)
    end
end)

local function rotate(axis, sign)
    if not isValidStructure(selectedModel) then
        clearSelection()
        setStatus("Select a placed structure first.")
        return
    end

    local degrees = tonumber(rotationBox.Text)
    if not degrees or degrees ~= degrees or math.abs(degrees) > 36000 then
        setStatus("Enter a valid rotation from -36000 to 36000.")
        return
    end

    local angle = math.rad(degrees * sign)
    local x = axis == "X" and angle or 0
    local y = axis == "Y" and angle or 0
    local z = axis == "Z" and angle or 0

    local ok = pcall(function()
        selectedModel:PivotTo(selectedModel:GetPivot() * CFrame.Angles(x, y, z))
    end)
    setStatus(ok and "Rotated locally. Server sync is not guaranteed." or "Could not rotate this model.")
end

local function move(direction)
    if not isValidStructure(selectedModel) then
        clearSelection()
        setStatus("Select a placed structure first.")
        return
    end

    local distance = tonumber(moveBox.Text)
    if not distance or distance ~= distance or distance <= 0 or distance > 10000 then
        setStatus("Enter a move step greater than 0.")
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then setStatus("Camera not ready.") return end

    local look = camera.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 0.001 then
        setStatus("Point the camera more toward the horizon.")
        return
    end
    flat = flat.Unit
    local right = Vector3.new(-flat.Z, 0, flat.X)
    local offsets = {
        FORWARD = flat * distance,
        BACK = -flat * distance,
        LEFT = -right * distance,
        RIGHT = right * distance,
        UP = Vector3.new(0, distance, 0),
        DOWN = Vector3.new(0, -distance, 0),
    }
    local offset = offsets[direction]
    local ok = pcall(function()
        selectedModel:PivotTo(CFrame.new(offset) * selectedModel:GetPivot())
    end)
    setStatus(ok and "Moved locally. Server sync is not guaranteed." or "Could not move this model.")
end

for index, axis in ipairs({"X", "Y", "Z"}) do
    local y = 220 + (index - 1) * 40
    local label = makeLabel(scroll, axis, UDim2.fromOffset(18, y), UDim2.fromOffset(30, 32), 15, axisColors[axis], true)
    local minus = makeButton(scroll, "−", UDim2.fromOffset(70, y), UDim2.fromOffset(100, 32))
    local plus = makeButton(scroll, "+", UDim2.fromOffset(178, y), UDim2.fromOffset(116, 32))
    minus.Activated:Connect(function() rotate(axis, -1) end)
    plus.Activated:Connect(function() rotate(axis, 1) end)
end

local moveButtons = {
    {"LEFT", 16, 350}, {"RIGHT", 162, 350},
    {"FORWARD", 16, 386}, {"BACK", 162, 386},
    {"UP", 16, 422}, {"DOWN", 162, 422},
}
-- Keep the panel within a mobile viewport by making the bottom controls scroll-free
-- and scaling the complete panel to fit the available screen height.
for _, item in ipairs(moveButtons) do
    local button = makeButton(scroll, item[1], UDim2.fromOffset(item[2], item[3]), UDim2.fromOffset(132, 30))
    button.Activated:Connect(function() move(item[1]) end)
end


-- LOCAL LOOSE-OBJECT FLING TEST.
-- Applies impulses only to nearby unanchored, non-character loose assemblies.
-- Roblox server ownership may override or reject client-side physics changes.
makeLabel(scroll, "LOOSE OBJECT FLING TEST", UDim2.fromOffset(16, 466), UDim2.fromOffset(278, 22), 11, COLORS.accent, true)
local flingButton = makeButton(scroll, "START OBJECT FLING", UDim2.fromOffset(16, 492), UDim2.fromOffset(278, 36), COLORS.accent)
local flingStatus = makeLabel(scroll, "Targets nearby loose, unanchored objects only. Results depend on network ownership.", UDim2.fromOffset(16, 534), UDim2.fromOffset(278, 36), 9, COLORS.muted, false)
flingStatus.TextWrapped = true

makeLabel(scroll, "FLING POWER (1–100)", UDim2.fromOffset(16, 576), UDim2.fromOffset(190, 20), 10, COLORS.text, true)
local powerValue = 50
local powerLabel = makeLabel(scroll, "50", UDim2.fromOffset(252, 576), UDim2.fromOffset(42, 20), 11, COLORS.accent, true)
powerLabel.TextXAlignment = Enum.TextXAlignment.Right

local powerBar = Instance.new("Frame")
powerBar.Position = UDim2.fromOffset(16, 602)
powerBar.Size = UDim2.fromOffset(278, 12)
powerBar.BackgroundColor3 = COLORS.panel
powerBar.BorderSizePixel = 0
powerBar.Parent = scroll
Instance.new("UICorner", powerBar).CornerRadius = UDim.new(1, 0)

local powerFill = Instance.new("Frame")
powerFill.Size = UDim2.new(0.5, 0, 1, 0)
powerFill.BackgroundColor3 = COLORS.accent
powerFill.BorderSizePixel = 0
powerFill.Parent = powerBar
Instance.new("UICorner", powerFill).CornerRadius = UDim.new(1, 0)

local powerTouching = false
local function setPowerFromX(x)
    local width = math.max(1, powerBar.AbsoluteSize.X)
    local fraction = math.clamp((x - powerBar.AbsolutePosition.X) / width, 0, 1)
    powerValue = math.clamp(math.floor(fraction * 99 + 1.5), 1, 100)
    powerFill.Size = UDim2.new(powerValue / 100, 0, 1, 0)
    powerLabel.Text = tostring(powerValue)
end
powerBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        powerTouching = true
        setPowerFromX(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if powerTouching and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        setPowerFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        powerTouching = false
    end
end)

local flingActive = false
local flingConnection = nil
local flingClock = 0
local flingCooldowns = {}
local FLING_RADIUS = 80
local MAX_ASSEMBLIES_PER_PULSE = 60

local function isCharacterPart(part)
    local model = part:FindFirstAncestorOfClass("Model")
    return model and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function stopFling()
    flingActive = false
    if flingConnection then
        flingConnection:Disconnect()
        flingConnection = nil
    end
    flingButton.Text = "START OBJECT FLING"
    flingStatus.Text = "Stopped. Only loose objects were targeted."
end

local function startFling()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        flingStatus.Text = "Your character is not ready. Try again."
        return
    end

    flingActive = true
    flingClock = 0
    table.clear(flingCooldowns)
    flingButton.Text = "STOP OBJECT FLING"
    flingStatus.Text = "Searching within 80 studs for loose, unanchored objects..."

    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = {character}
    overlap.MaxParts = 2000

    flingConnection = RunService.Heartbeat:Connect(function(dt)
        if not flingActive then return end
        local currentCharacter = player.Character
        local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
        if not currentRoot then
            stopFling()
            return
        end

        flingClock = flingClock + dt
        if flingClock < 0.22 then return end
        flingClock = 0

        local center = currentRoot.Position
        overlap.FilterDescendantsInstances = {currentCharacter}
        local ok, nearby = pcall(function()
            return workspace:GetPartBoundsInRadius(center, FLING_RADIUS, overlap)
        end)
        if not ok then
            flingStatus.Text = "Could not scan nearby objects in this game."
            return
        end

        local seen = {}
        local affected = 0
        local now = os.clock()
        local power = powerValue / 100

        for _, part in ipairs(nearby) do
            if affected >= MAX_ASSEMBLIES_PER_PULSE then break end
            if part:IsA("BasePart") and not part.Anchored
                and not isCharacterPart(part) then
                local assembly = part.AssemblyRootPart or part
                if assembly and not assembly.Anchored and not seen[assembly]
                    and (not flingCooldowns[assembly] or now - flingCooldowns[assembly] >= 0.65) then
                    seen[assembly] = true
                    local offset = assembly.Position - center
                    local distance = offset.Magnitude
                    if distance > 0.1 and distance <= FLING_RADIUS then
                        local outward = offset.Unit
                        local tangent = Vector3.new(-outward.Z, 0, outward.X)
                        local strength = 18 + power * 92
                        local velocityKick = outward * strength
                            + tangent * (strength * 0.45)
                            + Vector3.new(0, strength * 0.8, 0)

                        local applied = pcall(function()
                            assembly:ApplyImpulse(velocityKick * assembly.AssemblyMass)
                            assembly:ApplyAngularImpulse(Vector3.new(
                                math.random(-1, 1), 1, math.random(-1, 1)
                            ) * assembly.AssemblyMass * (8 + power * 32))
                        end)

                        if applied then
                            flingCooldowns[assembly] = now
                            affected = affected + 1
                        end
                    end
                end
            end
        end

        flingStatus.Text = affected > 0
            and ("Applied local fling to " .. affected .. " loose object(s).")
            or "No unanchored non-character objects detected within 80 studs. Items may be anchored or server-controlled."
    end)
end

flingButton.Activated:Connect(function()
    if flingActive then
        stopFling()
    else
        startFling()
    end
end)


-- MANUAL VEHICLE PICKUP / THROW TEST.
-- User taps a vehicle model; client-side impulses may be rejected by server ownership.
local selectTruckButton = makeButton(scroll, "TAP TO SELECT TRUCK", UDim2.fromOffset(16, 630), UDim2.fromOffset(278, 36), COLORS.accent)
local truckButton = makeButton(scroll, "LIFT / THROW SELECTED", UDim2.fromOffset(16, 672), UDim2.fromOffset(278, 36), COLORS.panel)
local truckStatus = makeLabel(scroll, "Tap Select, then tap the truck itself. Works with vehicle models that do not use VehicleSeat too.", UDim2.fromOffset(16, 712), UDim2.fromOffset(278, 38), 9, COLORS.muted, false)
truckStatus.TextWrapped = true
local dummyButton = makeButton(scroll, "CREATE LOCAL SEAT TEST DUMMY", UDim2.fromOffset(16, 754), UDim2.fromOffset(278, 36), COLORS.accent)
local removeDummyButton = makeButton(scroll, "REMOVE TEST DUMMY", UDim2.fromOffset(16, 794), UDim2.fromOffset(278, 32), COLORS.panel)
local dummyStatus = makeLabel(scroll, "A local-only dummy test. It cannot grant server vehicle ownership.", UDim2.fromOffset(16, 830), UDim2.fromOffset(278, 30), 9, COLORS.muted, false)
dummyStatus.TextWrapped = true
local visualThrowButton = makeButton(scroll, "VISUAL THROW (OUTSIDE)", UDim2.fromOffset(16, 874), UDim2.fromOffset(278, 36), COLORS.accent)
local visualThrowStatus = makeLabel(scroll, "Creates a client-only ghost effect. The real truck will not move for other players.", UDim2.fromOffset(16, 914), UDim2.fromOffset(278, 30), 9, COLORS.muted, false)
visualThrowStatus.TextWrapped = true

local selectedTruck = nil
local testDummy = nil
local selectingTruck = false
local truckActive = false
local truckConnection = nil
local truckLastPulse = 0

-- Client-only ghost animation for when the player is standing beside the vehicle.
-- This intentionally does not apply physics to the real vehicle or affect other players.
local visualThrowBusy = false
local function playVisualTruckThrow()
    if visualThrowBusy then
        visualThrowStatus.Text = "Visual throw is already playing."
        return
    end
    if not selectedTruck or not selectedTruck.Parent then
        visualThrowStatus.Text = "Select a truck first."
        return
    end

    local ghost
    local oldArchivable = selectedTruck.Archivable
    local ok, err = pcall(function()
        selectedTruck.Archivable = true
        ghost = selectedTruck:Clone()
        selectedTruck.Archivable = oldArchivable
        assert(ghost, "Truck could not be copied")
        for _, item in ipairs(ghost:GetDescendants()) do
            if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("ModuleScript") then
                item:Destroy()
            elseif item:IsA("BasePart") then
                item.Anchored = true
                item.CanCollide = false
                item.CanTouch = false
                item.CanQuery = false
                item.Material = Enum.Material.Neon
                item.Color = Color3.fromRGB(155, 120, 255)
                item.Transparency = 0.28
            end
        end
        ghost.Name = "LocalVisualTruckThrow"
        ghost.Parent = workspace
    end)
    selectedTruck.Archivable = oldArchivable
    if not ok or not ghost then
        if ghost then ghost:Destroy() end
        visualThrowStatus.Text = "Could not create the visual copy: " .. tostring(err):sub(1, 65)
        return
    end

    visualThrowBusy = true
    visualThrowStatus.Text = "Playing local visual throw. Other players will not see this."
    local startPivot = ghost:GetPivot()
    local startTime = os.clock()
    local duration = 1.25
    local outward = startPivot.Position - (player.Character and player.Character:GetPivot().Position or startPivot.Position)
    outward = Vector3.new(outward.X, 0, outward.Z)
    if outward.Magnitude < 0.05 then outward = Vector3.new(0, 0, -1) else outward = outward.Unit end

    task.spawn(function()
        while ghost.Parent and os.clock() - startTime < duration do
            local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
            local lift = 10 * alpha + 7 * math.sin(alpha * math.pi)
            local travel = outward * (18 * alpha)
            local spin = CFrame.Angles(0, math.rad(540 * alpha), math.rad(18 * math.sin(alpha * math.pi)))
            pcall(function()
                ghost:PivotTo(CFrame.new(startPivot.Position + Vector3.new(0, lift, 0) + travel) * (startPivot - startPivot.Position) * spin)
                for _, item in ipairs(ghost:GetDescendants()) do
                    if item:IsA("BasePart") then
                        item.Transparency = 0.28 + 0.72 * alpha
                    end
                end
            end)
            RunService.Heartbeat:Wait()
        end
        if ghost then ghost:Destroy() end
        visualThrowBusy = false
        visualThrowStatus.Text = "Visual throw finished. This was a local-only effect."
    end)
end

visualThrowButton.Activated:Connect(playVisualTruckThrow)

local function removeTestDummy()
    if testDummy then
        pcall(function() testDummy:Destroy() end)
        testDummy = nil
    end
    dummyStatus.Text = "Test dummy removed."
end

removeDummyButton.Activated:Connect(removeTestDummy)

dummyButton.Activated:Connect(function()
    if not selectedTruck or not selectedTruck.Parent then
        dummyStatus.Text = "Select a truck first."
        return
    end

    local character = player.Character
    local sourceHumanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not sourceHumanoid then
        dummyStatus.Text = "Your character is not ready."
        return
    end

    local seat = selectedTruck:FindFirstChildWhichIsA("VehicleSeat", true)
        or selectedTruck:FindFirstChildWhichIsA("Seat", true)
    if not seat then
        dummyStatus.Text = "No Seat or VehicleSeat found inside this truck."
        return
    end

    removeTestDummy()
    local oldArchivable = character.Archivable
    local clone
    local ok, err = pcall(function()
        character.Archivable = true
        clone = character:Clone()
        character.Archivable = oldArchivable
        assert(clone, "Character clone failed")
        clone.Name = "DarkSideLocalSeatDummy"
        for _, item in ipairs(clone:GetDescendants()) do
            if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("ModuleScript") then
                item:Destroy()
            elseif item:IsA("BasePart") then
                item.Anchored = false
                item.CanCollide = false
            end
        end
        clone.Parent = workspace
        local humanoid = clone:FindFirstChildOfClass("Humanoid")
        assert(humanoid, "Cloned character has no Humanoid")
        clone:PivotTo(seat.CFrame * CFrame.new(0, 3, 0))
        task.wait(0.15)
        seat:Sit(humanoid)
        testDummy = clone
    end)
    character.Archivable = oldArchivable
    if not ok then
        if clone then clone:Destroy() end
        dummyStatus.Text = "Dummy test failed: " .. tostring(err):sub(1, 85)
        return
    end

    dummyStatus.Text = "Local dummy placed in seat. Testing seat occupancy only; server control is not guaranteed."
end)

local function findTappedVehicle(position)
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local ray = camera:ScreenPointToRay(position.X, position.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = player.Character and {player.Character} or {}
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1500, params)
    if not result then return nil end

    local node = result.Instance
    while node and node ~= workspace do
        if node:IsA("Model") and not node:FindFirstChildOfClass("Humanoid") then
            local count = 0
            for _, item in ipairs(node:GetDescendants()) do
                if item:IsA("BasePart") then count = count + 1 end
            end
            if count >= 2 then return node end
        end
        node = node.Parent
    end
    return nil
end

selectTruckButton.Activated:Connect(function()
    selectingTruck = not selectingTruck
    selectTruckButton.Text = selectingTruck and "NOW TAP THE TRUCK..." or "TAP TO SELECT TRUCK"
    truckStatus.Text = selectingTruck and "Tap directly on the truck body in the game." or "Truck selection cancelled."
end)

local truckSelectConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not selectingTruck then return end
    if input.UserInputType ~= Enum.UserInputType.Touch
        and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    local model = findTappedVehicle(input.Position)
    selectingTruck = false
    selectTruckButton.Text = "TAP TO SELECT TRUCK"
    if model then
        selectedTruck = model
        truckStatus.Text = "Selected: " .. model.Name .. ". Press LIFT / THROW SELECTED."
    else
        truckStatus.Text = "Couldn't identify a model there. Tap the truck body, not the ground."
    end
end)

local function stopTruckLift()
    truckActive = false
    if truckConnection then
        truckConnection:Disconnect()
        truckConnection = nil
    end
    truckButton.Text = "LIFT / THROW SELECTED"
    truckStatus.Text = selectedTruck and ("Stopped. Selected: " .. selectedTruck.Name) or "Truck lift stopped."
end

local function startTruckLift()
    if not selectedTruck or not selectedTruck.Parent then
        truckStatus.Text = "Select a truck first using TAP TO SELECT TRUCK."
        return
    end

    truckActive = true
    truckLastPulse = 0
    truckButton.Text = "STOP TRUCK LIFT"
    truckStatus.Text = "Applying lift and throw to selected truck..."

    truckConnection = RunService.Heartbeat:Connect(function(dt)
        local ok, err = pcall(function()
            if not truckActive then return end
            if not selectedTruck or not selectedTruck.Parent then
                stopTruckLift()
                truckStatus.Text = "Selected truck is no longer available."
                return
            end

            truckLastPulse = truckLastPulse + dt
            if truckLastPulse < 0.25 then return end
            truckLastPulse = 0

            local assemblies = {}
            local partsFound = 0
            for _, item in ipairs(selectedTruck:GetDescendants()) do
                if item:IsA("BasePart") then
                    partsFound = partsFound + 1
                    local assembly = item.AssemblyRootPart or item
                    if assembly and not assembly.Anchored then
                        assemblies[assembly] = true
                    end
                end
            end

            local appliedCount = 0
            local power = powerValue / 100
            for assembly in pairs(assemblies) do
                local mass = assembly.AssemblyMass
                if mass > 0 and mass < math.huge then
                    local impulse = Vector3.new(0, 75 + power * 150, 0)
                        + (assembly.Position - (player.Character and player.Character:GetPivot().Position or assembly.Position)).Unit
                        * (25 + power * 90)
                    local success = pcall(function()
                        assembly:ApplyImpulse(impulse * mass)
                        assembly:ApplyAngularImpulse(Vector3.new(0, 1, 0) * mass * (20 + power * 45))
                    end)
                    if success then appliedCount = appliedCount + 1 end
                end
            end

            truckStatus.Text = "Parts: " .. partsFound .. " | unanchored assemblies: "
                .. #({}) .. " | impulse attempted: " .. appliedCount
                .. ". Server ownership may prevent movement."
        end)
        if not ok then
            truckStatus.Text = "Truck test error: " .. tostring(err):sub(1, 110)
            stopTruckLift()
        end
    end)
end

truckButton.Activated:Connect(function()
    if truckActive then
        stopTruckLift()
    else
        startTruckLift()
    end
end)

-- Slightly taller panel; responsive scaling keeps all touch targets visible.
frame.Size = UDim2.fromOffset(310, 390)
local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    scale.Scale = math.min(1, (viewport.X - 20) / 310, (viewport.Y - 24) / 390)
    frame.Position = UDim2.new(0, 10, 0.5, -195 * scale.Scale)
end
updateScale()
local cameraConnection
local function watchCamera()
    if cameraConnection then cameraConnection:Disconnect() end
    local camera = workspace.CurrentCamera
    if camera then
        cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
    end
    updateScale()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)

closeButton.Activated:Connect(function()
    gui:Destroy()
end)

gui.Destroying:Connect(function()
    inputConnection:Disconnect()
    if cameraConnection then cameraConnection:Disconnect() end
    highlight:Destroy()
    stopFling()
    stopTruckLift()
    removeTestDummy()
    if truckSelectConnection then truckSelectConnection:Disconnect() end
end)
