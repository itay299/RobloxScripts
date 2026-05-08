--////////////////////////////////////////////////
-- ALL THE GAMES HUB + COOKIE CLICKER
-- PART 1/3
-- CORE + SAVE + HUB + MAIN GUI
--////////////////////////////////////////////////

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

------------------------------------------------
-- REMOVE OLD GUI
------------------------------------------------

pcall(function()
	if pg:FindFirstChild("ATG_HUB") then
		pg.ATG_HUB:Destroy()
	end
end)

------------------------------------------------
-- SAVE SYSTEM
------------------------------------------------

local folder = "ISCRIPTS"
local gameFolder = folder.."/All The Games"
local saveFile = gameFolder.."/cookie_save.json"

if not isfolder(folder) then
	makefolder(folder)
end

if not isfolder(gameFolder) then
	makefolder(gameFolder)
end

local defaultData = {
	cookies = 0,
	owned = {},
	upgrades = {},
	adminUnlocked = false
}

local data = defaultData

if isfile(saveFile) then
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(readfile(saveFile))
	end)

	if ok and type(decoded) == "table" then
		data = decoded
	end
end

------------------------------------------------
-- CORE VALUES
------------------------------------------------

cookies = data.cookies or 0
owned = data.owned or {}
boughtUpgrades = data.upgrades or {}
adminUnlocked = data.adminUnlocked or false

clickMult = 1
cpsMult = 1
globalMult = 1

cookieGameOpen = false
autoClick = false
autoGolden = false

------------------------------------------------
-- SAVE FUNCTION
------------------------------------------------

function saveData()
	writefile(saveFile,HttpService:JSONEncode({
		cookies = cookies,
		owned = owned,
		upgrades = boughtUpgrades,
		adminUnlocked = adminUnlocked
	}))
end

------------------------------------------------
-- NUMBER FORMATTER
------------------------------------------------

local suffixes = {
	"K","M","B","T","Qa","Qi",
	"Sx","Sp","Oc","No","Dc"
}

function formatNumber(n)

	if n < 1000 then
		return tostring(math.floor(n))
	end

	local i = 1

	while n >= 1000 and i < #suffixes do
		n /= 1000
		i += 1
	end

	local formatted = string.format("%.3f",n)
	formatted = formatted:gsub("0+$","")
	formatted = formatted:gsub("%.$","")

	return formatted..suffixes[i-1]
end

------------------------------------------------
-- BUILDINGS
------------------------------------------------

buildings = {
	{
		name = "Cursor",
		baseCost = 15,
		cps = 0.1,
		emoji = "🖱️"
	},
	{
		name = "Grandma",
		baseCost = 100,
		cps = 1,
		emoji = "👵"
	},
	{
		name = "Farm",
		baseCost = 1100,
		cps = 8,
		emoji = "🌾"
	},
	{
		name = "Mine",
		baseCost = 12000,
		cps = 47,
		emoji = "⛏️"
	},
	{
		name = "Factory",
		baseCost = 130000,
		cps = 260,
		emoji = "🏭"
	},
	{
		name = "Bank",
		baseCost = 1400000,
		cps = 1400,
		emoji = "🏦"
	}
}

buildingMults = {}

for _,b in ipairs(buildings) do
	buildingMults[b.name] = 1
end

------------------------------------------------
-- CPS FUNCTION
------------------------------------------------

function getCPS()

	local total = 0

	for _,b in ipairs(buildings) do
		local amount = owned[b.name] or 0
		total += amount * b.cps * buildingMults[b.name]
	end

	return total * cpsMult * globalMult
end

------------------------------------------------
-- MAIN GUI
------------------------------------------------

gui = Instance.new("ScreenGui")
gui.Name = "ATG_HUB"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = pg

------------------------------------------------
-- HUB
------------------------------------------------

hub = Instance.new("Frame")
hub.Size = UDim2.fromScale(1,1)
hub.BackgroundColor3 = Color3.fromRGB(18,18,18)
hub.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,70)
title.BackgroundTransparency = 1
title.Text = "All The Games"
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.TextColor3 = Color3.new(1,1,1)
title.Parent = hub

------------------------------------------------
-- HUB X BUTTON
------------------------------------------------

local hubX = Instance.new("TextButton")
hubX.Size = UDim2.new(0,50,0,50)
hubX.Position = UDim2.new(1,-60,0,10)
hubX.Text = "X"
hubX.TextScaled = true
hubX.Font = Enum.Font.GothamBlack
hubX.BackgroundColor3 = Color3.fromRGB(170,50,50)
hubX.TextColor3 = Color3.new(1,1,1)
hubX.Parent = hub

