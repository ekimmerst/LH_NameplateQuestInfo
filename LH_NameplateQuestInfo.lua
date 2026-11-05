local addonName = ...
local Addon = {}
LH_NameplateQuestInfo = Addon
local events = CreateFrame("Frame")
local activePlates, icons = {}, {}
local elapsed = 0
local distances = {
    iconDistance = {default = 6, max = 50},
    progressDistance = {default = 6, max = 50},
    iconTargetDistance = {default = 24, max = 80},
    progressTargetDistance = {default = 24, max = 80},
}
local function ClampDistance(key, value)
    local config = distances[key]
    return math.max(0, math.min(config.max, math.floor(value + 0.5)))
end
local function GetOptions()
    LH_NameplateQuestInfoDB = type(LH_NameplateQuestInfoDB) == "table" and LH_NameplateQuestInfoDB or {}
    for _, key in ipairs({"enabled", "showIcon", "showProgress"}) do
        if type(LH_NameplateQuestInfoDB[key]) ~= "boolean" then LH_NameplateQuestInfoDB[key] = true end
    end
    for key, config in pairs(distances) do
        local value = LH_NameplateQuestInfoDB[key]
        LH_NameplateQuestInfoDB[key] = type(value) == "number" and ClampDistance(key, value)
            or config.default
    end
    return LH_NameplateQuestInfoDB
end
function Addon:GetOption(key) return GetOptions()[key] end
local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

-- Inspect structured objective lines, without English-only kill/loot keywords.
-- nil means unavailable or restricted data; false means no unfinished objective.
local function TooltipQuestObjective(unit)
    if not (C_TooltipInfo and C_TooltipInfo.GetUnit and Enum
        and Enum.TooltipDataLineType and Enum.TooltipDataLineType.QuestObjective) then
        return nil
    end
    local data = C_TooltipInfo.GetUnit(unit)
    if IsSecret(data) or type(data) ~= "table" then return nil end
    if TooltipUtil and TooltipUtil.SurfaceArgs then TooltipUtil.SurfaceArgs(data) end
    if IsSecret(data.lines) or type(data.lines) ~= "table" then return nil end
    local restricted, foundObjective = false, false
    local counters, seen = {}, {}
    for _, line in ipairs(data.lines) do
        if IsSecret(line) or type(line) ~= "table" then return nil end
        if TooltipUtil and TooltipUtil.SurfaceArgs then TooltipUtil.SurfaceArgs(line) end
        if IsSecret(line.type) then
            restricted = true
        elseif line.type == Enum.TooltipDataLineType.QuestObjective then
            foundObjective = true
            local text = line.leftText
            if IsSecret(text) or type(text) ~= "string"
                or not text:match("%d+%s*/%s*%d+") then
                text = line.rightText
            end
            if IsSecret(text) then
                restricted = true
            elseif type(text) == "string" then
                -- The counter can precede or follow a localized objective label.
                local have, need = text:match("(%d+)%s*/%s*(%d+)")
                if have and need then
                    if tonumber(have) < tonumber(need) then
                        local counter = have .. "/" .. need
                        if not seen[counter] then
                            counters[#counters + 1] = counter
                            seen[counter] = true
                        end
                    end
                else
                    -- Objectives without counters use the client's relation API.
                    restricted = true
                end
            else
                restricted = true
            end
        end
    end
    if #counters > 0 then return true, table.concat(counters, "\n") end
    if restricted or not foundObjective then return nil end
    return false
end

local function QuestRelation(unit)
    if C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest then
        local ok, related = pcall(C_QuestLog.UnitIsRelatedToActiveQuest, unit)
        if ok then return related end
    end
end

local function HideOverlay(icon)
    icon:Hide()
    if icon.progressFrame then icon.progressFrame:Hide() end
end

-- Platynator draws and scales its own health bar above Blizzard's hidden bar.
local function GetHealthAnchor(plate, unit)
    local children = {plate:GetChildren()}
    for _, display in ipairs(children) do
        if display.unit == unit and type(display.widgets) == "table" then
            for _, widget in ipairs(display.widgets) do
                if widget.kind == "bars" and widget.details
                    and widget.details.kind == "health" and widget:IsShown() then
                    return widget
                end
            end
        end
    end
end

-- Keep text independent: a text/layout failure must never suppress the icon.
local function UpdateProgress(icon, plate, unit, text, targeted, options)
    if not text or text == "" then return end
    local frame = icon.progressFrame
    if not frame then
        frame = CreateFrame("Frame", nil, plate)
        frame:Hide()
        icon.progressFrame = frame
        frame:SetSize(100, 20)
        frame:EnableMouse(false)
    end
    if not frame.text then
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", frame, "LEFT", 0, 0)
        label:SetTextColor(1, 0.82, 0)
        label:SetJustifyH("LEFT")
        frame.text = label
    end
    local anchor = GetHealthAnchor(plate, unit)
    if not anchor then
        local unitFrame = plate.UnitFrame
        anchor = unitFrame and (unitFrame.healthBar or unitFrame.HealthBar or unitFrame.HealthBarsContainer) or plate
    end
    frame:ClearAllPoints()
    frame:SetPoint("LEFT", anchor, "RIGHT",
        targeted and options.progressTargetDistance or options.progressDistance, 0)
    frame.text:SetText(text)
    frame:Show()
end

local function GetIcon(plate, unit, targeted, options)
    local icon = icons[plate]
    if not icon then
        -- Own unprotected overlay; never change Blizzard's nameplate visibility.
        icon = CreateFrame("Frame", nil, plate)
        icon:SetSize(20, 20)
        icon:EnableMouse(false)
        local texture = icon:CreateTexture(nil, "OVERLAY")
        texture:SetAllPoints()
        texture:SetAtlas("QuestNormal")
        icon:Hide()
        icons[plate] = icon
    end
    local unitFrame = plate.UnitFrame
    local anchor = GetHealthAnchor(plate, unit)
        or (unitFrame and (unitFrame.healthBar or unitFrame.HealthBar or unitFrame.HealthBarsContainer))
        or plate
    icon:ClearAllPoints()
    icon:SetPoint("RIGHT", anchor, "LEFT",
        -(targeted and options.iconTargetDistance or options.iconDistance), 0)
    return icon
end

local function UpdatePlate(unit, plate)
    local options = GetOptions()
    if not options.enabled then return end
    local targetOK, isTarget = pcall(UnitIsUnit, unit, "target")
    local targeted = targetOK and not IsSecret(isTarget) and isTarget == true
    local icon = GetIcon(plate, unit, targeted, options)
    HideOverlay(icon)
    if not options.showIcon and not options.showProgress then return end
    local ok, isPlayer = pcall(UnitIsPlayer, unit)
    if not ok or IsSecret(isPlayer) or isPlayer then return end
    local deadOK, dead = pcall(UnitIsDeadOrGhost, unit)
    if deadOK and not IsSecret(dead) and dead then return end

    local related = QuestRelation(unit)
    local tooltipOK, objective, progress = pcall(TooltipQuestObjective, unit)
    if not IsSecret(related) and related == false then
        -- Attackable NPCs can have objective counters despite a false relation.
        -- Require explicit unfinished tooltip evidence before overriding it.
        if not tooltipOK or objective ~= true then return end
        local attackOK, attackable = pcall(UnitCanAttack, "player", unit)
        if not attackOK or IsSecret(attackable) or attackable ~= true then return end
    end
    if tooltipOK and objective ~= nil then
        icon:SetShown(options.showIcon and objective)
        if objective and options.showProgress then
            if not pcall(UpdateProgress, icon, plate, unit, progress, targeted, options) and icon.progressFrame then
                icon.progressFrame:Hide()
            end
        end
    elseif IsSecret(related) then
        -- A secret boolean may only be passed to the engine, never inspected.
        if options.showIcon and not pcall(icon.SetShown, icon, related) then icon:Hide() end
    else
        icon:SetShown(options.showIcon and related == true)
    end
end

local function UpdateAll()
    for unit, plate in pairs(activePlates) do UpdatePlate(unit, plate) end
end

local function DiscoverPlates()
    for _, icon in pairs(icons) do HideOverlay(icon) end
    wipe(activePlates)
    if not Addon:GetOption("enabled") then return end
    if C_NamePlate and C_NamePlate.GetNamePlates then
        for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
            local unit = plate.namePlateUnitToken
            if not IsSecret(unit) and type(unit) == "string" then activePlates[unit] = plate end
        end
    end
    -- Some client/layout combinations omit namePlateUnitToken on plate frames.
    -- Resolve the engine's unit tokens directly when discovering existing plates.
    if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
        for i = 1, 40 do
            local unit = "nameplate" .. i
            local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
            if ok and plate then activePlates[unit] = plate end
        end
    end
    UpdateAll()
end

function Addon:SetOption(key, value)
    if distances[key] then
        if type(value) ~= "number" then return end
        GetOptions()[key] = ClampDistance(key, value)
    elseif key == "enabled" or key == "showIcon" or key == "showProgress" then
        GetOptions()[key] = value == true
    else
        return
    end
    elapsed = 0
    DiscoverPlates()
    if self.RefreshSettings then self:RefreshSettings() end
end

for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD",
    "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "QUEST_LOG_UPDATE",
    "UNIT_QUEST_LOG_CHANGED", "PLAYER_TARGET_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED" }) do
    events:RegisterEvent(event)
