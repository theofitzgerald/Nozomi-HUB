local MarketplaceService = game:GetService("MarketplaceService")
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local ui = {}
ui.library = loadstring(game:HttpGet(repo .. "library.lua"))()
ui.saveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
ui.options = ui.library.Options
ui.toggles = ui.library.Toggles
ui.tabs = {}
ui.window = ui.library:CreateWindow({
    Title = "Nozomi HUB",
    Footer = MarketplaceService:GetProductInfo(game.PlaceId).Name,
    Icon = "",
    NotifySide = "Left"
})


function ui:addTab(name: string, icon: string)
    local newTab = self.window:AddTab(name, icon)
    table.insert(self.tabs, newTab)
    self.tabs[name] = newTab
    return newTab
end

--// Default Tabs : Settings
local UI_SETTINGS_BOX = ui:addTab("Settings", "wrench")
UI_SETTINGS_BOX:AddToggle("KeybindMenuOpen", {
    Default = ui.library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",

    Callback = function(v)
        ui.library.KeybindFrame.Visible = v
    end,
})
UI_SETTINGS_BOX:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,

    Callback = function(v)
        ui.library.ShowCustomCursor = v
    end,
})
UI_SETTINGS_BOX:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",

    Callback = function(v)
        ui.library:SetNotifySide(v)
    end,
})
UI_SETTINGS_BOX:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",

    Callback = function(v)
        v = v:gsub("%%", "")

        ui.library:SetDPIScale(tonumber(v))
    end,
})
UI_SETTINGS_BOX:AddSlider("UICornerSlider", {
    Text = "Corner Radius",
    Default = ui.library.CornerRadius,
    Min = 0,
    Max = 20,
    Rounding = 0,

    Callback = function(v)
        ui.window:SetCornerRadius(v)
    end,
})
UI_SETTINGS_BOX:AddDivider()
UI_SETTINGS_BOX:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", {
        Default = "F3",
        NoUI = true,
        Text = "Menu keybind"
    })

ui.library.ToggleKeybind = ui.options.MenuKeybind
UI_SETTINGS_BOX:AddButton("Unload", function()
    ui.library:Unload()
end)

return ui