hubX.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

------------------------------------------------
-- COOKIE CLICKER APP
------------------------------------------------

cookieApp = Instance.new("TextButton")
cookieApp.Size = UDim2.new(0,130,0,130)
cookieApp.Position = UDim2.new(0,40,0,100)
cookieApp.BackgroundColor3 = Color3.fromRGB(125,85,45)
cookieApp.Text = ""
cookieApp.Parent = hub

local appCorner = Instance.new("UICorner")
appCorner.CornerRadius = UDim.new(0,24)
appCorner.Parent = cookieApp

for i=1,18 do
	local chip = Instance.new("Frame")
	chip.Size = UDim2.new(0,14,0,14)
	chip.Position = UDim2.new(math.random(),-7,math.random(),-7)
	chip.BackgroundColor3 = Color3.fromRGB(60,30,20)
	chip.BorderSizePixel = 0
	chip.Parent = cookieApp

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(1,0)
	cc.Parent = chip
end

local appName = Instance.new("TextLabel")
appName.Size = UDim2.new(0,130,0,30)
appName.Position = UDim2.new(0,40,0,235)
appName.BackgroundTransparency = 1
appName.Text = "Cookie Clicker"
appName.TextScaled = true
appName.Font = Enum.Font.GothamBold
appName.TextColor3 = Color3.new(1,1,1)
appName.Parent = hub

------------------------------------------------
-- COOKIE CLICKER WINDOW
------------------------------------------------

gameFrame = Instance.new("Frame")
gameFrame.Visible = false
gameFrame.Size = UDim2.fromScale(1,1)
gameFrame.BackgroundColor3 = Color3.fromRGB(28,28,28)
gameFrame.Parent = gui

local gameX = Instance.new("TextButton")
gameX.Size = UDim2.new(0,50,0,50)
gameX.Position = UDim2.new(1,-60,0,10)
gameX.Text = "X"
gameX.TextScaled = true
gameX.Font = Enum.Font.GothamBlack
gameX.BackgroundColor3 = Color3.fromRGB(170,50,50)
gameX.TextColor3 = Color3.new(1,1,1)
gameX.Parent = gameFrame

gameX.MouseButton1Click:Connect(function()
	gameFrame.Visible = false
	hub.Visible = true
	cookieGameOpen = false
end)

cookieApp.MouseButton1Click:Connect(function()
	hub.Visible = false
	gameFrame.Visible = true
	cookieGameOpen = true
end)

------------------------------------------------
-- LEFT PANEL
------------------------------------------------

leftPanel = Instance.new("Frame")
leftPanel.Size = UDim2.new(0,350,1,0)
leftPanel.BackgroundColor3 = Color3.fromRGB(35,35,35)
leftPanel.Parent = gameFrame

bigCookie = Instance.new("TextButton")
bigCookie.Size = UDim2.new(0,240,0,240)
bigCookie.Position = UDim2.new(0.5,-120,0.18,0)
bigCookie.BackgroundColor3 = Color3.fromRGB(170,120,60)
bigCookie.Text = ""
bigCookie.Parent = leftPanel

local cookieCorner = Instance.new("UICorner")
cookieCorner.CornerRadius = UDim.new(1,0)
cookieCorner.Parent = bigCookie

for i=1,24 do
	local chip = Instance.new("Frame")
	chip.Size = UDim2.new(0,16,0,16)
	chip.Position = UDim2.new(math.random(),-8,math.random(),-8)
	chip.BackgroundColor3 = Color3.fromRGB(60,30,20)
	chip.BorderSizePixel = 0
	chip.Parent = bigCookie

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(1,0)
	cc.Parent = chip
end

cookieText = Instance.new("TextLabel")
cookieText.Size = UDim2.new(1,0,0,50)
cookieText.Position = UDim2.new(0,0,0.54,0)
cookieText.BackgroundTransparency = 1
cookieText.Text = "0 Cookies"
cookieText.TextScaled = true
cookieText.Font = Enum.Font.GothamBlack
cookieText.TextColor3 = Color3.new(1,1,1)
cookieText.Parent = leftPanel

cpsText = Instance.new("TextLabel")
cpsText.Size = UDim2.new(1,0,0,40)
cpsText.Position = UDim2.new(0,0,0.61,0)
cpsText.BackgroundTransparency = 1
cpsText.Text = "0 CPS"
cpsText.TextScaled = true
cpsText.Font = Enum.Font.Gotham
cpsText.TextColor3 = Color3.new(1,1,1)
cpsText.Parent = leftPanel

------------------------------------------------
-- PART 1 LOADED
------------------------------------------------

print("ATG PART 1 LOADED")
