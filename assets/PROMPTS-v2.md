

## 2026-10-24 修正案対応・追加画像
組み込みGPTImage使用、全画像は透明背景。posesとenemiesは既存atlas.pngを参照。既存素材は保持。

### poses.png
Reference is identity/style reference only. Create a NEW transparent sprite sheet, exactly FOUR equal cells in ONE HORIZONTAL ROW, full bodies with padding, same heroine as reference: pink bob, star hairclip, white teal armor and arm cannon. All face RIGHT. Left to right: low forward dash with legs trailing; recoiling after impact; standing charging cannon with teal glow; cheerful victorious raised fist. No text no borders no extra characters. Polished crisp 2D anime art.

### enemies.png
Create a transparent 2D anime game sprite sheet exactly FOUR equal cells in ONE HORIZONTAL ROW, each isolated with padding. Match reference art. Left to right: navy ground robot with large golden energy shield facing LEFT; wall mounted gun turret aiming LEFT; orange wheel robot with red visor facing LEFT; purple flying bomber with downward bomb hatch. Full silhouettes no text no borders.

### explosion.png
Transparent 2D game explosion animation sprite sheet. Exactly SIX equal square cells in ONE horizontal row. Each centered isolated, generous transparent margins. Chronological frames: tiny white flash, expanding yellow star, orange fireball, large orange smoky burst, fading red wisps, small fading embers. Consistent center. Crisp anime effects. No text no borders.

### charge.png
Transparent 2D game CHARGED PROJECTILE animation sprite sheet. Exactly SIX equal square cells in ONE horizontal row. Each centered isolated cyan energy orb with white core, pink lightning highlights and small tail trailing LEFT, flying RIGHT. Six successive pulsing phases of SAME orb, consistent scale and centered anchor. No text borders.

### muzzle.png
Transparent 2D anime muzzle flash animation sprite sheet. Exactly SIX equal square cells in ONE horizontal row. Every frame isolated with generous padding. A teal-white energy blaster muzzle flash pointing RIGHT, tiny spark, growing cone, bright cone, diminishing cone, wisps, tiny fading spark. No gun no text no borders. Consistent center.

### tiles.png
Transparent game terrain sprite atlas exactly THREE equal cells in ONE horizontal row. First: side view seamless horizontally tiling metal floor block with flat glowing teal top edge at top and dark navy industrial panels below, rectangular 3:1 shape. Second: short floating metal platform with teal illuminated top, thin clean rectangular side view, 3:1. Third: long floating metal platform of same design, 4:1. Match anime futuristic night-city game aesthetic. Each isolated centered, generous padding, no text no perspective floor plane, top surfaces strictly horizontal.

### core.png
Single isolated golden five-point star crystal encircled by thin luminous gold orbital rings, collectible star core for 2D anime action game. Transparent background, centered full silhouette with generous margin, bright warm gold, readable at 48 pixels, no teal, no text.

### poses-v2.png（採用版）
NEW sprite sheet. EXACTLY TWO COLUMNS TWO ROWS (2x2), four equal SQUARE cells in a SQUARE canvas. Each sprite occupies only the central 65% of its cell with generous transparent gutters, NO overlapping. Same adult heroine from reference. Top left: dashing RIGHT, body low, no trail. Top right: recoiling from damage facing RIGHT. Bottom left: standing charging cannon RIGHT, small glow only. Bottom right: standing happy victory pose fist raised. Pink bob, white teal armor, star hairclip, arm cannon. Full body each same scale, feet visible. Transparent, no border no labels.


### enemies-v2.png（採用版）
NEW sprite sheet. EXACTLY TWO COLUMNS TWO ROWS (2x2), four equal square cells in SQUARE canvas. Each robot occupies central 65% of its cell with generous empty transparent gutters. Top left: navy ground shield robot facing LEFT. Top right: wall-mounted gun turret facing LEFT. Bottom left: orange wheeled ramming robot facing LEFT. Bottom right: purple hovering bomber with downward hatch, no detached bombs. Full isolated silhouettes, no overlap, no labels. Same polished anime art as reference. Transparent.


## 2026-10-24 改善案1〜4

扉4枠・機器3枠・電流4コマ・風4コマ・搬送路ミニボス3枠を組み込みGPTImageで生成。採用画像・全プロンプト・切り出し方は [improvements/PROMPTS.md](improvements/PROMPTS.md)。BGMはユーザー提供曲へ変更（audio/README.md）。
