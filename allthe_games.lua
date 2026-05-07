-- ALL THE GAMES HUB + COOKIE CLICKER

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

pcall(function()
	if pg:FindFirstChild("ATG_HUB") then
		pg.ATG_HUB:Destroy()
	end
end)

local cookies = 0
local owned = {}
local boughtUpgrades = {}

local secretSequence = {}
local secretGoal = {
	"Grandma",
	"Grandma",
	"Cursor",
	"Cursor",
	"Cursor",
	"Cursor",
	"Cursor",
	"Farm",
	"Farm"
}

local adminUnlocked = false
local autoClick = false
local autoGolden = false

local suffixes = {
	"K","M","B","T","Qa","Qi"
}

local function formatNumber(n)
	if n < 1000 then
		return tostring(math.floor(n))
	end

	local i = 1

	while n >= 1000 and i < #suffixes do
		n /= 1000
		i += 1
	end

	local formatted = string.format("%.3f", n)
	formatted = formatted:gsub("0+$","")
	formatted = formatted:gsub("%.$","")

	return formatted..suffixes[i-1]
end

local gui = Instance.new("ScreenGui")
gui.Name = "ATG_HUB"
gui.ResetOnSpawn = false
gui.Parent = pg

local hub = Instance.new("Frame")
hub.Size = UDim2.fromScale(1,1)
hub.BackgroundColor3 = Color3.fromRGB(20,20,20)
hub.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,60)
title.BackgroundTransparency = 1
title.Text = "All The Games"
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBlack
title.Parent = hub

local app = Instance.new("TextButton")
app.Size = UDim2.new(0,120,0,120)
app.Position = UDim2.new(0,40,0,100)
app.Text = ""
app.BackgroundColor3 = Color3.fromRGB(120,80,40)
app.Parent = hub

local appCorner = Instance.new("UICorner")
appCorner.CornerRadius = UDim.new(0,20)
appCorner.Parent = app

for i=1,15 do
	local chip = Instance.new("Frame")
	chip.Size = UDim2.new(0,12,0,12)
	chip.Position = UDim2.new(math.random(),-6,math.random(),-6)
	chip.BackgroundColor3 = Color3.fromRGB(70,40,20)
	chip.BorderSizePixel = 0
	chip.Parent = app

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(1,0)
	cc.Parent = chip
end

local adminButton = Instance.new("TextButton")
adminButton.Visible = false
adminButton.Size = UDim2.new(0,120,0,40)
adminButton.Position = UDim2.new(0.5,-60,0.1,0)
adminButton.Text = "Admin"
adminButton.TextScaled = true
adminButton.BackgroundColor3 = Color3.fromRGB(150,50,50)
adminButton.TextColor3 = Color3.new(1,1,1)
adminButton.Parent = hub

local adminPanel = Instance.new("Frame")
adminPanel.Visible = false
adminPanel.Size = UDim2.new(0,260,0,320)
adminPanel.Position = UDim2.new(0.5,-130,0.2,0)
adminPanel.BackgroundColor3 = Color3.fromRGB(35,35,35)
adminPanel.Parent = hub

local addBox = Instance.new("TextBox")
addBox.PlaceholderText = "Add Cookies"
addBox.Size = UDim2.new(1,-20,0,40)
addBox.Position = UDim2.new(0,10,0,10)
addBox.Text = ""
addBox.Parent = adminPanel

local addButton = Instance.new("TextButton")
addButton.Size = UDim2.new(1,-20,0,40)
addButton.Position = UDim2.new(0,10,0,60)
addButton.Text = "Add Cookies 🍪"
addButton.Parent = adminPanel

local autoClickButton = Instance.new("TextButton")
autoClickButton.Size = UDim2.new(1,-20,0,40)
autoClickButton.Position = UDim2.new(0,10,0,110)
autoClickButton.Text = "Auto Click: OFF"
autoClickButton.Parent = adminPanel

local autoGoldenButton = Instance.new("TextButton")
autoGoldenButton.Size = UDim2.new(1,-20,0,40)
autoGoldenButton.Position = UDim2.new(0,10,0,160)
autoGoldenButton.Text = "Auto Golden: OFF"
autoGoldenButton.Parent = adminPanel

local ruinButton = Instance.new("TextButton")
ruinButton.Size = UDim2.new(1,-20,0,40)
ruinButton.Position = UDim2.new(0,10,0,210)
ruinButton.Text = "Ruin The Fun"
ruinButton.Parent = adminPanel

adminButton.MouseButton1Click:Connect(function()
	adminPanel.Visible = not adminPanel.Visible
end)

addButton.MouseButton1Click:Connect(function()
	local num = tonumber(addBox.Text)

	if num then
		cookies += num
	end
end)

autoClickButton.MouseButton1Click:Connect(function()
	autoClick = not autoClick
	autoClickButton.Text = "Auto Click: "..(autoClick and "ON" or "OFF")
end)

autoGoldenButton.MouseButton1Click:Connect(function()
	autoGolden = not autoGolden
	autoGoldenButton.Text = "Auto Golden: "..(autoGolden and "ON" or "OFF")
end)

ruinButton.MouseButton1Click:Connect(function()
	local buildings = {
		"Cursor",
		"Grandma",
		"Farm"
	}

	for _,v in ipairs(buildings) do
		owned[v] = 10000
	end

	for i=1,100 do
		boughtUpgrades["Upgrade"..i] = true
	end

	cookies = 1e30
end)

print("ATG massive update loaded")