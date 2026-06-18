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
	Header = nil,
	HeaderTitle = nil,
	MinimizeButton = nil,
	CloseButton = nil,
	ToggleIcon = nil,
	ToggleCount = nil,
	ResizeHandle = nil,

	StatsTitle = nil,
	RewardsTitle = nil,
	StatsContainer = nil,
	StatLayout = nil,
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
	ResultHandled = false,

	ContentScale = 0.5,
	CurrentRewardCellSize = 40
}

local Hub = _G.RewardTrackerUI

local DESIGN_WIDTH = 470
local DESIGN_HEIGHT = 370

local MAIN_WIDTH = 235
local MAIN_HEIGHT = 185

local MIN_WIDTH = 150
local MIN_HEIGHT = 150
local MAX_WIDTH = 360
local MAX_HEIGHT = 290

local HEADER_HEIGHT = 58
local SCREEN_PADDING = 5
local RESIZE_HANDLE_SIZE = 28

local updateResponsiveLayout

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

local function isDragStartInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isDragMoveInput(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local function getViewportSize()
	local cam = workspace.CurrentCamera

	if cam then
		return cam.ViewportSize
	end

	return Vector2.new(1366, 768)
end

local function clampNumber(value, minValue, maxValue)
	if maxValue < minValue then
		return minValue
	end

	return math.clamp(value, minValue, maxValue)
end

local function getContentScale(size)
	local scaleX = size.X / DESIGN_WIDTH
	local scaleY = size.Y / DESIGN_HEIGHT

	return math.clamp(math.min(scaleX, scaleY), 0.32, 0.9)
end

local function scaleValue(value, minValue)
	local scaled = math.floor((value * Hub.ContentScale) + 0.5)

	if minValue then
		return math.max(minValue, scaled)
	end

	return math.max(1, scaled)
end

local function getSizeBounds()
	local viewport = getViewportSize()

	local maxW = math.max(220, math.min(MAX_WIDTH, viewport.X - (SCREEN_PADDING * 2)))
	local maxH = math.max(185, math.min(MAX_HEIGHT, viewport.Y - (SCREEN_PADDING * 2)))

	local minW = math.min(MIN_WIDTH, maxW)
	local minH = math.min(MIN_HEIGHT, maxH)

	return minW, minH, maxW, maxH
end

local function getInitialSize()
	local minW, minH, maxW, maxH = getSizeBounds()

	local w = clampNumber(MAIN_WIDTH, minW, maxW)
	local h = clampNumber(MAIN_HEIGHT, minH, maxH)

	return Vector2.new(w, h)
end

local function centerPositionForSize(size)
	local viewport = getViewportSize()

	return UDim2.fromOffset(
		math.floor((viewport.X - size.X) / 2),
		math.floor((viewport.Y - size.Y) / 2)
	)
end

local function clampGuiToScreen(guiObject)
	if not guiObject then
		return
	end

	local viewport = getViewportSize()
	local size = guiObject.AbsoluteSize

	if size.X <= 0 or size.Y <= 0 then
		size = Vector2.new(
			guiObject.Size.X.Offset,
			guiObject.Size.Y.Offset
		)
	end

	local pos = guiObject.AbsolutePosition
	local minX = SCREEN_PADDING
	local minY = SCREEN_PADDING
	local maxX = math.max(SCREEN_PADDING, viewport.X - size.X - SCREEN_PADDING)
	local maxY = math.max(SCREEN_PADDING, viewport.Y - size.Y - SCREEN_PADDING)

	guiObject.Position = UDim2.fromOffset(
		clampNumber(pos.X, minX, maxX),
		clampNumber(pos.Y, minY, maxY)
	)
end

local function fitMainToViewport()
	if not Hub.Main then
		return
	end

	local minW, minH, maxW, maxH = getSizeBounds()
	local currentSize = Hub.Main.AbsoluteSize

	if currentSize.X <= 0 or currentSize.Y <= 0 then
		currentSize = getInitialSize()
	end

	local newW = clampNumber(currentSize.X, minW, maxW)
	local newH = clampNumber(currentSize.Y, minH, maxH)

	Hub.Main.Size = UDim2.fromOffset(newW, newH)
	clampGuiToScreen(Hub.Main)
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
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Position = UDim2.fromScale(0.5, 0.5)
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

local function updateRewardCellsScale()
	local cellSize = Hub.CurrentRewardCellSize or 40

	for _, data in pairs(Hub.Rewards) do
		if data.Cell and data.Clone and data.Scale and data.BaseSize then
			local baseW = math.max(1, data.BaseSize.X)
			local baseH = math.max(1, data.BaseSize.Y)

			data.Clone.Size = UDim2.fromOffset(baseW, baseH)
			data.Clone.AnchorPoint = Vector2.new(0.5, 0.5)
			data.Clone.Position = UDim2.fromScale(0.5, 0.5)

			local margin = scaleValue(1, 0)
			local available = math.max(10, cellSize - margin)

			local scale = math.min(available / baseW, available / baseH)
			data.Scale.Scale = math.clamp(scale, 0.25, 1.25)
		end
	end
end

local function updateGridCellSize()
	if updateResponsiveLayout then
		updateResponsiveLayout()
	end
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
	label.TextTruncate = Enum.TextTruncate.AtEnd
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
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent = scroll

	return scroll
end

local function createStatCard(parent, name, text, order)
	local card = Instance.new("TextLabel")
	card.Name = name
	card.Size = UDim2.fromOffset(198, 24)
	card.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	card.BorderSizePixel = 0
	card.Text = text
	card.TextColor3 = Color3.fromRGB(235, 235, 245)
	card.Font = Enum.Font.GothamBold
	card.TextSize = 14
	card.TextScaled = true
	card.TextXAlignment = Enum.TextXAlignment.Left
	card.TextTruncate = Enum.TextTruncate.AtEnd
	card.LayoutOrder = order or 0
	card.Parent = parent

	local textLimit = Instance.new("UITextSizeConstraint")
	textLimit.MinTextSize = 7
	textLimit.MaxTextSize = 14
	textLimit.Parent = card

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = card

	return card
end

local function setMinimized(state)
	if not Hub.Main or not Hub.ToggleIcon then
		return
	end

	Hub.Main.Visible = not state
	Hub.ToggleIcon.Visible = state

	if state then
		clampGuiToScreen(Hub.ToggleIcon)
	else
		clampGuiToScreen(Hub.Main)

		if updateResponsiveLayout then
			updateResponsiveLayout()
		end
	end
end

local function makeDraggable(guiObject, dragArea)
	local dragging = false
	local dragStart
	local startPosition

	addConnection(dragArea.InputBegan:Connect(function(input)
		if isDragStartInput(input) then
			dragging = true
			dragStart = input.Position
			startPosition = guiObject.AbsolutePosition

			addConnection(input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end))
		end
	end))

	addConnection(UserInputService.InputChanged:Connect(function(input)
		if dragging and isDragMoveInput(input) then
			local delta = input.Position - dragStart

			guiObject.Position = UDim2.fromOffset(
				startPosition.X + delta.X,
				startPosition.Y + delta.Y
			)

			clampGuiToScreen(guiObject)
		end
	end))
