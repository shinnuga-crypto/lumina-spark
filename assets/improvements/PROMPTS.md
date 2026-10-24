# 改善案1〜4の画像（2026-10-24）

組み込みGPTImageで生成。参照はassets/tiles.png（扉・機器の金属）とassets/enemies-v2.png（ミニボスの画風）。電流・風は新規生成。生成後に以下へコピーし、採用元の画素は変更していない。

- doors.png：通常シャッター、破損中、破損大、固定壁の4枠。扉の開閉は通路の高さに合わせた描画領域の切り取りで表現し、上部の壁と一方通行ロックを維持。
- devices.png：赤スイッチ、金スイッチ、投光器の3枠。
- electricity.png：床・天井の帯電に使う4コマ。
- wind.png：右向きの風4コマ。逆風は描画時に反転。
- miniboss.png：待機・予告・突進の3枠。再配置版を採用。最初のコマを基準に共通倍率を使い、頭のバイザーで位置を揃える。突進の拳が長いため実際の枠間に合わせて切り出し境界を調整。

領域・ミニボスのピボットはtools/measure_improvements.pyでregions.jsonへ記録。通常の敵、最終ボス、主人公の画像は継続使用。

生成プロンプト（最終のミニボスは再配置指示も適用）:

[
  [
    "doors",
    "Production 2D side-scroller environment atlas matching the dark navy painted metal and cyan lights of reference. FOUR equal square cells in ONE horizontal row, large transparent gutters. Cell1: a CLOSED heavy vertical industrial shutter panel, narrow about 1:3.8 width:height, beveled steel plates, cyan thin trim, neutral white status lamp near top, NO surrounding doorway frame. Cell2: identical closed shutter same exact shape/scale with moderate cracked lock and armor, orange inner sparks limited to cracks. Cell3: identical panel with heavily cracked lock, still whole intact silhouette, no floating debris. Cell4: matching permanent WALL SEGMENT, same narrow vertical proportions and dimensions as shutter, seamless top/bottom ends, dark metal, bolts, horizontal panel seams, NO opening. Each entire object centered in its own equal square cell, same baseline and height, 15 percent transparent margin. Crisp hand-painted anime game environment art, readable at only 44x172 game pixels, restrained small highlights, not pixel art. Truly transparent background, no haze or scenery, no words, letters, numbers, labels, borders or ground shadows. This is a component atlas, not a whole room."
  ],
  [
    "devices",
    "Production 2D game DEVICE COMPONENT atlas. Match reference painted dark navy steel, cyan trim, worn beveled industrial metal. THREE equal square cells in ONE row, transparent gutters, separate isolated devices. Cell1: compact vertical wall-mounted SWITCH, dark metal casing, central RED unlit push plate, red small indicator. Cell2: EXACT same switch with GOLD yellow lit plate, identical size/silhouette/position. Cell3: ceiling-mounted SEARCHLIGHT projector with a short hanging bracket, armored dark blue housing and round warm-white lens aimed downward; draw only the fixture, NO beam/cone/light fog. Full devices within each cell with generous margins. Switches must be readable at 28x44 game pixels; searchlight readable at 50x40, simple bold highlights. Crisp polished 2D hand painted anime sci-fi game style, truly transparent background, no scenery, ground shadow, text, numbers, labels, arrows or lines. Keep parts separate; not a room."
  ],
  [
    "electricity",
    "A horizontal animation strip of FOUR consecutive frames of an electrified FLOOR BAND for a polished 2D sci-fi platform game. FOUR equal wide rectangular cells, one row. Each frame is a narrow horizontal ribbon of vivid blue/cyan/white arcing electricity hugging a floor edge, intermittent branching bolts with different zig-zag paths each frame, confined to the central 45 percent height of its cell. Left and right tips terminate at the same middle height so the band can repeat across a long platform. Continuous readable luminous core, crisp sharp sparks, contained glow and genuinely transparent background outside the electricity. Exact 4-frame flickering loop with changing forks, not 4 identical images. Flat side view, no perspective, no floor, no metal, no character, no surrounding fog, no black background, no text, no grid or labels. At game scale each tile will be about 90x25 pixels. Generous transparent gutters between equal cells."
  ],
  [
    "wind",
    "Production transparent VFX spritesheet: FOUR sequential animation frames in FOUR equal columns ONE row. Stylized forceful WIND streaks flowing from LEFT TO RIGHT for a 2D sci-fi platform game. Each frame contains one elongated group of pale icy cyan-white tapered speed lines and one curling gust, same footprint/scale, slightly different curves traveling right across the four frames, loopable. Direction must clearly point right via thin trailing tails to left and thicker rounded moving heads on right. Crisp hand painted luminous strokes, limited subtle glow, isolated on genuinely transparent canvas, broad transparent margins between frames. No arrows or symbols, no letters, numbers, labels, borders, fog, environment, floor, characters or shadows. Readable at 180x35 game pixels. A clean game effect strip, not a poster."
  ],
  [
    "miniboss",
    "Production 2D anime sci-fi game MINIBOSS spritesheet matching reference enemies' hand-painted dark navy/white metal, bright cyan power and orange warning lamps. Design an original medium-sized CARGO SENTINEL robot, a squat powerful bipedal industrial guardian with two heavy armored fists, broad shoulder plates, a small helmet/visor, thick articulated legs, a bright cyan circular chest reactor and orange hazard insets. NO shield, no wheels, no sword. It should be clearly different from reference's standard shield soldier and final humanoid boss. THREE equal square cells in ONE row: frame1 idle ready stance facing LEFT (toward the player's approach), frame2 telegraph winding both fists up with orange warning glow in reactor, frame3 a leftward rushing punch with body leaning left and one fist extended. Same exact robot design, body/head/legs size across all3, same grounded sole baseline, no detached parts, all limbs and armor within each cell with15 percent transparent margin. Whole full body all three frames. Big readable silhouette at 150px high, around1.5x the heroine's size. Crisp painted 2D game sprite art, transparent background with no scenery, labels, text, numbers, lines, or ground shadows. No projectile trails. One 3-frame component atlas."
  ],
  [
    "miniboss packing correction",
    "Technical spritesheet packing correction ONLY. Keep this exact robot and all THREE poses, proportions, colors, face, silhouette and same facing. Repack on a transparent THREE EQUAL COLUMNS ONE ROW atlas. Uniformly SHRINK ALL THREE robot drawings by 25 percent within their cells, maintaining the SAME scale for all three robots and the same sole baseline. Center each full character within its cell. Every fist, foot and shoulder of the THIRD extended-punch pose MUST be completely inside cell3 with at least 12 percent transparent margin from left/right slot boundary. No sprite can cross a column boundary or touch another robot. Preserve all art and exact relative body size between poses; do NOT crop the extended fist and do NOT shrink only the third robot. Transparent background, no labels, no extra elements."
  ]
]
