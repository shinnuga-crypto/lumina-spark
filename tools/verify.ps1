param([switch]$Capture)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$env:APPDATA=Join-Path $root 'runtime\profile'
$out=Join-Path $root 'test-output'
New-Item -ItemType Directory -Force $out,$env:APPDATA | Out-Null
$jobs=@(
    @{Name='import'; Args='--headless --editor --import --quit'},
    @{Name='self-test'; Args='--headless -- --self-test'},
    @{Name='doors'; Args='--headless --script res://tools/door_test.gd'},
    @{Name='motion'; Args='--headless -- --motion-test'},
    @{Name='route'; Args='--headless --script res://tools/route_test.gd'}
)
if($Capture){$jobs+=@{Name='capture'; Args='-- --capture-qa'}; $jobs+=@{Name='motion-capture'; Args='-- --capture-motion'}}
foreach($job in $jobs){
    $arguments='--path "'+$root+'" '+$job.Args
    $log=Join-Path $out ($job.Name+'.txt')
    $err=Join-Path $out ($job.Name+'-errors.txt')
    $process=Start-Process -FilePath (Join-Path $root 'runtime\Godot.exe') -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
    Get-Content $log
    $errors=Get-Content $err -Raw
    if($errors){Write-Output $errors}
    if($process.ExitCode -ne 0 -or $errors -match '(?m)^(SCRIPT ERROR|ERROR):'){throw ($job.Name+' failed')}
}
