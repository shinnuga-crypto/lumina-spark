# ステージ2・3のGPTImage素材

2026-10-25 / GPT / 組み込み image_gen。APIキーは使用していない。

- 採用: `actors-v2.png`（新敵4体＋飛行ボス＋壁面固定ボス、透過PNG）、`surface.png`、`underground.png`。
- 初版 `actors.png` は生成履歴として保存。初版はボスの翼の余白が狭かったため、同じデザインを保って再配置したv2を採用。
- 画像の画素は加工せず、`tools/measure_campaign.py` が透明領域の連結成分から描画範囲を測定し `regions.json` へ保存する。
- 元参照: `../improvements/miniboss.png`（描画スタイルのみ）。地上・地下背景は新規生成。

## 新敵・ボス初版

```text
Production game sprite atlas for LUMINA SPARK, an original anime sci-fi 2D platform action game. Use the reference only for crisp illustrated mechanical design and shaded metal palette, do not copy the reference robot. Transparent background, 3 columns by 2 rows of equal spacious cells, exactly SIX separate complete isolated sprites, no text, no floor, no shadows beyond the objects. Leave generous transparent gaps and margins, nothing crosses cell boundaries. Top left: crimson kestrel interceptor drone, angular wings, cyan cockpit, small jet nacelles, side view facing LEFT. Top middle: white and orange small hovering mine-laying carrier with 3 dangling blue mines, side view facing LEFT. Top right: violet mechanical bat with jointed blade wings, face centered, front three-quarter view. Bottom left: squat yellow industrial spider miner robot with four legs and drill arms, side view facing LEFT. Bottom middle: STAGE TWO BOSS a large intimidating dark crimson and brass jet-powered armored flying manta warship, forward view, sweeping wings, huge paired thrusters, bright blue central core and underslung cannons, no legs. Bottom right: FINAL BOSS a colossal ominous wall-mounted techno-organic reactor idol, frontal symmetrical view, black and ivory armored face with one magenta central eye, two giant shoulder gun housings, exposed cables and mechanical ribs descending into a mounting pedestal, bolted backplate, immobile architectural machine, no humanoid legs. Each of the six sprites fits fully within its own equal cell with no clipping. Detailed anime ink outlines and richly painted metal shading matching the reference, strong readable silhouettes, luminous cyan/orange/magenta cores. Transparent alpha output.
```

## アトラス余白の修正（採用版）

```text
Edit this six-sprite game atlas for technical usability. Preserve EXACTLY the same six machine designs, order, visual style and colors. Re-layout them in a rigid 3 columns by 2 rows grid on a truly TRANSPARENT alpha background. Each entire sprite must fit within the central 72 percent of its equal rectangular cell, leaving a wide completely transparent gutter around EVERY sprite. Especially shrink the bottom-middle flying boss enough so BOTH wingtips stay far inside its own cell. No sprite overlaps the rectangular bounding box of any other sprite. Keep all wings, noses, drill tips, cables and backplates completely inside their cells. No cropping, no labels, no frame borders. Six complete objects with large transparent separation: top row interceptor, mine carrier, mechanical bat; bottom row drill spider, flying warship boss, wall-mounted final boss. Actual transparent background, no painted backdrop or checker pattern.
```

## 地上背景

```text
Wide 16:9 background painting only for an original anime sci-fi side scrolling action game LUMINA SPARK. Stage 2: THE SURFACE, a huge abandoned ground-level city and air-defense cargo port at dawn after a rainy night. Teal and muted amber sky fills upper 55%, distant tiny aircraft contrails only, terraced brutalist buildings, damaged elevated railway and domed anti-air shelters in the middle distance, wet concrete foundations at bottom. Crisp illustrated anime background, painterly metal detail, quiet readable central sky where gameplay enemies will appear. Palette cool desaturated blue-green, early morning pale gold horizon, distant magenta signal lights. No playable character, no large enemies, no UI, no text, no logos, no sharp foreground obstacles, no foreground railing. Entire scene is a distant parallax backdrop, side-on panorama, natural depth, epic atmosphere, readable rather than excessively busy.
```

## 地下背景

```text
A 16:9 illustrated game background for LUMINA SPARK, anime science fiction 2D action platformer. UNDERGROUND STAR REACTOR SHAFT: view looking sideways at the far wall of an immense subterranean cylindrical industrial shaft, dark blue-black layered excavated rock and heavy ribbed metal architecture, giant conduits going vertically downward, amber maintenance lamps and magenta energy veins, distant catwalks and shafts of dusty purple light. Strong sense of descending into a mysterious ancient machine. Deep shadow, oppressive scale, detailed painted anime environment, restrained contrast to keep cyan heroine and bullets legible. No characters, no enemies, no boss, no UI, no text, no foreground platforms or floor that could be mistaken for collision surfaces. This is ONLY a distant backdrop behind independently drawn playable ledges, pistons and a wall-mounted boss. Border structures at left and right, dim clean center.
```
