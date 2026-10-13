# XP12 Forest Density Tweak

**Denser, more realistic forests for X-Plane 12 – for vanilla, simHeaven X-World and Global Forests v2. Optionally smaller trees.**

Even with the vegetation slider at maximum, X-Plane 12 forests often look like loose groups of trees instead of a forest. That's because the slider can never go above the density set in the forest definition files (`.for`). This tool lowers the tree spacing in those files, safely and reversibly.

Default factor 0.7 ≈ **twice as many trees per area.**

---

## Features

- **Two editions:** pick the one that matches your scenery setup
- **Simple menu:** Apply · Restore original · Status. No command line needed
- **Factor of your choice:** 0.4 – 1.0, default 0.7
- **Optional tree height:** factor 0.5 – 1.0 scales min and max height of the trees, so the height variation shrinks along. The 3D tree models are scaled too, so near and far trees match
- **Fully reversible:** the original values are logged and restored byte-for-byte
- **Survives updates:** after an X-Plane or Global Forests update, just run *Apply* again. Files that were reset are detected and tweaked again
- **Never applied twice:** both editions share one backup log, so the default forests are only ever scaled once
- **Grass, shrubs and hedges are left alone:** only files with a spacing above 3.1 m are changed
- **Minimal changes:** only two header lines per file (`SPACING`, `RANDOM`) are edited. The 3D tree meshes stay byte-identical
- **Safe if interrupted:** the change is logged before each file is written, and every file is written to a temp copy and then swapped in
- **Optional in-sim window:** a small FlyWithLua script switches the forest density in 4 steps during flight, see below

## Which edition?

| Your setup | Run |
|---|---|
| Plain X-Plane 12 | `Start_Vanilla-simHeaven.bat` |
| X-Plane 12 + simHeaven X-World | `Start_Vanilla-simHeaven.bat` |
| X-Plane 12 + Global Forests v2 (GeoReality) | `Start_GlobalForestsV2.bat` |

simHeaven X-World links its forests to the X-Plane default forest files, so the vanilla edition covers it.
The GFv2 edition also tweaks the default forests, because they are still used outside GFv2 coverage.

## Installation & usage

1. **Close X-Plane.**
2. Download the latest ZIP from [Releases](../../releases) and unzip it anywhere. If you unzip it into your X-Plane 12 folder, it finds X-Plane automatically. Otherwise it reads `x-plane_install_12.txt` or asks for the path.
3. Double-click the `.bat` for your edition.
4. Choose from the menu:
   - `1` **Apply.** Asks for the density factor (Enter = 0.7) and the height factor (Enter = 1 = unchanged)
   - `2` **Restore original**
   - `3` **Status.** Shows how many forest files are tweaked or original

No admin rights needed. Windows only (PowerShell, which ships with Windows 10/11).

### Choosing a factor

| Factor | Effect | GPU load |
|---|---|---|
| 0.8 | noticeably denser | low |
| **0.7** | **≈ 2× trees, recommended** | medium |
| 0.6 | very dense | high |

### Tree height (optional)

| Height factor | Effect |
|---|---|
| **1.0** | **unchanged (default)** |
| 0.8 | trees 20 % smaller |
| 0.5 | half height (minimum) |

Min and max height of every tree are scaled by the same factor, so a tree that varied between 12 and 17 m now varies between 9.6 and 13.6 m at 0.8. Undergrowth, branches and stones inside the forest files are scaled along to keep the proportions. Density and height can be combined, or used on their own (density 1 = unchanged).

Smaller trees also need smaller 3D models (the close-up trees), otherwise they pop when switching from the distant billboards. The tool scales those models, which rewrites the forest files completely (a few minutes). Before that it stores a compressed copy of each original file in `ForestDensityTweak\mesh_backup` (about 30 % of the file size, roughly 1.5 GB with Global Forests v2) for an exact restore. The tool checks the free disk space first.

To change a factor, choose *Restore* first and then *Apply* with the new values.