end

local function makeResizable(main, handle)
	local resizing = false
	local resizeStart
	local startSize

	addConnection(handle.InputBegan:Connect(function(input)
		if isDragStartInput(input) then
			resizing = true
			resizeStart = input.Position
			startSize = main.AbsoluteSize

			addConnection(input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
				end
			end))
		end
	end))

	addConnection(UserInputService.InputChanged:Connect(function(input)
		if resizing and isDragMoveInput(input) then
			local delta = input.Position - resizeStart
			local minW, minH, maxW, maxH = getSizeBounds()

			local newW = clampNumber(startSize.X + delta.X, minW, maxW)
			local newH = clampNumber(startSize.Y + delta.Y, minH, maxH)

			main.Size = UDim2.fromOffset(newW, newH)
			clampGuiToScreen(main)

			if updateResponsiveLayout then
				updateResponsiveLayout()
			end
		end
	end))
end

local function createToggleIcon(gui)
	local viewport = getViewportSize()

	local toggle = Instance.new("TextButton")
	toggle.Name = "Toggle"
	toggle.Size = UDim2.fromOffset(62, 62)
	toggle.Position = UDim2.fromOffset(25, math.max(80, math.floor(viewport.Y / 2 - 31)))
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

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 95, 180)
	stroke.Thickness = 1.5
	stroke.Parent = toggle

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

	makeDraggable(toggle, toggle)

	return toggle, count
