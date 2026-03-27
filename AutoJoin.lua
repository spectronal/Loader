local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local settings = {
	plrsToJoin = {},
	SelectedGamemode = {},
	AutoJoinPublic = false,
	AutoJoinSelected = false,
}

local Framework = require(game.ReplicatedStorage.Framework.Library)

local GamemodeData = Framework:GetData("GamemodeData")

local PlayersInGamemode = {}
local Gamemodes = {}

local gamemodeFold = workspace:WaitForChild("_MAP"):WaitForChild("Gamemode")

for id in pairs(GamemodeData) do
	table.insert(Gamemodes, id)
end

for _, names in pairs(Players:GetPlayers()) do
	table.insert(PlayersInGamemode, names.Name)
end

local function autoJoinGamemode(gamemode, select)
	if LocalPlayer:GetAttribute("InMode") then
		return
	end

	if select == "Private" then
		for playerName, _ in pairs(settings.plrsToJoin) do
			if not Players[playerName] then
				return
			end

			local player = Players[playerName] or nil
			if player:GetAttribute("Mode") then
				local modeText = player:GetAttribute("Mode")
				if settings.SelectedGamemode[modeText] then
					Framework.Remote:Fire("GamemodeSystem", "Join", modeText, player.UserId)
				end
			end
		end
	elseif select == "Public" then
		for _, playerObj in pairs(Players:GetPlayers()) do
			if not Players[playerObj.Name] then
				return
			end

			local player = Players[playerObj.Name]
			if player:GetAttribute("Mode") then
				local modeText = player:GetAttribute("Mode")
				if settings.SelectedGamemode[modeText] then
					Framework.Remote:Fire("GamemodeSystem", "Join", modeText, player.UserId)
				end
			end
		end
	end
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local KeyWindow = Fluent:CreateWindow({
	Title = "DramaHub",
	SubTitle = "Auto Join",
	TabWidth = 0,
	Size = UDim2.fromOffset(380, 300),
	Acrylic = true,
	Theme = "Darker",
	MinimizeKey = Enum.KeyCode.RightControl,
})

local Tab = KeyWindow:AddTab({ Title = "Auto Join", Icon = "" })

KeyWindow:SelectTab(1)
local selectGamemode = Tab:AddDropdown("selectGamemode", {
	Title = "Select Gamemode",
	Description = "",
	Values = Gamemodes,
	Multi = true,
	Default = {},
})

local selectPlayersToJoin = Tab:AddDropdown("selectPlayersToJoin", {
	Title = "Select Player's Party to Join",
	Description = "Select players to join the gamemode",
	Values = PlayersInGamemode,
	Multi = true,
	Default = {},
})

Tab:AddButton({
	Title = "Refresh Players List",
	Callback = function()
		table.clear(PlayersInGamemode)

		for _, names in pairs(Players:GetPlayers()) do
			table.insert(PlayersInGamemode, names.Name)
		end

		selectPlayersToJoin:SetValue(PlayersInGamemode)
	end,
})

Tab:AddToggle("autoJoinSelected", {
	Title = "Auto Join Gamemode (Selected Players)",
	Default = false,
	Callback = function(state)
		settings.AutoJoinSelected = state
	end,
})

Tab:AddToggle("autoJoinPublic", {
	Title = "Auto Join Gamemode (Public)",
	Default = false,
	Callback = function(state)
		settings.AutoJoinPublic = state
	end,
})

selectGamemode:OnChanged(function(Value)
	settings.SelectedGamemode = Value
end)

selectPlayersToJoin:OnChanged(function(Value)
	settings.plrsToJoin = Value
end)

task.spawn(function()
	while true do
		task.wait()
		if settings.AutoJoinPublic then
			autoJoinGamemode(gamemodeFold, "Public")
		end

		if settings.AutoJoinSelected then
			autoJoinGamemode(gamemodeFold, "Private")
		end
	end
end)
