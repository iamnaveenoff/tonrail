---
name: Tonrail
description: The headphones' remote as a precise anthracite audio panel; few controls, each exact.
colors:
  signal-orange: "#EE6A24"
  signal-orange-ink: "#1A0D05"
  signal-orange-wash: "#3A2214"
  signal-orange-deep: "#B6461A"
  running-green: "#74B884"
  running-green-deep: "#2F7A42"
  fault-coral: "#FF8B7A"
  fault-red: "#B3261E"
  fault-ink: "#3B0A04"
  anthracite-ground: "#1E1F1F"
  recess: "#171818"
  panel-face: "#262727"
  panel-raised: "#2B2C2C"
  key-high: "#333434"
  key-top: "#3C3D3D"
  hairline: "#404141"
  rule-grey: "#6E6A63"
  warm-grey-legend: "#B0ABA2"
  bone-ink: "#ECE8E1"
  graphite: "#292927"
  enclosure-tile: "#1C1C1B"
  slider-metal: "#8E8A82"
  paper-ground: "#E8E5DE"
  paper-face: "#EFEDE8"
  paper-hairline: "#D2CEC5"
  paper-legend: "#5A564F"
  paper-ink: "#1C1C1B"
typography:
  headline:
    fontFamily: "Archivo, sans-serif"
    fontSize: "28px"
    fontWeight: 600
    lineHeight: "36px"
    letterSpacing: "-0.5px"
  headline-small:
    fontFamily: "Archivo, sans-serif"
    fontSize: "24px"
    fontWeight: 600
    lineHeight: "32px"
    letterSpacing: "-0.3px"
  title:
    fontFamily: "Archivo, sans-serif"
    fontSize: "22px"
    fontWeight: 600
    lineHeight: "28px"
    letterSpacing: "-0.2px"
  title-small:
    fontFamily: "Archivo, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: "20px"
    letterSpacing: "0px"
  body:
    fontFamily: "Archivo, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: "24px"
    letterSpacing: "0.1px"
  body-small:
    fontFamily: "Archivo, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: "16px"
    letterSpacing: "0.2px"
  label:
    fontFamily: "Archivo, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: "20px"
    letterSpacing: "0.3px"
  legend:
    fontFamily: "Archivo, sans-serif"
    fontSize: "11px"
    fontWeight: 600
    lineHeight: "16px"
    letterSpacing: "1.4px"
  readout:
    fontFamily: "Archivo, sans-serif"
    fontSize: "28px"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "-0.5px"
    fontFeature: "tnum"
rounded:
  cell: "1px"
  key: "12px"
  field: "14px"
  panel: "16px"
  dialog: "20px"
  sheet: "22px"
  stadium: "9999px"
spacing:
  hair: "2px"
  xs: "4px"
  sm: "8px"
  key-gap: "10px"
  md: "12px"
  icon-gap: "14px"
  gutter: "16px"
  header-x: "20px"
  sheet-x: "24px"
  section: "28px"
