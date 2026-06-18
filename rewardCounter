local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer

if _G.RewardTrackerUI then
	_G.RewardTrackerUI:Destroy()
end

_G.RewardTrackerUI = {
	Running = true,
	Connections = {},
	Gui = nil,
	Main = nil,
	MinimizeButton = nil,
	ToggleIcon = nil,

	StatsContainer = nil,
	RewardGrid = nil,
	RewardLayout = nil,

	MatchLabel = nil,
	DamageLabel = nil,
	TotalDamageLabel = nil,
	ClearedTimeLabel = nil,
	PlaytimeLabel = nil,
	ActLabel = nil,

	Rewards = {},
	RewardOrder = 0,

	MatchCount = 0,
	TotalDamage = 0,
	LastDamagePerMatch = 0,
	LastClearedTime = "0",
	LastAct = "0",

	StartTime = os.clock(),

	WasRewardVisible = false,
	ProcessedVisibleContainers = {},
	CellSizeSet = false,
	ResultHandled = false
}

local Hub = _G.RewardTrackerUI

local MAIN_WIDTH = 470
local MAIN_HEIGHT = 370

local REWARD_SCROLL_HEIGHT = 105

local function addConnection(c)
	table.insert(Hub.Connections, c)
	return c
end

function Hub:Destroy()
	self.Running = false

	for _, c in ipairs(self.Connections) do
		pcall(function()
			c:Disconnect()
		end)
	end

	table.clear(self.Connections)

	if self.Gui then
		self.Gui:Destroy()
	end

	_G.RewardTrackerUI = nil
end

local function waitForMissionResult()
	local pg = plr:WaitForChild("PlayerGui")

	return pg
		:WaitForChild("GameUI")
		:WaitForChild("MissionResultFrameNew")
		:WaitForChild("Root")
		:WaitForChild("MainVictory")
		:WaitForChild("Content")
		:WaitForChild("Description")
		:WaitForChild("Content")
end

local function waitForMainVictory()
	local pg = plr:WaitForChild("PlayerGui")

	return pg
		:WaitForChild("GameUI")
		:WaitForChild("MissionResultFrameNew")
		:WaitForChild("Root")
		:WaitForChild("MainVictory")
end

local function waitForRewardFrame()
	return waitForMissionResult()
		:WaitForChild("Rewards")
		:WaitForChild("frame")
end

local function waitForStatsFrame()
	return waitForMissionResult()
		:WaitForChild("Stats")
		:WaitForChild("frame")
end

local function getResultVictoryText()
	local mainVictory = waitForMainVictory()
	local stageBanner = mainVictory:FindFirstChild("StageBanner")
	local resultVictory = stageBanner and stageBanner:FindFirstChild("ResultVictory")

	if resultVictory and (resultVictory:IsA("TextLabel") or resultVictory:IsA("TextButton") or resultVictory:IsA("TextBox")) then
		return tostring(resultVictory.Text or "")
	end

	return ""
end

local function isWonResult()
	local result = getResultVictoryText()
	result = result:lower():gsub("%s+", "")
	return result == "won" or result == "win" or result == "victory"
end

local function isAmountText(text)
	text = tostring(text or "")
	text = text:gsub("%s+", "")

	if text == "" then
		return false
	end

	return text:match("^[xX]?[%d,%.]+[kKmMbB]?$") ~= nil
end

local function parseNumber(text)
	text = tostring(text or "")
	text = text:gsub(",", "")
	text = text:gsub("x", "")
	text = text:gsub("X", "")
	text = text:gsub("%s+", "")

	local lower = text:lower()
	local multiplier = 1

	if lower:find("k") then
		multiplier = 1000
	elseif lower:find("m") then
		multiplier = 1000000
	elseif lower:find("b") then
		multiplier = 1000000000
	end

	text = text:gsub("[kKmMbB]", "")

	local num = tonumber(text) or 0
	return num * multiplier
end

local function formatNumber(num)
	num = math.floor(tonumber(num) or 0)

	local str = tostring(num)
	local result = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()

	if result:sub(1, 1) == "," then
		result = result:sub(2)
	end

	return result
end

local function formatRewardAmount(num)
	num = math.floor(tonumber(num) or 0)

	if num >= 1000000 and num % 1000000 == 0 then
		return "x" .. tostring(num / 1000000) .. "m"
	end

	if num >= 1000 and num % 1000 == 0 then
		return "x" .. tostring(num / 1000) .. "k"
	end

	return "x" .. tostring(num)
end

