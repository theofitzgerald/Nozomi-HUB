-- cek apakah function "clear" tersedia di executor
if typeof(clear) == "function" then
    clear()
end

-- variable untuk footer
local GAME_NAME = game.MarketplaceService:GetProductInfo(game.PlaceId).Name
local VERSION = "v1"
local EXECUTOR = identifyexecutor and identifyexecutor() or "Unknown"

-- Window ui library installation
local obsidian_repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local ObsidianLibs  = loadstring(game:HttpGet(obsidian_repo .. "Library.lua"))()
local ThemeManager  = loadstring(game:HttpGet(obsidian_repo .. "addons/ThemeManager.lua"))()
local SaveManager   = loadstring(game:HttpGet(obsidian_repo .. "addons/SaveManager.lua"))()
local options       = ObsidianLibs.Options
local toggles       = ObsidianLibs.Toggles
local Window        = ObsidianLibs:CreateWindow({
    Footer  = "Game: "..GAME_NAME.." | Version: "..VERSION.." | Executor: "..EXECUTOR,
    Icon    = 88863555863606,
    NotifySide = "Right",
    Size = UDim2.fromOffset(670, 550),
    IconSize = UDim2.fromOffset(40, 40)
})


    -- utility function
local function loadModule(path)
    local function geturl(path)
        path = tostring(path):gsub("\\", "/"):gsub("^/", "")
        local url = "https://raw.githubusercontent.com/theofitzgerald/Nozomi-HUB/main/" .. path
        return url
    end


    local url = geturl(path)

    local ok, src = pcall(game.HttpGet, game, url)
    if not ok then
        warn("[http error]", src, url)
        return
    end

    local fn, err = loadstring(src)
    if not fn then
        warn("[compile error]", err)
        print(src:sub(1, 300))
        return
    end

    local ok2, res = pcall(fn)
    if not ok2 then
        warn("[runtime error]", res)
    end

    print("[loaded]", path)
    return res
end

-- load all module required
local services = loadModule("services.lua")

-- tabs registration
local TABS = {}
TABS.main = Window:AddTab("main", "house")
TABS.settings = Window:AddTab("settings", "settings")

-- Window settings
Window:SetCompact(true)
Window:SetCornerRadius(0)
SaveManager:SetLibrary(ObsidianLibs)
ThemeManager:SetFolder("NozomiHUB")
SaveManager:SetFolder("NozomiHUB/example")
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:IgnoreThemeSettings()
ThemeManager:SetLibrary(ObsidianLibs)
ThemeManager:SetDefaultTheme({
    FontColor       = Color3.fromRGB(240, 240, 240), -- teks putih
    MainColor       = Color3.fromRGB(32,  32,  32),  -- panel gelap (Windows dark)
    AccentColor     = Color3.fromRGB(255,  128, 0),  -- orange
    BackgroundColor = Color3.fromRGB(20,  20,  20),  -- bg hitam keabu-abuan
    OutlineColor    = Color3.fromRGB(60,  60,  60),  -- border abu gelap
})

--[[======================   MAIN TABS   ======================]]
local testMenu = TABS.main:AddLeftGroupbox("TEST", "user")
    testMenu:AddToggle("test", {
        Default = false,
        Text = "This is just a test",
        Callback = function(v)
        end,
    })



--[[====================== SETTINGS TABS ======================]]
local settingsMenu = TABS.settings:AddLeftGroupbox("UI Settings", "wrench")
        settingsMenu:AddToggle("KeybindMenuOpen", {
            Default  = ObsidianLibs.KeybindFrame.Visible,
            Text     = "Open Keybind Menu",
            Callback = function(v) ObsidianLibs.KeybindFrame.Visible = v end,
        })
        settingsMenu:AddToggle("ShowCustomCursor", {
            Text     = "Custom Cursor",
            Default  = true,
            Callback = function(v) ObsidianLibs.ShowCustomCursor = v end,
        })
        settingsMenu:AddDropdown("NotificationSide", {
            Values   = { "Left", "Right" },
            Default  = "Right",
            Text     = "Notification Side",
            Callback = function(v) ObsidianLibs:SetNotifySide(v) end,
        })
        settingsMenu:AddSlider("DPISlider", {
            Default = 100,
            Min = 50,
            Max = 200,
            Rounding = 0,
            Text = "DPI Scale (Default = 100%)",
            Suffix = "%",

            Callback = function(v)
                ObsidianLibs:SetDPIScale(v)
            end,
        })
        settingsMenu:AddSlider("UICornerSlider", {
            Text     = "Corner Radius",
            Default  = ObsidianLibs.CornerRadius,
            Min      = 0,
            Max      = 20,
            Rounding = 0,
            Callback = function(v) Window:SetCornerRadius(v) end,
        })
        
        settingsMenu:AddLabel("Menu Keyinbd") :AddKeyPicker("MenuKeybind", { Default="F3", NoUI=true, Text="Menu keybind" })
        ObsidianLibs.ToggleKeybind = options.MenuKeybind
        settingsMenu:AddDivider()
        settingsMenu:AddButton({
            Text = '<font color="rgb(255, 0, 0)"><b>Unload</b></font>',
            Func = function()
                Window:AddDialog("unloadDialog", {
                    Title = "Unload",
                    Description = "Are you sure to unload script? it will destroy the ui and remove ongoing script, but your data will be saved",
                    AutoDismiss = true,
                    OutsideClickDismiss = true,
                    FooterButtons = {
                        Cancel = {
                            Title = "Cancel",
                            Variant = "Ghost",
                            Order = 1,
                            Callback = function() end
                        },
                        Confirm = {
                            Title = "Confirm",
                            Variant = "Primary",
                            Order = 2,
                            Callback = function() 
                                ObsidianLibs:Unload() 
                            end
                        }
                    }
                })
            end
        })


-- End of the script
SaveManager:BuildConfigSection(TABS.settings)
SaveManager:LoadAutoloadConfig()        


