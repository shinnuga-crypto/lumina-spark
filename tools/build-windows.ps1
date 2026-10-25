param(
    [string]$GodotExe,
    [string]$Version='1.4.0'
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(!$GodotExe){$GodotExe=Join-Path $root 'runtime/Godot.exe'}
if(!(Test-Path -LiteralPath $GodotExe)){throw 'Godot 4.7.2と対応するWindows x86_64エクスポートテンプレートが必要です。-GodotExeでエディターを指定できます。'}
$GodotExe=(Resolve-Path -LiteralPath $GodotExe).Path
$out=Join-Path $root 'build/windows'
$logs=Join-Path $root 'build/logs'
New-Item -ItemType Directory -Force $out,$logs | Out-Null
$previousAppData=$env:APPDATA
try {
$env:APPDATA=Join-Path $root 'build/export-profile'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
foreach($job in @(
    @{Name='import'; Args='--headless --editor --import --quit'},
    @{Name='export'; Args='--headless --export-release "Windows Standalone"'}
)){
    $log=Join-Path $logs ($job.Name+'.txt')
    $err=Join-Path $logs ($job.Name+'-errors.txt')
    $arguments='--path "'+$root+'" '+$job.Args
    $process=Start-Process -FilePath $GodotExe -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
    $errors=Get-Content -LiteralPath $err -Raw
    if($process.ExitCode -ne 0 -or $errors -match '(?m)^(SCRIPT ERROR|ERROR):'){throw ($job.Name+' failed: '+$errors)}
}
} finally {$env:APPDATA=$previousAppData}
Copy-Item -LiteralPath (Join-Path $root 'GODOT-LICENSE.txt'),(Join-Path $root 'GODOT-COPYRIGHT.txt') -Destination $out
$guide=@'
LUMINA SPARK — 星炉のリベリオン —

LuminaSpark.exeをダブルクリックしてください。
Windows 10/11 x64、OpenGL 3.3対応のグラフィックス環境が必要です。
インストール・Godot・インターネットは不要。画像とBGMはEXEへ内蔵しています。

Enter：出撃 / E：難易度（ノーマル・アシスト・弾幕・鬼弾幕）/ O：設定（キー設定・音量）
タイトルの1 / 2 / 3（パッドの十字左右）でステージを直接選択できます。
移動：←→ / A D、ジャンプ：Z / Space（二段ジャンプ）
射撃：X / J / マウス左 / パッドRT（長押しして離すとため撃ち）
狙う方向：↑ / W、↓ / Sと左右で8方向。マウスの左か右を押すとマウス照準に切り替え。
マウス照準はキーボード操作で解除。パッドの右スティックは全方向照準、左スティックは移動。
セーバー：K / パッドRB。押した瞬間に通常斬り。0.18秒 / 1.6秒長押しして離すと溜め斬り。
1段溜めは2回斬り（リーチ180px）、最大溜めは前方への大きな金色の一撃。
溜め攻撃の発生は1段0.12秒 / 最大0.22秒、再使用は0.70秒 / 1.0秒。地上・空中の振り抜き、ダッシュ中は突き。
移動・空中の勢いを保ちます。棒立ちで通常斬りを繰り返すと待ち時間が増え、動くと戻ります。
通常/1段の刃は小さく、最大溜めで大きくなります。ダッシュ斬りは細い槍、溜めると太い槍。
射撃0.8秒以上＋セーバー0.18秒以上を溜めてどちらかを離すと、両方を消費して飛翔斬撃。
両方1.6秒なら強化版。発動後はいったん両方を離して溜め直してください。振り始めの敵弾は追尾反射、溜め中は防げません。
ダッシュ：Shift / C（弾をくぐると次の1発がMAXため撃ち）、急降下：↓ / S、足場降下：下＋ジャンプ
Esc：一時停止、M：音の切替、F11：全画面
Xbox配置のゲームパッドにも対応しています（実機未確認）。パッドを触ると画面の操作説明が切り替わります。
設定画面は1つの機能につきパッド4枠。左右で枠を選択し、Aで変更、Xでその枠を解除します。
キーボードではEnterで変更・Deleteで枠解除、マウスでは各枠を直接クリックできます。

3ステージ：空中都市→地上の迎撃線→下へ降りる地下施設。クリア後にEnterで次へ。
地上では空爆の予告を見てシェルターへ。地下では隔壁を下へ撃ち、崩れる床と圧搾機に注意。
地下の壁面固定ボスは2つの封印装置を破壊し、装甲が開いたコアを狙ってください。
床からは左の上昇台と段差で復帰。上段に居座ると予告後の重力パルスで落とされます。
HP半分で攻撃激化。＋印の援軍を倒すと必ず回復を落とします。
最高スコアはWindowsのユーザーデータへ保存されます。
進行状態は終了時にリセットされます。

同梱のGODOT-LICENSE.txt、GODOT-COPYRIGHT.txtは使用エンジンのライセンス表示です。
'@
[System.IO.File]::WriteAllText((Join-Path $out '遊び方.txt'),$guide,[System.Text.UTF8Encoding]::new($false))
$zip=Join-Path $root ('build/LuminaSpark-v'+$Version+'-windows-x64.zip')
Compress-Archive -LiteralPath (Join-Path $out 'LuminaSpark.exe'),(Join-Path $out '遊び方.txt'),(Join-Path $out 'GODOT-LICENSE.txt'),(Join-Path $out 'GODOT-COPYRIGHT.txt') -DestinationPath $zip -Force
$hashes=foreach($file in @((Join-Path $out 'LuminaSpark.exe'),$zip)){
    $hash=Get-FileHash -LiteralPath $file -Algorithm SHA256
    $hash.Hash.ToLowerInvariant()+'  '+[System.IO.Path]::GetFileName($file)
}
[System.IO.File]::WriteAllText((Join-Path $root 'build/SHA256SUMS.txt'),(($hashes -join "`n")+"`n"),[System.Text.UTF8Encoding]::new($false))
Get-Item -LiteralPath (Join-Path $out 'LuminaSpark.exe'),$zip | Select-Object FullName,Length
Get-Content -LiteralPath (Join-Path $root 'build/SHA256SUMS.txt')