components:
  button-primary:
    backgroundColor: "{colors.bone-ink}"
    textColor: "{colors.paper-ink}"
    typography: "{typography.label}"
    rounded: "{rounded.key}"
    padding: "14px 18px"
    height: "52px"
  button-primary-light:
    backgroundColor: "{colors.graphite}"
    textColor: "{colors.bone-ink}"
    rounded: "{rounded.key}"
  button-primary-disabled:
    backgroundColor: "{colors.key-high}"
    rounded: "{rounded.key}"
  button-outlined:
    backgroundColor: "transparent"
    textColor: "{colors.bone-ink}"
    typography: "{typography.label}"
    rounded: "{rounded.key}"
    padding: "14px 16px"
    height: "52px"
  button-text:
    backgroundColor: "transparent"
    textColor: "{colors.bone-ink}"
    typography: "{typography.label}"
    rounded: "{rounded.key}"
    height: "52px"
  button-destructive:
    backgroundColor: "{colors.fault-coral}"
    textColor: "{colors.fault-ink}"
    rounded: "{rounded.key}"
  panel:
    backgroundColor: "{colors.panel-face}"
    rounded: "{rounded.panel}"
  panel-row:
    textColor: "{colors.bone-ink}"
    typography: "{typography.body}"
    padding: "12px 12px 12px 16px"
    height: "64px"
  slide-switch-track:
    backgroundColor: "{colors.recess}"
    rounded: "{rounded.panel}"
    padding: "4px"
    height: "56px"
  slide-switch-thumb:
    backgroundColor: "{colors.key-top}"
    textColor: "{colors.bone-ink}"
    typography: "{typography.label}"
    rounded: "{rounded.key}"
  scene-key:
    backgroundColor: "{colors.recess}"
    textColor: "{colors.bone-ink}"
    rounded: "{rounded.field}"
    padding: "10px 10px 10px 12px"
    height: "84px"
  scene-key-selected:
    backgroundColor: "{colors.key-top}"
    textColor: "{colors.bone-ink}"
    rounded: "{rounded.field}"
  moment-key:
    backgroundColor: "{colors.panel-face}"
    textColor: "{colors.bone-ink}"
    typography: "{typography.title-small}"
    rounded: "{rounded.panel}"
    padding: "14px 12px 12px 14px"
    width: "156px"
  moment-key-active:
    backgroundColor: "{colors.key-high}"
    textColor: "{colors.bone-ink}"
    rounded: "{rounded.panel}"
  icon-tile:
    backgroundColor: "{colors.key-top}"
    textColor: "{colors.bone-ink}"
    rounded: "{rounded.key}"
    size: "40px"
  chip-selected:
    backgroundColor: "{colors.signal-orange}"
    textColor: "{colors.signal-orange-ink}"
    typography: "{typography.label}"
    rounded: "{rounded.key}"
  input:
    backgroundColor: "{colors.panel-raised}"
    textColor: "{colors.bone-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.key}"
  nav-bar:
    backgroundColor: "{colors.panel-face}"
    textColor: "{colors.warm-grey-legend}"
    height: "76px"
  nav-indicator:
    backgroundColor: "{colors.signal-orange-wash}"
    textColor: "{colors.signal-orange}"
    rounded: "{rounded.stadium}"
  snackbar:
    backgroundColor: "{colors.bone-ink}"
    textColor: "{colors.paper-ink}"
    rounded: "{rounded.field}"
---

# Design System: Tonrail

## Overview

**Creative North Star: "The Regie Panel"**

The app is the headphones' remote, built as the front panel of a piece of hi-fi in the Braun Regie / Atelier lineage: a matte anthracite enclosure, warm-grey printed legends, and controls that each do one exact thing. The dark theme is the product; the light theme is the same panel in warm paper, with the same roles and the same restraint. Material 3 governs structure (navigation bar, sheets, dialogs, switches, list rows), and the panel world dresses it: tonal surfaces, hairline edges, tracked-caps legends, physical state marks.

Density is calm and one-handed. A screen is a stack of legend-plus-panel sections on a 16dp gutter. The primary selector is a detented slide switch, not a segmented button; state reads as a lit, hairline or struck mark; the noise mode shows as a perforated grille of dots that draws inward or spreads outward. The build softened the original square shoulders into 12dp keys and 16dp panels, lifted the ground from near-black to a mid anthracite, gave the navigation a stadium indicator, set row icons in rounded tiles, and puts a drawn (never photographed) headphone on the Listen header. Those choices are now the system. Actions are neutral; orange is spent only on what is currently on.

**Key Characteristics:**
- Mid-anthracite tonal ladder; depth by surface step and 1dp hairline, not shadow.
- One signal orange for "active", one running green for "connected"; actions stay neutral.
- One grotesque (Archivo) in every role; small legends in tracked caps.
- Perforated dot grilles as the signature texture: the noise field, EQ reference rows, the launcher mark, the cup grilles.
- Physical state marks: detents on switch positions and lists, a lit edge on selected keys.

## Colors

A near-monochrome warm anthracite panel with exactly two lamps: orange for the active state, green for the running link.

### Primary
- **Signal Orange**: the only active-state color. Selected nav icon, slide-switch detent, selected scene key and active Moment edge, EQ curve and selected handle core, slider fill, switch track, selected chips, focused field border, lit grille dots, the "unsaved" detent. Never a button fill. **Signal Orange Deep** carries the same role in the light theme. **Signal Orange Wash** is the tonal container behind the selected nav destination (orange at 18% in dark, 14% in light).

