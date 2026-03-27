-- DramaHub Auto Join
-- UI nativa Roblox, sem dependencias externas

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer    = Players.LocalPlayer
local PlayerGui      = LocalPlayer:WaitForChild("PlayerGui")

local Framework    = require(game.ReplicatedStorage.Framework.Library)
local GamemodeData = Framework:GetData("GamemodeData")

local settings = {
	plrsToJoin      = {},
	SelectedGamemode = {},
	AutoJoinPublic   = false,
	AutoJoinSelected = false,
}

local Gamemodes         = {}
local PlayersInGamemode = {}

for id in pairs(GamemodeData) do
	table.insert(Gamemodes, id)
end

local function refreshPlayersList()
	table.clear(PlayersInGamemode)
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(PlayersInGamemode, p.Name)
		end
	end
end
refreshPlayersList()

-- AUTO JOIN
local function autoJoinGamemode(mode)
	if LocalPlayer:GetAttribute("InMode") then return end
	if mode == "Private" then
		for playerName in pairs(settings.plrsToJoin) do
			local player = Players:FindFirstChild(playerName)
			if player and player:GetAttribute("Mode") then
				local modeText = player:GetAttribute("Mode")
				if settings.SelectedGamemode[modeText] then
					Framework.Remote:Fire("GamemodeSystem", "Join", modeText, player.UserId)
				end
			end
		end
	elseif mode == "Public" then
		for _, player in pairs(Players:GetPlayers()) do
			if player:GetAttribute("Mode") then
				local modeText = player:GetAttribute("Mode")
				if settings.SelectedGamemode[modeText] then
					Framework.Remote:Fire("GamemodeSystem", "Join", modeText, player.UserId)
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(0.1)
		if settings.AutoJoinPublic   then autoJoinGamemode("Public")  end
		if settings.AutoJoinSelected then autoJoinGamemode("Private") end
	end
end)

-- ============================================================
--  COLORS
-- ============================================================
local BG        = Color3.fromRGB(16,  16,  20 )
local SURFACE   = Color3.fromRGB(26,  26,  33 )
local SURFACE2  = Color3.fromRGB(34,  34,  44 )
local SURFACE3  = Color3.fromRGB(20,  20,  28 )
local BORDER    = Color3.fromRGB(55,  55,  70 )
local ACCENT    = Color3.fromRGB(127, 119, 221)
local ACCENT2   = Color3.fromRGB(93,  202, 165)
local TEXT      = Color3.fromRGB(220, 220, 228)
local MUTED     = Color3.fromRGB(110, 110, 128)
local HINT      = Color3.fromRGB(55,  55,  70 )
local TOG_ON    = Color3.fromRGB(127, 119, 221)
local TOG_OFF   = Color3.fromRGB(50,  50,  64 )
local TAG_BG    = Color3.fromRGB(36,  33,  65 )
local TAG_BD    = Color3.fromRGB(75,  68,  130)
local TAG_TEXT  = Color3.fromRGB(175, 169, 236)
local WHITE     = Color3.fromRGB(255, 255, 255)
local GREEN     = Color3.fromRGB(93,  202, 165)

-- ============================================================
--  HELPERS
-- ============================================================
local function new(cls, props, parent)
	local o = Instance.new(cls)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

-- bare frame (no border, no auto-color)
local function fr(props, parent)
	props.BorderSizePixel = 0
	if props.BackgroundColor3 == nil then props.BackgroundTransparency = 1 end
	return new("Frame", props, parent)
end

local function lbl(props, parent)
	props.BorderSizePixel = 0
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font       = props.Font       or Enum.Font.GothamMedium
	props.TextSize   = props.TextSize   or 13
	props.TextColor3 = props.TextColor3 or TEXT
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return new("TextLabel", props, parent)
end

