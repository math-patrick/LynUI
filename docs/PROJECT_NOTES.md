# LynUI for WoW Midnight: project notes

Sep 25, 2026 · exported from the project notes doc

## Overview

LynUI Midnight is Lyn's 2016 Legion UI rebuilt as one small companion addon to EllesmereUI for World of Warcraft Midnight Season 2 (patch 12.1, interface 120100). EllesmereUI does the heavy lifting (action bars, cooldown manager, raid frames, minimap, chat engine, bags); LynUI adds Lyn's look on top of it.

- **Why not a straight port:** the 2016 package bundled 2016 copies of oUF, LiteBag, ls_Toasts, tullaRange and ExtraQuestButton, and almost every API it used is gone. Midnight also hides combat values from addons, so Lyn's old math and chat tricks break.
- **What was kept:** Lyn's oUF unit frame layout (ported to current oUF), Lyn's fonts and bar textures, the beveled border, the stone strip with gold trim, the race-portrait menu button, and the compact chat lines.
- **Where it lives:** `World of Warcraft\_retail_\Interface\AddOns\LynUI` in game, and the GitHub repo `math-patrick/LynUI` (github.com/math-patrick/LynUI) as the backup. The original download stays untouched at `Downloads\LynUI_Legion_2016-39`.

## Architecture

LynUI is one addon folder with a settings store, small modules, and the current oUF embedded privately so it never clashes with another oUF install.

| File | Role |
| --- | --- |
| `LynUI.toc` | Loads everything; interface 120000–120100; optional deps EllesmereUI and LibSharedMedia |
| `Core.lua` | Defaults, `ns:Set` / `ns:OnChange` live settings store, combat queue (`ns:AfterCombat`), module loader, `/lyn` commands |
| `Media.lua` | Registers Lyn fonts and bar textures with SharedMedia |
| `libs/oUF/` | Current oUF (MIT, Sep 22 2026 build), embedded without a global |
| `units/Library.lua` | Shared building blocks: border, text, bars, heal prediction, power, cast bars, auras, class resource strip, live texture/font registry |
| `units/Tags.lua` | Lyn tags: `lyn:name`, `lyn:pvp`, `lyn:classification`, `lyn:color`; Lyn power colors |
| `units/Units.lua` | Player, target, target of target, focus, pet, boss layouts; spawning; live scale and part toggles |
| `units/Move.lua` | `/lyn move` drag handles and saved positions |
| `ActionBars.lua` | Lyn bevel around EllesmereUI's action buttons, live on/off and color |
| `InfoBar.lua` | Stone strip with metal trim |
| `Menu.lua` | Race-portrait button with micro menu |
| `Chat.lua` | Compact chat message filters and spam hiding |
| `Profile.lua` | EllesmereUI profile install, bar layout, chat style, raid font pin |
| `Settings.lua` | The in-game settings panel |
| `media/` | Fonts, bar textures, border pieces, shadow |

Settings flow: every control writes through `ns:Set(key, value)`; modules subscribe with `ns:OnChange(key, fn)` and update immediately. Changes to secure frames go through `ns:AfterCombat` so nothing is touched mid-fight.

## Features

LynUI draws Lyn's unit frames itself and styles everything else EllesmereUI draws.