### Tertiary
- **Running Green**: the status lamp beside the device name when the control link runs, the charging bolt, and the illustration's LED. Never a button, never decoration. **Running Green Deep** in light.

### Neutral
- **Anthracite Ground**: scaffold, app bar, splash and the Android launch window (they match so launch never flashes).
- **Recess**: the sunken wells: slide-switch track, unselected scene keys, ± steppers and symbol keys.
- **Panel Face**: panels, cards, nav bar, bottom sheets; the default raised face.
- **Panel Raised / Key High / Key Top**: progressively raised faces: link banner and inputs; active Moment, dialogs and disabled filled buttons; slide-switch thumb, selected keys and icon tiles.
- **Hairline**: every 1dp panel edge, divider, unselected key border and inactive slider track.
- **Rule Grey**: off-state detent rings, EQ zero line, drag handle.
- **Warm-Grey Legend**: legends, subtitles, values, unselected nav, axis labels, EQ band stems.
- **Bone Ink**: primary text, the slider/EQ thumb face, and the fill of primary buttons and snackbars (inverse surface).
- **Graphite**: the inverse surface in light theme, so primary buttons there are dark keys with Bone Ink text.
- **Enclosure Tile / Slider Metal**: the launcher adaptive-icon ground and its grille dots (also the splash mark).
- **Paper Ground / Paper Face / Paper Hairline / Paper Legend / Paper Ink**: the light theme's equivalents of ground, panel, hairline, legend and text.
- **Fault Coral / Fault Red**: destructive rows and confirm buttons, and the low-battery cells only.

### Named Rules
**The Two Lamps Rule.** Orange means "this is the active setting"; green means "the link is running". No third hue, no decorative use of either, and green never marks a selection.

**The Neutral Action Rule.** Buttons are not lamps. Primary actions are inverse-surface keys (Bone Ink in dark, Graphite in light), secondary actions are hairline outlines, text actions are ink. If a control is orange, it must be reporting a current state.

**The Lit-Only-When-Active Rule.** An option is orange only while it is the current state. Rest states are hairline grey; disabled states are struck through, never merely faded orange.

## Typography

**Display Font:** Archivo (bundled: Regular, Medium, SemiBold, Bold)
**Body Font:** Archivo
**Label/Mono Font:** Archivo with tabular figures for every numeric readout

**Character:** One sober grotesque in every role, tightened slightly at headline sizes and opened wide at legend size, like the printing on a hi-fi faceplate.

### Hierarchy
- **Headline** (600, 28/36, −0.5): the noise mode readout in the grille core and the battery percentage. Both sit in fixed cells and roll in vertically, never reflow.
- **Headline Small** (600, 24/32, −0.3): the screen title in every tab's header and the splash word.
- **Title** (600, 22/28, −0.2): app bar, sheet and dialog titles.
- **Title Small** (600, 14/20): Moment and scene names, link banner title.
- **Body** (400, 16/24, +0.1; rows use 500): row titles, choice-sheet options. **Body Small** (12/16, +0.2) in Warm-Grey Legend for subtitles and hints.
- **Label** (600, 14/20, +0.3): buttons, slide-switch positions, chips.
- **Legend** (600, 11/16, +1.4, UPPERCASE): the section legend above each control group and right-aligned state readouts ("CANCELLING", "OUTPUT −4.5 DB", "CHANGED"). Status legends are orange only when they report an active mode; a "changed" tag is Bone Ink.

Display sizes are configured (500, negative tracking) but no surface uses them.

### Named Rules
**The Faceplate Legend Rule.** Every control group is named by one tracked-caps legend in Warm-Grey Legend, set immediately above its panel. A legend names controls or reports state; it is never a decorative line above a headline.

**The Tabular Readout Rule.** Every number that changes (battery, dB, frequency, timers) uses tabular figures so values never jitter.

## Layout

Single column, phone-first, edge-to-edge with transparent system bars. A 16dp gutter holds panels; screen headers sit at 20dp, sheets at 24dp. Each section is a 40dp legend line, 6dp gap, then its panel; sections open with 28dp above (20 to 24 where a section follows a lighter strip). Rows inside a panel are at least 64dp tall with 16dp leading padding, a 40dp icon tile and 14dp gap to the text; rows are separated by hairline dividers inset 16dp each side.

