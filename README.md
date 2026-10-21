# LH_NameplateQuestInfo

Version: 0.2.8

LH_NameplateQuestInfo helps you spot quest mobs in WoW Forever Beta. It automatically adds a yellow quest marker to the left of their nameplates and shows your objective progress, such as **3/10**, on the right for kill and quest-item objectives.

## Getting started

Install LH_NameplateQuestInfo in your `Interface/AddOns` folder and enable it in the AddOns menu. Quest markers and progress appear automatically when the addon loads. No commands or configuration are needed.

Nameplates must be visible for LH_NameplateQuestInfo to display markers. Enable friendly nameplates when looking for friendly quest mobs.

Disable the addon in the AddOns menu to turn off its display. LH_NameplateQuestInfo requires the shared LH_Tweaks core.

The addon uses a golden quest exclamation mark as its icon in the AddOns menu.

## Installation and upgrade

The `LH_NameplateQuestInfo` folder must contain `LH_NameplateQuestInfo.toc`, `LH_NameplateQuestInfo.lua` and the bundled `Media` folder. When upgrading from NameplateQuestInfo, replace the old folder, fully restart WoW and enable **LH_NameplateQuestInfo** in the AddOns menu. Do not enable both versions together. There are no saved settings to migrate.

## Changelog

### 0.2.8 - 2026-10-21

- Renamed NameplateQuestInfo to LH_NameplateQuestInfo, including the folder, Lua/TOC files, metadata, icon path and English documentation.

## Required core addon

Install and enable **LH_Tweaks** alongside this addon. LH_Tweaks is the shared LiteHawk configuration host and must load first. CurseForge releases must list LH_Tweaks as a required dependency so the client installs it automatically.
