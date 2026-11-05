local addonName = ...
local Addon = LH_NameplateQuestInfo
local variables = {}

function Addon:RefreshSettings()
    if self.notifying or not Settings or not Settings.NotifyUpdate then return end
    self.notifying = true
    for _, variable in ipairs(variables) do Settings.NotifyUpdate(variable) end
    self.notifying = false
end

local function Build(category, layout)
    Addon.category = category
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Quest nameplates"))
    local parent
    for _, option in ipairs({
        {key = "enabled", label = "Enable nameplate quest information", tooltip = "Show quest overlays on visible Blizzard nameplates. Disabling immediately hides all markers and progress. Saved per character."},
        {key = "showIcon", label = "Show quest markers", tooltip = "Show a yellow quest marker to the left of relevant NPC nameplates. Independent of objective progress. Saved per character."},
        {key = "showProgress", label = "Show objective progress", tooltip = "Show readable unfinished objective counters to the right of relevant nameplates. Different counters stack; duplicate counters appear once. Independent of the quest marker. Restricted counters remain hidden. Saved per character."},
    }) do
        local key = option.key
        local variable = "LH_NameplateQuestInfo_" .. key
        variables[#variables + 1] = variable
        local setting = Settings.RegisterProxySetting(category, variable, "boolean", option.label, true,
            function() return Addon:GetOption(key) end,
            function(value) Addon:SetOption(key, value) end)
        local control = Settings.CreateCheckbox(category, setting, option.tooltip)
        if parent then
            control:SetParentInitializer(parent, function() return Addon:GetOption("enabled") end)
        else parent = control end
    end
    for _, option in ipairs({
        {key = "iconDistance", label = "Quest marker distance", default = 6, max = 50, tooltip = "Horizontal distance between the health bar and the quest marker on its left. Saved per character."},
        {key = "iconTargetDistance", label = "Quest marker distance (targeted)", default = 24, max = 80, tooltip = "Distance on the left while this NPC is your target. Increase it to clear Platynator's target indicator. Saved per character."},
        {key = "progressDistance", label = "Objective progress distance", default = 6, max = 50, tooltip = "Horizontal distance between the health bar and objective progress on its right. Saved per character."},
        {key = "progressTargetDistance", label = "Objective progress distance (targeted)", default = 24, max = 80, tooltip = "Distance on the right while this NPC is your target. Increase it to clear Platynator's target indicator. Saved per character."},
    }) do
        local key = option.key
        local variable = "LH_NameplateQuestInfo_" .. key
        variables[#variables + 1] = variable
        local setting = Settings.RegisterProxySetting(category, variable, "number", option.label, option.default,
            function() return Addon:GetOption(key) end,
            function(value) Addon:SetOption(key, value) end)
        local slider = Settings.CreateSliderOptions(0, option.max, 1)
        slider:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
            function(value) return string.format("%d", value) end)
        local control = Settings.CreateSlider(category, setting, slider, option.tooltip)
        control:SetParentInitializer(parent, function() return Addon:GetOption("enabled") end)
    end
end

if LH_Tweaks and LH_Tweaks.RegisterModule then
    LH_Tweaks:RegisterModule(addonName, "LH NameplateQuestInfo", Build)
end
