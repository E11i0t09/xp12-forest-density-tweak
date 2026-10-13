# XP12 Forest Density Tweak

**Denser, more realistic forests for X-Plane 12 – for vanilla, simHeaven X-World and Global Forests v2.**

Even with the vegetation slider at maximum, X-Plane 12 forests often look like loose groups of trees instead of a forest. That's because the slider can never go above the density set in the forest definition files (`.for`). This tool lowers the tree spacing in those files, safely and reversibly.

Default factor 0.7 ≈ **twice as many trees per area.**

Tweaked
<img width="3839" height="2159" alt="Screenshot_14" src="https://github.com/user-attachments/assets/0d63d504-4830-487d-bc6b-1ec4a3617fa7" /> 

Vanilla
<img width="3839" height="2159" alt="Screenshot_16" src="https://github.com/user-attachments/assets/11fe19c2-0c84-4c32-ae9d-50b301609397" />

---

## Features

- **Two editions:** pick the one that matches your scenery setup
- **Simple menu:** Apply · Restore original · Status. No command line needed
- **Factor of your choice:** 0.4 – 1.0, default 0.7
- **Fully reversible:** the original values are logged and restored byte-for-byte
- **Survives updates:** after an X-Plane or Global Forests update, just run *Apply* again. Files that were reset are detected and tweaked again
- **Never applied twice:** both editions share one backup log, so the default forests are only ever scaled once
- **Grass, shrubs and hedges are left alone:** only files with a spacing above 3.1 m are changed
- **Minimal changes:** only two header lines per file (`SPACING`, `RANDOM`) are edited. The 3D tree meshes stay byte-identical
- **Safe if interrupted:** the change is logged before each file is written, and every file is written to a temp copy and then swapped in

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
   - `1` **Apply.** Enter a factor or just press Enter for 0.7
   - `2` **Restore original**
   - `3` **Status.** Shows how many forest files are tweaked or original

No admin rights needed. Windows only (PowerShell, which ships with Windows 10/11).

### Choosing a factor

| Factor | Effect | GPU load |
|---|---|---|
| 0.8 | noticeably denser | low |
| **0.7** | **≈ 2× trees, recommended** | medium |
| 0.6 | very dense | high |

To change the factor, choose *Restore* first and then *Apply* with the new value.

## How it works

Every `.for` file defines the grid that trees are placed on:

```
SPACING 13 13    # distance between trees in metres
RANDOM  8 8      # how far each tree may deviate from that grid
```

The tool multiplies both values by your factor. RANDOM is scaled too, so the forest keeps the same natural irregularity instead of trees clumping together.

Folders that are changed:

- `Resources\default scenery\1200 forests` (both editions)
- `Custom Scenery\Global_Forests_v2` (GFv2 edition only)

The original values are kept in `<X-Plane 12>\ForestDensityTweak\backup.log`. **Don't delete this folder while the tweak is active.**

## Undo

- Use **Restore original** in the menu. It writes back the exact original values.
- Alternative for the default forests: run the X-Plane installer and choose *Update*. It repairs modified files.

## Performance

More trees means more GPU work, especially when flying low over large forests. Check your FPS after applying. If needed, restore and try 0.8.

## Compatibility

- Tested with **X-Plane 12.4.4**. The `.for` format and the `SPACING` command are documented in Laminar's [forest file format specification](https://developer.x-plane.com/article/forest-for-file-format-specification).
- Works alongside simHeaven X-World and Global Forests v2.
- Forests from other add-ons are not touched.

## Credits

Inspired by the `.for` spacing approach discussed on the X-Plane.org forums.

## Disclaimer

Use at your own risk. Not affiliated with Laminar Research, simHeaven or GeoReality.