| Area | What it does | Who draws it |
| --- | --- | --- |
| Unit frames | Player and target 342×40 with Fer35 bars, Passion One text, beveled border and shadow; power number left, health % right (hidden at full, red to green); target name abbreviated ("L. B. CONSTRUCT"); target of target as a colored name; focus and pet 140×26; boss 160×20 | LynUI (oUF) |
| Cast bars | Striped bar over the player, focus and pet health bars, spell name in capitals below; big target bar near screen center, green when interruptible, grey when not | LynUI (oUF) |
| Auras | Important procs above the player; your debuffs above and its buffs below the target; gold duration text | LynUI (oUF) |
| Class resources | Slim segmented strip on top of the player frame, hidden when unused; DK runes the same way | LynUI (oUF) |
| Action bars | Lyn bevel around every button; Lyn layout on the stone strip (see EllesmereUI integration) | EllesmereUI + LynUI skin |
| Chat | Transparent, borderless, class-colored tabs, input below; compact loot/xp/rep/quest/achievement/raid/AFK lines; AFK replies and join spam hidden | EllesmereUI engine + LynUI filters |
| Stone strip | Stone band along the screen bottom with metal trim (gold, class, dark or black) | LynUI |
| Menu button | Race portrait; left-click micro menu, right-click game menu, shift+right-click reload, shift+drag move | LynUI |
| Minimap | Square with a gold border | EllesmereUI (styled by install) |
| Media | Fonts: Lyn Roboto Slab (+ Regular), Lyn Passion One, Lyn Cameltoe. Bars: Lyn Fer35, Smooth, Striped, Gradient. All in SharedMedia | LynUI |

## Midnight rules we designed around

Midnight hands addons "secret" values in combat and instances, so every Lyn trick that did math or string work on game data was rebuilt.

| Rule | What breaks | What LynUI does instead |
| --- | --- | --- |
| Health and power are secret in combat | Comparisons like "hide at 100%" or "under 75%" error | Client-evaluated curves: a step curve sets the text's alpha to 0 at full; a color curve gives the red-to-green percent color; `AbbreviateNumbers` formats values |
| Unit names and cast flags can be secret | Uppercasing, abbreviating, interrupt checks | Only transform names when not secret; cast bar color picked with `C_CurveUtil.EvaluateColorValueFromBoolean` |
| Chat lines are secret in instances, M+ and PvP | Replacing `AddMessage` or the `CHAT_*_GET` strings taints Blizzard's chat handler and breaks whispers | Only message filters (the sanctioned route), skipping secret messages; EllesmereUI's engine renders the chat |
| Writing fields onto Blizzard secure frames taints them | Button borders stored on action buttons | Borders tracked in LynUI's own table |
| Secure frames can't change in combat | Unit frame scale, positions, aura containers, cast bar toggles | Queued with `ns:AfterCombat` and applied when combat ends |
| Legion spell IDs are gone | Lyn's player aura whitelist | The game's `IMPORTANT` aura filter |

One unconfirmed piece: whether `SetTextColor` accepts a secret color. If the client refuses, the health percent falls back to white with no error.

## EllesmereUI integration

`/lyn install` builds an EllesmereUI profile named "Lyn" through EllesmereUI's own export and import, so other profiles stay untouched and switching back is one click in EllesmereUI's Profiles page.

1. Exports the active profile in full: every module, unlock layout, cooldown manager and spells, global settings, spec overrides, window skins.
2. Applies the Lyn look, then imports it as "Lyn" (keeping your UI scale and spec assignments). If you are already on "Lyn", it restyles it in place instead.
3. Reloads.

What the Lyn look changes:

| Module | Change |
| --- | --- |
| Fonts | Global font Lyn Roboto Slab, shadow outline; raid frames pinned to your previous font (Expressway) |
| Unit frames | EllesmereUI's player, target, target of target, focus, pet and boss frames hidden (LynUI draws them); remaining units get Fer35, class color, dark solid border |
| Action bars | 32px buttons (pet 28px), 5px spacing, EllesmereUI border off (Lyn bevel instead), no macro names, keybind 10 / count 14; main bar and bar 2 on the stone strip, bar 3 bottom right, bars 4 and 5 above it, bar 6 centered above, stance to its left, pet bottom left; bars 3, 4, 5 and pet fade to 30% until hovered; unlock-mode anchors removed for these bars; bars 7 and 8 and hidden bars left alone |
| Chat | No background or borders, font 12, class-colored active tab and grey others, no tab backgrounds or underline, side buttons hidden, input below, no idle fade, 400×250 at bottom left (50, 95) |
| Minimap | Square, solid 2px gold border |

