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


-- LOCAL-ONLY item attraction: gifts and clearly dropped tree/log objects.
makeLabel(scroll, "ITEM DISTRACTION (LOCAL PREVIEW)", UDim2.fromOffset(16, 466), UDim2.fromOffset(278, 22), 11, COLORS.accent, true)
local giftToggle = makeButton(scroll, "PULL GIFTS: OFF", UDim2.fromOffset(16, 492), UDim2.fromOffset(132, 34))
local treeToggle = makeButton(scroll, "PULL DROPPED TREES: OFF", UDim2.fromOffset(162, 492), UDim2.fromOffset(132, 34))
local radiusLabel = makeLabel(scroll, "Pull radius (studs)", UDim2.fromOffset(16, 535), UDim2.fromOffset(170, 24), 11, COLORS.text, true)
local radiusBox = Instance.new("TextBox")
radiusBox.Position = UDim2.fromOffset(206, 532)
radiusBox.Size = UDim2.fromOffset(88, 30)
radiusBox.BackgroundColor3 = COLORS.panel
radiusBox.BorderSizePixel = 0
radiusBox.TextColor3 = COLORS.text
radiusBox.Font = Enum.Font.GothamBold
radiusBox.TextSize = 14
radiusBox.Text = "35"
radiusBox.ClearTextOnFocus = false
radiusBox.Parent = scroll
Instance.new("UICorner", radiusBox).CornerRadius = UDim.new(0, 6)
local stopPullButton = makeButton(scroll, "STOP ITEM PULL", UDim2.fromOffset(16, 572), UDim2.fromOffset(278, 32), Color3.fromRGB(120, 55, 68))
local pullStatus = makeLabel(scroll, "Attraction affects only locally movable objects.", UDim2.fromOffset(16, 608), UDim2.fromOffset(278, 28), 9, COLORS.muted, false)
pullStatus.TextWrapped = true

local pullGifts = false
local pullTrees = false
local pullConnection = nil
local scanClock = 0
local pullTargets = {}
local originalPositions = {}

local function isCharacterObject(object)
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        local character = otherPlayer.Character
        if character and (object == character or object:IsDescendantOf(character)) then
            return true
        end
    end
    return false
end

local function getPullRoot(object)
    local current = object
    while current and current.Parent ~= workspace do
        if current:IsA("Model") then
            return current
        end
        current = current.Parent
    end
    if object:IsA("Model") or object:IsA("BasePart") then
        return object
    end
    return nil
end

local function isPullCandidate(object)
    if not (object:IsA("Model") or object:IsA("BasePart")) then return false end
    if isCharacterObject(object) then return false end
    local name = string.lower(object.Name)
    local isGift = string.find(name, "gift", 1, true) ~= nil
    local hasDroppedFlag = object:GetAttribute("Dropped") == true
    local looksLikeDroppedTree = string.find(name, "dropped", 1, true) ~= nil
        or string.find(name, "log", 1, true) ~= nil
        or string.find(name, "wood", 1, true) ~= nil
        or hasDroppedFlag
    local isTree = string.find(name, "tree", 1, true) ~= nil and looksLikeDroppedTree
    return (pullGifts and isGift) or (pullTrees and (isTree or looksLikeDroppedTree))
end

local function getObjectPosition(object)
    if object:IsA("Model") then
        return object:GetPivot().Position
    end
    return object.Position
end

local function moveObjectToward(object, targetPosition, alpha)
    if object:IsA("Model") then
        local pivot = object:GetPivot()
        local nextPosition = pivot.Position:Lerp(targetPosition, alpha)
        object:PivotTo(CFrame.new(nextPosition) * (pivot - pivot.Position))
    elseif object:IsA("BasePart") then
        object.CFrame = object.CFrame:Lerp(CFrame.new(targetPosition) * (object.CFrame - object.Position), alpha)
    end
end

local function restorePullTargets()
    for object, original in pairs(originalPositions) do
        if object and object.Parent then
            pcall(function()
                if object:IsA("Model") then
                    object:PivotTo(original)
                elseif object:IsA("BasePart") then
                    object.CFrame = original
                end
            end)
        end
    end
    table.clear(originalPositions)
    table.clear(pullTargets)
end

local function stopItemPull()
    pullGifts = false
    pullTrees = false
    giftToggle.Text = "PULL GIFTS: OFF"
    treeToggle.Text = "PULL DROPPED TREES: OFF"
    if pullConnection then
        pullConnection:Disconnect()
        pullConnection = nil
    end
    restorePullTargets()
    pullStatus.Text = "Item pull stopped. Local preview positions restored."
end

local function startItemPull()
    if pullConnection then pullConnection:Disconnect() pullConnection = nil end
    if not pullGifts and not pullTrees then
        pullStatus.Text = "Turn on Gifts or Dropped Trees first."
        return
    end
    pullStatus.Text = "Searching nearby gifts and dropped tree items..."
    scanClock = 0
    pullConnection = RunService.Heartbeat:Connect(function(deltaTime)
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        scanClock = scanClock + deltaTime
        if scanClock >= 0.6 then
            scanClock = 0
            table.clear(pullTargets)
            local radius = tonumber(radiusBox.Text) or 35
            radius = math.clamp(radius, 5, 250)
            for _, object in ipairs(workspace:GetDescendants()) do
                if isPullCandidate(object) then
                    local candidate = getPullRoot(object)
                    if candidate and not pullTargets[candidate] then
                        local ok, position = pcall(getObjectPosition, candidate)
                        if ok and (position - root.Position).Magnitude <= radius then
                            pullTargets[candidate] = true
                            if not originalPositions[candidate] then
                                originalPositions[candidate] = candidate:IsA("Model") and candidate:GetPivot() or candidate.CFrame
                            end
                        end
                    end
                end
            end
        end
        for object in pairs(pullTargets) do
            if object and object.Parent then
                pcall(function()
                    local position = getObjectPosition(object)
                    local offset = root.Position - position
                    if offset.Magnitude > 4 then
                        local step = math.min(0.12, deltaTime * 2.5)
                        moveObjectToward(object, root.Position - offset.Unit * 3.5, step)
                    end
                end)
            end
        end
    end)
end

giftToggle.Activated:Connect(function()
    pullGifts = not pullGifts
    giftToggle.Text = pullGifts and "PULL GIFTS: ON" or "PULL GIFTS: OFF"
    if pullGifts or pullTrees then startItemPull() else stopItemPull() end
end)
treeToggle.Activated:Connect(function()
    pullTrees = not pullTrees
    treeToggle.Text = pullTrees and "PULL TREES: ON" or "PULL DROPPED TREES: OFF"
    if pullGifts or pullTrees then startItemPull() else stopItemPull() end
end)
stopPullButton.Activated:Connect(stopItemPull)

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
end)
