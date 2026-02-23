--[[
    Rockside
    Main Script
]]

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local WindUI

do
    local ok, result = pcall(function()
        return require("./WindUI/src/Init")
    end)

    if ok then
        WindUI = result
    else
        if cloneref(game:GetService("RunService")):IsStudio() then
            WindUI = require(cloneref(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init")))
        else
            WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/fihzprogramms/WindUIFork/refs/heads/main/Main.lua"))()
        end
    end
end

-- Transparency & Theme
WindUI.TransparencyValue = 0.45
WindUI:SetTheme("Dark")

-- Colors
local Blue = Color3.fromHex("#257AF7")

-- ========================================
--  Window
-- ========================================
local Window = WindUI:CreateWindow({
    Title = "Rockside",
    Icon = "rbxassetid://89336236403062",
    Folder = "Rockside",
    Size = UDim2.fromOffset(680, 540),
    NewElements = true, -- iOS 26 style toggles/sliders

    Topbar = {
        Height = 44,
        ButtonsType = "Mac", -- Mac-style window buttons
    },

    OpenButton = {
        Title = "Rockside",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        OnlyMobile = false,
        Draggable = true,
        Scale = 0.5,
        Color = ColorSequence.new(
            Color3.fromHex("#ff3f3f"),
            Color3.fromHex("#ff8c00")
        ),
    },

    User = {
        Enabled = true,
        Anonymous = false,
    },

    Acrylic = true,
    SideBarWidth = 200,
    HideSearchBar = false,
})

-- Apply semi-transparency
Window:SetBackgroundTransparency(0.45)



-- ========================================
--  Config Manager
-- ========================================
local ConfigManager = Window.ConfigManager
if ConfigManager then
    ConfigManager:Init(Window)
end
local configFile = ConfigManager and ConfigManager:CreateConfig("default", true)

-- helper: register + callback
local function flagged(element)
    if configFile and element.Flag then
        configFile:Register(element.Flag, element)
    end
end

-- ========================================
--  Sections & Tabs
-- ========================================
local SettingsSection = Window:Section({ Title = "Settings", Opened = true })

local Tabs = {
    Config = SettingsSection:Tab({
        Title = "Config",
        Icon = "settings",
        IconColor = Blue,
        IconShape = "Square",
        Border = true,
    }),
}

-- ========================================
--  Config Tab
-- ========================================
do
    local configName = "default"

    if ConfigManager then
        -- Config management section
        local CfgSection = Tabs.Config:Section({
            Title = "Configs",
            Box = true,
            Opened = true,
        })

        local configInput = CfgSection:Input({
            Title = "Config Name",
            Value = configName,
            Callback = function(value)
                configName = value or "default"
            end,
        })

        CfgSection:Space()

        local _, configDropdown = CfgSection:Dropdown({
            Title = "Existing Configs",
            Values = ConfigManager:AllConfigs(),
            Value = configName,
            AllowNone = false,
            Callback = function(value)
                configName = value or "default"
                configInput:Set(configName)
            end,
        })

        CfgSection:Space()

        CfgSection:Toggle({
            Title = "Auto-Load",
            Desc = "Load this config automatically on startup",
            Value = true,
            Callback = function(state)
                if configFile then
                    configFile:SetAutoLoad(state)
                    configFile:Save()
                end
            end,
        })

        Tabs.Config:Space()

        -- Buttons
        local BtnGroup = Tabs.Config:Group({})

        BtnGroup:Button({
            Title = "Save",
            Icon = "save",
            Justify = "Center",
            Callback = function()
                configFile = ConfigManager:CreateConfig(configName)
                configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))
                local ok = configFile:Save()
                if ok and configDropdown then
                    configDropdown:Refresh(ConfigManager:AllConfigs())
                end
                WindUI:Notify({
                    Title = ok and "Saved" or "Error",
                    Content = ok and configName or "Failed to save",
                    Icon = ok and "check" or "x",
                    Duration = 2,
                })
            end,
        })

        BtnGroup:Space()

        BtnGroup:Button({
            Title = "Load",
            Icon = "folder-open",
            Justify = "Center",
            Callback = function()
                configFile = ConfigManager:CreateConfig(configName)
                local data = configFile:Load()
                WindUI:Notify({
                    Title = data and "Loaded" or "Error",
                    Content = data and configName or "Failed to load",
                    Icon = data and "check" or "x",
                    Duration = 2,
                })
            end,
        })

        BtnGroup:Space()

        BtnGroup:Button({
            Title = "Delete",
            Icon = "trash-2",
            Justify = "Center",
            Callback = function()
                Window:Dialog({
                    Title = "Delete '" .. configName .. "'?",
                    Content = "This cannot be undone.",
                    Buttons = {
                        {
                            Title = "Delete",
                            Variant = "Primary",
                            Callback = function()
                                local ok, msg = ConfigManager:DeleteConfig(configName)
                                if ok and configDropdown then
                                    configDropdown:Refresh(ConfigManager:AllConfigs())
                                end
                                WindUI:Notify({
                                    Title = ok and "Deleted" or "Error",
                                    Content = msg,
                                    Icon = ok and "check" or "x",
                                    Duration = 2,
                                })
                            end,
                        },
                        { Title = "Cancel", Variant = "Tertiary" },
                    },
                })
            end,
        })

        Tabs.Config:Space()

        -- Appearance section
        local AppearSection = Tabs.Config:Section({
            Title = "Appearance",
            Box = true,
            Opened = true,
        })

        AppearSection:Dropdown({
            Title = "Theme",
            Values = WindUI:GetThemes(),
            Value = "Dark",
            Callback = function(theme)
                WindUI:SetTheme(theme)
            end,
        })

        AppearSection:Space()

        AppearSection:Slider({
            Title = "Transparency",
            Value = { Min = 0, Max = 1, Default = 0.45 },
            Step = 0.05,
            Callback = function(value)
                Window:SetBackgroundTransparency(value)
            end,
        })
    end
end

-- ========================================
--  Auto-save on close
-- ========================================
Window:OnClose(function()
    if ConfigManager and configFile then
        configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))
        configFile:Save()
    end
end)

-- Unlock all elements
Window:UnlockAll()
