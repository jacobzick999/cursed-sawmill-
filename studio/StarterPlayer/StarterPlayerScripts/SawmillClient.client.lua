-- Sawmill Studio client controller
-- Install in StarterPlayer > StarterPlayerScripts as SawmillClient.client.lua.
-- This UI talks to the server-owned SawmillAction RemoteEvent.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("SawmillAction")
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("SawmillControlPanel")
if old then old:Destroy() end

local colors = {
    background = Color3.fromRGB(18, 20, 39),
    surface = Color3.fromRGB(34, 38, 66),
    accent = Color3.fromRGB(239, 76, 170),
    cyan = Color3.fromRGB(76, 218, 230),
    text = Color3.fromRGB(248, 248, 255),
    muted = Color3.fromRGB(180, 190, 215),
}

local gui = Instance.new("ScreenGui")
gui.Name = "SawmillControlPanel"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(300, 440)
panel.Position = UDim2.new(0, 16, 0.5, -220)
panel.BackgroundColor3 = colors.background
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
local outline = Instance.new("UIStroke")
outline.Color = colors.cyan
outline.Thickness = 1.5
outline.Parent = panel

local header = Instance.new("TextButton")
header.Size = UDim2.new(1, -96, 0, 58)
header.BackgroundTransparency = 1
header.Text = "🌳  SAWMILL CONTROL"
header.TextColor3 = colors.text
header.Font = Enum.Font.GothamBold
header.TextSize = 16
header.Parent = panel

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(34, 30)
minimize.Position = UDim2.new(1, -78, 0, 12)
minimize.Text = "−"
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 20
minimize.TextColor3 = colors.text
minimize.BackgroundColor3 = colors.surface
minimize.Parent = panel
Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 8)

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(34, 30)
close.Position = UDim2.new(1, -38, 0, 12)
close.Text = "×"
close.Font = Enum.Font.GothamBold
close.TextSize = 18
close.TextColor3 = colors.text
close.BackgroundColor3 = colors.surface
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(12, 64)
content.Size = UDim2.new(1, -24, 1, -76)
content.BackgroundTransparency = 1
content.Parent = panel

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 42)
status.BackgroundColor3 = colors.surface
status.TextColor3 = colors.muted
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextWrapped = true
status.Text = "Ready. Trees need the ChoppableTree tag."
status.Parent = content
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 8)

local function makeButton(text, y, callback)
    local button = Instance.new("TextButton")
    button.Position = UDim2.fromOffset(0, y)
    button.Size = UDim2.new(1, 0, 0, 34)
    button.BackgroundColor3 = colors.surface
    button.TextColor3 = colors.text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.Text = text
    button.Parent = content
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    button.Activated:Connect(callback)
    return button
end

local function getRoot()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getTreePosition(tree)
    if tree:IsA("Model") then return tree:GetPivot().Position end
    if tree:IsA("BasePart") then return tree.Position end
end

local treeHighlights = {}
local finderOn = false
local autoCutOn = false
local savedPosition = nil

local function clearHighlights()
    for tree, marker in pairs(treeHighlights) do
        if marker then marker:Destroy() end
        treeHighlights[tree] = nil
    end
end

local function getTaggedTrees()
    local result = {}
    for _, tree in ipairs(CollectionService:GetTagged("ChoppableTree")) do
        if tree:IsDescendantOf(workspace) then
            table.insert(result, tree)
        end
    end
    return result
end

local function nearestTree()
    local root = getRoot()
    if not root then return nil end
    local best, bestDistance
    for _, tree in ipairs(getTaggedTrees()) do
        local position = getTreePosition(tree)
        if position then
            local distance = (root.Position - position).Magnitude
            if distance <= 120 and (not bestDistance or distance < bestDistance) then
                best, bestDistance = tree, distance
            end
        end
    end
    return best, bestDistance
end

local finderButton
finderButton = makeButton("START TREE FINDER", 54, function()
    finderOn = not finderOn
    finderButton.Text = finderOn and "STOP TREE FINDER" or "START TREE FINDER"
    if not finderOn then clearHighlights() end
end)

local autoButton
autoButton = makeButton("START AUTO-CUT", 96, function()
    autoCutOn = not autoCutOn
    autoButton.Text = autoCutOn and "STOP AUTO-CUT" or "START AUTO-CUT"
    status.Text = autoCutOn and "Auto-cut running. Equip an axe and stay near trees." or "Auto-cut stopped."
end)

makeButton("EQUIP AXE", 138, function()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not humanoid or not backpack then status.Text = "Character or backpack not ready." return end
    local equipped = character:FindFirstChildOfClass("Tool")
    if equipped and (equipped:GetAttribute("IsAxe") == true or string.find(string.lower(equipped.Name), "axe", 1, true)) then
        status.Text = "Axe already equipped."
        return
    end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool:GetAttribute("IsAxe") == true or string.find(string.lower(tool.Name), "axe", 1, true)) then
            humanoid:EquipTool(tool)
            status.Text = "Axe equipped."
            return
        end
    end
    status.Text = "No axe found. Add an Axe Tool to StarterPack."
end)

