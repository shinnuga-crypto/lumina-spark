# 歩行作り直し（2026-10-24）

組み込みGPTImageを使用。採用画像はrig-raw.png。rig/の5枚は元の画素を変えずに部品ごとに切り出したもの。元の8コマ歩行は右脚が常に前に残るため不採用とし、履歴用に保存、実行時には読み込まない。

1枚の全コマ生成、左右脚の文章指定、関節ガイド参照でも左右の支持脚交代が守られなかったため、部品方式へ変更。ゲーム側で同じ近側・遠側の脚を固定して使い、8基準姿勢＋補間、2関節IK、独立した足首角度で歩く。接地側の足は半周期で前26pxから後26pxへ進み、移動量13pxごとに1基準姿勢進める。後半は同じ脚を遊脚として前へ戻す。

全身の外接矩形で拡大せず、頭の同じ領域を基準に倍率を測る。曲げた脚・流れた髪・剣・光の外縁は体格の倍率に使わない。calibrate_hero.pyで頭の基準、各ポーズ倍率、骨のピボット、靴底の輪郭を保存。靴は描画時に脛・足首を別に動かして靴底を床に合わせる。

採用プロンプト:

Game animation RIG PARTS atlas, not a character pose sheet. Reference is the exact costume/style/color/proportions. Create EXACTLY SIX isolated cutout components arranged in a 3 columns x2 rows grid with very wide transparent gutters. Top-left: heroine UPPER BODY ONLY, head hair neck shoulders torso waist hip belt, right arm cannon pointing horizontally RIGHT, left hand low by side. Torso ends at hip sockets, NO THIGHS, NO LEGS below belt. Same pink bob star hairclip, face and armor as reference. Top-middle: NEAR upper leg/thigh only, a straight vertical thigh from rounded hip joint at top to rounded knee joint at bottom, peach skin upper thigh with teal hip edge, matching reference. Top-right: NEAR lower leg BOOT only, straight vertical shin from rounded knee joint top to ankle and large foot bottom pointing RIGHT, same white/teal armored boot, gold ankle ring. Bottom-left: FAR upper leg/thigh only, same dimensions as near thigh, straight vertical, darker blue-gray shadowed skin/armor. Bottom-middle: FAR lower leg BOOT only, same dimensions and view as near boot, straight vertical, foot pointing RIGHT, darker shadow tint. Bottom-right: leave EMPTY. All cutout parts have opaque clean anatomy inside and transparent outside, no glows. Each limb is perfectly vertical at rest with round overlapping ends suitable for 2D bone rotation. White background MUST BE TRANSPARENT. No text, lines, shadows, duplicate body parts, scenery, effects, no whole lower body and no posed knees. First cell upperbody has original 3/4 side view facingright; leg parts match that same projection. Crisp polished 2D anime game art, coherent same character. Keep generous space around each separate part.
