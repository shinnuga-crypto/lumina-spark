# 未作画ギミックのGPTImage素材

2026-10-25 / GPT / 組み込み image_gen（APIキー不要）。原画の画素は変更していない。

- `props-surface.png`：地上の床・足場・防空屋根・支柱・跳躍台・搬送ベルト（6点）。
- `props-shaft.png`：地下の床・足場・隔壁/破損・崩れ床/亀裂・圧搾機の伸長/収納・封印装置（9点、差分含む）。
- 参照は既存の `../tiles.png`。既存ステージと同じ金属表現と発光色を引き継いだ。
- `tools/measure_props.py` がアルファの連結領域を測定し `props-regions.json` を保存する。圧搾機は筐体とヘッドの大きさを保ち、シャフトだけを伸縮させて描画する。

## 地上

```text
Production environment sprite atlas for the ground stage of LUMINA SPARK, original 2D anime sci-fi platform action game. Match the supplied reference's richly painted steel, crisp dark outlines and luminous trim, but use muted industrial blue-gray metal with cyan guide lights and small amber warning stripes. A TRANSPARENT alpha background, exactly 2 columns by 3 rows of equal square cells, with wide transparent gutters. Every object's rectangular bounding box must stay inside its own cell, leave 12 percent padding on each edge. Six isolated complete SIDE-VIEW objects, no perspective floor, no text or labels: top-left a wide heavy reinforced concrete-and-steel GROUND PLATFORM block, straight perfectly flat top, dark vented metal front; top-right a wide shallow floating CATWALK LEDGE, straight flat top, reinforced underside; middle-left a wide thick ARMORED ANTI-AIR SHELTER ROOF, shallow rectangular slab with cyan light along flat upper edge, no legs or posts; middle-right one tall thin vertical STEEL SUPPORT COLUMN for that shelter, straight cylindrical reinforced pillar with small flat base; bottom-left a compact wide JUMP-BOOSTER PAD, vent grille pointing straight upward, cyan energy emitter, no plume; bottom-right a wide shallow CONVEYOR BELT module with dark ribbed belt on flat top, visible side rollers and amber caution marks. Only the six sprites. Generous transparent separation, no overlap, no character, no environment backdrop. Objects face camera directly from the side for a 2D game.
```

## 地下

```text
Production environment sprite atlas for the underground stage of LUMINA SPARK, original 2D anime sci-fi action game. Match the supplied reference's crisp ink outlines and painted metal detail. Palette deep blue-violet steel, copper, worn brass, cyan energy accents and small amber warning stripes. TRANSPARENT alpha background. Exactly 3 columns by 3 rows of equal square cells, wide completely transparent gutters, each entire object including all tips must fit within central 76 percent of its cell. Nine isolated SIDE-VIEW game props with absolutely no overlap of bounding rectangles, no text or labels: row 1 left: wide heavy subterranean FLOOR block made of rock and riveted metal, perfectly flat upper collision edge; row 1 middle: wide thin reinforced CATWALK LEDGE with flat top and inset cyan light; row 1 right: wide shallow bronze DESTRUCTIBLE BULKHEAD slab in intact state, cracked central cyan energy lock inset, horizontal flat top. Row 2 left: wide shallow CRUMBLING ROCK-AND-METAL PLATFORM with slight hairline cracks, flat top; row 2 middle: EXACT SAME crumbling platform shape and dimensions but deeply cracked glowing amber and missing a few tiny chips, still intact enough to stand on; row 2 right: EXACT SAME bronze bulkhead from row 1 right but heavily damaged with fractured front plates, same bounding proportions. Row 3 left: a horizontal industrial CRUSHER PISTON fully extended from a square housing at LEFT to a broad heavy crushing head at RIGHT, no wall, complete machinery, profile view; row 3 middle: SAME piston retracted, same height of head and housing but compact horizontal length, no extra debris; row 3 right: a single round SHIELD SEAL DEVICE, intricate circular steel housing, bright cyan central crystal and concentric mechanical rings, front view. All machinery fully contained, no floor beneath, no backdrop, actual transparent alpha, no cast ground shadows. Strong silhouettes readable at small in-game sizes.
```
