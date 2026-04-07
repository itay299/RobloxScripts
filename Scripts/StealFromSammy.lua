local Xeno = loadstring(game:HttpGet("https://raw.githubusercontent.com/itay299/RobloxScripts/main/Scripts/!MyLibrary"))()
local UI = Xeno:Create("Steal From Sammy", "sammy_script")

local player = game.Players.LocalPlayer

-- REMOVE REBIRTH BARRIERS
UI:Button("Remove Rebirth Requirements", function()
    local barriers = workspace:FindFirstChild("Map")
        and workspace.Map:FindFirstChild("RebirthBarriers")

    if barriers then
        for _, v in pairs(barriers:GetChildren()) do
            v:Destroy()
        end
    end
end)

-- GO TO END
UI:Button("Go to End", function()
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(227.85, 199.01, -171.62)
    end
end)

-- GO TO SPAWN
UI:Button("Go to Spawn", function()
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(-69.56, 3.70, -154.46)
    end
end)

-- AUTO GIGA
local autoGiga = false

local regionMin = Vector3.new(185.88, 226, -195.38)
local regionMax = Vector3.new(264.71, 239.30, -116.62)

local afterTP = CFrame.new(-50.36, 3.70, -329.32)

local function inRegion(pos)
    return pos.X >= math.min(regionMin.X, regionMax.X)
        and pos.X <= math.max(regionMin.X, regionMax.X)
        and pos.Y >= math.min(regionMin.Y, regionMax.Y)
        and pos.Y <= math.max(regionMin.Y, regionMax.Y)
        and pos.Z >= math.min(regionMin.Z, regionMax.Z)
        and pos.Z <= math.max(regionMin.Z, regionMax.Z)
end

local function getPrompt()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local parent = v.Parent
            if parent and parent:IsA("BasePart") then
                if inRegion(parent.Position) then
                    return v, parent
                end
            end
        end
    end
end

local function usePrompt(prompt)
    if not prompt then return end
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.1)
        prompt:InputHoldEnd()
    end)
end

UI:Toggle("Auto Giga", false, function(v)
    autoGiga = v
end)

task.spawn(function()
    while true do
        if autoGiga then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local prompt, part = getPrompt()

                if prompt and part then
                    local hrp = char.HumanoidRootPart

                    -- 1. TP to prox
                    hrp.CFrame = part.CFrame

                    -- 2. wait 0.3
                    task.wait(0.3)

                    -- 3. use prox prompt
                    usePrompt(prompt)

                    -- 4. wait 0.5
                    task.wait(0.5)

                    -- 5. TP to afterTP
                    hrp.CFrame = afterTP
                end
            end
        end
        task.wait(1)
    end
end)
