
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Don't Steal the Brainrots Script",
    SubTitle = "by phemonaz",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})
local Tabs = {
    Farm       = Window:AddTab({ Title = "Farm",       Icon = "bot"     }),
    Upgrades   = Window:AddTab({ Title = "Upgrades",   Icon = "bot"     }),
    Automation = Window:AddTab({ Title = "Automation", Icon = "clock"   }),
    Quests     = Window:AddTab({ Title = "Quests",     Icon = "list"   }),
    Mutation   = Window:AddTab({ Title = "Mutation Machine", Icon = "settings"}),
    Settings   = Window:AddTab({ Title = "Settings",   Icon = "settings"})
}
local Options = Fluent.Options
------------------------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart")
local questEnabled = false
local questInterval = 10
local questTask = nil

local lastBrainrotPrefix = nil
player.CharacterAdded:Connect(function(c)
    character = c
    rootPart  = c:WaitForChild("HumanoidRootPart")
end)
local Remotes = {
    CollectAllCash = ReplicatedStorage:FindFirstChild("CollectAllCash"),
    UpgradeAllNPCs = ReplicatedStorage:FindFirstChild("UpgradeAllNPCs"),
    Rebirth        = ReplicatedStorage.Remotes and ReplicatedStorage.Remotes:FindFirstChild("Rebirth"),
    Spin           = ReplicatedStorage:FindFirstChild("SpinFolder") and ReplicatedStorage.SpinFolder:FindFirstChild("Spin"),
    Recv           = ReplicatedStorage:FindFirstChild("Recv"),
    PlotUpgrade    = ReplicatedStorage.Remotes and ReplicatedStorage.Remotes:FindFirstChild("UpgradePlotEvent"),
}
local function fireRemote(remote, ...)
    if not remote then return false end
    if remote:IsA("RemoteEvent")    then remote:FireServer(...);        return true end
    if remote:IsA("RemoteFunction") then return remote:InvokeServer(...) end
    return false
end
local DataAggregation, Replica
task.spawn(function()
    if not player.Character then player.CharacterAdded:Wait() end
    local ps  = player:FindFirstChild("PlayerScripts")
    local mod = ps and ps:FindFirstChild("ClientLoader") and ps.ClientLoader:FindFirstChild("Modules")
    local da  = mod and mod:FindFirstChild("DataAggregation")
    if da then
        DataAggregation = require(da)
        Replica = DataAggregation.WaitForReplica()
    end
end)
local function getNumericLevel(l)
    if type(l) == "table" then return (l.first * 10^l.second) * (l.sign or 1) end
    return tonumber(l) or 1
end
local function getAllNPCs()
    return (Replica and Replica.Data and Replica.Data.NPCs) or {}
end
local function allNPCsAtOrAboveTarget(tl)
    for _, npc in pairs(getAllNPCs()) do
        if (npc.Location == "TOOLBAR" or npc.Location == "PLOT") and getNumericLevel(npc.Level or 1) < tl then
            return false
        end
    end
    return true
end
local function getLevelInfo()
    if Replica and Replica.Data then
        return getNumericLevel(Replica.Data.Level or 1), Replica.Data.ReqRebirthLevel or 15
    end
    return 1, 15
end
local function getSpinCount()
    if Replica and Replica.Data and Replica.Data.Spin then return Replica.Data.Spin end
    local s = player:FindFirstChild("PlayerStats")
    return s and s:FindFirstChild("Spin") and s.Spin.Value or 0
end
local function tweenTo(position)
    local dist     = (rootPart.Position - position).Magnitude
    local duration = math.clamp(dist / 300, 0.1, 3)
    local tween    = TweenService:Create(rootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = CFrame.new(position) })
    tween:Play()
    tween.Completed:Wait()
end
local function getWorldPos(inst)
    if inst:IsA("Attachment") then return inst.WorldPosition
    elseif inst:IsA("BasePart") then return inst.Position end
    return Vector3.zero
end
local function approachAndFire(prompt)
    for _ = 1, 20 do
        local wp   = getWorldPos(prompt.Parent)
        local dist = (rootPart.Position - wp).Magnitude
        if dist <= 6 then
            fireproximityprompt(prompt)
            return true
        end
        tweenTo(wp + Vector3.new(0, 3, 0))
        task.wait(0.05)
    end
    return false