local function formatSeconds(sec)
	sec = math.floor(sec)

	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60

	if h > 0 then
		return string.format("%02d:%02d:%02d", h, m, s)
	end

	return string.format("%02d:%02d", m, s)
end

local function getStatValue(statName)
	local statsFrame = waitForStatsFrame()

	for _, child in ipairs(statsFrame:GetChildren()) do
		local content = child:FindFirstChild("Content")
		local frame = content and content:FindFirstChild("Frame")
		local title = frame and frame:FindFirstChild("Title")
		local value = frame and frame:FindFirstChild("Value")

		if title and value then
			if (title:IsA("TextLabel") or title:IsA("TextButton") or title:IsA("TextBox")) and
				(value:IsA("TextLabel") or value:IsA("TextButton") or value:IsA("TextBox")) then

				if tostring(title.Text) == statName then
					return tostring(value.Text or "")
				end
			end
		end
	end

	return ""
end

local function getStatNumber(statName)
	return parseNumber(getStatValue(statName))
end

local function isImageGui(obj)
	return obj:IsA("ImageLabel") or obj:IsA("ImageButton")
end

local function isValidImage(image)
	image = tostring(image or "")
	return image ~= "" and image ~= "rbxassetid://0"
end

local function getRewardImage(container)
	local preferredNames = {
		"ItemIcon",
		"RewardIcon",
		"Icon",
		"ItemImage",
		"Image"
	}

	for _, name in ipairs(preferredNames) do
		local icon = container:FindFirstChild(name, true)

		if icon and isImageGui(icon) and isValidImage(icon.Image) then
			return icon.Image, icon
		end
	end

	for _, v in ipairs(container:GetDescendants()) do
		if isImageGui(v) and isValidImage(v.Image) then
			return v.Image, v
		end
	end

	return nil, nil
end

local function getAmountObject(container)
	local rightInfos = container:FindFirstChild("RightInfos", true)

	if rightInfos then
		local unitName = rightInfos:FindFirstChild("UnitName", true)

		if unitName and (unitName:IsA("TextLabel") or unitName:IsA("TextButton") or unitName:IsA("TextBox")) then
			if isAmountText(unitName.Text) then
				return unitName
			end
		end

		for _, v in ipairs(rightInfos:GetDescendants()) do
			if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
				if isAmountText(v.Text) then
					return v
				end
			end
		end
	end

	for _, v in ipairs(container:GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
			if isAmountText(v.Text) then
				return v
			end
		end
	end

	return nil
end

local function getRewardAmount(container)
	local amountObj = getAmountObject(container)

	if amountObj then
		local amount = parseNumber(amountObj.Text)

		if amount > 0 then
			return amount
		end
	end

	return 1
end

local function createAmountLabel(container, amount)
	local label = Instance.new("TextLabel")
	label.Name = "RewardAmountCounter"
	label.Size = UDim2.fromOffset(46, 22)
	label.Position = UDim2.new(1, -48, 1, -24)
	label.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	label.BackgroundTransparency = 0.15
	label.BorderSizePixel = 0
	label.Text = formatRewardAmount(amount)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.35
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 13
	label.ZIndex = 999
	label.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = label

	return label
end

local function setRewardAmount(container, amount)
	local amountObj = getAmountObject(container)

	if amountObj then
		amountObj.ZIndex = 999
		amountObj.Text = formatRewardAmount(amount)
	else
		createAmountLabel(container, amount)
	end
end

local function setupCloneCard(clone)
	clone.Visible = true
	clone.AnchorPoint = Vector2.new(0, 0)
	clone.Position = UDim2.fromOffset(0, 0)
	clone.LayoutOrder = 0

	if clone:IsA("GuiObject") then
		clone.ClipsDescendants = false
	end

	local rarity = clone:FindFirstChild("Rarity")
	if rarity and rarity:IsA("GuiObject") then
		rarity.ZIndex = 1
	end

	local selected = clone:FindFirstChild("Selected")
	if selected then
		selected:Destroy()
	end

	for _, v in ipairs(clone:GetDescendants()) do
		if v:IsA("GuiObject") then
			v.Visible = true
		end
	end
end

local function updateGridCellSize(container)
	if Hub.CellSizeSet then
		return
	end

	task.wait()

	local size = container.AbsoluteSize

	if size.X <= 0 or size.Y <= 0 then
		size = Vector2.new(72, 72)
	end

	if Hub.RewardLayout then
		Hub.RewardLayout.CellSize = UDim2.fromOffset(
			math.clamp(size.X, 58, 95),
			math.clamp(size.Y, 58, 95)
		)
	end

	Hub.CellSizeSet = true
end

local function createSectionTitle(parent, text, posY)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -34, 0, 22)
	label.Position = UDim2.fromOffset(17, posY)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(185, 185, 200)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent

	return label
