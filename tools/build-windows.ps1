param(
    [string]$GodotExe,
    [string]$Version='1.1.0'
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
移動：←→ / A D、ジャンプ：Z / Space（二段ジャンプ）
射撃：X / J（長押しして離すとため撃ち）
セーバー：K（振り始めに敵弾へ当てると敵を追う反射弾）
ダッシュ：Shift / C（弾をくぐると次の1発がMAXため撃ち）、急降下：↓ / S、足場降下：下＋ジャンプ
Esc：一時停止、M：音の切替、F11：全画面
Xbox配置のゲームパッドにも対応しています（実機未確認）。パッドを触ると画面の操作説明が切り替わります。

1ステージ・6エリア＋ミニボス＋最終ボス。
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