end

updateResponsiveLayout = function()
	if not Hub.Main then
		return
	end

	local mainSize = Hub.Main.AbsoluteSize

	if mainSize.X <= 0 or mainSize.Y <= 0 then
		return
	end

	Hub.ContentScale = getContentScale(mainSize)

	local headerHeight = scaleValue(HEADER_HEIGHT, 22)
	local sidePadding = scaleValue(17, 7)
	local contentWidth = math.max(1, mainSize.X - (sidePadding * 2))

	if Hub.Header then
		Hub.Header.Size = UDim2.new(1, 0, 0, headerHeight)
	end

	local btnSize = scaleValue(40, 18)
	local btnGap = scaleValue(6, 3)
	local btnRightPad = scaleValue(10, 5)
	local btnTop = math.floor((headerHeight - btnSize) / 2)

	if Hub.CloseButton then
		Hub.CloseButton.Size = UDim2.fromOffset(btnSize, btnSize)
		Hub.CloseButton.Position = UDim2.new(1, -(btnRightPad + btnSize), 0, btnTop)
		Hub.CloseButton.TextSize = scaleValue(16, 9)
	end

	if Hub.MinimizeButton then
		Hub.MinimizeButton.Size = UDim2.fromOffset(btnSize, btnSize)
		Hub.MinimizeButton.Position = UDim2.new(1, -(btnRightPad + (btnSize * 2) + btnGap), 0, btnTop)
		Hub.MinimizeButton.TextSize = scaleValue(22, 10)
	end

	if Hub.HeaderTitle then
		local titleLeft = scaleValue(18, 8)
		local titleRight = btnRightPad + (btnSize * 2) + btnGap + scaleValue(18, 6)

		Hub.HeaderTitle.Position = UDim2.fromOffset(titleLeft, 0)
		Hub.HeaderTitle.Size = UDim2.new(1, -(titleLeft + titleRight), 1, 0)
		Hub.HeaderTitle.TextSize = scaleValue(18, 10)

		local limit = Hub.HeaderTitle:FindFirstChildOfClass("UITextSizeConstraint")
		if limit then
			limit.MinTextSize = 8
			limit.MaxTextSize = scaleValue(18, 10)
		end
	end

	if Hub.StatsTitle then
		Hub.StatsTitle.Position = UDim2.fromOffset(sidePadding, headerHeight + scaleValue(12, 5))
		Hub.StatsTitle.Size = UDim2.new(1, -(sidePadding * 2), 0, scaleValue(22, 12))
		Hub.StatsTitle.TextSize = scaleValue(14, 8)
	end

	local statsTop = headerHeight + scaleValue(38, 16)
	local statPadding = scaleValue(10, 5)
	local gapX = scaleValue(10, 4)
	local gapY = scaleValue(8, 4)

	local columns = 2
	if contentWidth < scaleValue(190, 110) then
		columns = 1
	end

	local rows = math.ceil(6 / columns)
	local cardHeight = scaleValue(24, 14)

	local cellWidth = math.floor((contentWidth - (statPadding * 2) - (gapX * (columns - 1))) / columns)
	cellWidth = math.max(scaleValue(120, 70), cellWidth)

	local statsHeight = (statPadding * 2) + (rows * cardHeight) + ((rows - 1) * gapY)

	if Hub.StatLayout then
		Hub.StatLayout.CellSize = UDim2.fromOffset(cellWidth, cardHeight)
		Hub.StatLayout.CellPadding = UDim2.fromOffset(gapX, gapY)
	end

	if Hub.StatsContainer then
		Hub.StatsContainer.Position = UDim2.fromOffset(sidePadding, statsTop)
		Hub.StatsContainer.Size = UDim2.new(1, -(sidePadding * 2), 0, statsHeight)

		local pad = Hub.StatsContainer:FindFirstChildOfClass("UIPadding")
		if pad then
			pad.PaddingTop = UDim.new(0, statPadding)
			pad.PaddingLeft = UDim.new(0, statPadding)
			pad.PaddingRight = UDim.new(0, statPadding)
			pad.PaddingBottom = UDim.new(0, statPadding)
		end
	end

	local statTextSize = scaleValue(14, 8)
	local statTextMin = math.max(7, statTextSize - 3)

	for _, label in ipairs({
		Hub.MatchLabel,
		Hub.DamageLabel,
		Hub.TotalDamageLabel,
		Hub.ClearedTimeLabel,
		Hub.PlaytimeLabel,
		Hub.ActLabel
	}) do
		if label then
			label.TextSize = statTextSize

			local limit = label:FindFirstChildOfClass("UITextSizeConstraint")
			if limit then
				limit.MinTextSize = statTextMin
				limit.MaxTextSize = statTextSize
			end

			local pad = label:FindFirstChildOfClass("UIPadding")
			if pad then
				pad.PaddingLeft = UDim.new(0, scaleValue(12, 5))
				pad.PaddingRight = UDim.new(0, scaleValue(8, 4))
			end
		end
	end

	local rewardsTitleY = statsTop + statsHeight + scaleValue(14, 5)
	local rewardsScrollY = rewardsTitleY + scaleValue(26, 13)
	local rewardHeight = math.max(scaleValue(70, 35), mainSize.Y - rewardsScrollY - sidePadding)

	if Hub.RewardsTitle then
		Hub.RewardsTitle.Position = UDim2.fromOffset(sidePadding, rewardsTitleY)
		Hub.RewardsTitle.Size = UDim2.new(1, -(sidePadding * 2), 0, scaleValue(22, 12))
		Hub.RewardsTitle.TextSize = scaleValue(14, 8)
	end

	if Hub.RewardGrid then
		Hub.RewardGrid.Position = UDim2.fromOffset(sidePadding, rewardsScrollY)
		Hub.RewardGrid.Size = UDim2.new(1, -(sidePadding * 2), 0, rewardHeight)
		Hub.RewardGrid.ScrollBarThickness = scaleValue(4, 2)

		local pad = Hub.RewardGrid:FindFirstChildOfClass("UIPadding")
		if pad then
			local rewardPad = scaleValue(4, 2)

			pad.PaddingTop = UDim.new(0, rewardPad)
			pad.PaddingLeft = UDim.new(0, rewardPad)
			pad.PaddingRight = UDim.new(0, rewardPad)
			pad.PaddingBottom = UDim.new(0, rewardPad)
		end
	end

	if Hub.RewardLayout and Hub.RewardGrid then
		local rewardPad = scaleValue(4, 2)
		local rewardInnerWidth = math.max(1, Hub.RewardGrid.AbsoluteSize.X - (rewardPad * 2))

		local padding = scaleValue(4, 2)

		local minCell = scaleValue(46, 28)
		local maxCell = scaleValue(76, 38)

		local cols = math.floor((rewardInnerWidth + padding) / (minCell + padding))
		cols = math.clamp(cols, 2, 6)

		local cell = math.floor((rewardInnerWidth - ((cols - 1) * padding)) / cols)
		cell = math.clamp(cell, minCell, maxCell)

		Hub.CurrentRewardCellSize = cell

		Hub.RewardLayout.CellSize = UDim2.fromOffset(cell, cell)
		Hub.RewardLayout.CellPadding = UDim2.fromOffset(padding, padding)

		updateRewardCellsScale()
	end

	if Hub.ResizeHandle then
		local handleSize = scaleValue(RESIZE_HANDLE_SIZE, 12)

		Hub.ResizeHandle.Size = UDim2.fromOffset(handleSize, handleSize)
		Hub.ResizeHandle.Position = UDim2.new(1, -handleSize, 1, -handleSize)
		Hub.ResizeHandle.TextSize = scaleValue(16, 9)
	end