Finite option sets stay fully visible: the five noise environments sit in a 3-column wrapping grid with 8dp gaps, keys 84dp tall growing to 140dp with system text scale, so the active one is never scrolled away. Open-ended rosters (Moments) scroll horizontally with 10dp gaps, 148 to 220dp tall with text scale. Every tap target is at least 52dp. The bottom navigation bar is 76dp with labels always shown.

## Elevation & Depth

Flat by default. Depth comes from the tonal ladder (Recess → Ground → Panel Face → Panel Raised → Key High → Key Top) plus a 1dp hairline on every panel and key. App bar, nav bar, cards and sheets carry zero elevation and no surface tint. Shadow appears only on the moving physical part of a control.

### Shadow Vocabulary
- **Key shadow** (`0 1px 3px rgba(0,0,0,0.25)`): the slide-switch thumb only, so it reads as a cap riding in its track.
- **Thumb shadow** (`0 1px 2px blur rgba(0,0,0,0.35)`): the selected EQ handle; slider thumbs use Material elevation 1, 2 when pressed.
- **Snackbar** (elevation 2): floating confirmation.

### Named Rules
**The Hairline-Not-Shadow Rule.** A panel separates from the ground by a tonal step and a 1dp hairline. If a static container needs a shadow to read, raise its tone instead.

## Shapes

Soft-shouldered hardware: 12dp keys (buttons, chips, icon buttons, inputs, list rows, slide-switch thumb, tooltips), 14dp for scene keys, symbol keys and the snackbar, 16dp for panels, the slide-switch well, Moment keys and menus, 20dp for dialogs and 22dp for the bottom-sheet top. Icon tiles round at 30% of their size. The stadium is reserved for the selected navigation indicator. Battery cells are near-square (1dp). Circles are reserved for marks: detents, the status lamp, grille dots and EQ handles. Borders are always 1dp hairlines; 1.5dp only for a selected scene key, an active Moment and a focused field, always in Signal Orange.

## Components

### Buttons
- **Shape:** gently squared key (12dp), 52dp minimum on every button and icon button.
- **Primary (Filled):** inverse surface: Bone Ink with Paper Ink text in dark, Graphite with Bone Ink text in light; 14 × 18 padding. Used for the single confirming action in banners and sheets (Connect, Allow, Save moment, Restore). Disabled drops to Key High.
- **Destructive confirm:** the same key filled Fault Coral with dark ink, only inside a confirmation dialog.
- **Outlined:** transparent with Bone Ink text and a hairline border. The default for on-page actions, including the Sound header's Save, Hold to compare and Start flat.
- **Text:** Bone Ink label, used for trailing section actions ("Save current") and dialog cancels.
- **Press:** Material ink sparkle; no hover treatments on the target platform.

### Slide Switch (signature)
The panel's primary selector (noise Off / Cancel / Aware, strength Low / Medium / High). A Recess well (16dp radius, 4dp inset, hairline) holds a Key Top thumb (12dp, key shadow) that glides 320ms easeOutQuart; tap a position or drag across with a selection haptic per detent. Each position shows a 7dp detent plus its label; the selected label goes Bone Ink. Disabled: thumb drops to Key High, labels fade, detents strike through.

### Detent and Status Lamp
- **Detent:** filled Signal Orange when on, 1dp Rule Grey ring when off, ring with a diagonal strike when unavailable. Used in slide switches, Moment keys, preset lists, choice sheets, and beside the Sound title to flag an unsaved curve.
- **Status Lamp:** an 8dp Running Green detent when linked; a pulsing grey dot (1100ms) while searching; hollow when offline.

### Noise Field (signature)
A perforated grille on a 13dp pitch around a hollow core holding the mode readout. Cancelling rolls light inward and pulls dots toward the core; Aware rolls light outward; Off rests in Rule Grey. Lit dots lerp to Signal Orange; a hairline core rim tracks the mode. Mode changes cross-fade over 520ms; reduce-motion freezes to a still lit pattern.

### Cards / Containers (Panel)
- **Corner Style:** 16dp.
- **Background:** Panel Face (link banner uses Panel Raised).
- **Shadow Strategy:** none; see Elevation & Depth.
- **Border:** 1dp hairline.
- **Internal Padding:** rows carry their own 16dp padding; grouped rows are split by inset hairlines. Never nest one panel inside another.

