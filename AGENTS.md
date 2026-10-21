# LH_NameplateQuestInfo project knowledge

- Communicate with the user in German. Addon messages, comments, metadata, and documentation are in English, matching LH_HideMe.
- Read LH_NameplateQuestInfo.lua, LH_NameplateQuestInfo.toc and README.md before editing.
- WoW Forever Beta addon; interface 16001 copied from the installed LH_HideMe metadata. Version 0.3.0; requires the LH_Tweaks configuration host.
- Work only within LH_NameplateQuestInfo for LH_NameplateQuestInfo requests. Other addons are separate projects.
- No build step. Local Git repository uses main. GitHub remotes were removed on October 21, 2026 at the user's request. A new repository is planned but has not been created; no GitHub repository is currently connected.
- Quest icons and objective progress default to enabled. Version 0.3.0 introduces LH_NameplateQuestInfoDB per character with enabled/showIcon/showProgress, plus /lh_nameplatequestinfo to open settings and on|off to toggle the master setting. Discover existing plates on addon load, login, world entry and option changes. Disabled mode hides both overlays, clears tracked plates and skips event/polling inspections.
- Own unprotected overlays use QuestNormal, size 20, anchored RIGHT to the health-bar LEFT at -6, 0. Prefer UnitFrame.HealthBarsContainer, then healthBar, then the plate.
- A separate progress frame appears six pixels right of the health-bar area or visible level badge. Read counters from leftText/rightText, deduplicate identical counters and stack different counters. Hide both overlays before evaluation and on removal/discovery. Text failures must not suppress the icon; missing/restricted counters hide progress. Discover nameplate1..40 with GetNamePlateForUnit as well as GetNamePlates to support frames without namePlateUnitToken.
- Track NAME_PLATE_UNIT_ADDED/REMOVED and discover existing plates at addon load/login/world entry. Hide old markers when a plate is removed/recycled. Only refresh visible tracked plates every 0.5 seconds.
- C_TooltipInfo.GetUnit with Enum.TooltipDataLineType.QuestObjective detects unfinished localized counters. C_QuestLog.UnitIsRelatedToActiveQuest gates explicitly unrelated mobs and provides a fallback for absent/restricted/non-counter tooltip data. A false relation can be overridden only by a readable unfinished tooltip objective plus a non-secret true UnitCanAttack("player", unit), supporting friendly/neutral attackable quest NPCs.
- Never branch on secret values. Guard all inspected tooltip/flag/relation values. Use pcall around API inspection and direct SetShown for secret relation booleans; hide if rejected. Do not infer relations from mob names.
- Preserve Blizzard nameplate visibility and scripts; do not modify other addons or enable nameplate CVars automatically.
- Version 0.2.1 passed the extended Lua 5.1 simulation using the progress harness and Lua runtime in TEMP. An older state harness also remains in TEMP. Tests cover off/on without frame unit-token fields, left/right counters, updates/completion, multiple counters, badge placement, restricted fallback, recycling and font failure/recovery. Real rendering and engine secret-value behavior remain unverified.
- The user confirmed on October 11, 2026 that the corrected progress display and off/on behavior work in game in version 0.2.1. Detailed compatibility checks remain pending, especially restricted data, completion updates, combat overlays, custom plate layouts and interaction with ForeverQuestMark.
- Update version and README for functional releases; change interface only with client evidence.
- The user confirmed on October 11, 2026 that version 0.2.4 works in game for friendly attackable quest mobs. Extended Lua 5.1 regression tests passed, including the false-relation override and restricted/error attackability checks.

## Addon list artwork

- Version 0.2.2 adds an open-eye icon matching LH_HideMe's golden frame, violet glow and hand-painted WoW style. No Lua behavior changes.
- Media/Icon.png is the current golden quest exclamation icon generated with the built-in image_gen tool, using the previous eye icon as an edit target.
- Media/Icon.tga is the 256x256 uncompressed 32-bit BGRA texture with top-left origin. LH_NameplateQuestInfo.toc references Interface\AddOns\LH_NameplateQuestInfo\Media\Icon through IconTexture.
- Keep Media when installing. Native addon-list rendering requires in-game verification; restart the client after adding the texture if needed.

- Version 0.2.5 renames the addon, directory, Lua/TOC files, slash registration, chat prefix, texture path and per-character settings to the former NameplateQuestInfo name. Historical command: /nameplatequestinfo. Settings default to off under the new SavedVariables name.

- Version 0.2.6 removes slash commands and saved settings; quest overlays activate automatically, including when older saved settings were off.

- Version 0.2.7 replaces the addon-list eye artwork with a bold golden quest exclamation mark, preserving the gold border and violet fantasy background. Media/Icon.tga is converted from the PNG with bicubic downsampling. No Lua behavior changes.

## Rename to LH_NameplateQuestInfo

- Version 0.2.8 renames the folder, Lua/TOC files, title, author metadata, icon path and English documentation to LH_NameplateQuestInfo.
- The Lua implementation is byte-for-byte unchanged. It receives the addon name through varargs, so ADDON_LOADED discovery follows the new folder name automatically.
- No slash commands or saved variables exist; no settings migration is required. Fully restart WoW after the folder rename.
- In-game verification of the rename remains pending.

- The addon now requires LH_Tweaks as its shared configuration host and load-order dependency. CurseForge releases must also declare the LH_Tweaks project as a required dependency.

## Native settings and shared icon (0.3.0)

- Settings.lua loads after the implementation and registers LH NameplateQuestInfo using LH_Tweaks:RegisterModule. A master checkbox and two dependent checkboxes use native proxies with true defaults. Defaults restores enabled, marker and progress. All use the same per-character table and setters; slash toggles notify all proxies.
- Marker and progress preferences are independent. Progress remains parented to the plate, so disabling the marker must not hide readable counters. Secret relation values are still forwarded directly only when showIcon is enabled; never branch on them. Existing detection, dimensions, anchors and visibility rules remain unchanged.
- TOC Title is LH NameplateQuestInfo, Group/X-Part-Of is LH_Tweaks. Media/Icon.png and Media/Icon.tga are byte-identical copies of the shared LH_Tweaks icon (gold LH lettering; Spoken frame reference). Historical golden-exclamation addon-list artwork above was replaced; the QuestNormal on-nameplate marker is unchanged.
- .settings-test.py passed Lua 5.1 simulation for all controls, immediate toggles, saved state/defaults, independent overlays, discovery/recycling, counter layout/completion, relation override/secret forwarding and font failures. In-game rendering and real secret-value behavior remain pending. Restart WoW for the new TOC entries.
