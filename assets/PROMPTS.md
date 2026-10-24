# GPTImage生成記録

2026-10-24 / GPT / 組み込み image_gen ツール。CLI・外部APIキー不使用。
生成結果をこのプロジェクトへコピー。原本はCodexのgenerated_imagesに保持。

## atlas.png

透明背景指定：true。4列2行の各セルを実行時に取り出し、アルファ境界で余白を詰めて描画します。

Use case: stylized-concept. Game sprite atlas for an original Japanese side scrolling action game Lumina Spark. Transparent background. A precise 4 columns by 2 rows uniform grid, eight isolated full body sprites, generous transparent padding within every cell, no text, no ground, no shadows. Each cell same size. Top row: SAME cute young adult anime heroine with pink bob hair, white and teal armored bodysuit, large teal boots, star hairclip, right arm energy blaster aiming RIGHT. Four poses: idle aiming right, running right left leg forward, running right right leg forward, jumping right knees bent. Bottom row: small orange beetle robot facing left; hovering purple spherical drone; teal healing crystal; large intimidating navy and magenta armored reactor guardian robot facing left with huge shoulders and glowing orange core. Crisp polished hand painted 2D game art with dark outlines, clearly readable silhouettes. All elements fit entirely in their own cells. No copyrighted characters.

## background.png

透明背景指定：false。

Use case: stylized-concept. Wide 16:9 background painting for an original 2D side scrolling Japanese action game Lumina Spark. A magnificent futuristic power city floating above clouds at midnight, deep navy sky with tiny stars and a luminous moon, teal glass towers with warm golden windows, distant energy conduits and a giant circular star reactor to the far right, cherry pink and teal accent lights. Anime videogame background art, painterly precise architectural details, atmospheric perspective. All architecture is distant background scenery; no foreground platforms, no characters, no interface, no text, no logos. Dark quiet upper half and lower half support readable bright foreground game sprites. Beautiful cinematic composition, softly glowing night atmosphere.


## 改良版の追加画像
2026-10-24の追加7素材と再生成のプロンプトは [PROMPTS-v2.md](PROMPTS-v2.md) を参照。採用版は poses-v2.png / enemies-v2.png / explosion.png / charge.png / muzzle.png / tiles.png / core.png。旧画像は保存。画素は変更せず、regions.jsonに切り出し範囲を記録。
