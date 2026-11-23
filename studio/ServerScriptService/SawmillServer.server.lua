-- Sawmill server system
-- Install in ServerScriptService as SawmillServer.server.lua.
-- Tag each tree MODEL with CollectionService tag "ChoppableTree".
-- Set optional model attributes: TreeType (string), Health (number), MaxHealth (number).
-- Set the IsAxe attribute (boolean true) on each legitimate axe Tool.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local REMOTE_NAME = "SawmillAction"
local MAX_CHOP_DISTANCE = 14
local CHOP_COOLDOWN = 0.45
local DEFAULT_TREE_HEALTH = 5
local LOGS_PER_TREE = 3
local lastChopAt = {}

local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = REMOTE_NAME
    remote.Parent = ReplicatedStorage
end

local function getRoot(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function hasAxeEquipped(player)
    local character = player.Character
    if not character then return false end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            if child:GetAttribute("IsAxe") == true or string.find(string.lower(child.Name), "axe", 1, true) then
                return true
            end
        end
    end
    return false
end

local function getTreePosition(tree)
    if tree:IsA("Model") then
        return tree:GetPivot().Position
    elseif tree:IsA("BasePart") then
        return tree.Position
    end
    return nil
end

local function spawnLog(position, treeType, index)
    local log = Instance.new("Part")
    log.Name = "SawmillLog"
    log.Shape = Enum.PartType.Cylinder
    log.Size = Vector3.new(2, 4, 2)
    log.Material = Enum.Material.Wood
    log.Color = Color3.fromRGB(126, 83, 49)
    log.Anchored = false
    log.CanCollide = true
    local sideOffset = (index - (LOGS_PER_TREE + 1) / 2) * 2.4
    log.CFrame = CFrame.new(position + Vector3.new(sideOffset, 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
    log:SetAttribute("IsSawmillLog", true)
    log:SetAttribute("TreeType", treeType or "Unknown")
    log.Parent = workspace

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Collect log"
    prompt.ObjectText = tostring(treeType or "Wood") .. " log"
    prompt.HoldDuration = 0.25
    prompt.MaxActivationDistance = 10
    prompt.Parent = log

    prompt.Triggered:Connect(function(player)
        if not log.Parent then return end
        local root = getRoot(player)
        if not root or (root.Position - log.Position).Magnitude > 12 then return end
        local stats = player:FindFirstChild("leaderstats")
        local wood = stats and stats:FindFirstChild("Wood")
        if wood and wood:IsA("IntValue") then
            wood.Value += 1
            log:Destroy()
        end
    end)
    Debris:AddItem(log, 120)
end

local function chopTree(player, tree)
    if typeof(tree) ~= "Instance" or not tree:IsDescendantOf(workspace) then return end
    if not CollectionService:HasTag(tree, "ChoppableTree") then return end
    if not (tree:IsA("Model") or tree:IsA("BasePart")) then return end

    local root = getRoot(player)
    local position = getTreePosition(tree)
    if not root or not position or (root.Position - position).Magnitude > MAX_CHOP_DISTANCE then return end
    if not hasAxeEquipped(player) then return end

    local now = os.clock()
    if now - (lastChopAt[player] or 0) < CHOP_COOLDOWN then return end
    lastChopAt[player] = now

    local health = tonumber(tree:GetAttribute("Health")) or DEFAULT_TREE_HEALTH
    health -= 1
    tree:SetAttribute("Health", health)

    if health <= 0 then
        local treeType = tree:GetAttribute("TreeType") or tree.Name
        CollectionService:RemoveTag(tree, "ChoppableTree")
        -- Turn the tree into several collectible logs instead of making it fall.
        for index = 1, LOGS_PER_TREE do
            spawnLog(position, treeType, index)
        end
        tree:Destroy()
    end
end

remote.OnServerEvent:Connect(function(player, action, target)
    if action == "Chop" then
        chopTree(player, target)
    end
end)

Players.PlayerAdded:Connect(function(player)
    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"
    stats.Parent = player

    local wood = Instance.new("IntValue")
    wood.Name = "Wood"
    wood.Value = 0
    wood.Parent = stats
end)

Players.PlayerRemoving:Connect(function(player)
    lastChopAt[player] = nil
end)
