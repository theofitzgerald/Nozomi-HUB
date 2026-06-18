local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer

if _G.PromptFarmHub then
	_G.PromptFarmHub:Destroy()
end

_G.PromptFarmHub = {
	Running = false,
	Connection = nil,
	LoopThread = nil,
	Gui = nil
}

local PromptFarm = _G.PromptFarmHub

local Y_OFFSET = 4
local CHECK_DELAY = 0.2
local AUTO_FIRE = true

function PromptFarm:Destroy()
	self.Running = false

	if self.Connection then
		pcall(function()
			self.Connection:Disconnect()
		end)
		self.Connection = nil
	end

	if self.Gui then
		pcall(function()
			self.Gui:Destroy()
		end)
		self.Gui = nil
	end

	_G.PromptFarmHub = nil
end

local function getHRP()
	local char = plr.Character or plr.CharacterAdded:Wait()
	return char:FindFirstChild("HumanoidRootPart")
end

local function getPromptPart(prompt)
	local p = prompt.Parent
	if not p then return nil end

	if p:IsA("BasePart") then
		return p
	elseif p:IsA("Attachment") and p.Parent and p.Parent:IsA("BasePart") then
		return p.Parent
	elseif p:IsA("Model") then
		return p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart", true)
	end

	return nil
end

local function setPrompt(v)
	if v:IsA("ProximityPrompt") then
		v.HoldDuration = 0
	end
end

for _, v in ipairs(workspace:GetDescendants()) do
	setPrompt(v)
end

PromptFarm.Connection = workspace.DescendantAdded:Connect(setPrompt)

local old = CoreGui:FindFirstChild("PromptFarmUI")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "PromptFarmUI"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

PromptFarm.Gui = gui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 155, 0, 78)
frame.Position = UDim2.new(0, 25, 0.5, -40)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 13)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 170, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.25
stroke.Parent = frame

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 35)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 12))
})
grad.Rotation = 90
grad.Parent = frame

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 30)
top.BackgroundTransparency = 1
top.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -65, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ Prompt Farm"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 12
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.new(0, 24, 0, 22)
minimize.Position = UDim2.new(1, -54, 0, 4)
minimize.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
minimize.BackgroundTransparency = 0.15
minimize.Text = "—"
minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
minimize.TextSize = 14
minimize.Font = Enum.Font.GothamBold
minimize.Parent = top

Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 7)

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 24, 0, 22)
close.Position = UDim2.new(1, -28, 0, 4)
close.BackgroundColor3 = Color3.fromRGB(210, 65, 75)
close.BackgroundTransparency = 0.05
close.Text = "✕"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.TextSize = 13
close.Font = Enum.Font.GothamBold
close.Parent = top

Instance.new("UICorner", close).CornerRadius = UDim.new(0, 7)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -16, 1, -38)
content.Position = UDim2.new(0, 8, 0, 34)
content.BackgroundTransparency = 1
content.Parent = frame

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, 0, 0, 34)
toggle.Position = UDim2.new(0, 0, 0, 0)
toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
toggle.BackgroundTransparency = 0.08
toggle.Text = "OFF"
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.TextSize = 15
toggle.Font = Enum.Font.GothamBold
toggle.Parent = content

Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 10)

local dragging = false
local dragStart
local startPos

top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart

		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

local function updateToggle()
	if PromptFarm.Running then
		toggle.Text = "ON"

		TweenService:Create(toggle, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(40, 180, 100)
		}):Play()
	else
		toggle.Text = "OFF"

		TweenService:Create(toggle, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		}):Play()
	end
end

local function findPrompt()
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("ProximityPrompt") and v.Enabled then
			local part = getPromptPart(v)

			if part then
				return v, part
			end
		end
	end

	return nil, nil
end

local function startFarm()
	if PromptFarm.Running then return end

	PromptFarm.Running = true
	updateToggle()

	PromptFarm.LoopThread = task.spawn(function()
		while PromptFarm.Running do
			task.wait(CHECK_DELAY)

			local hrp = getHRP()
			if not hrp then
				continue
			end

			local prompt, part = findPrompt()

			if prompt and part then
				hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, Y_OFFSET, 0))

				if AUTO_FIRE and fireproximityprompt then
					task.wait(0.08)

					pcall(function()
						fireproximityprompt(prompt)
					end)
				end
			end
		end
	end)
end

local function stopFarm()
	PromptFarm.Running = false
	updateToggle()
end

toggle.MouseButton1Click:Connect(function()
	if PromptFarm.Running then
		stopFarm()
	else
		startFarm()
	end
end)

local minimized = false

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized

	if minimized then
		content.Visible = false
		minimize.Text = "+"

		TweenService:Create(frame, TweenInfo.new(0.18), {
			Size = UDim2.new(0, 155, 0, 34)
		}):Play()
	else
		TweenService:Create(frame, TweenInfo.new(0.18), {
			Size = UDim2.new(0, 155, 0, 78)
		}):Play()

		task.wait(0.18)

		if frame and frame.Parent then
			content.Visible = true
			minimize.Text = "—"
		end
	end
end)

close.MouseButton1Click:Connect(function()
	PromptFarm:Destroy()
end)

updateToggle()