### Keys (scene, Moment, symbol)
- **Scene key:** one cell of the 3-column environment grid. Recess with a hairline, name in Title Small and a two-line hint. Selected rises to Key Top with a 1.5dp Signal Orange edge; no detent, the edge is the mark.
- **Moment key:** 156dp wide, Panel Face, 16dp; a 38dp icon tile top-left, detent top-right, name and two legend lines at the foot. Active rises to Key High with a 1.5dp Signal Orange edge. Long-press opens an action sheet.
- **Symbol key:** 52dp square, 14dp, Recess; selected rises to Key Top with an orange edge and orange glyph.

### Lists and Icon Tiles
- **Panel row:** icon tile, 500-weight title, Body Small subtitle, tabular value, then a switch or chevron. Destructive rows tint title and tile Fault Coral.
- **Icon tile:** 40dp rounded tile in Key Top with Bone Ink glyph at 52% size; selected uses a 16% orange wash with an orange glyph; a tone (error) uses a 14% wash.

### Chips
- **Style:** 12dp, Panel Face with a hairline, label typography, no checkmark.
- **State:** selected fills Signal Orange with dark ink.

### Inputs / Fields
- **Style:** filled Panel Raised, hairline outline, 12dp.
- **Focus:** border shifts to 1.5dp Signal Orange; cursor and selection handles orange.

### Navigation
Material 3 bottom navigation bar, 76dp, Panel Face, no elevation or tint, labels always shown. Icons 22dp in Warm-Grey Legend; the selected destination gets a Signal Orange icon on a stadium Signal Orange Wash indicator and a Bone Ink label. Pages fade forward between routes.

### EQ Editor
A log-frequency plot: perforated dot rows at ±4 and ±8 dB, a solid zero rule, three vertical hairlines at 100, 1k and 10k. Each band is a point on a stem from 0 dB: the points are the band levels, the orange line is the summed response you hear. The response curve is a 2.2dp Signal Orange stroke over a 12% orange fill. Unselected bands are hollow rings on 1.5dp Warm-Grey Legend stems at 45%; the selected band is a Bone Ink disc with an orange core on a 2dp orange stem at 50%, inside a faint column. Factory tunings show the bands as thin grey rings without stems. Double-tap resets a band, with haptics at 0 dB and the limits. A 10-fader strip and ± steppers under the plot edit the selected band.

### Battery Cells
Five 5 × 12dp cells: lit cells in Bone Ink, empty cells as hairline outlines, all lit cells Fault Coral at 15% or below, plus a green bolt when charging.

### Headphone Illustration
The Listen header carries a drawn, generic over-ear headphone in matte anthracite with perforated cups, a green LED and an orange multifunction button. It brightens and scales up over 700ms when connected and recedes dimmed when offline. It is an illustration, not a source of tokens.

## Do's and Don'ts

### Do:
- **Do** name every control group with one tracked-caps Legend (11/600/+1.4) above a 16dp hairline panel.
- **Do** use the Slide Switch for any 2 to 4 position mutually exclusive setting, with a detent on every position.
- **Do** keep a finite option set fully visible in a grid rather than a scrolling strip.
- **Do** keep Signal Orange for the current state only, and Running Green for the link only.
- **Do** make actions neutral: inverse-surface filled keys, hairline outlined keys, ink text buttons.
- **Do** separate surfaces by tonal step plus a 1dp hairline, keeping containers at zero elevation.
- **Do** set every changing number in tabular figures inside a fixed-size cell.
- **Do** give every custom-painted control a semantics label, honor reduce-motion (switch to still states) and keep targets at 52dp.
- **Do** keep the launch window, splash and scaffold on Anthracite Ground so launch never flashes.

### Don't:
- **Don't** fill a button, tag or text action with Signal Orange; orange reports state, it does not invite action.
- **Don't** introduce a third accent hue or color a control decoratively.
- **Don't** put a shadow on a static container; shadows belong to moving caps and thumbs.
- **Don't** nest a panel inside a panel.
- **Don't** use the stadium shape except on the selected navigation indicator.
- **Don't** add a second typeface; Archivo covers every role.
- **Don't** use product photography or any headphone maker's logos or trade dress; the headphone stays drawn and generic.
