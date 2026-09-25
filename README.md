# LynUI (Midnight)

LynUI 2016 (Legion), rebuilt as a small companion to **EllesmereUI**. EllesmereUI
handles unit frames, action bars, minimap, chat, bags and so on, and it already
works with Midnight's secret values and Edit Mode. LynUI adds Lyn's look on top.

## What it adds

- **Lyn's unit frames** (player, target, target of target, focus, pet, boss),
  ported from oUF_Lyn to the current Midnight-compatible oUF (embedded in
  `libs\oUF`). They have Fer35 bars, Passion One text, the beveled border and
  shadow, the striped cast bar over the health bar, and the big target cast
  bar. Health and power numbers are secret values in combat, so the "hide at
  full" and color gradients use client-side curves instead of Lua math.
- **Media**: Lyn's fonts (Roboto Slab, Passion One, Cameltoe) and bar textures
  (Fer35, Smooth, Striped, Gradient), registered with SharedMedia so they show up
  in every EllesmereUI font and texture dropdown.
- **`/lyn install`**: copies your current EllesmereUI profile into a new profile
  called "Lyn", then applies the Lyn look: Roboto Slab font, Fer35 class-colored
  health bars, dark 1px borders on unit frames and action bars, and a square
  minimap with a gold border. Your layout, cooldown manager and spells stay as
  they are.
- **Lyn's action bars** on top of EllesmereUI's: `/lyn install` lays them out
  the Lyn way (main bar and bar 2 on the stone strip, bar 3 bottom right,
  bars 4 and 5 stacked above it, faded until moused over) with 32px buttons.
  LynUI draws Lyn's beveled border around every button.
- **Stone info bar**: the stone strip with gold trim along the bottom of the screen.
- **Menu button**: a race portrait. Left-click opens the micro menu, right-click
  opens the game menu, shift + right-click reloads, shift + drag moves it.
- **Lyn's chat window** (via `/lyn install`, on EllesmereUI's chat engine):
  no background or borders, plain tabs (class colored when active, grey
  otherwise), input box below, no side buttons, 400x250 at the bottom left.
- **Compact chat**: shorter loot, currency, reputation, XP, skill, quest and
  friend online/offline lines. It works in any client language.

## Settings

Everything is in **Esc > Options > AddOns > LynUI** (or type `/lyn`, or pick
"LynUI settings" from the menu button). Changes apply immediately, except
turning Lyn's unit frames on or off, which needs a reload. Changes to unit
frame parts and scale made in combat apply when combat ends.

- **LynUI**: move/reset unit frames, reload, install or re-apply the Lyn
  EllesmereUI profile (and what it includes), keep raid frames on your font.
- **Unit frames**: on/off, scale, bar texture, font (any SharedMedia texture
  or font), and each part: class resource strip, player/target cast bars,
  procs, target buffs and debuffs.
- **Action bars**: Lyn button borders and their color; apply the Lyn bar
  layout to EllesmereUI.
- **Chat**: compact messages, hide AFK replies and join spam; apply the Lyn
  chat style to EllesmereUI.
- **Stone strip and menu**: strip on/off, height, trim color; menu button
  on/off, size, reset position.

## Commands

| Command | Effect |
|---|---|
| `/lyn` | Open the settings |
| `/lyn install` | Create or re-apply the "Lyn" EllesmereUI profile |
| `/lyn move` | Unlock or lock the unit frames for dragging |
| `/lyn resetframes` | Put the unit frames back in Lyn's original layout |
| `/lyn resetmenu` | Move the menu button back to its default spot |
| `/lyn raidfont` | Keep EllesmereUI's raid frames on your original font |

## Optional extras in EllesmereUI

- Floating combat text font: choose **Lyn Cameltoe** in EllesmereUI's font settings.
- Lyn's class colors (from the old `!swag` addon): set them in EllesmereUI's custom colors.
