local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

if _G.MapCleanerHub then
	_G.MapCleanerHub:Destroy()
end

_G.MapCleanerHub = {
	Enabled = false,
	Connections = {},
	MovedData = {},
	Gui = nil,
	StorageFolder = nil
}

local Hub = _G.MapCleanerHub

local STORAGE_NAME = "MapCleanerStorage"
local GUI_NAME = "MapCleanerHub"

local EXCLUDED_TERRAIN_NAMES = {
	Floor = true,
	Hills = true
}

local function addConnection(conn)
	table.insert(Hub.Connections, conn)
	return conn
end

local function getStorageFolder()
	local folder = ReplicatedStorage:FindFirstChild(STORAGE_NAME)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = STORAGE_NAME
		folder.Parent = ReplicatedStorage
	end

	Hub.StorageFolder = folder
	return folder
end

local function getMap()
	return workspace:FindFirstChild("Map")
end

local function getDecorations()
	local map = getMap()
	if not map then return nil end

	return map:FindFirstChild("Decorations")
end

local function getTerrainParts()
	local terrainParts = workspace:FindFirstChild("TerrainParts")

	if terrainParts then
		return terrainParts
	end

	local map = getMap()
	if map then
		return map:FindFirstChild("TerrainParts")
	end

	return nil
end

local function saveAndMove(obj)
	if not obj or not obj.Parent then
		return
	end

	if obj:IsDescendantOf(ReplicatedStorage) then
		return
	end

	if not Hub.MovedData[obj] then
		Hub.MovedData[obj] = {
			Parent = obj.Parent
		}
	end

	obj.Parent = getStorageFolder()
end

local function restoreMoved()
	for obj, data in pairs(Hub.MovedData) do
		if obj and data and data.Parent then
			pcall(function()
				obj.Parent = data.Parent
			end)
		end
	end

	Hub.MovedData = {}
end

local function cleanDecorations()
	local decorations = getDecorations()

	if decorations then
		saveAndMove(decorations)
	end
end

local function cleanTerrainParts()
	local terrainParts = getTerrainParts()

	if not terrainParts then
		return
	end

	for _, child in ipairs(terrainParts:GetChildren()) do
		if not EXCLUDED_TERRAIN_NAMES[child.Name] then
			saveAndMove(child)
		end
	end
end

local function cleanAll()
	cleanDecorations()
	cleanTerrainParts()
end

function Hub:Destroy()
	self.Enabled = false

	for _, conn in ipairs(self.Connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end

	self.Connections = {}

	if self.Gui then
		self.Gui:Destroy()
	end

	_G.MapCleanerHub = nil
end

local function createUI()
	local old = CoreGui:FindFirstChild(GUI_NAME)
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.ResetOnSpawn = false
	gui.Parent = CoreGui

	Hub.Gui = gui

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.fromOffset(215, 42)
	main.Position = UDim2.new(0, 25, 0.5, -21)
	main.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	main.BorderSizePixel = 0
	main.Active = true
	main.Draggable = true
	main.Parent = gui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = main

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = Color3.fromRGB(65, 65, 75)
	mainStroke.Thickness = 1
	mainStroke.Parent = main

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -100, 1, 0)
	label.Position = UDim2.fromOffset(12, 0)
	label.BackgroundTransparency = 1
	label.Text = "Map Cleaner"
	label.TextColor3 = Color3.fromRGB(235, 235, 240)
	label.TextSize = 13
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = main

	local toggle = Instance.new("TextButton")
	toggle.Name = "Toggle"
	toggle.Size = UDim2.fromOffset(46, 24)
	toggle.Position = UDim2.new(1, -82, 0.5, -12)
	toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 78)
	toggle.BorderSizePixel = 0
	toggle.Text = ""
	toggle.AutoButtonColor = false
	toggle.Parent = main

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggle

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.fromOffset(20, 20)
	knob.Position = UDim2.fromOffset(2, 2)
	knob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
	knob.BorderSizePixel = 0
	knob.Parent = toggle

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Size = UDim2.fromOffset(24, 24)
	close.Position = UDim2.new(1, -30, 0.5, -12)
	close.BackgroundColor3 = Color3.fromRGB(150, 45, 55)
	close.BorderSizePixel = 0
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.TextSize = 12
	close.Font = Enum.Font.GothamBold
	close.Parent = main

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = close

	local function updateToggle()
		if Hub.Enabled then
			label.Text = "Map Cleaner: ON"

			TweenService:Create(toggle, TweenInfo.new(0.18), {
				BackgroundColor3 = Color3.fromRGB(50, 150, 85)
			}):Play()

			TweenService:Create(knob, TweenInfo.new(0.18), {
				Position = UDim2.fromOffset(24, 2)
			}):Play()
		else
			label.Text = "Map Cleaner: OFF"

			TweenService:Create(toggle, TweenInfo.new(0.18), {
				BackgroundColor3 = Color3.fromRGB(70, 70, 78)
			}):Play()

			TweenService:Create(knob, TweenInfo.new(0.18), {
				Position = UDim2.fromOffset(2, 2)
			}):Play()
		end
	end

	addConnection(toggle.MouseButton1Click:Connect(function()
		Hub.Enabled = not Hub.Enabled

		if Hub.Enabled then
			cleanAll()
		else
			restoreMoved()
		end

		updateToggle()
	end))

	addConnection(close.MouseButton1Click:Connect(function()
		Hub:Destroy()
	end))

	updateToggle()
end

local function setupAutoCleanConnections()
	local terrainParts = getTerrainParts()

	if terrainParts then
		addConnection(terrainParts.ChildAdded:Connect(function(child)
			if Hub.Enabled and not EXCLUDED_TERRAIN_NAMES[child.Name] then
				task.wait()
				saveAndMove(child)
			end
		end))
	end

	local map = getMap()

	if map then
		addConnection(map.ChildAdded:Connect(function(child)
			if child.Name == "Decorations" then
				if Hub.Enabled then
					task.wait()
					saveAndMove(child)
				end
			elseif child.Name == "TerrainParts" then
				task.wait()

				addConnection(child.ChildAdded:Connect(function(newChild)
					if Hub.Enabled and not EXCLUDED_TERRAIN_NAMES[newChild.Name] then
						task.wait()
						saveAndMove(newChild)
					end
				end))

				if Hub.Enabled then
					cleanTerrainParts()
				end
			end
		end))
	end

	addConnection(workspace.ChildAdded:Connect(function(child)
		if child.Name == "TerrainParts" then
			task.wait()

			addConnection(child.ChildAdded:Connect(function(newChild)
				if Hub.Enabled and not EXCLUDED_TERRAIN_NAMES[newChild.Name] then
					task.wait()
					saveAndMove(newChild)
				end
			end))

			if Hub.Enabled then
				cleanTerrainParts()
			end
		elseif child.Name == "Map" then
			task.wait()

			addConnection(child.ChildAdded:Connect(function(newChild)
				if newChild.Name == "Decorations" then
					if Hub.Enabled then
						task.wait()
						saveAndMove(newChild)
					end
				elseif newChild.Name == "TerrainParts" then
					task.wait()

					addConnection(newChild.ChildAdded:Connect(function(tpChild)
						if Hub.Enabled and not EXCLUDED_TERRAIN_NAMES[tpChild.Name] then
							task.wait()
							saveAndMove(tpChild)
						end
					end))

					if Hub.Enabled then
						cleanTerrainParts()
					end
				end
			end))

			if Hub.Enabled then
				cleanAll()
			end
		end
	end))
end

getStorageFolder()
createUI()
setupAutoCleanConnections()