end
local function getMyPlotPos()
    for i = 1, 5 do
        local ok, pos = pcall(function()
            local face  = workspace.Map.Plots["Plot"..i].OwnerSign.Face
            local label = face.SurfaceGui:FindFirstChild("BaseTextLabel")
            if label and (label.Text == player.DisplayName or label.Text == player.Name) then
                return face.Position + Vector3.new(0, 4, 0)
            end
        end)
        if ok and pos then return pos end
    end
    return nil
end
local function getEquippedTool()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end
local collectEnabled, collectInterval, collectTask = false, 5, nil
local function startAutoCollect()
    if collectTask then task.cancel(collectTask) end
    collectTask = task.spawn(function()
        while collectEnabled do fireRemote(Remotes.CollectAllCash); task.wait(collectInterval) end
    end)
end
local upgradeEnabled, upgradeInterval, targetLevel, upgradeTask = false, 30, 100, nil
local function startAutoUpgrade()
    if upgradeTask then task.cancel(upgradeTask) end
    upgradeTask = task.spawn(function()
        while upgradeEnabled do
            if allNPCsAtOrAboveTarget(targetLevel) then
                Fluent:Notify({ Title = "Auto Upgrade", Content = "All NPCs reached level "..targetLevel.."!", Duration = 3 })
                upgradeEnabled = false; Options.AutoUpgrade:SetValue(false); break
            end
            fireRemote(Remotes.UpgradeAllNPCs)
            task.wait(upgradeInterval)
        end
    end)
end
local rebirthEnabled, rebirthCheckInterval, rebirthTask = false, 10, nil
local function startAutoRebirth()
    if rebirthTask then task.cancel(rebirthTask) end

    rebirthTask = task.spawn(function()
        while rebirthEnabled do
            local args = {
                "REBIRTH"
            }

            game:GetService("ReplicatedStorage")
                :WaitForChild("Remotes")
                :WaitForChild("Rebirth")
                :FireServer(unpack(args))

            task.wait(rebirthCheckInterval)
        end
    end)
end
local spinEnabled, spinTask = false, nil
local function startAutoSpin()
    if spinTask then task.cancel(spinTask) end
    spinTask = task.spawn(function()
        while spinEnabled do
            if getSpinCount() > 0 then fireRemote(Remotes.Spin); task.wait(2) end
            task.wait(5)
        end
    end)
end
local timeRewardsEnabled, timeRewardsTask = false, nil
local function startAutoTimeRewards()
    if timeRewardsTask then task.cancel(timeRewardsTask) end
    timeRewardsTask = task.spawn(function()
        while timeRewardsEnabled do
            if Remotes.Recv then
                local status = fireRemote(Remotes.Recv, "GetTimeRewardsStatus")
                if status and type(status) == "table" then
                    for i, reward in ipairs(status) do
                        if not reward.ClaimUsed and reward.CanClaim then
                            fireRemote(Remotes.Recv, "TimeGift", i); task.wait(0.5)
                        end
                    end
                end
            end
            task.wait(300)
        end
    end)
end
local plotUpgradeEnabled, plotUpgradeTask = false, nil
local function startAutoPlotUpgrade()
    if plotUpgradeTask then task.cancel(plotUpgradeTask) end
    plotUpgradeTask = task.spawn(function()
        while plotUpgradeEnabled do
            fireRemote(Remotes.PlotUpgrade); task.wait(300)
        end
    end)
end
local function startAutoQuest()
    if questTask then task.cancel(questTask) end

    questTask = task.spawn(function()
        while questEnabled do
            game:GetService("ReplicatedStorage")
                :WaitForChild("Remotes")
                :WaitForChild("Quest")
                :FireServer("SUBMIT_NPC")

            task.wait(questInterval)
        end
    end)
end
local questLoopToken = 0
local function isQuestCompleted()
    local ok, result = pcall(function()
        local text = player.PlayerGui.QuestUI.Frame.ProgressBar.Amount.Text
        local pct, cur, tot = text:match("(%d+)%%%s*Completed %((%d+)/(%d+)%)")
        if pct then return pct == "100" and cur == tot end
        return text:match("^(%d+)%%") == "100"
    end)
    return ok and result
end
local function findQuestNPCMatch()
    for _, questNPC in ipairs(workspace.QuestSign.NPCFolder:GetChildren()) do
        for _, mapNPC in ipairs(workspace.Map.Zones.Field.NPC:GetChildren()) do
            if mapNPC:IsA("Model") and mapNPC:GetAttribute("NPCId") == questNPC.Name then
                return mapNPC
            end
        end
    end
    return nil
