--////////////////////////////////////////////////
-- ALL THE GAMES HUB + COOKIE CLICKER
--////////////////////////////////////////////////

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

pcall(function()
	if pg:FindFirstChild("ATG_HUB") then
		pg.ATG_HUB:Destroy()
	end
end)

local function formatNumber(n)
	if n < 1000 then
		return tostring(math.floor(n))
	end

	local suffixes = {"K","M","B","T","Qa","Qi"}
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

print(formatNumber(1400000))
print("ATG loaded")
