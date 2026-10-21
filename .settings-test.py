from pathlib import Path
import sys

addon = Path(__file__).resolve().parent
core = addon.parent / 'LH_Tweaks'
sys.path.insert(0, str(core / '.test-runtime'))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime()
lua.execute('''
frames={};SlashCmdList={};queries=0;secret={};failFonts=false
function issecretvalue(value) return value==secret end
function wipe(t) for k in pairs(t) do t[k]=nil end end
function print() end
local M={}
function M:SetScript(k,v) self.scripts[k]=v end
function M:RegisterEvent() end
function M:SetSize(w,h) self.width=w;self.height=h end
function M:EnableMouse(value) self.mouse=value end
function M:SetAllPoints() end
function M:SetAtlas(a) self.atlas=a end
function M:SetPoint(...) self.point={...} end
function M:ClearAllPoints() self.point=nil end
function M:SetTextColor() end
function M:SetJustifyH() end
function M:SetText(text) if failFonts then error('Font unavailable') end;self.text=text end
function M:Show() self.shown=true end
function M:Hide() self.shown=false end
function M:IsShown() return self.shown end
function M:SetShown(value) self.forwarded=value;self.shown=value==secret or value==true end
function M:CreateTexture() local t=CreateFrame('Texture',nil,self);self.texture=t;return t end
function M:CreateFontString() return CreateFrame('Font',nil,self) end
function CreateFrame(kind,name,parent)
 local f=setmetatable({kind=kind,parent=parent,scripts={},shown=true},{__index=M});frames[#frames+1]=f;return f
end
plates={};related=true;attackable=true;dead=false;isPlayer=false
function newPlate()
 local plate=CreateFrame('Frame');local health=CreateFrame('Frame',nil,plate)
 local badge=CreateFrame('Frame',nil,plate)
 plate.UnitFrame={HealthBarsContainer=health,PlayerLevelDiffFrame=badge}
 return plate
end
plates.nameplate1=newPlate()
C_NamePlate={GetNamePlates=function() return {plates.nameplate1} end,
 GetNamePlateForUnit=function(unit) return plates[unit] end}
Enum={TooltipDataLineType={QuestObjective=10}}
lines={{type=10,leftText='Collect: 3/10'}, {type=10,rightText='3/10'},
 {type=10,leftText='Defeat: 2/5'}, {type=10,leftText='Done: 5/5'}}
C_TooltipInfo={GetUnit=function() queries=queries+1;return {lines=lines} end}
C_QuestLog={UnitIsRelatedToActiveQuest=function() return related end}
function UnitIsPlayer() return isPlayer end
function UnitIsDeadOrGhost() return dead end
function UnitCanAttack() return attackable end
registry={};notices={};Settings={}
function Settings.RegisterVerticalLayoutSubcategory(parent,title)
 local c={parent=parent,title=title};function c:GetID() return self.title end
 local l={rows={}};function l:AddInitializer(row) table.insert(self.rows,row) end;c.layout=l;return c,l
end
function Settings.RegisterAddOnCategory(c) registered=c end
function Settings.RegisterProxySetting(c,v,kind,label,default,get,set)
 local s={category=c,default=default,get=get,set=set};registry[v]=s;return s
end
function Settings.CreateCheckbox(c,s,t)
 local row={setting=s,tooltip=t}
 function row:SetParentInitializer(parent,predicate) self.parent=parent;self.canModify=predicate end
 c.layout:AddInitializer(row);return row
end
function Settings.NotifyUpdate(v) notices[v]=(notices[v] or 0)+1 end
function Settings.OpenToCategory(id) opened=id end
function CreateSettingsListSectionHeaderInitializer(t) return {header=t} end
LH_Tweaks={modules={}}
function overlays(plate)
 local icon
 for _,f in ipairs(frames) do if f.parent==plate and f.texture then icon=f end end
 return icon,icon and icon.progressFrame
end
''')
source = (core / 'LH_Tweaks.lua').read_text()
registration = source.split('function Hub:RegisterModule(id, title, build)')[1].split('\nfunction Hub:RestoreDefaults')[0]
lua.execute('local Hub=LH_Tweaks\nfunction Hub:RegisterModule(id, title, build)' + registration)
source = (core / 'Settings.lua').read_text()
registration = source.split('function Hub:RegisterModulePage(id)')[1].split('\nlocal function RegisterSettings')[0]
lua.execute('local Hub=LH_Tweaks\nfunction Hub:RegisterModulePage(id)' + registration)
lua.execute((addon / 'LH_NameplateQuestInfo.lua').read_text(), 'LH_NameplateQuestInfo')
lua.execute('driver=frames[#frames]')
lua.execute((addon / 'Settings.lua').read_text(), 'LH_NameplateQuestInfo')
lua.execute('''
local a=LH_NameplateQuestInfo
local function fire(event,unit) driver.scripts.OnEvent(driver,event,unit) end
assert(LH_Tweaks.modules.LH_NameplateQuestInfo and not registered)
fire('ADDON_LOADED','LH_NameplateQuestInfo')
local plate=plates.nameplate1
local icon,progress=overlays(plate)
assert(icon.shown and icon.texture.atlas=='QuestNormal' and icon.width==20)
assert(progress.shown and progress.text.text=='3/10\\n2/5')
assert(icon.point[2]==plate.UnitFrame.HealthBarsContainer and progress.point[2]==plate.UnitFrame.PlayerLevelDiffFrame)
LH_Tweaks.category={};LH_Tweaks:RegisterModulePage('LH_NameplateQuestInfo')
local category=registered
assert(category.parent==LH_Tweaks.category and category.title=='LH NameplateQuestInfo')
local enabled,marker,counter=registry.LH_NameplateQuestInfo_enabled,registry.LH_NameplateQuestInfo_showIcon,registry.LH_NameplateQuestInfo_showProgress
assert(enabled.get() and marker.get() and counter.get())
assert(enabled.default and marker.default and counter.default and #category.layout.rows==4)
assert(category.layout.rows[3].parent==category.layout.rows[2])
marker.set(false);assert(not icon.shown and progress.shown,'Progress depends on icon visibility')
marker.set(true);counter.set(false);assert(icon.shown and not progress.shown)
enabled.set(false);assert(not icon.shown and not progress.shown and plate.shown)
assert(marker.get() and not counter.get() and not category.layout.rows[3].canModify())
local previous=queries;fire('QUEST_LOG_UPDATE');driver.scripts.OnUpdate(driver,1)
assert(queries==previous,'Disabled addon still inspects units')
-- Enabling discovers plates created while disabled, including those without a unit-token field.
local oldPlate=plate;plates.nameplate1=newPlate();plate=plates.nameplate1
SlashCmdList.LH_NAMEPLATEQUESTINFO(' ON ')
icon,progress=overlays(plate);assert(icon.shown and not progress)
counter.set(true);progress=icon.progressFrame;assert(progress.shown)
local oldIcon=overlays(oldPlate);assert(not oldIcon.shown)
assert(notices.LH_NameplateQuestInfo_enabled>0)
SlashCmdList.LH_NAMEPLATEQUESTINFO();assert(opened==category:GetID())
-- Existing quest detection: relation override only for readable objectives on attackable NPCs.
related=false;attackable=true;fire('QUEST_LOG_UPDATE');assert(icon.shown and progress.shown)
attackable=false;fire('QUEST_LOG_UPDATE');assert(not icon.shown and not progress.shown)
attackable=secret;fire('QUEST_LOG_UPDATE');assert(not icon.shown)
related=secret;lines={{type=secret,leftText=secret}};fire('QUEST_LOG_UPDATE')
assert(icon.shown and icon.forwarded==secret and not progress.shown)
marker.set(false);assert(not icon.shown and not progress.shown)
related=true;lines={{type=10,rightText='Quest: 4/10'}};marker.set(true)
assert(icon.shown and progress.shown and progress.text.text=='4/10')
failFonts=true;fire('QUEST_LOG_UPDATE');assert(icon.shown and not progress.shown)
failFonts=false;driver.scripts.OnUpdate(driver,.5);assert(progress.shown)
lines={{type=10,leftText='10/10'}};fire('QUEST_LOG_UPDATE');assert(not icon.shown and not progress.shown)
lines={{type=10,leftText='1/10'}};dead=true;fire('QUEST_LOG_UPDATE');assert(not icon.shown)
dead=false;isPlayer=true;fire('QUEST_LOG_UPDATE');assert(not icon.shown)
isPlayer=false;fire('NAME_PLATE_UNIT_ADDED','nameplate1');assert(icon.shown)
fire('NAME_PLATE_UNIT_REMOVED','nameplate1');assert(not icon.shown and not progress.shown)
fire('PLAYER_ENTERING_WORLD');assert(icon.shown and progress.shown)
-- Native defaults restore this category's three proxies, leaving other addons alone.
LH_MP5DB={enabled=false};enabled.set(false);marker.set(false);counter.set(false)
for _,setting in pairs(registry) do if setting.category==category then setting.set(setting.default) end end
assert(enabled.get() and marker.get() and counter.get() and not LH_MP5DB.enabled)
SlashCmdList.LH_NAMEPLATEQUESTINFO('off');SlashCmdList.LH_NAMEPLATEQUESTINFO('on extra')
assert(not enabled.get())
fire('ADDON_LOADED','LH_NameplateQuestInfo');fire('PLAYER_LOGIN')
assert(not enabled.get() and not icon.shown and not progress.shown)
''')
for ext in ('png', 'tga'):
    assert (addon / f'Media/Icon.{ext}').read_bytes() == (core / f'Icon.{ext}').read_bytes()
toc = (addon / 'LH_NameplateQuestInfo.toc').read_text()
assert '## Group: LH_Tweaks' in toc and '## SavedVariablesPerCharacter: LH_NameplateQuestInfoDB' in toc
assert 'Settings.lua' in toc
print('PASS: host integration, all three settings, immediate toggles, independent overlays, defaults, saved state, plate discovery/recycling, counters, relation/secret fallback, text failures and shared icons')
