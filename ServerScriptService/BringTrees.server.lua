-- BringTrees.server.lua
-- Install this Script in ServerScriptService in your own Roblox experience.
-- Recognized trees must be Models named with "tree", have a TreeType string
-- attribute, or have IsTree = true as a boolean attribute.
-- The server owns the movement; the client cannot choose arbitrary instances.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:FindFirstChild("BringTreesRequest")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "BringTreesRequest"
    remote.Parent = ReplicatedStorage
end

local MAX_DISTANCE = 120
local MAX_TREES_PER_REQUEST = 8
local COOLDOWN = 4
local SPACING = 7
local lastRequest = {}

local function isTreeModel(instance)
    if not instance:IsA("Model") then
        return false
    end

    if instance:GetAttribute("IsTree") == true then
        return true
    end

    local treeType = instance:GetAttribute("TreeType")
    if typeof(treeType) == "string" and treeType ~= "" then
        return true
    end

    return string.find(string.lower(instance.Name), "tree", 1, true) ~= nil
end

local function hasBasePart(model)
    return model:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

remote.OnServerEvent:Connect(function(player)
    local now = os.clock()
    if lastRequest[player] and now - lastRequest[player] < COOLDOWN then
        return
    end
    lastRequest[player] = now

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local candidates = {}
    for _, instance in ipairs(workspace:GetDescendants()) do
        if isTreeModel(instance) and hasBasePart(instance)
            and not (character and instance:IsDescendantOf(character)) then
            local ok, pivot = pcall(function()
                return instance:GetPivot()
            end)
            if ok then
                local distance = (pivot.Position - root.Position).Magnitude
                if distance <= MAX_DISTANCE then
                    table.insert(candidates, {
                        model = instance,
                        distance = distance,
                    })
                end
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.distance < b.distance
    end)

    local moved = 0
    for _, entry in ipairs(candidates) do
        if moved >= MAX_TREES_PER_REQUEST then
            break
        end

        local model = entry.model
        if model.Parent then
            local angle = (moved / MAX_TREES_PER_REQUEST) * math.pi * 2
            local offset = Vector3.new(math.cos(angle) * SPACING, 0, math.sin(angle) * SPACING)
            local destination = root.Position + offset
            local currentPivot = model:GetPivot()
            local rotation = currentPivot - currentPivot.Position
            local target = CFrame.new(destination) * rotation

            local ok = pcall(function()
                model:PivotTo(target)
            end)
            if ok then
                moved += 1
            end
        end
    end

    -- Server output is visible to all players. A client status label can be
    -- added later if you want exact moved-count feedback.
    print(("[BringTrees] %s brought %d nearby tree model(s)."):format(player.Name, moved))
end)

Players.PlayerRemoving:Connect(function(player)
    lastRequest[player] = nil
end)