end
local function findPickupPrompt(model)
    local prompts = model:FindFirstChild("Prompts")
    if not prompts then return nil end
    local pickup = prompts:FindFirstChild("Pickup")
    if pickup and pickup:IsA("ProximityPrompt") and pickup.ActionText == "Steal" then return pickup end
    return nil
end
local function runQuestLoop(token)
    while questLoopToken == token do
        if isQuestCompleted() then print("Quest completed, stopping."); break end
        local target = findQuestNPCMatch()
        if not target then task.wait(1); continue end
        local prompt = findPickupPrompt(target)
        if not prompt then task.wait(0.5); continue end
        local fired = approachAndFire(prompt)
        if not fired or questLoopToken ~= token then task.wait(0.3); continue end
        task.wait(0.3)
        if questLoopToken ~= token then break end
        local plotPos = getMyPlotPos()
        if plotPos then tweenTo(plotPos) end
        task.wait(0.7)
    end
end
local farmLoopToken = 0
local function getSelected(optValue)
    local t = {}
    for v, state in next, optValue do if state then table.insert(t, v) end end
    return t
end
local function getNPCLabels(model)
    local ok, name, mutation, rarity = pcall(function()
        local frame = model.OverheadAttachment.CharacterInfo.Frame
        local m = frame.Mutation.Text
        if m == "Mutation" then m = "Normal" end
        return frame.CharacterName.Text, m, frame.Rarity.Text
    end)
    if ok then return name, mutation, rarity end
    return nil, nil, nil
