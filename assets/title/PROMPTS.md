# タイトル画面のGPTImage素材

2026-10-24 / GPT / 組み込み image_gen（APIキー不要）。参照キャラクターのピンク髪・白と青緑の装甲、左腕の銃と右手のセーバーを引き継いで生成。

## 一枚イラスト

採用ファイル: `keyart.png`（1672×941）。参照: `../motion/seed.png`、`../background.png`。ゲーム内は比率を保って画面いっぱいに表示し、文字の下に暗いグラデーションを重ねる。

```text
Create a premium TITLE SCREEN KEY VISUAL for an original Japanese 2D action game, a single full-bleed cinematic illustration, WIDE LANDSCAPE 16:9 composition. Reference1 is the exact heroine identity and armor design; reference2 is the world and architecture. No text or logos in this illustration. The heroic adult anime girl Lumina, pink bob, gold star hairpin, teal eyes, white/teal/gold sci-fi armor, stands dynamically leaning into the wind on a dark rooftop in the RIGHT HALF of the frame, gazing decisively LEFT into the city. Her LEFT arm is the integrated white/teal arm cannon, aimed diagonally toward the left-center, and her RIGHT hand holds a sharp cyan energy saber angled up toward the upper-right. Preserve the reference character's recognizable face, short bob, same compact stylized proportions, no redesign, no sexualized pose. Beautiful detailed painterly anime game cover quality, strong silhouette, polished armor, confident expressive face, sharp focus. Full or three-quarter figure from head to armored boots, important anatomy inside central80 percent of height so nothing crucial is cut by a16:9 screen crop. Character face around x77percent,y32percent; torso centered around x76percent. Nighttime floating industrial power city with towering spires, bridges and cyan-lit reactor architecture like reference2, stars and clouds, a luminous orange-gold star reactor far behind her on the right, scattering tiny sparks and rim lighting her armor. Palette deep midnight navy with electric cyan, pink hair and a restrained gold reactor accent. LEFT45percent must stay calm and dark: low-contrast sky/cloud/city silhouettes, beautiful depth, ample negative space for a game logo and menu; no bright focal lights, character or blade crossing that left area. Foreground details and brightest lights stay in right55percent. Cinematic low angle, dramatic but readable, commercial-quality cohesive illustration. No duplicate characters, no extra arms, no text, symbols, title, watermark, borders, UI or poster lettering. Opaque full scene, not transparent.
```

## ロゴ

採用ファイル: `logo.png`（1774×887、透過PNG）。文字は LUMINA / SPARK。日本語副題はゲーム内フォントで描画する。

```text
A premium ORIGINAL Japanese sci-fi action game TITLE LOGO / wordmark, isolated on genuinely TRANSPARENT background. EXACT text only: first line "LUMINA", second line "SPARK". Spell all letters perfectly, NO other words, no Japanese subtitle. Both lines large, bold, custom angular italic display lettering, coherent readable letter shapes with racing cuts, crisp edges, white-silver luminous faces, dark navy inner bevels, electric cyan upper edges and magenta-pink lower edge accents. A small sharp four-point star glint integrated subtly at one letter A, and one restrained diagonal cyan/pink energy slash behind the lettering. Wide sturdy silhouette, LUMINA on top slightly wider and SPARK directly beneath, tight intentional spacing, not a generic font. Professional high-end 2D action-game branding: energetic and cool with a little heroic elegance, matching a pink-haired armored heroine and a night power city. Keep the whole logo compact within center80percent of a landscape canvas, no cropping, broad transparent margins, no fog or decorative backgrounds, no black rectangle, no unrelated icons, no mockup, no frame, no slogan or watermark. Controlled crisp glow only close to the contours so it remains legible when reduced to about520px wide. Transparent background, only the two-line wordmark and the subtle slash/glints.
```

## 組み込み

`tools/measure_title.py` は透明余白を測定して `regions.json` を更新する。生成画像そのものは加工せず保存。タイトルは **LUMINA SPARK — 星炉のリベリオン —**。既存の記録保存先を保つため、プロジェクト識別名とフォルダー名は従来どおり。

