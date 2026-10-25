# ビーム・爆撃素材 v3 生成プロンプト全文

2026-10-25 GPT。組み込み image_gen、透明背景。原画の画素は変更しない。

## ビーム16領域（beam-v3.png）、新規生成・参照なし

Production VFX atlas for a 2D side-scrolling anime sci-fi action game. EXACTLY FOUR columns x FOUR rows, sixteen separate equal cells, read row by row. Transparent RGBA alpha-zero background, no labels, numbers, grid, scenery, ground or characters. MONOCHROME WHITE / SILVER / LIGHT GRAY light ONLY, designed for additive blending and later orange or magenta tint. Crisp high-contrast white-hot filaments with soft alpha edges, no black paint, no colored background cloud. Each effect belongs to its own cell and never bleeds into neighbors. Leave 15% empty horizontal padding for every cell. Each row has FOUR animation phases of the SAME effect.
ROW ONE frames1-4: TELEGRAPH CONVERGENCE, 5 to 7 thin vertical white energy threads. Phase1 widely spaced threads, phase2 drawing inward, phase3 close to center, phase4 narrow central cluster, not yet a solid damaging beam. Tall vertical threads with a gentle inward bend, no big bloom, empty alpha between lines. Full line tips visible and padded.
ROW TWO frames5-8: MAIN VERTICAL LASER CORE tile animation, a long straight COLUMN of energy with a WHITE central core and turbulent lightning filaments on both sides. Each column width 40% of cell. Four subtle different turbulence phases; SAME column width and length. IMPORTANT top and bottom edges of THIS row must match for vertical tiling: column continues straight through top/bottom cell boundaries, no caps or flare at either end. Smooth even white core centered at same x. Horizontal edges transparent. Only this row may touch vertical cell edges for tiling.
ROW THREE frames9-12: EMITTER FLASH animation, round radiant energy flower around a central bright spot, phase1 compact ignition, phase2 large starburst, phase3 expanded sharp petals, phase4 fading smaller sparks. All rays completely within cell, no cropping. No objects or machines.
ROW FOUR frames13-16: GROUND / ROOF IMPACT animation, flattened white energy ellipse with short sparks spraying UP. Phase1 small contact, phase2 large bright elliptical splash, phase3 expanding flatter ring with sparks, phase4 sparse fading ring fragments. No painted ground. Keep full oval and sparks INSIDE slot with generous transparent border.
This is an asset sheet, not a poster. Exact 4x4 organization is critical. White/silver only; glow belongs tightly to each effect. Transparent background.

## 爆撃機3コマ・爆弾・左右の火の玉（airraid-v3.png）

参照: assets/campaign/actors-v2.png

Create a compact production sprite atlas for a 2D anime sci-fi side-scrolling action game, matching the armored mechanical enemies in the reference. Exactly THREE columns by TWO rows, SIX isolated equal cells. Transparent RGBA alpha-zero background, no floor/shadow/scenery/text/grid; no ambient haze. Nothing cut by any cell border; generous transparent gutters around entire silhouettes and exhaust/flames.
TOP ROW: three animation frames of ONE NEW small BOMBER AIRCRAFT in true SIDE VIEW flying to SCREEN LEFT. Distinct from the red fighter in reference: a stocky gunmetal-and-white fuselage with gold/orange warning trim, swept heavy wings, cyan cockpit window in the LEFT nose, TWO rear engine exhausts at RIGHT, clearly visible underside BOMB BAY. No hanging mines. Compact dangerous military robot aircraft, not a passenger airplane, not a bird. All three same pose, same silhouette size, same placement, LEFT facing. Frame1 short orange exhaust, frame2 bright medium exhaust, frame3 long narrow exhaust flicker. Preserve exact hull and wing geometry across all three. Clean dark contour and polished material shading like the reference.
BOTTOM LEFT: one falling BOMB sprite, vertical nose DOWN, compact white/gunmetal armored body, orange warning band, small cyan arming light and four tail fins on TOP; no flame, no wings, no rocket trail. Full bomb fits with margins.
BOTTOM MIDDLE: one ground-skimming FIREBALL pointing LEFT, bright white-yellow leading core on left and orange-red tapering flame tail trailing RIGHT, low horizontal shape with clear dark orange contour, sharp animated game fire, no smoke cloud. Not a circular explosion.
BOTTOM RIGHT: counterpart ground-skimming FIREBALL pointing RIGHT, white-yellow leading core on right, tapering orange-red flame tail trailing LEFT. Similar scale to previous. Not a circular explosion. Keep complete fire tails within cell. These two are directional projectiles released when a bomb hits the ground. All assets readable when small and free of background glows.


原画の画素は変更せず、v3-regions.jsonで領域を指定。ビームは白い芯を別に重ね、外光をステージごとの色へ着色する。上下タイルは端のキャップを含まない中央領域を使用。

実描画の調整：繰り返した外光に境界線が見えたため、本体は端のキャップを除いた領域を一本の可変長で描画。発射光と着弾は別領域、白い芯も別描画。屋根の終端と発射/収束の幅は既存コードの値を使用する。