end

local function createUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "RewardTrackerUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true

	local parented = pcall(function()
		gui.Parent = CoreGui
	end)

	if not parented then
		gui.Parent = plr:WaitForChild("PlayerGui")
	end

	local initialSize = getInitialSize()

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.fromOffset(initialSize.X, initialSize.Y)
	main.Position = centerPositionForSize(initialSize)
	main.BackgroundColor3 = Color3.fromRGB(13, 14, 20)
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Active = true
	main.Parent = gui

	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 18)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 80, 120)
	stroke.Thickness = 1.4
	stroke.Parent = main

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 29)
	header.BackgroundColor3 = Color3.fromRGB(25, 25, 34)
	header.BorderSizePixel = 0
	header.Active = true
	header.Parent = main

	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 18)

	local title = Instance.new("TextLabel")
	title.Name = "HeaderTitle"
	title.Size = UDim2.new(1, -130, 1, 0)
	title.Position = UDim2.fromOffset(18, 0)
	title.BackgroundTransparency = 1
	title.Text = "Match Reward Counter"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 18
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = header

	local titleLimit = Instance.new("UITextSizeConstraint")
	titleLimit.MinTextSize = 8
	titleLimit.MaxTextSize = 18
	titleLimit.Parent = title

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

	local statsTitle = createSectionTitle(main, "Statistic:", 72)

	local statsContainer = Instance.new("Frame")
	statsContainer.Name = "StatisticContainer"
	statsContainer.Size = UDim2.new(1, -34, 0, 104)
	statsContainer.Position = UDim2.fromOffset(17, 98)
	statsContainer.BackgroundColor3 = Color3.fromRGB(18, 19, 27)
	statsContainer.BorderSizePixel = 0
	statsContainer.ClipsDescendants = true
	statsContainer.Parent = main

	Instance.new("UICorner", statsContainer).CornerRadius = UDim.new(0, 13)

	local statPadding = Instance.new("UIPadding")
	statPadding.PaddingTop = UDim.new(0, 10)
	statPadding.PaddingLeft = UDim.new(0, 10)
	statPadding.PaddingRight = UDim.new(0, 10)
	statPadding.PaddingBottom = UDim.new(0, 10)
	statPadding.Parent = statsContainer

	local statLayout = Instance.new("UIGridLayout")
	statLayout.CellSize = UDim2.fromOffset(198, 24)
	statLayout.CellPadding = UDim2.fromOffset(10, 8)
	statLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statLayout.Parent = statsContainer

	local matchLabel = createStatCard(statsContainer, "MatchLabel", "Match: 0", 1)
	local damageLabel = createStatCard(statsContainer, "DamageLabel", "Damage: 0", 2)
	local totalDamageLabel = createStatCard(statsContainer, "TotalDamageLabel", "Total Damage: 0", 3)
	local clearedTimeLabel = createStatCard(statsContainer, "ClearedTimeLabel", "Cleared Time: 0", 4)
	local playtimeLabel = createStatCard(statsContainer, "PlaytimeLabel", "Play Time: 0", 5)
	local actLabel = createStatCard(statsContainer, "ActLabel", "Act: 0", 6)

	local rewardsTitle = createSectionTitle(main, "Rewards Collected:", 219)
	local rewardScroll = createScrollFrame(main, "RewardGrid", 246, 105)

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(72, 72)
	grid.CellPadding = UDim2.fromOffset(4, 4)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = rewardScroll

	local resizeHandle = Instance.new("TextButton")
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.Size = UDim2.fromOffset(RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE)
	resizeHandle.Position = UDim2.new(1, -RESIZE_HANDLE_SIZE, 1, -RESIZE_HANDLE_SIZE)
	resizeHandle.BackgroundColor3 = Color3.fromRGB(45, 47, 70)
	resizeHandle.BackgroundTransparency = 0.1
	resizeHandle.BorderSizePixel = 0
	resizeHandle.Text = "↘"
	resizeHandle.TextColor3 = Color3.fromRGB(230, 230, 245)
	resizeHandle.Font = Enum.Font.GothamBlack
	resizeHandle.TextSize = 16
	resizeHandle.ZIndex = 50
	resizeHandle.Parent = main

	Instance.new("UICorner", resizeHandle).CornerRadius = UDim.new(0, 9)

	local toggle, toggleCount = createToggleIcon(gui)

	addConnection(minimize.MouseButton1Click:Connect(function()
		setMinimized(true)
	end))

	addConnection(close.MouseButton1Click:Connect(function()
		Hub:Destroy()
	end))

	Hub.Gui = gui
	Hub.Main = main
	Hub.Header = header
	Hub.HeaderTitle = title
	Hub.StatsTitle = statsTitle
	Hub.RewardsTitle = rewardsTitle
	Hub.StatsContainer = statsContainer
	Hub.StatLayout = statLayout
	Hub.RewardGrid = rewardScroll
	Hub.RewardLayout = grid
	Hub.ResizeHandle = resizeHandle

	Hub.MatchLabel = matchLabel
	Hub.DamageLabel = damageLabel
	Hub.TotalDamageLabel = totalDamageLabel
	Hub.ClearedTimeLabel = clearedTimeLabel
	Hub.PlaytimeLabel = playtimeLabel
	Hub.ActLabel = actLabel

	Hub.MinimizeButton = minimize
	Hub.CloseButton = close
	Hub.ToggleIcon = toggle
	Hub.ToggleCount = toggleCount

	makeDraggable(main, header)
	makeResizable(main, resizeHandle)

	addConnection(main:GetPropertyChangedSignal("Size"):Connect(function()
		if updateResponsiveLayout then
			task.defer(updateResponsiveLayout)
		end
	end))

	local function bindCameraViewport()
		local cam = workspace.CurrentCamera

		if cam then
			addConnection(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				fitMainToViewport()

				if Hub.ToggleIcon then
					clampGuiToScreen(Hub.ToggleIcon)
				end

				if updateResponsiveLayout then
					updateResponsiveLayout()
				end
			end))
		end
	end

	bindCameraViewport()

	addConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		task.wait()
		bindCameraViewport()
	end))

	task.defer(function()
		fitMainToViewport()

		if updateResponsiveLayout then
			updateResponsiveLayout()
		end
	end)
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

