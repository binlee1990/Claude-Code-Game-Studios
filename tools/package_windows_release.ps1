param(
    [string]$GodotExe = "G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe",
    [string]$Preset = "Windows Desktop",
    [string]$Output = "builds/windows/SRPG.exe"
)

$ErrorActionPreference = "Stop"

function Stop-LingeringGodotHeadless {
    $godotName = Split-Path $GodotExe -Leaf
    $targets = Get-CimInstance Win32_Process | Where-Object {
        $_.Name -eq $godotName -and (
            $_.ParentProcessId -eq $PID -or
            $_.CommandLine -match '--headless --check-only project.godot' -or
            $_.CommandLine -match '--headless res://tests/test_runner.tscn' -or
            $_.CommandLine -match '--headless --export-release'
        )
    }
    $ids = @($targets | Select-Object -ExpandProperty ProcessId)
    if ($ids.Count -gt 0) {
        Stop-Process -Id $ids -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-GutSuite {
    $gutStdout = New-TemporaryFile
    $gutStderr = New-TemporaryFile
    try {
        $gutProcess = Start-Process -FilePath $GodotExe `
            -ArgumentList @("--headless", "res://tests/test_runner.tscn") `
            -PassThru `
            -WindowStyle Hidden `
            -RedirectStandardOutput $gutStdout.FullName `
            -RedirectStandardError $gutStderr.FullName

        $deadline = (Get-Date).AddMinutes(5)
        $sawSummary = $false
        while ((Get-Date) -lt $deadline) {
            Start-Sleep -Seconds 2
            $currentOutput = Get-Content -Raw $gutStdout.FullName -ErrorAction SilentlyContinue
            if ($currentOutput -match "====== GUT SUMMARY ======" -and $currentOutput -match "Total:\s+(\d+)\s+\|\s+Pass:\s+(\d+)\s+\|\s+Fail:\s+(\d+)") {
                $sawSummary = $true
                break
            }
            if ($gutProcess.HasExited) {
                break
            }
        }

        if (-not $gutProcess.HasExited) {
            Start-Sleep -Seconds 2
            if (-not $gutProcess.HasExited) {
                Stop-Process -Id $gutProcess.Id -Force -ErrorAction SilentlyContinue
            }
        }

        $gutOutput = Get-Content -Raw $gutStdout.FullName -ErrorAction SilentlyContinue
        $gutError = Get-Content -Raw $gutStderr.FullName -ErrorAction SilentlyContinue
    }
    finally {
        Remove-Item -LiteralPath $gutStdout.FullName, $gutStderr.FullName -Force -ErrorAction SilentlyContinue
    }

    if (-not $sawSummary -and $gutOutput -notmatch "Total:\s+(\d+)\s+\|\s+Pass:\s+(\d+)\s+\|\s+Fail:\s+(\d+)") {
        throw "GUT did not produce a complete summary."
    }
    if ($gutOutput -notmatch "Total:\s+(\d+)\s+\|\s+Pass:\s+(\d+)\s+\|\s+Fail:\s+(\d+)") {
        throw "GUT summary could not be parsed."
    }

    $total = [int]$Matches[1]
    $passed = [int]$Matches[2]
    $failed = [int]$Matches[3]
    if ($failed -ne 0 -or $total -ne $passed) {
        throw "GUT failed: Total=$total Pass=$passed Fail=$failed."
    }
    if ($gutError -match "(SCRIPT ERROR|ERROR:)") {
        throw "GUT emitted engine/script errors."
    }

    Write-Output "GUT full suite PASS: Total=$total Pass=$passed Fail=$failed"
}

& $GodotExe --headless --check-only project.godot
Stop-LingeringGodotHeadless
Invoke-GutSuite
Stop-LingeringGodotHeadless
& $GodotExe --headless --export-release $Preset $Output
Stop-LingeringGodotHeadless

$artifact = Get-Item $Output
$hash = Get-FileHash $artifact.FullName -Algorithm SHA256

$smokeStdout = New-TemporaryFile
$smokeStderr = New-TemporaryFile
try {
    $smokeProcess = Start-Process -FilePath $artifact.FullName `
        -ArgumentList @("--headless", "--srpg-playthrough-smoke") `
        -PassThru `
        -Wait `
        -WindowStyle Hidden `
        -RedirectStandardOutput $smokeStdout.FullName `
        -RedirectStandardError $smokeStderr.FullName
    $smokeText = ((Get-Content -Raw $smokeStdout.FullName) + "`n" + (Get-Content -Raw $smokeStderr.FullName)).Trim()
}
finally {
    Remove-Item -LiteralPath $smokeStdout.FullName, $smokeStderr.FullName -Force -ErrorAction SilentlyContinue
}
Write-Output $smokeText
if ($smokeProcess.ExitCode -ne 0) {
    throw "Packaged smoke failed with exit code $($smokeProcess.ExitCode)."
}
if ($smokeText -notmatch "PACKAGED_PLAYTHROUGH_SMOKE PASS" -or $smokeText -match "(SCRIPT ERROR|ERROR:|PACKAGED_PLAYTHROUGH_SMOKE FAIL)") {
    throw "Packaged smoke failed or emitted engine/script errors."
}

$process = Start-Process -FilePath $artifact.FullName -PassThru -WindowStyle Hidden
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
