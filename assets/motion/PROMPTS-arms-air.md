# 腕振りと空中セーバー（2026-10-24）

組み込みGPTImageを使用。腕分離は既存rig/body.pngを編集参照し、upper-raw.pngに保存。calibrate_hero.pyで画素を変えずにrig/torso-v2.png、gun_arm.png、free_arm.pngへ切り出し。頭の基準を維持し、肩を支点として同じ部品を回転する。

空中セーバーはseed.pngを体格・顔の参照、saber-raw.pngを剣の参照にしてair-saber-raw.pngへ生成。flatten_motion.pyで3×2から横ストリップにし、sprite-pipelineのnormalize_sprite_strip.pyで6枚を共通倍率の256pxへ正規化。採用先air_saber/01.png〜06.png。calibrate_hero.pyで同じ頭基準へ倍率を合わせ、腰が物理的な足元より51px上になるようアンカーを設定。地上攻撃の途中でジャンプした場合も空中用へ切替、着地してもその一振りが終わるまでは同じアニメーションを維持。

プロンプト:

[
  [
    "腕分離パーツ",
    "Precise edit for a 2D game skeletal rig. Reference image is the APPROVED head/torso costume and proportions. Make ONE transparent parts atlas in 3 equal columns, single row, with three SEPARATED components. LEFT CELL: exactly the same pink-haired head, face, neck, chest, waist and hip armor as reference, same upright view facing RIGHT, but BOTH ARMS REMOVED cleanly at shoulder sockets; keep compact torso and the two shoulder socket caps, NO hands/cannon attached, NO thighs or legs. CENTER CELL: the heroine's detached RIGHT ARM WITH ARM CANNON, entire shoulder-to-muzzle, straight down VERTICAL so the cannon muzzle points DOWN and the shoulder joint is at top. Same white/teal/gold cannon design and peach upper arm, large cyan muzzle opening at bottom. Treat as one connected rotating shoulder-arm-cannon rig part. RIGHT CELL: detached LEFT ARM WITHOUT weapon, whole shoulder-to-clenched fist, relaxed slightly bent elbow, hangs VERTICALLY DOWN, white teal armor and black glove, shoulder joint top. Both detached arms similar shoulder-to-hand length to reference, cannon naturally larger than glove. Opaque crisp painted sprite components with truly transparent surrounding pixels; no glow haze, no scenery, NO text or labels, no lines, no full character, no extra parts. Equal cells with 15% gutters; no component crosses cell boundaries. Preserve reference head/body proportions and face exactly. Whole atlas one row 3 columns."
  ],
  [
    "空中セーバー6コマ",
    "Production 2D game animation spritesheet. Reference1 is exact approved heroine identity and compact proportions. Reference2 is the ground sword swing only as weapon/style reference. Create a DIFFERENT AIRBORNE SABER ATTACK: six sequential frames in THREE columns x TWO rows, all facing RIGHT, same head and torso size, no camera angle changes. In EVERY frame both boots are CLEARLY OFF THE GROUND and BOTH KNEES TUCKED up near the hips, like a jumping side-scroller air slash. NEVER draw standing spread straight legs. Same pink bob, star hairclip, white teal gold armor, big boots. Right arm cannon aimed horizontal right; free LEFT hand wields cyan energy saber. Frame1 tuck knees and draw sword back above shoulder. Frame2 wind up sword overhead. Frame3 slash diagonally forward/down with upper-body twist. Frame4 strongest forward sweeping slash, knees still bent. Frame5 follow-through across front of torso. Frame6 recover with sword near shoulder and boots still tucked. Keep hip at same x,y within all six equal cells; keep full hair, cannon, boots and saber inside transparent gutters. Same compact cute body proportions as reference1; head/hair size must be constant and around one-third of standing-body length, do not elongate legs or shrink head. Crisp production game sprite art, simple concentrated cyan blade trails, no fog, no background, no text, labels, borders or ground shadows. Truly transparent outside each sprite. SIX unique airborne slash frames, 3x2 grid."
  ]
]