local function createRewardCell(container)
	local baseW = container.AbsoluteSize.X
	local baseH = container.AbsoluteSize.Y

	if baseW <= 0 then
		baseW = 72
	end

	if baseH <= 0 then
		baseH = 72
	end

	local cell = Instance.new("Frame")
	cell.Name = "RewardCell"
	cell.BackgroundTransparency = 1
	cell.BorderSizePixel = 0
	cell.ClipsDescendants = false

	local clone = container:Clone()
	setupCloneCard(clone)
	clone.Size = UDim2.fromOffset(baseW, baseH)
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Position = UDim2.fromScale(0.5, 0.5)
	clone.Parent = cell

	local uiScale = Instance.new("UIScale")
	uiScale.Name = "RewardAutoScale"
	uiScale.Scale = 1
	uiScale.Parent = clone

	return cell, clone, uiScale, Vector2.new(baseW, baseH)
end

local function addReward(container)
	local image = getRewardImage(container)

	if not image then
		return
	end

	updateGridCellSize()

	local amount = getRewardAmount(container)

	if Hub.Rewards[image] then
		Hub.Rewards[image].Amount += amount
		setRewardAmount(Hub.Rewards[image].Clone, Hub.Rewards[image].Amount)
	else
		local cell, clone, uiScale, baseSize = createRewardCell(container)

		Hub.RewardOrder += 1
		cell.LayoutOrder = Hub.RewardOrder
		cell.Parent = Hub.RewardGrid

		Hub.Rewards[image] = {
			Amount = amount,
			Cell = cell,
			Clone = clone,
			Scale = uiScale,
			BaseSize = baseSize
		}

		setRewardAmount(clone, amount)
	end

	updateGridCellSize()
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