end

events:SetScript("OnEvent", function(_, event, unit)
    if event == "ADDON_LOADED" then
        if unit == addonName then GetOptions(); DiscoverPlates() end
        return
    end
    if not Addon:GetOption("enabled") then return end
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        DiscoverPlates()
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit(unit)
        if plate then
            -- Clear a recycled plate's old marker before evaluating its new mob.
            if icons[plate] then HideOverlay(icons[plate]) end
            activePlates[unit] = plate
            UpdatePlate(unit, plate)
        end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local plate = activePlates[unit]
        if plate and icons[plate] then HideOverlay(icons[plate]) end
        activePlates[unit] = nil
    elseif event ~= "UNIT_QUEST_LOG_CHANGED" or unit == "player" then
        UpdateAll()
    end
end)

-- Retry delayed tooltip data and keep anchors current when plate layouts change.
-- Only visible tracked plates are inspected.
events:SetScript("OnUpdate", function(_, delta)
    if not Addon:GetOption("enabled") or not next(activePlates) then
        elapsed = 0
        return
    end
    elapsed = elapsed + delta
    if elapsed >= 0.5 then
        elapsed = 0
        UpdateAll()
    end
end)

SLASH_LH_NAMEPLATEQUESTINFO1 = "/lh_nameplatequestinfo"
SlashCmdList.LH_NAMEPLATEQUESTINFO = function(message)
    local command = (message or ""):lower():match("^%s*(.-)%s*$")
    if command == "on" or command == "off" then
        Addon:SetOption("enabled", command == "on")
        print(Addon:GetOption("enabled") and "LH_NameplateQuestInfo: Enabled." or "LH_NameplateQuestInfo: Disabled.")
    elseif command == "" and Addon.category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(Addon.category:GetID())
    elseif command == "" then
        print("LH_NameplateQuestInfo: /lh_nameplatequestinfo on | off. Install and load LH Tweaks for settings.")
    else
        print("LH_NameplateQuestInfo: /lh_nameplatequestinfo on | off. Use /lh_nameplatequestinfo to open settings.")
    end
end
