param(
    [string]$GodotExe = "G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe",
    [string]$Preset = "Windows Desktop",
    [string]$Output = "builds/windows/SRPG.exe"
)

$ErrorActionPreference = "Stop"

& $GodotExe --headless --check-only project.godot
& $GodotExe --headless res://tests/test_runner.tscn
& $GodotExe --headless --export-release $Preset $Output

$artifact = Get-Item $Output
$hash = Get-FileHash $artifact.FullName -Algorithm SHA256

& $artifact.FullName --headless --srpg-playthrough-smoke

$process = Start-Process -FilePath $artifact.FullName -PassThru
Start-Sleep -Seconds 5
$alive = -not $process.HasExited
if ($alive) {
    Stop-Process -Id $process.Id -Force
}

[pscustomobject]@{
    artifact = $artifact.FullName
    bytes = $artifact.Length
    sha256 = $hash.Hash
    launch_started = $true
    still_running_after_5s = $alive
} | Format-List