The settings panel can apply the bar layout or the chat style alone to the active profile. To undo everything, switch back to your original profile ("DPS") in EllesmereUI.

## Settings and commands

All settings live in Esc > Options > AddOns > LynUI (or `/lyn`, or "LynUI settings" in the menu button). Everything applies instantly except turning the unit frames on or off, which needs a reload; unit frame changes made in combat apply when combat ends.

| Page | Controls |
| --- | --- |
| LynUI | Move unit frames, reset their positions, reload; install or re-apply the Lyn profile, include bar layout, include chat style; keep raid frames on original font |
| Unit frames | Enable (reload), scale 0.5–1.5, bar texture and font (any SharedMedia entry), class resource strip, player cast bar, target cast bar, procs, target debuffs, target buffs |
| Action bars | Lyn button borders, border color (dark grey, gold, class, black), apply Lyn layout to EllesmereUI |
| Chat | Compact messages, hide AFK replies and join spam, apply Lyn chat style to EllesmereUI |
| Stone strip and menu | Strip on/off, height 20–80, trim color; menu button on/off, size 20–48, reset position |

| Command | Effect |
| --- | --- |
| `/lyn` | Open the settings |
| `/lyn install` | Create or re-apply the Lyn EllesmereUI profile |
| `/lyn move` | Unlock or lock unit frames for dragging |
| `/lyn resetframes` | Unit frames back to Lyn's layout |
| `/lyn resetmenu` | Menu button back to bottom right |
| `/lyn raidfont` | Keep EllesmereUI raid frames on your original font |

## Proposed layout and performance

The proposed screen keeps combat information in one oval around the character and pushes everything else to the edges. It is a mockup, not yet built into `/lyn install`.

| Ring | Contents | In combat |
| --- | --- | --- |
| Combat core (center) | Player and target frames, class resource strip, essential cooldowns with utility cooldowns below, procs above the player, your debuffs above the target, target cast bar, extra/zone button; main bar and bar 2 on the stone strip | Always visible |
| Status (middle) | Party/raid left, focus and pet near them, boss frames right, buffs and debuffs beside the minimap | Always visible |
| Edges | Chat bottom left, quest tracker under the minimap, damage meter bottom right, bars 3–5 and the menu | Tracker hides, chat dims, bars stay at 30% until hovered |

Performance guidelines:

- One addon per job: EllesmereUI for bars, cooldowns, raid, minimap and chat; LynUI only for unit frames and styling. No second bar, cooldown or unit frame addon.
- Use EllesmereUI's cooldown manager (built on Blizzard's cooldown viewer) rather than aura-tracking addons.
- Fade or turn off unused bars (7, 8; bar 6 on mouseover) to cut button updates.
- LynUI runs no timers of its own: frames update on events, and the hide-at-full and color effects are computed by the game.
- Details is the heaviest combat addon here: one window, lower update rate.

## Known limitations and next steps

All Lua files parse and the chat rewrites were tested in a Lua VM, but the latest round (settings panel, live controls) has not been run in game yet.

- **Chat text:** Lyn's `/g Name:` tags, bracketless names and whisper arrows can't be done safely in Midnight; EllesmereUI's `[G]` tags are used. Exact `/g` would need a hook in EllesmereUI's chat engine.
- **Chat tabs:** EllesmereUI has no hover-only tabs, so inactive tabs stay visible in grey.
- **Target power bar:** if the game hides a target's max power in combat, its power bar stays visible instead of collapsing.
- **Stone strip texture:** uses an old Blizzard texture; if it ever shows as a green block, LynUI needs its own copy.
- **Party frames:** Lyn's party frames were not ported; EllesmereUI raid frames handle groups.
- **Bar layout:** re-running the install resets bar positions to the Lyn layout.

Next steps:

- [ ] First in-game pass of the settings panel and live controls
- [ ] Decide on the proposed layout and add it to `/lyn install`
- [ ] Optional: port Lyn's party frames
- [ ] Optional: bundle a stone texture
