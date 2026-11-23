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
scroll.CanvasSize = UDim2.fromOffset(0, 640)
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


-- LOCAL-ONLY tornado visual effect around the player's character.
makeLabel(scroll, "TORNADO DISTRACTION (VISUAL)", UDim2.fromOffset(16, 466), UDim2.fromOffset(278, 22), 11, COLORS.accent, true)
local tornadoButton = makeButton(scroll, "START TORNADO", UDim2.fromOffset(16, 492), UDim2.fromOffset(278, 36), COLORS.accent)
local tornadoStatus = makeLabel(scroll, "Creates a local swirling effect around your character.", UDim2.fromOffset(16, 534), UDim2.fromOffset(278, 34), 9, COLORS.muted, false)
tornadoStatus.TextWrapped = true

local tornadoActive = false
local tornadoConnection = nil
local tornadoParts = {}
local tornadoRings = {}
local tornadoClock = 0
local tornadoPartCount = 48
local suctionClock = 0
local SUCTION_RADIUS = 45
local MAX_SUCTION_ASSEMBLIES = 60

local function clearTornado()
    if tornadoConnection then
        tornadoConnection:Disconnect()
        tornadoConnection = nil
    end
    for _, part in ipairs(tornadoParts) do
        if part and part.Parent then part:Destroy() end
    end
    table.clear(tornadoParts)
    for _, ring in ipairs(tornadoRings) do
        if ring and ring.Parent then ring:Destroy() end
    end
    table.clear(tornadoRings)
    tornadoClock = 0
    suctionClock = 0
end

local function stopTornado()
    tornadoActive = false
    clearTornado()
    tornadoButton.Text = "START TORNADO"
    tornadoStatus.Text = "Tornado and suction stopped. Object collisions were not changed."
end

local function isInsideCharacter(part)
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        local character = otherPlayer.Character
        if character and part:IsDescendantOf(character) then
            return true
        end
    end
    return false
end

local function isStructurePart(part)
    local current = part
    while current and current ~= workspace do
        if current:IsA("Model") then
            local typeValue = current:FindFirstChild("Type")
            if typeValue and typeValue:IsA("StringValue") and typeValue.Value == "Structure" then
                return true
            end
            if current:FindFirstChildOfClass("Humanoid") then
                return true
            end
        end
        current = current.Parent
    end
    return false
end

local function pullLooseObjects(center)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    local excluded = {}
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer.Character then
            table.insert(excluded, otherPlayer.Character)
        end
    end
    overlap.FilterDescendantsInstances = excluded
    overlap.MaxParts = 350

    local nearbyParts = workspace:GetPartBoundsInRadius(center, SUCTION_RADIUS, overlap)
    local handled = {}
    local processed = 0

    for _, part in ipairs(nearbyParts) do
        if processed >= MAX_SUCTION_ASSEMBLIES then break end
        if part:IsA("BasePart") and part.Parent and not part.Anchored
            and part.CanCollide and not isInsideCharacter(part) and not isStructurePart(part) then

            local assembly = part.AssemblyRootPart or part
            if assembly and assembly.Parent and not assembly.Anchored and not handled[assembly] then
                handled[assembly] = true
                local offset = center - assembly.Position
                local distance = offset.Magnitude

                if distance > 2 and distance <= SUCTION_RADIUS then
                    local inward = offset.Unit
                    local tangent = Vector3.new(-inward.Z, 0, inward.X)
                    if tangent.Magnitude > 0 then tangent = tangent.Unit end

                    -- Apply force only to loose, collidable physics assemblies.
                    -- CanCollide is deliberately left unchanged.
                    local mass = assembly.AssemblyMass
                    if mass > 0 and mass < 100000 then
                        local distanceFactor = 0.65 + 0.35 * (1 - distance / SUCTION_RADIUS)
                        local impulse = (
                            inward * 85
                            + tangent * 65
                            + Vector3.new(0, 110, 0)
                        ) * mass * 0.32 * distanceFactor

                        pcall(function()
                            assembly:ApplyImpulse(impulse)
                        end)
                        processed = processed + 1
                    end
                end
            end
        end
    end