end

local function createScrollFrame(parent, name, posY, height)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = name
	scroll.Size = UDim2.new(1, -34, 0, height)
	scroll.Position = UDim2.fromOffset(17, posY)
	scroll.BackgroundColor3 = Color3.fromRGB(18, 19, 27)
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ClipsDescendants = true
	scroll.Parent = parent

	Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 13)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = scroll

	return scroll
end

local function createStatCard(parent, name, text, size, pos)
	local card = Instance.new("TextLabel")
	card.Name = name
	card.Size = size
	card.Position = pos
	card.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	card.BorderSizePixel = 0
	card.Text = text
	card.TextColor3 = Color3.fromRGB(235, 235, 245)
	card.Font = Enum.Font.GothamBold
	card.TextSize = 14
	card.TextXAlignment = Enum.TextXAlignment.Left
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.Parent = card

	return card
end

local function setMinimized(state)
	if not Hub.Main or not Hub.ToggleIcon then
		return
	end

	Hub.Main.Visible = not state
	Hub.ToggleIcon.Visible = state
end

local function createToggleIcon(gui)
	local toggle = Instance.new("TextButton")
	toggle.Name = "Toggle"
	toggle.Size = UDim2.fromOffset(62, 62)
	toggle.Position = UDim2.new(0, 25, 0.5, -31)
	toggle.BackgroundColor3 = Color3.fromRGB(34, 28, 70)
	toggle.BorderSizePixel = 0
	toggle.Text = "🎁"
	toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggle.TextSize = 28
	toggle.Font = Enum.Font.GothamBlack
	toggle.Visible = false
	toggle.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = toggle

	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.Size = UDim2.fromOffset(24, 24)
	count.Position = UDim2.new(1, -18, 0, -4)
	count.BackgroundColor3 = Color3.fromRGB(220, 45, 70)
	count.BorderSizePixel = 0
	count.Text = "0"
	count.TextColor3 = Color3.fromRGB(255, 255, 255)
	count.Font = Enum.Font.GothamBlack
	count.TextSize = 12
	count.Parent = toggle

	local countCorner = Instance.new("UICorner")
	countCorner.CornerRadius = UDim.new(1, 0)
	countCorner.Parent = count

	addConnection(toggle.MouseButton1Click:Connect(function()
		setMinimized(false)
	end))

	local dragging = false
	local dragStart
	local startPos

	addConnection(toggle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = toggle.Position
		end
	end))

	addConnection(toggle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end))

	addConnection(UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart

			toggle.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end))

	return toggle, count
end