makeButton("SAVE CURRENT LOCATION", 180, function()
    local root = getRoot()
    if not root then status.Text = "Character not ready." return end
    savedPosition = root.Position
    status.Text = "Location saved."
end)

makeButton("WALK BACK TO SAVED LOCATION", 222, function()
    if not savedPosition then status.Text = "Save a location first." return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = getRoot()
    if not humanoid or not root then status.Text = "Character not ready." return end
    local path = PathfindingService:CreatePath()
    local ok = pcall(function() path:ComputeAsync(root.Position, savedPosition) end)
    if not ok or path.Status ~= Enum.PathStatus.Success then
        status.Text = "No walking path found. Try a closer saved location."
        return
    end
    status.Text = "Walking back..."
    for _, waypoint in ipairs(path:GetWaypoints()) do
        if not gui.Parent or not humanoid.Parent then return end
        if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
        humanoid:MoveTo(waypoint.Position)
        local reached = humanoid.MoveToFinished:Wait()
        if not reached then status.Text = "Path blocked." return end
    end
    status.Text = "Returned to saved location."
end)

local themeIndex = 1
local themes = {
    {background = Color3.fromRGB(18,20,39), surface = Color3.fromRGB(34,38,66), accent = Color3.fromRGB(239,76,170), cyan = Color3.fromRGB(76,218,230)},
    {background = Color3.fromRGB(24,38,27), surface = Color3.fromRGB(43,65,45), accent = Color3.fromRGB(95,210,112), cyan = Color3.fromRGB(172,245,130)},
    {background = Color3.fromRGB(40,25,20), surface = Color3.fromRGB(73,48,36), accent = Color3.fromRGB(238,133,67), cyan = Color3.fromRGB(255,200,115)},
}
makeButton("CHANGE PANEL THEME", 264, function()
    themeIndex = themeIndex % #themes + 1
    local theme = themes[themeIndex]
    panel.BackgroundColor3 = theme.background
    outline.Color = theme.cyan
    for _, item in ipairs(content:GetChildren()) do
        if item:IsA("TextButton") or item:IsA("TextLabel") then
            item.BackgroundColor3 = theme.surface
        end
    end
    status.Text = "Theme changed."
end)

makeButton("SCAN TREE TYPES", 306, function()
    local counts = {}
    for _, tree in ipairs(getTaggedTrees()) do
        local treeType = tostring(tree:GetAttribute("TreeType") or tree.Name)
        counts[treeType] = (counts[treeType] or 0) + 1
    end
    local total = 0
    for _, count in pairs(counts) do total += count end
    status.Text = "Found " .. total .. " tagged trees across " .. tostring(#(function() local t={} for name in pairs(counts) do table.insert(t,name) end return t end)()) .. " types."
end)

local minimized = false
minimize.Activated:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    panel.Size = UDim2.fromOffset(300, minimized and 58 or 440)
    minimize.Text = minimized and "+" or "−"
end)
close.Activated:Connect(function() gui:Destroy() end)

-- Touch + mouse drag from the header.
local dragging, dragInput, dragStart, startPosition
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragInput = input
        dragStart = input.Position
        startPosition = panel.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    local mouseMove = input.UserInputType == Enum.UserInputType.MouseMovement
    local touchMove = input.UserInputType == Enum.UserInputType.Touch and input == dragInput
    if not mouseMove and not touchMove then return end
    local delta = input.Position - dragStart
    panel.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
end)
UserInputService.InputEnded:Connect(function(input)
    if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

task.spawn(function()
    while gui.Parent do
        if finderOn then
            local trees = getTaggedTrees()
            local root = getRoot()
            local count = 0
            if root then
                for _, tree in ipairs(trees) do
                    local position = getTreePosition(tree)
                    if position and (position - root.Position).Magnitude <= 120 then
                        count += 1
                        if not treeHighlights[tree] then
                            local marker = Instance.new("Highlight")
                            marker.FillColor = Color3.fromRGB(80, 255, 140)
                            marker.OutlineColor = Color3.fromRGB(210, 255, 220)
                            marker.FillTransparency = 0.8
                            marker.Adornee = tree
                            marker.Parent = workspace
                            treeHighlights[tree] = marker
                        end
                    end
                end
            end
            status.Text = "Tree finder: highlighted " .. count .. " nearby trees."
            for tree, marker in pairs(treeHighlights) do
                if not tree:IsDescendantOf(workspace) or not finderOn then
                    marker:Destroy()
                    treeHighlights[tree] = nil
                end
            end
        end
        if autoCutOn then
            local tree, distance = nearestTree()
            if tree and distance and distance <= 14 then
                remote:FireServer("Chop", tree)
                status.Text = "Chopping: " .. tostring(tree:GetAttribute("TreeType") or tree.Name)
            elseif tree then
                status.Text = "Nearest tree is " .. math.floor(distance) .. " studs away. Move closer."
            else
                status.Text = "No tagged trees found."
            end
        end
        task.wait(0.5)
    end
end)

gui.Destroying:Connect(function()
    finderOn = false
    autoCutOn = false
    clearHighlights()
end)