-- invisible clickable button (NO AutoButtonColor quirks)
local function hitBtn(parent, zIndex)
	return new("TextButton", {
		Size = UDim2.new(1,0,1,0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = zIndex or 10,
	}, parent)
end

local function corner(r, p)  new("UICorner",  { CornerRadius = UDim.new(0,r) }, p) end
local function stroke(c, t, p) new("UIStroke", { Color=c, Thickness=t, ApplyStrokeMode=Enum.ApplyStrokeMode.Border }, p) end
local function pad(t,r,b,l,p)
	new("UIPadding",{PaddingTop=UDim.new(0,t),PaddingRight=UDim.new(0,r),PaddingBottom=UDim.new(0,b),PaddingLeft=UDim.new(0,l)},p)
end
local function vlist(gap, p) new("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,gap)},p) end
local function tw(obj,t,props) TweenService:Create(obj,TweenInfo.new(t),props):Play() end

-- ============================================================
--  SCREEN + WINDOW
-- ============================================================
local Screen = new("ScreenGui",{
	Name = "DramaHubAutoJoin",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	DisplayOrder = 9999,
	IgnoreGuiInset = true,
}, PlayerGui)

local W, H = 380, 356

local Window = fr({
	Size = UDim2.fromOffset(W, H),
	Position = UDim2.new(0.5,-W/2, 0.5,-H/2),
	BackgroundColor3 = BG,
	ClipsDescendants = true,
	ZIndex = 1,
}, Screen)
corner(10, Window)
stroke(BORDER, 1, Window)

-- ============================================================
--  DRAG (title bar area only, top 48px)
-- ============================================================
do
	local dragging, ds, ws
	Window.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if (inp.Position.Y - Window.AbsolutePosition.Y) > 48 then return end
		dragging = true
		ds = Vector2.new(inp.Position.X, inp.Position.Y)
		ws = Vector2.new(Window.AbsolutePosition.X, Window.AbsolutePosition.Y)
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = Vector2.new(inp.Position.X, inp.Position.Y) - ds
			Window.Position = UDim2.fromOffset(ws.X + d.X, ws.Y + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end

-- ============================================================
--  TITLE BAR
-- ============================================================
local TitleBar = fr({ Size=UDim2.new(1,0,0,48), BackgroundColor3=Color3.fromRGB(19,19,25), ZIndex=2 }, Window)
-- bottom border
fr({ Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=BORDER, ZIndex=3 }, TitleBar)

local Dot = fr({ Size=UDim2.fromOffset(20,20), Position=UDim2.new(0,14,0.5,-10), BackgroundColor3=ACCENT, ZIndex=3 }, TitleBar)
corner(10, Dot)
new("UIGradient",{ Color=ColorSequence.new({ColorSequenceKeypoint.new(0,ACCENT),ColorSequenceKeypoint.new(1,ACCENT2)}), Rotation=135 }, Dot)

lbl({ Text="DramaHub", Size=UDim2.new(0,180,0,18), Position=UDim2.new(0,42,0,8), Font=Enum.Font.GothamBold, TextSize=14, TextColor3=Color3.fromRGB(240,240,248), ZIndex=3 }, TitleBar)
lbl({ Text="Auto Join", Size=UDim2.new(0,180,0,14), Position=UDim2.new(0,42,0,27), Font=Enum.Font.Gotham, TextSize=11, TextColor3=MUTED, ZIndex=3 }, TitleBar)
lbl({ Text="[RCtrl] minimizar", Size=UDim2.new(0,130,0,14), Position=UDim2.new(1,-144,0.5,-7), Font=Enum.Font.Gotham, TextSize=10, TextXAlignment=Enum.TextXAlignment.Right, TextColor3=HINT, ZIndex=3 }, TitleBar)

-- ============================================================
--  TAB BAR
-- ============================================================
local TabBar = fr({ Size=UDim2.new(1,0,0,32), Position=UDim2.new(0,0,0,48), BackgroundColor3=Color3.fromRGB(17,17,22), ZIndex=2 }, Window)
fr({ Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=BORDER, ZIndex=3 }, TabBar)
lbl({ Text="Auto Join", Size=UDim2.fromOffset(90,32), Position=UDim2.new(0,14,0,0), Font=Enum.Font.GothamMedium, TextSize=12, TextColor3=ACCENT, ZIndex=3 }, TabBar)
local tabLine = fr({ Size=UDim2.fromOffset(72,2), Position=UDim2.new(0,23,1,-2), BackgroundColor3=ACCENT, ZIndex=3 }, TabBar)
corner(2, tabLine)

-- ============================================================
--  CONTENT (ScrollingFrame, starts at Y=80)
-- ============================================================
local CONTENT_H = H - 80 - 26
local Content = new("ScrollingFrame",{
	Size = UDim2.new(1,0,0,CONTENT_H),
	Position = UDim2.new(0,0,0,80),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = BORDER,
	CanvasSize = UDim2.new(0,0,0,0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 2,
}, Window)
vlist(10, Content)
pad(12,14,12,14, Content)

-- ============================================================
--  STATUS BAR
-- ============================================================
local StatusBar = fr({ Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,0,1,-26), BackgroundColor3=Color3.fromRGB(13,13,17), ZIndex=2 }, Window)
fr({ Size=UDim2.new(1,0,0,1), BackgroundColor3=BORDER, ZIndex=3 }, StatusBar)
pad(0,0,0,14, StatusBar)

local StatusDot = fr({ Size=UDim2.fromOffset(6,6), Position=UDim2.new(0,0,0.5,-3), BackgroundColor3=HINT, ZIndex=3 }, StatusBar)
corner(3, StatusDot)
local StatusLabel = lbl({ Text="Inativo", Size=UDim2.new(1,-18,1,0), Position=UDim2.new(0,14,0,0), Font=Enum.Font.Gotham, TextSize=10, TextColor3=MUTED, ZIndex=3 }, StatusBar)

local function updateStatus()
	local active = settings.AutoJoinPublic or settings.AutoJoinSelected
	tw(StatusDot, 0.2, { BackgroundColor3 = active and GREEN or HINT })
	if not active then StatusLabel.Text = "Inativo"; return end
	local modes = {}
	for k, v in pairs(settings.SelectedGamemode) do if v then table.insert(modes, k) end end
	local modeStr = settings.AutoJoinPublic and "Público" or "Selecionados"
	StatusLabel.Text = "Ativo — "..modeStr..(#modes > 0 and (" · "..table.concat(modes,", ")) or "")
end

-- ============================================================
--  DROPDOWN (multi-select)
--  Key fix: every clickable row uses a TextButton that sits on
--  top and is NOT inside any UIListLayout that could block it.
-- ============================================================
local activeMenu = nil -- currently open menu frame

local function makeDropdown(cfg)
	-- cfg: { title, getItems, onChanged, layoutOrder, parent }

	-- outer wrapper (auto-grows vertically)
	local wrap = fr({
		Size = UDim2.new(1,0,0,0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = cfg.layoutOrder,
		ZIndex = 2,
	}, cfg.parent)
	vlist(5, wrap)

	-- section label
	lbl({ Text=string.upper(cfg.title), Size=UDim2.new(1,0,0,12), Font=Enum.Font.GothamBold, TextSize=10, TextColor3=MUTED, LayoutOrder=1, ZIndex=3 }, wrap)

	-- button row
	local btnF = fr({ Size=UDim2.new(1,0,0,34), BackgroundColor3=SURFACE2, LayoutOrder=2, ZIndex=3 }, wrap)
	corner(7, btnF)
	stroke(BORDER, 1, btnF)

	local btnTxt = lbl({ Text="Selecionar...", Size=UDim2.new(1,-34,1,0), Position=UDim2.new(0,12,0,0), Font=Enum.Font.Gotham, TextSize=12, TextColor3=MUTED, ZIndex=4 }, btnF)
	lbl({ Text="▾", Size=UDim2.fromOffset(24,34), Position=UDim2.new(1,-26,0,0), Font=Enum.Font.GothamBold, TextSize=12, TextColor3=MUTED, ZIndex=4 }, btnF)

	-- invisible button covering entire btnF
	local openBtn = hitBtn(btnF, 5)

	-- tags row (wraps)
	local tagsRow = fr({
		Size = UDim2.new(1,0,0,0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
		ZIndex = 3,
	}, wrap)
	new("UIListLayout",{ FillDirection=Enum.FillDirection.Horizontal, Wraps=true, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4) }, tagsRow)

	-- dropdown menu (below button, same parent = wrap)
	local menuF = fr({
		Size = UDim2.new(1,0,0,0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = SURFACE3,
		Visible = false,
		LayoutOrder = 4,
		ZIndex = 50,
	}, wrap)
	corner(7, menuF)
	stroke(BORDER, 1, menuF)
	vlist(0, menuF)
	pad(4,4,4,4, menuF)

	local selected = {}

	-- rebuild tag pills
	local function renderTags()
		for _, c in pairs(tagsRow:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		local count = 0
		for k, v in pairs(selected) do
			if v then
				count += 1
				local tag = fr({ Size=UDim2.fromOffset(0,22), AutomaticSize=Enum.AutomaticSize.X, BackgroundColor3=TAG_BG, LayoutOrder=count, ZIndex=4 }, tagsRow)
				corner(11, tag)
				stroke(TAG_BD, 1, tag)
				pad(0,8,0,8, tag)
				-- label + × side by side
				lbl({ Text=k, Size=UDim2.fromOffset(0,22), AutomaticSize=Enum.AutomaticSize.X, Font=Enum.Font.GothamMedium, TextSize=11, TextColor3=TAG_TEXT, ZIndex=5 }, tag)
				local kk = k
				local xBtn = new("TextButton",{
					Text="×", Size=UDim2.fromOffset(16,22),
					Position=UDim2.new(1,-16,0,0),
					BackgroundTransparency=1, BorderSizePixel=0,
					Font=Enum.Font.GothamBold, TextSize=14,
					TextColor3=TAG_TEXT, AutoButtonColor=false,
					ZIndex=6,
				}, tag)
				xBtn.MouseButton1Click:Connect(function()
					selected[kk] = nil
					renderTags()
					cfg.onChanged(selected)
					updateStatus()
				end)
			end
		end
		local n = count
		if n > 0 then btnTxt.Text = n.." selecionado(s)"; btnTxt.TextColor3 = TEXT
		else           btnTxt.Text = "Selecionar...";    btnTxt.TextColor3 = MUTED end
	end

	-- rebuild menu items
	local function buildMenu()
		for _, c in pairs(menuF:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		local items = cfg.getItems()
		for i, item in ipairs(items) do
			-- row is a plain Frame (no UIListLayout inside!)
			local row = fr({ Size=UDim2.new(1,0,0,30), BackgroundColor3=SURFACE3, LayoutOrder=i, ZIndex=51 }, menuF)

			-- checkbox (purely visual)
			local chk = selected[item] == true
			local cbF = fr({ Size=UDim2.fromOffset(14,14), Position=UDim2.new(0,8,0.5,-7), BackgroundColor3=chk and ACCENT or SURFACE2, ZIndex=52 }, row)
			corner(3, cbF)
			stroke(chk and ACCENT or BORDER, 1, cbF)
			if chk then
				lbl({ Text="✓", Size=UDim2.new(1,0,1,0), Font=Enum.Font.GothamBold, TextSize=10, TextColor3=WHITE, ZIndex=53 }, cbF)
			end

			-- item label
			lbl({ Text=item, Size=UDim2.new(1,-34,1,0), Position=UDim2.new(0,30,0,0), Font=Enum.Font.Gotham, TextSize=12, TextColor3=TEXT, ZIndex=52 }, row)

			-- full-row hitbox ON TOP of everything in this row
			local cap = item
			local rowHit = new("TextButton",{
				Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
				BorderSizePixel=0, Text="", AutoButtonColor=false, ZIndex=55,
			}, row)
			rowHit.MouseButton1Click:Connect(function()
				selected[cap] = not selected[cap] or nil
				buildMenu()
				renderTags()
				cfg.onChanged(selected)
				updateStatus()
			end)
			rowHit.MouseEnter:Connect(function() tw(row,0.1,{BackgroundColor3=SURFACE2}) end)
			rowHit.MouseLeave:Connect(function() tw(row,0.1,{BackgroundColor3=SURFACE3}) end)
		end
	end

	local isOpen = false
	openBtn.MouseButton1Click:Connect(function()
		-- close any other open menu
		if activeMenu and activeMenu ~= menuF then
			activeMenu.Visible = false
		end
		isOpen = not isOpen
		if isOpen then buildMenu() end
		menuF.Visible = isOpen
		activeMenu = isOpen and menuF or nil
	end)
	openBtn.MouseEnter:Connect(function() tw(btnF,0.1,{BackgroundColor3=Color3.fromRGB(42,42,54)}) end)
	openBtn.MouseLeave:Connect(function() tw(btnF,0.1,{BackgroundColor3=SURFACE2}) end)

	-- return a reset function
	return function()
		selected = {}
		isOpen = false
		menuF.Visible = false
		renderTags()
		cfg.onChanged(selected)
	end
end

-- ============================================================
--  TOGGLE
--  Key fix: no UIListLayout — position everything manually so
--  there's no invisible layout element blocking clicks.
-- ============================================================
local function makeToggle(cfg)
	-- cfg: { title, subtitle, default, layoutOrder, parent, onChanged }

	local ROW_H = cfg.subtitle and 54 or 40
	local row = fr({ Size=UDim2.new(1,0,0,ROW_H), BackgroundColor3=SURFACE, LayoutOrder=cfg.layoutOrder, ZIndex=3 }, cfg.parent)
	corner(8, row)
	stroke(BORDER, 1, row)

	-- title
	lbl({
		Text = cfg.title,
		Size = UDim2.new(1,-62,0,16),
		Position = UDim2.new(0,14,0, cfg.subtitle and 10 or (ROW_H/2-8)),
		Font = Enum.Font.GothamMedium, TextSize=13, TextColor3=TEXT, ZIndex=4,
	}, row)

	-- subtitle
	if cfg.subtitle then
		lbl({
			Text = cfg.subtitle,
			Size = UDim2.new(1,-62,0,13),
			Position = UDim2.new(0,14,0,28),
			Font=Enum.Font.Gotham, TextSize=10, TextColor3=MUTED, ZIndex=4,
		}, row)
	end

	-- toggle track (positioned to right, vertically centered)
	local state = cfg.default or false
	local track = fr({ Size=UDim2.fromOffset(38,20), Position=UDim2.new(1,-52,0.5,-10), BackgroundColor3=state and TOG_ON or TOG_OFF, ZIndex=4 }, row)
	corner(10, track)
	local knob = fr({ Size=UDim2.fromOffset(16,16), Position=UDim2.fromOffset(state and 20 or 2,2), BackgroundColor3=WHITE, ZIndex=5 }, track)
	corner(8, knob)

	-- full-row hitbox
	local rowHit = new("TextButton",{
		Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
		BorderSizePixel=0, Text="", AutoButtonColor=false, ZIndex=6,
	}, row)
	rowHit.MouseButton1Click:Connect(function()
		state = not state
		tw(track,0.15,{BackgroundColor3 = state and TOG_ON or TOG_OFF})
		tw(knob, 0.15,{Position = UDim2.fromOffset(state and 20 or 2, 2)})
		cfg.onChanged(state)
		updateStatus()
	end)
	rowHit.MouseEnter:Connect(function() tw(row,0.1,{BackgroundColor3=Color3.fromRGB(30,30,38)}) end)
	rowHit.MouseLeave:Connect(function() tw(row,0.1,{BackgroundColor3=SURFACE}) end)
end

-- ============================================================
--  ACTION BUTTON
-- ============================================================
local function makeActionButton(cfg)
	local b = new("TextButton",{
		Text=cfg.text, Size=UDim2.new(1,0,0,32),
		BackgroundColor3=SURFACE2, BorderSizePixel=0,
		TextColor3=MUTED, Font=Enum.Font.GothamMedium, TextSize=12,
		AutoButtonColor=false, LayoutOrder=cfg.layoutOrder, ZIndex=3,
	}, cfg.parent)
	corner(7, b)
	stroke(BORDER, 1, b)
	b.MouseEnter:Connect(function() tw(b,0.1,{BackgroundColor3=Color3.fromRGB(42,42,54),TextColor3=TEXT}) end)
	b.MouseLeave:Connect(function() tw(b,0.1,{BackgroundColor3=SURFACE2,TextColor3=MUTED}) end)
	b.MouseButton1Click:Connect(function() if cfg.callback then cfg.callback() end end)
end

-- ============================================================
--  BUILD UI
-- ============================================================

makeDropdown({
	title    = "Select Gamemode",
	getItems = function() return Gamemodes end,
	onChanged= function(sel) settings.SelectedGamemode = sel end,
	layoutOrder = 1,
	parent   = Content,
})

local resetPlayers = makeDropdown({
	title    = "Select Player's Party to Join",
	getItems = function() return PlayersInGamemode end,
	onChanged= function(sel) settings.plrsToJoin = sel end,
	layoutOrder = 2,
	parent   = Content,
})

makeActionButton({
	text    = "↺   Refresh Players List",
	layoutOrder = 3,
	parent  = Content,
	callback= function()
		refreshPlayersList()
		resetPlayers()
	end,
})

makeToggle({
	title    = "Auto Join (Jogadores Selecionados)",
	subtitle = "Entra no modo dos jogadores escolhidos",
	default  = false,
	layoutOrder = 4,
	parent   = Content,
	onChanged= function(state) settings.AutoJoinSelected = state end,
})

makeToggle({
	title    = "Auto Join (Público)",
	subtitle = "Entra no modo de qualquer jogador",
	default  = false,
	layoutOrder = 5,
	parent   = Content,
	onChanged= function(state) settings.AutoJoinPublic = state end,
})

-- ============================================================
--  MINIMIZE  (RightControl)
-- ============================================================
local minimized = false
UserInputService.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.RightControl then
		minimized = not minimized
		tw(Window, 0.2, { Size = UDim2.fromOffset(W, minimized and 48 or H) })
	end
end)