local function createUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "RewardTrackerUI"
	gui.ResetOnSpawn = false
	gui.Parent = CoreGui

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.fromOffset(MAIN_WIDTH, MAIN_HEIGHT)
	main.Position = UDim2.new(0.5, -(MAIN_WIDTH / 2), 0.5, -(MAIN_HEIGHT / 2))
	main.BackgroundColor3 = Color3.fromRGB(13, 14, 20)
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Parent = gui

	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 18)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 80, 120)
	stroke.Thickness = 1.4
	stroke.Parent = main

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 58)
	header.BackgroundColor3 = Color3.fromRGB(25, 25, 34)
	header.BorderSizePixel = 0
	header.Parent = main

	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 18)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -130, 1, 0)
	title.Position = UDim2.fromOffset(18, 0)
	title.BackgroundTransparency = 1
	title.Text = "Match Reward Counter"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local minimize = Instance.new("TextButton")
	minimize.Name = "Minimize"
	minimize.Size = UDim2.fromOffset(40, 40)
	minimize.Position = UDim2.new(1, -96, 0, 9)
	minimize.BackgroundColor3 = Color3.fromRGB(55, 55, 80)
	minimize.Text = "—"
	minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
	minimize.Font = Enum.Font.GothamBlack
	minimize.TextSize = 22
	minimize.Parent = header

	Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 12)

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Size = UDim2.fromOffset(40, 40)
	close.Position = UDim2.new(1, -50, 0, 9)
	close.BackgroundColor3 = Color3.fromRGB(190, 45, 60)
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.Font = Enum.Font.GothamBlack
	close.TextSize = 16
	close.Parent = header

	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 12)

	createSectionTitle(main, "Statistic:", 72)

	local statsContainer = Instance.new("Frame")
	statsContainer.Name = "StatisticContainer"
	statsContainer.Size = UDim2.new(1, -34, 0, 104)
	statsContainer.Position = UDim2.fromOffset(17, 98)
	statsContainer.BackgroundColor3 = Color3.fromRGB(18, 19, 27)
	statsContainer.BorderSizePixel = 0
	statsContainer.Parent = main

	Instance.new("UICorner", statsContainer).CornerRadius = UDim.new(0, 13)

	local leftX = 10
	local rightX = 226
	local topY = 10
	local gapY = 31
	local cardW = 198
	local cardH = 22

	local matchLabel = createStatCard(
		statsContainer,
		"MatchLabel",
		"Match: 0",
		UDim2.fromOffset(cardW, cardH),
		UDim2.fromOffset(leftX, topY)
	)

	local damageLabel = createStatCard(
		statsContainer,
		"DamageLabel",
		"Damage: 0",
		UDim2.fromOffset(cardW, cardH),
		UDim2.fromOffset(leftX, topY + gapY)
	)

	local totalDamageLabel = createStatCard(
		statsContainer,
		"TotalDamageLabel",
		"Total Damage: 0",
		UDim2.fromOffset(cardW, cardH),
		UDim2.fromOffset(leftX, topY + (gapY * 2))
	)

	local clearedTimeLabel = createStatCard(
		statsContainer,
		"ClearedTimeLabel",
		"Cleared Time: 0",
		UDim2.fromOffset(cardW, cardH),
		UDim2.fromOffset(rightX, topY)
	)

	local playtimeLabel = createStatCard(
		statsContainer,
		"PlaytimeLabel",
		"Play Time: 0",
		UDim2.fromOffset(cardW, cardH),
		UDim2.fromOffset(rightX, topY + gapY)
	)

	local actLabel = createStatCard(
		statsContainer,
		"ActLabel",
		"Act: 0",
		UDim2.fromOffset(cardW, cardH),
		UDim2.fromOffset(rightX, topY + (gapY * 2))
	)

	local rewardsTitleY = 98 + 104 + 17
	local rewardsScrollY = rewardsTitleY + 27

	createSectionTitle(main, "Rewards Collected:", rewardsTitleY)

	local rewardScroll = createScrollFrame(main, "RewardGrid", rewardsScrollY, REWARD_SCROLL_HEIGHT)

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(72, 72)
	grid.CellPadding = UDim2.fromOffset(11, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = rewardScroll

	local toggle, toggleCount = createToggleIcon(gui)

	addConnection(minimize.MouseButton1Click:Connect(function()
		setMinimized(true)
	end))

	addConnection(close.MouseButton1Click:Connect(function()
		Hub:Destroy()
	end))

	local dragging = false
	local dragStart
	local startPos

	addConnection(header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end))

	addConnection(header.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end))

	addConnection(UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart

			main.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end))

	Hub.Gui = gui
	Hub.Main = main
	Hub.StatsContainer = statsContainer
	Hub.RewardGrid = rewardScroll
	Hub.RewardLayout = grid

	Hub.MatchLabel = matchLabel
	Hub.DamageLabel = damageLabel
	Hub.TotalDamageLabel = totalDamageLabel
	Hub.ClearedTimeLabel = clearedTimeLabel
	Hub.PlaytimeLabel = playtimeLabel
	Hub.ActLabel = actLabel

	Hub.MinimizeButton = minimize
	Hub.ToggleIcon = toggle
	Hub.ToggleCount = toggleCount
end

local function findRewardRootFromIcon(iconObj, rewardFrame)
	local current = iconObj

	while current and current.Parent and current.Parent ~= rewardFrame do
		current = current.Parent

		if current:IsA("GuiObject") then
			if current.Name == "ContainerNoBottom" then
				return current
			end

			if current:FindFirstChild("ItemIcon", true) and current:FindFirstChild("RightInfos", true) then
				return current
			end

			if current:FindFirstChild("ItemIcon", true) and current:FindFirstChildWhichIsA("TextLabel", true) then
				return current
			end
		end
	end

	if current and current:IsA("GuiObject") then
		return current
	end

	return nil
end