end

local function startTornado()
    clearTornado()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        tornadoStatus.Text = "Your character is not ready. Try again."
        return
    end

    tornadoActive = true
    tornadoButton.Text = "STOP TORNADO"
    tornadoStatus.Text = "ULTIMATE VORTEX: 48 particles, triple spinning rings, and a towering spiral."

    -- Three horizontal neon rings create a layered, expanding vortex base.
    for ringIndex = 1, 3 do
        local ring = Instance.new("Part")
        ring.Name = "DarkSideTornadoRing"
        ring.Shape = Enum.PartType.Cylinder
        ring.Size = Vector3.new(0.16, 5 + ringIndex * 2.1, 5 + ringIndex * 2.1)
        ring.Material = Enum.Material.Neon
        ring.Color = ringIndex % 2 == 0 and Color3.fromRGB(92, 190, 255) or COLORS.accent
        ring.Transparency = 0.42 + ringIndex * 0.08
        ring.Anchored = true
        ring.CanCollide = false
        ring.CanTouch = false
        ring.CanQuery = false
        ring.CastShadow = false
        ring.Parent = workspace
        table.insert(tornadoRings, ring)
    end

    for i = 1, tornadoPartCount do
        local orb = Instance.new("Part")
        orb.Name = "DarkSideTornadoParticle"
        orb.Shape = Enum.PartType.Ball
        orb.Size = Vector3.new(0.8, 0.8, 0.8)
        orb.Material = Enum.Material.Neon
        orb.Color = i % 2 == 0 and COLORS.accent or Color3.fromRGB(92, 190, 255)
        orb.Transparency = 0.12
        orb.Anchored = true
        orb.CanCollide = false
        orb.CanTouch = false
        orb.CanQuery = false
        orb.CastShadow = false
        orb.Parent = workspace
        table.insert(tornadoParts, orb)
    end

    tornadoConnection = RunService.Heartbeat:Connect(function(deltaTime)
        local currentCharacter = player.Character
        local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
        if not currentRoot then
            stopTornado()
            return
        end

        tornadoClock = tornadoClock + deltaTime
        suctionClock = suctionClock + deltaTime
        local center = currentRoot.Position

        for i, orb in ipairs(tornadoParts) do
            if orb and orb.Parent then
                local fraction = (i - 1) / tornadoPartCount
                local arm = (i - 1) % 4
                local angle = tornadoClock * (4.2 + arm * 0.18) + fraction * math.pi * 8 + arm * math.pi * 0.5
                local height = 0.7 + fraction * 14
                local radius = 0.9 + fraction * 4.2
                local wobble = math.sin(tornadoClock * 5 + i) * 0.38
                local position = center + Vector3.new(
                    math.cos(angle) * (radius + wobble),
                    height,
                    math.sin(angle) * (radius + wobble)
                )
                orb.CFrame = CFrame.new(position)
                local size = 0.38 + fraction * 0.8
                orb.Size = Vector3.new(size, size, size)
            end
        end

        for ringIndex, ring in ipairs(tornadoRings) do
            if ring and ring.Parent then
                local ringRadius = 4.5 + ringIndex * 1.1 + math.sin(tornadoClock * 2 + ringIndex) * 0.25
                ring.Size = Vector3.new(0.16, ringRadius * 2, ringRadius * 2)
                ring.CFrame = CFrame.new(center + Vector3.new(0, 0.45 + ringIndex * 0.5, 0))
                    * CFrame.Angles(0, tornadoClock * (1.8 + ringIndex * 0.45), math.rad(90))
            end
        end

        -- Scan and apply suction several times per second instead of every frame.
        if suctionClock >= 0.08 then
            suctionClock = 0
            pullLooseObjects(center)
        end
    end)
end

tornadoButton.Activated:Connect(function()
    if tornadoActive then
        stopTornado()
    else
        startTornado()
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
    clearTornado()
end)
