XP12 Forest Density Tweak  v1.0
===============================

Denser forests for X-Plane 12. The vegetation slider can never exceed the tree
density defined in the forest files (.for) - this tool lowers the tree spacing
there. Default factor 0.7 = roughly twice as many trees per area.

Tested with X-Plane 12.4.4.


WHICH EDITION?
--------------
  Start_Vanilla-simHeaven.bat  -> plain X-Plane 12, or with simHeaven X-World
                                  (simHeaven uses the default forests)
  Start_GlobalForestsV2.bat    -> with Global Forests v2 (GeoReality);
                                  also tweaks the default forests used
                                  outside GFv2 coverage

Running both editions is safe: they share one backup log, nothing is ever
scaled twice.


HOW TO USE
----------
1. Close X-Plane.
2. Unzip anywhere (or into your X-Plane 12 folder - then it is found
   automatically). Otherwise the script finds X-Plane via x-plane_install_12.txt
   or asks for the path.
3. Double-click the .bat of your edition.
4. Menu: [1] Apply   [2] Restore original   [3] Status

  Factor: 0.7 recommended. 0.8 = milder / cheaper, 0.6 = very dense (strong GPU).
  To change the factor: Restore first, then Apply with the new value.

Grass, shrubs and hedges (spacing <= 3.1 m) are not changed.
Only two header lines per file are edited; the 3D tree models stay byte-identical.


BACKUP / UNDO
-------------
Original values are logged in  <X-Plane 12>\ForestDensityTweak\backup.log
"Restore" writes them back exactly. Do not delete this folder while the tweak
is active. Alternative for the default forests: run the X-Plane installer
("Update") - it repairs modified files.


AFTER AN UPDATE
---------------
X-Plane and Global Forests updates replace the forest files with originals.
Just run "Apply" again - the tool detects which files were reset.


PERFORMANCE
-----------
More trees = more GPU load, especially low over large forests. Check your FPS
and go to 0.8 if needed.


Use at your own risk. Not affiliated with Laminar Research, simHeaven or
GeoReality.
