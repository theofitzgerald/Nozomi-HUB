local Services = {}

Services.MarketplaceService = game:GetService("MarketplaceService")
Services.Players = game:GetService("Players")
Services.RunService = game:GetService("RunService")
Services.UserInputService = game:GetService("UserInputService")
Services.GuiService = game:GetService("GuiService")
Services.Workspace = game:GetService("Workspace")
Services.ReplicatedStorage = game:GetService("ReplicatedStorage")
Services.HttpService = game:GetService("HttpService")
Services.Lighting = game:GetService("Lighting")
Services.localPlayer = Services.Players.LocalPlayer
Services.camera = Services.Workspace.CurrentCamera

return Services