-- Dark Side Rotation - Delta Android-friendly client preview
-- Paste into Delta only in a game you are authorized to modify.
-- Changes are local previews; the game may not replicate them to the server.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
assert(player, "Run this from a Roblox client")

local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("DarkSideRotation")
if oldGui then oldGui:Destroy() end

local COLORS = {
    bg = Color3.fromRGB(15, 18, 38),
    panel = Color3.fromRGB(28, 34, 58),
    line = Color3.fromRGB(75, 218, 230),
    text = Color3.fromRGB(250, 250, 255),
    muted = Color3.fromRGB(174, 190, 215),
    accent = Color3.fromRGB(255, 76, 168),
    accentDark = Color3.fromRGB(105, 83, 255),
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
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

local frameGradient = Instance.new("UIGradient")
frameGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(47, 24, 79)),
    ColorSequenceKeypoint.new(0.48, Color3.fromRGB(19, 43, 77)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 27, 48)),
})
frameGradient.Rotation = 35
frameGradient.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.line
stroke.Thickness = 1.5
stroke.Transparency = 0.12
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
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 9)
    local outline = Instance.new("UIStroke")
    outline.Color = color or COLORS.line
    outline.Transparency = color and 0.35 or 0.65
    outline.Thickness = 1
    outline.Parent = button
    if color == COLORS.accent then
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 75, 164)),
            ColorSequenceKeypoint.new(0.52, Color3.fromRGB(145, 91, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 207, 232)),
        })
        gradient.Rotation = 12
        gradient.Parent = button
    end
    return button
end

local dragArea = Instance.new("TextButton")
dragArea.Name = "DragArea"
dragArea.Position = UDim2.fromOffset(0, 0)
dragArea.Size = UDim2.fromOffset(205, 60)
dragArea.BackgroundTransparency = 1
dragArea.Text = ""
dragArea.AutoButtonColor = false
dragArea.ZIndex = 1
dragArea.Parent = frame

local titleLabel = makeLabel(frame, "🌳 DARK SIDE", UDim2.fromOffset(16, 8), UDim2.fromOffset(190, 26), 18, COLORS.text, true)
titleLabel.ZIndex = 2
local subtitleLabel = makeLabel(frame, "SAWMILL CONTROL CENTER", UDim2.fromOffset(17, 34), UDim2.fromOffset(220, 16), 9, COLORS.muted, true)
subtitleLabel.ZIndex = 2
local headerAccent = Instance.new("Frame")
headerAccent.Position = UDim2.fromOffset(16, 52)
headerAccent.Size = UDim2.fromOffset(42, 3)
headerAccent.BackgroundColor3 = COLORS.accent
headerAccent.BorderSizePixel = 0
headerAccent.ZIndex = 2
headerAccent.Parent = frame
local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 83, 164)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(158, 102, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(54, 222, 224)),
})
headerGradient.Parent = headerAccent
Instance.new("UICorner", headerAccent).CornerRadius = UDim.new(1, 0)

local minimizeButton = makeButton(frame, "−", UDim2.new(1, -88, 0, 12), UDim2.fromOffset(40, 30), COLORS.accent)
minimizeButton.Name = "MinimizeButton"
minimizeButton.ZIndex = 3
local closeButton = makeButton(frame, "X", UDim2.new(1, -48, 0, 12), UDim2.fromOffset(34, 30))
closeButton.ZIndex = 3

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ControlsScroll"
scroll.Position = UDim2.fromOffset(0, 54)
scroll.Size = UDim2.new(1, 0, 1, -62)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = COLORS.accent
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.CanvasSize = UDim2.fromOffset(0, 780)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
scroll.Parent = frame

-- Drag the panel using the MOVE handle (works with touch on Android).
local dragging = false
local dragTouch = nil
local dragStart = nil
local panelStart = nil

dragArea.InputBegan:Connect(function(input)
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

local selectedLabel = makeLabel(scroll, "TARGET  •  NONE", UDim2.fromOffset(16, 52), UDim2.fromOffset(278, 20), 11, COLORS.text, true)
local statusCard = Instance.new("Frame")
statusCard.Position = UDim2.fromOffset(14, 76)
statusCard.Size = UDim2.fromOffset(282, 40)
statusCard.BackgroundColor3 = COLORS.panel
statusCard.BackgroundTransparency = 0.15
statusCard.BorderSizePixel = 0
statusCard.Parent = scroll
Instance.new("UICorner", statusCard).CornerRadius = UDim.new(0, 8)
local statusOutline = Instance.new("UIStroke")
statusOutline.Color = COLORS.line
statusOutline.Transparency = 0.55
statusOutline.Parent = statusCard
local statusLabel = makeLabel(statusCard, "Tap Select, then tap a placed structure.", UDim2.fromOffset(10, 3), UDim2.new(1, -20, 1, -6), 10, COLORS.muted, false)
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
Instance.new("UICorner", rotationBox).CornerRadius = UDim.new(0, 8)
local rotationStroke = Instance.new("UIStroke")
rotationStroke.Color = COLORS.line
rotationStroke.Transparency = 0.25
rotationStroke.Parent = rotationBox

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
Instance.new("UICorner", moveBox).CornerRadius = UDim.new(0, 8)
local moveStroke = Instance.new("UIStroke")
moveStroke.Color = COLORS.line
moveStroke.Transparency = 0.25
moveStroke.Parent = moveBox

makeLabel(scroll, "ROTATE", UDim2.fromOffset(16, 198), UDim2.fromOffset(100, 20), 10, COLORS.muted, true)
local axisColors = {
    X = Color3.fromRGB(255, 105, 157),
    Y = Color3.fromRGB(180, 255, 112),
    Z = Color3.fromRGB(77, 218, 255),
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
    selectedLabel.Text = "TARGET  •  NONE"
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
    selectedLabel.Text = "TARGET  •  " .. string.upper(candidate.Name)
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


-- Responsive panel sizing and compact minimize mode.
local minimized = false
local FULL_HEIGHT = 390
local MIN_HEIGHT = 62
frame.Size = UDim2.fromOffset(310, FULL_HEIGHT)

local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local targetHeight = minimized and MIN_HEIGHT or FULL_HEIGHT
    scale.Scale = math.min(1, (viewport.X - 20) / 310, (viewport.Y - 24) / targetHeight)
    frame.Position = UDim2.new(0, math.clamp(frame.Position.X.Offset, 0, math.max(0, viewport.X - 310 * scale.Scale)),
        0, math.clamp(frame.Position.Y.Offset, 0, math.max(0, viewport.Y - targetHeight * scale.Scale)))
end

local function setMinimized(value)
    minimized = value
    scroll.Visible = not minimized
    frame.Size = UDim2.fromOffset(310, minimized and MIN_HEIGHT or FULL_HEIGHT)
    minimizeButton.Text = minimized and "+" or "−"
    updateScale()
end

minimizeButton.Activated:Connect(function()
    setMinimized(not minimized)
end)

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
    treeHighlight:Destroy()
end)