end
local function farmModelPassesFilter(model)
    local name, mutation, rarity = getNPCLabels(model)
    if not name then return false end
    local mode         = Options.FarmFilterMode.Value
    local excludeMode  = (mode == "Exclude Selected")
    local selNames     = getSelected(Options.FarmFilterNames.Value)
    local selMutations = getSelected(Options.FarmFilterMutations.Value)
    local selRarities  = getSelected(Options.FarmFilterRarities.Value)
    if #selNames == 0 and #selMutations == 0 and #selRarities == 0 then return true end
    local function contains(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
    local matched = contains(selNames, name) or contains(selMutations, mutation) or contains(selRarities, rarity)
    return excludeMode and not matched or not excludeMode and matched
end
local function runFarmLoop(token)
    while farmLoopToken == token do
        local validModels = {}
        for _, model in ipairs(workspace.Map.Zones.Field.NPC:GetChildren()) do
            if model:IsA("Model") and farmModelPassesFilter(model) then
                table.insert(validModels, model)
            end
        end
        if #validModels == 0 then task.wait(1); continue end
        local target = validModels[math.random(1, #validModels)]
        if not target or not target.Parent then task.wait(0.2); continue end
        local prompt = findPickupPrompt(target)
        if not prompt then task.wait(0.3); continue end
        local fired = approachAndFire(prompt)
        if not fired or farmLoopToken ~= token then task.wait(0.3); continue end
        task.wait(0.3)
        if farmLoopToken ~= token then break end
        local plotPos = getMyPlotPos()
        if plotPos then tweenTo(plotPos) end
        task.wait(0.7)
    end
end
local npcNames = {}
pcall(function()
    for _, v in ipairs(ReplicatedStorage.Assets.NPC:GetChildren()) do
        table.insert(npcNames, v.Name)
    end
    table.sort(npcNames)
end)
Tabs.Automation:AddSection("Auto Collect")
Tabs.Automation:AddToggle("AutoCollect", { Title = "Auto Collect Cash", Default = false }):OnChanged(function()
    collectEnabled = Options.AutoCollect.Value
    if collectEnabled then startAutoCollect() elseif collectTask then task.cancel(collectTask); collectTask = nil end
end)
Tabs.Automation:AddSlider("CollectInterval", {
    Title = "Collect Interval", Default = 5, Min = 0.1, Max = 30, Rounding = 1,
    Callback = function(val) collectInterval = val; if collectEnabled then startAutoCollect() end end
})
Tabs.Farm:AddSection("Auto Rebirth")

Tabs.Farm:AddButton({
    Title = "Rebirth",
    Callback = function()
        local args = {
            "REBIRTH"
        }
        game:GetService("ReplicatedStorage")
            :WaitForChild("Remotes")
            :WaitForChild("Rebirth")
            :FireServer(unpack(args))
    end
})

Tabs.Farm:AddToggle("AutoRebirth", { Title = "Auto Rebirth", Default = false }):OnChanged(function()
    rebirthEnabled = Options.AutoRebirth.Value
    if rebirthEnabled then
        startAutoRebirth()
    elseif rebirthTask then
        task.cancel(rebirthTask)
        rebirthTask = nil
    end
end)

Tabs.Farm:AddSlider("RebirthInterval", {
    Title = "Rebirth Interval",
    Default = 10,
    Min = 0.1,
    Max = 30,
    Rounding = 1,
    Callback = function(val)
        rebirthCheckInterval = val
        if rebirthEnabled then startAutoRebirth() end
    end
})
Tabs.Farm:AddSection("Auto Farm")
Tabs.Farm:AddDropdown("FarmFilterMode", {
    Title = "Filter Mode",
    Values = {"Exclude Selected", "Exclude Non-Selected"},
    Multi = false,
    Default = "Exclude Non-Selected",
}):OnChanged(function() end)
Tabs.Farm:AddDropdown("FarmFilterNames", {
    Title = "Name Filter",
    Values = npcNames,
    Multi = true,
    Default = {},
}):OnChanged(function() end)
Tabs.Farm:AddDropdown("FarmFilterMutations", {
    Title = "Mutation Filter",
    Values = {"Normal", "Gold", "Diamond", "Candy", "Blood Moon", "Music", "Galaxy", "Toxic", "Radioactive", "Volcano", "Lava", "Rainbow"},
    Multi = true,
    Default = {},
}):OnChanged(function() end)
Tabs.Farm:AddDropdown("FarmFilterRarities", {
    Title = "Rarity Filter",
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "God", "Secret", "Exclusive"},
    Multi = true,
    Default = {},
}):OnChanged(function() end)
Tabs.Farm:AddToggle("AutoFarmToggle", { Title = "Auto Farm Brainrots", Default = false }):OnChanged(function()
    if Options.AutoFarmToggle.Value then
        farmLoopToken = farmLoopToken + 1
        local token = farmLoopToken
        task.spawn(function()
            local ok, err = pcall(runFarmLoop, token)
            if not ok then warn("AutoFarm error:", err) end
        end)
    else
        farmLoopToken = farmLoopToken + 1
    end
end)
Options.AutoFarmToggle:SetValue(false)
Tabs.Upgrades:AddSection("Auto Upgrade")
Tabs.Upgrades:AddToggle("AutoUpgrade", { Title = "Auto Upgrade Brainrots", Default = false }):OnChanged(function()
    upgradeEnabled = Options.AutoUpgrade.Value
    if upgradeEnabled then startAutoUpgrade() elseif upgradeTask then task.cancel(upgradeTask); upgradeTask = nil end
end)
Tabs.Upgrades:AddSlider("UpgradeInterval", {
    Title = "Upgrade Interval", Default = 30, Min = 0.1, Max = 120, Rounding = 1,
    Callback = function(val) upgradeInterval = val; if upgradeEnabled then startAutoUpgrade() end end
})
Tabs.Upgrades:AddSection("Alert")

local alertMessage = "Teleported successfully!"
local alertType = "SUCCESS"

Tabs.Upgrades:AddInput("AlertText", {
    Title = "Alert Message",
    Default = alertMessage,
    Placeholder = "Enter message...",
    Numeric = false,
    Finished = false,
    Callback = function(val)
        alertMessage = val
    end
})

Tabs.Upgrades:AddDropdown("AlertType", {
    Title = "Alert Type",
    Values = {"SUCCESS", "ERROR"},
    Default = "SUCCESS",
    Multi = false
}):OnChanged(function(val)
    alertType = val
end)

Tabs.Upgrades:AddButton({
    Title = "Send Alert",
    Callback = function()
        local args = {
            "Preset",
            alertType,
            alertMessage
        }

        game:GetService("ReplicatedStorage")
            :WaitForChild("AlertRequest")
            :FireServer(unpack(args))
    end
})
Tabs.Automation:AddSection("Spins & Rewards")
Tabs.Automation:AddToggle("AutoSpin", { Title = "Auto Spin", Default = false }):OnChanged(function()
    spinEnabled = Options.AutoSpin.Value
    if spinEnabled then startAutoSpin() elseif spinTask then task.cancel(spinTask); spinTask = nil end
end)
Tabs.Automation:AddToggle("AutoTimeRewards", { Title = "Auto Claim Free Rewards", Default = false }):OnChanged(function()
    timeRewardsEnabled = Options.AutoTimeRewards.Value
    if timeRewardsEnabled then startAutoTimeRewards() elseif timeRewardsTask then task.cancel(timeRewardsTask); timeRewardsTask = nil end
end)
Tabs.Automation:AddSection("Upgrades")
Tabs.Automation:AddToggle("AutoPlotUpgrade", { Title = "Auto Upgrade Plot", Default = false }):OnChanged(function()
    plotUpgradeEnabled = Options.AutoPlotUpgrade.Value
    if plotUpgradeEnabled then startAutoPlotUpgrade() elseif plotUpgradeTask then task.cancel(plotUpgradeTask); plotUpgradeTask = nil end
end)
Tabs.Quests:AddSection("Quests")

Tabs.Quests:AddButton({
    Title = "Give Quest",
    Callback = function()
        game:GetService("ReplicatedStorage")
            :WaitForChild("Remotes")
            :WaitForChild("Quest")
            :FireServer("SUBMIT_NPC")
    end
})
local questEnabled = false
local questInterval = 10
local questTask = nil

local function startAutoQuest()
    if questTask then task.cancel(questTask) end

    questTask = task.spawn(function()
        while questEnabled do
            game:GetService("ReplicatedStorage")
                :WaitForChild("Remotes")
                :WaitForChild("Quest")
                :FireServer("SUBMIT_NPC")

            task.wait(questInterval)
        end
    end)
end

Tabs.Quests:AddToggle("AutoQuest", {
    Title = "Auto Give Quest",
    Default = false
}):OnChanged(function()
    questEnabled = Options.AutoQuest.Value

    if questEnabled then
        startAutoQuest()
    elseif questTask then
        task.cancel(questTask)
        questTask = nil
    end
end)

Tabs.Quests:AddSlider("QuestInterval", {
    Title = "Quest Interval",
    Default = 10,
    Min = 1,
    Max = 60,
    Rounding = 1,
    Callback = function(val)
        questInterval = val
        if questEnabled then startAutoQuest() end
    end
})
Tabs.Quests:AddSection("Quest Farm")

Tabs.Quests:AddToggle("QuestFarmToggle", {
    Title = "Auto Quest Farm",
    Default = false
}):OnChanged(function()
    if Options.QuestFarmToggle.Value then
        questLoopToken = questLoopToken + 1
        local token = questLoopToken

        task.spawn(function()
            local ok, err = pcall(runQuestLoop, token)
            if not ok then warn("QuestFarm error:", err) end
        end)
    else
        questLoopToken = questLoopToken + 1
    end
end)

Options.QuestFarmToggle:SetValue(false)
Tabs.Mutation:AddButton({
    Title = "Place Brainrot",
    Callback = function()
        local tool = getEquippedTool()

        if tool then
            lastBrainrotPrefix = tool.Name:match("^(.-)%(") or tool.Name
        end

        game:GetService("ReplicatedStorage")
            :WaitForChild("Remotes")
            :WaitForChild("Mutation")
            :FireServer("ADD_NPC")
    end
})

Tabs.Mutation:AddButton({
    Title = "Put Last Brainrot",
    Callback = function()
        if not lastBrainrotPrefix then return end

        local backpack = player:WaitForChild("Backpack")
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        local candidates = {}

        for _, v in ipairs(backpack:GetChildren()) do
            if v:IsA("Tool") and v.Name:sub(1, #lastBrainrotPrefix) == lastBrainrotPrefix then
                table.insert(candidates, v)
            end
        end

        if char then
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Tool") and v.Name:sub(1, #lastBrainrotPrefix) == lastBrainrotPrefix then
                    table.insert(candidates, v)
                end
            end
        end

        if #candidates == 0 then return end

        local chosen = candidates[math.random(1, #candidates)]

        if hum and chosen then
            task.spawn(function()
                task.wait(0.15)
                hum:EquipTool(chosen)

                task.wait(0.5)

                -- SAME ACTION AS "Place Brainrot"
                local args = { "ADD_NPC" }

                game:GetService("ReplicatedStorage")
                    :WaitForChild("Remotes")
                    :WaitForChild("Mutation")
                    :FireServer(unpack(args))
            end)
        end
    end
})
------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
