# LH_NameplateQuestInfo

Version: 0.3.0

LH_NameplateQuestInfo helps you spot quest mobs in WoW Forever Beta. It automatically adds a yellow quest marker to the left of their nameplates and shows your objective progress, such as **3/10**, on the right for kill and quest-item objectives.

## Getting started

Install LH_NameplateQuestInfo in your `Interface/AddOns` folder together with LH_Tweaks. Enable **LH NameplateQuestInfo**, grouped under **LH Tweaks**, in the AddOns menu. Quest markers and progress appear automatically by default.

Nameplates must be visible for LH_NameplateQuestInfo to display markers. Enable friendly nameplates when looking for friendly quest mobs.

Open WoW Settings > AddOns > LH Tweaks > LH NameplateQuestInfo, or type `/lh_nameplatequestinfo`. The native page provides three checkboxes:

- **Enable nameplate quest information:** Immediately enable or hide both quest overlays. While disabled, no nameplates or objective tooltips are inspected. Reenabling discovers existing visible plates.
- **Show quest markers:** Show the yellow quest marker to the left of relevant nameplates.
- **Show objective progress:** Show readable unfinished objective counters to the right. Different counters stack; duplicate counters appear once. This display remains available even with the marker disabled.

All three settings default to enabled and are saved per character in `LH_NameplateQuestInfoDB`. The two display preferences remain saved when the main switch is off. Blizzard's Defaults for this category restores all three checkboxes. Use `/lh_nameplatequestinfo on` or `off` to toggle the main setting directly; chat commands and native controls use the same state.

The AddOns menu uses the shared LH icon. Media/Icon.png and Media/Icon.tga are exact copies of LH_Tweaks' gold LH artwork, using Spoken's chamfered gold frame as the reference. There is no runtime Spoken dependency. The on-nameplate marker continues to use Blizzard's yellow QuestNormal artwork.

## Installation and upgrade

The `LH_NameplateQuestInfo` folder must contain LH_NameplateQuestInfo.toc, LH_NameplateQuestInfo.lua, Settings.lua and the bundled Media folder. Fully restart WoW after upgrading to 0.3.0 because the TOC adds Settings.lua, saved variables and grouping metadata.

When upgrading from NameplateQuestInfo, replace the old folder, fully restart WoW and enable **LH NameplateQuestInfo** in the AddOns menu. Do not enable both versions together. Versions 0.2.6 through 0.2.8 had no saved settings to migrate. Version 0.3.0 uses the new LH_NameplateQuestInfoDB table; historical settings under older addon names are not imported.

## Verification

`.settings-test.py` passed Lua 5.1 simulations for real host module registration, all three native controls, immediate hiding/rediscovery, independent marker/progress display, saved settings, command synchronization and scoped defaults. Regression coverage includes tokenless plate discovery, recycled plates, health-bar/level-badge placement, counter deduplication/stacking/completion, attackable NPC relation overrides, restricted relation forwarding, text failures/recovery and player/dead-unit filtering. Icons were verified byte-for-byte against LH_Tweaks; `git diff --check` passed.

Run `python LH_NameplateQuestInfo/.settings-test.py` from the AddOns folder with Lupa available in `LH_Tweaks/.test-runtime`. Native rendering and actual engine secret-value behavior remain pending in game: restart WoW, open the new options page, exercise all three checkboxes with quest NPC nameplates visible, update an objective and check persistence after `/reload`.

## Changelog

### 0.3.0 - 2026-10-21

- Added a native LH NameplateQuestInfo settings page under LH Tweaks, with a master switch and independent quest-marker and objective-progress controls, all enabled by default.
- Added per-character saved settings and `/lh_nameplatequestinfo` to open settings, plus `on|off` commands.
- Hiding is immediate; reenabling discovers existing plates. Existing quest detection, restricted-data handling, overlay placement and Blizzard plate visibility remain intact.
- Added the shared LH icon and native AddOn list grouping under LH Tweaks.

### 0.2.8 - 2026-10-21

- Renamed NameplateQuestInfo to LH_NameplateQuestInfo, including the folder, Lua/TOC files, metadata, icon path and English documentation.

## Required core addon

Install and enable **LH_Tweaks** alongside this addon. LH_Tweaks is the shared LiteHawk configuration host and must load first. CurseForge releases must list LH_Tweaks as a required dependency so the client installs it automatically.