## In-sim window (optional, FlyWithLua)

`ForestDensityToggle.lua` adds a small window to switch the forest density during flight in 4 steps (Original, Low, Medium, Dense), without touching any files, and shows the tree height set by the tweak (typical and tallest tree before/after, whether the 3D models are scaled). Handy for FPS-heavy areas or before/after comparisons.

**Requires:** the tweak applied (see above) and [FlyWithLua NG+](https://github.com/X-Friese/FlyWithLua) for X-Plane 12 (the download link is on that page). Without the tweak the script can only thin out the vanilla forests.

1. Copy `ForestDensityToggle.lua` to `X-Plane 12\Resources\plugins\FlyWithLua\Scripts\`
2. In the sim: *Plugins → Forest Density → Show / hide window* (fallback: *Plugins → FlyWithLua → FlyWithLua Macros → Forest density: window*)
3. Window: pick a step (blue) and press **Apply**; the active step is green.
   - **Reload scenery on apply** off (default): the new density shows on scenery that loads as you fly on.
   - On: it shows at once. X-Plane loads all scenery around you again, which takes a while because trees are placed while scenery loads (at most one reload per minute).

   Position, size and settings are remembered.
4. Optional key or joystick bindings (search `ForestDensity` in the settings):
   - `FlyWithLua/ForestDensity/window`
   - `FlyWithLua/ForestDensity/toggle`
   - `FlyWithLua/ForestDensity/dense`
   - `FlyWithLua/ForestDensity/original`

How it works: X-Plane multiplies the forest density from the `.for` files by the vegetation slider value (`forest/density`). The script sets that value between slider × factor² (about the original density) and the slider value (full tweaked density). The factor is read from the tweak's backup log. Trees are placed when scenery loads, so a change shows on newly loaded scenery, or at once with the optional reload. Changing graphics settings resets the value to the slider setting. Tree height can't be changed in the sim, only with the tweak.

## How it works

Every `.for` file defines the grid that trees are placed on:

```
SPACING 13 13    # distance between trees in metres
RANDOM  8 8      # how far each tree may deviate from that grid
```

The tool multiplies both values by your factor. RANDOM is scaled too, so the forest keeps the same natural irregularity instead of trees clumping together.

The tree list at the end of each file holds min and max height per tree type (`TREE … 12 17 …`, `TREE2 … 1.5 2.5 1.5 …`). The height factor scales these two values.

- `TREE2` trees have a nominal height that matches their 3D model; X-Plane scales the model to the chosen height by itself, so nothing else changes.
- `TREE` trees have no nominal height; their 3D models are built in real metres and drawn at that size. For these, the tool multiplies the vertex coordinates (`VERTEX x y z`) of the referenced models by the height factor.

With density only, just the header lines change and the 3D mesh data is copied byte for byte.

Folders that are changed:

- `Resources\default scenery\1200 forests` (both editions)
- `Custom Scenery\Global_Forests_v2` (GFv2 edition only)

The original values (density and height lines) are kept in `<X-Plane 12>\ForestDensityTweak\backup.log`. **Don't delete this folder while the tweak is active.**

## Undo

- Use **Restore original** in the menu. It writes back the exact original values.
- Alternative for the default forests: run the X-Plane installer and choose *Update*. It repairs modified files.

## Performance

More trees means more GPU work, especially when flying low over large forests. Check your FPS after applying. If needed, restore and try 0.8.

## Compatibility

- Tested with **X-Plane 12.4.4** and FlyWithLua NG 2.8.12. The `.for` format and the `SPACING` command are documented in Laminar's [forest file format specification](https://developer.x-plane.com/article/forest-for-file-format-specification).
- Works alongside simHeaven X-World and Global Forests v2.
- Forests from other add-ons are not touched.

## Credits

Inspired by the `.for` spacing approach discussed on the X-Plane.org forums.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## Disclaimer

Use at your own risk. Not affiliated with Laminar Research, simHeaven or GeoReality.