local function getContainers(frame)
	local containers = {}
	local seen = {}

	local function addContainer(container)
		if not container then
			return
		end

		if seen[container] then
			return
		end

		local image = getRewardImage(container)

		if not image then
			return
		end

		seen[container] = true
		table.insert(containers, container)
	end

	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("GuiObject") then
			if child.Name == "ContainerNoBottom" then
				addContainer(child)
			else
				local image = getRewardImage(child)

				if image then
					addContainer(child)
				end
			end
		end
	end

	for _, obj in ipairs(frame:GetDescendants()) do
		if isImageGui(obj) and isValidImage(obj.Image) then
			local root = findRewardRootFromIcon(obj, frame)

			if root then
				addContainer(root)
			end
		end
	end

	return containers
end

local function addReward(container)
	local image = getRewardImage(container)

	if not image then
		return
	end

	updateGridCellSize(container)

	local amount = getRewardAmount(container)

	if Hub.Rewards[image] then
		Hub.Rewards[image].Amount += amount
		setRewardAmount(Hub.Rewards[image].Clone, Hub.Rewards[image].Amount)
	else
		local clone = container:Clone()
		setupCloneCard(clone)

		Hub.RewardOrder += 1
		clone.LayoutOrder = Hub.RewardOrder
		clone.Parent = Hub.RewardGrid

		Hub.Rewards[image] = {
			Amount = amount,
			Clone = clone
		}

		setRewardAmount(clone, amount)
	end
end

local function updatePlaytime()
	if Hub.PlaytimeLabel then
		local elapsed = os.clock() - Hub.StartTime
		Hub.PlaytimeLabel.Text = "Play Time: " .. formatSeconds(elapsed)
	end
end

local function updateToggleCount()
	if Hub.ToggleCount then
		Hub.ToggleCount.Text = tostring(Hub.MatchCount)
	end
end

local function updateMatchStats()
	local damage = getStatNumber("Total Damage")
	local clearedTime = getStatValue("Play Time")
	local act = getStatValue("Act")

	Hub.MatchCount += 1
	Hub.TotalDamage += damage
	Hub.LastDamagePerMatch = damage
	Hub.LastClearedTime = clearedTime ~= "" and clearedTime or "0"
	Hub.LastAct = act ~= "" and act or "0"

	if Hub.MatchLabel then
		Hub.MatchLabel.Text = "Match: " .. Hub.MatchCount
	end

	if Hub.DamageLabel then
		Hub.DamageLabel.Text = "Damage: " .. formatNumber(Hub.LastDamagePerMatch)
	end

	if Hub.TotalDamageLabel then
		Hub.TotalDamageLabel.Text = "Total Damage: " .. formatNumber(Hub.TotalDamage)
	end

	if Hub.ClearedTimeLabel then
		Hub.ClearedTimeLabel.Text = "Cleared Time: " .. Hub.LastClearedTime
	end

	if Hub.ActLabel then
		Hub.ActLabel.Text = "Act: " .. Hub.LastAct
	end

	updateToggleCount()
end

local function scanRewardFrame(frame)
	local containers = getContainers(frame)

	if #containers > 0 then
		if not Hub.WasRewardVisible then
			Hub.WasRewardVisible = true

			if isWonResult() and not Hub.ResultHandled then
				Hub.ResultHandled = true
				updateMatchStats()

				for _, container in ipairs(containers) do
					if not Hub.ProcessedVisibleContainers[container] then
						Hub.ProcessedVisibleContainers[container] = true
						addReward(container)
					end
				end
			end
		else
			if Hub.ResultHandled then
				for _, container in ipairs(containers) do
					if not Hub.ProcessedVisibleContainers[container] then
						Hub.ProcessedVisibleContainers[container] = true
						addReward(container)
					end
				end
			end
		end
	else
		Hub.WasRewardVisible = false
		Hub.ResultHandled = false
		table.clear(Hub.ProcessedVisibleContainers)
	end
end

createUI()

task.spawn(function()
	local rewardFrame = waitForRewardFrame()

	addConnection(rewardFrame.ChildAdded:Connect(function()
		task.wait(0.35)

		if Hub.Running then
			scanRewardFrame(rewardFrame)
		end
	end))

	addConnection(rewardFrame.ChildRemoved:Connect(function()
		task.wait(0.35)

		if Hub.Running then
			scanRewardFrame(rewardFrame)
		end
	end))

	addConnection(rewardFrame.DescendantAdded:Connect(function()
		task.wait(0.2)

		if Hub.Running then
			scanRewardFrame(rewardFrame)
		end
	end))

	addConnection(RunService.RenderStepped:Connect(function()
		if Hub.Running then
			updatePlaytime()
		end
	end))

	while Hub.Running do
		scanRewardFrame(rewardFrame)
		task.wait(0.6)
	end
end)
