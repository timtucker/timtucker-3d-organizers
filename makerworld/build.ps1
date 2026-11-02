<#
.SYNOPSIS
    MakerWorld Single-File SCAD Build Script (PowerShell)
.DESCRIPTION
    Compiles all OpenSCAD models in the parent directory (excluding makerworld/)
    into standalone single-file scripts under makerworld/dist/, preserving the
    exact directory hierarchy.

    Uses OpenSCAD's -o export function (--export-format csg) to inline all
    includes, modules, and dependencies into self-contained .scad files ready
    for upload to MakerWorld's Parametric Model Maker.
.PARAMETER Src
    Parent directory containing source files (default: parent of makerworld/)
.PARAMETER Dist
    Target output directory (default: makerworld/dist)
.PARAMETER OpenSCAD
    Path to openscad executable (autodetected if omitted)
.PARAMETER Clean
    Clean the target dist directory before building
.PARAMETER DryRun
    List files that would be compiled without running OpenSCAD
.PARAMETER Filter
    Filter source files by substring or relative path pattern
.PARAMETER TimeoutSeconds
    Timeout in seconds per file (default: 300)
#>

[CmdletBinding()]
param(
    [string]$Src,
    [string]$Dist,
    [string]$OpenSCAD,
    [switch]$Clean,
    [switch]$DryRun,
    [string]$Filter,
    [int]$TimeoutSeconds = 300
)

$ErrorActionPreference = "Stop"

# Derive default paths based on script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ((Split-Path -Leaf $ScriptDir).ToLower() -eq "makerworld") {
    $DefaultSrc = Resolve-Path (Join-Path $ScriptDir "..")
    $DefaultDist = Join-Path $ScriptDir "dist"
} else {
    $DefaultSrc = Resolve-Path $ScriptDir
    $DefaultDist = Join-Path $ScriptDir "makerworld\dist"
}

$SrcDir = if ($Src) { (Resolve-Path $Src).Path } else { $DefaultSrc.Path }
$DistDir = if ($Dist) { [System.IO.Path]::GetFullPath($Dist) } else { $DefaultDist }

Write-Host ("=" * 72) -ForegroundColor Cyan
Write-Host "MakerWorld OpenSCAD Single-File Builder (PowerShell)" -ForegroundColor Cyan
Write-Host ("=" * 72) -ForegroundColor Cyan
Write-Host "Source Directory:      $SrcDir"
Write-Host "Output Directory:      $DistDir"

# Function to locate OpenSCAD executable
function Find-OpenSCAD {
    param([string]$Custom)

    if ($Custom -and (Test-Path $Custom)) { return $Custom }
    if ($env:OPENSCAD -and (Test-Path $env:OPENSCAD)) { return $env:OPENSCAD }

    $which = Get-Command "openscad.com", "openscad.exe", "openscad" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($which) { return $which.Source }

    $candidates = @(
        "C:\Program Files\OpenSCAD (Nightly)\openscad.com",
        "C:\Program Files\OpenSCAD\openscad.com",
        "C:\Program Files (x86)\OpenSCAD\openscad.com",
        "C:\Program Files\OpenSCAD (Nightly)\openscad.exe",
        "C:\Program Files\OpenSCAD\openscad.exe",
        "C:\Program Files (x86)\OpenSCAD\openscad.exe",
        "$env:LOCALAPPDATA\Programs\OpenSCAD\openscad.com",
        "$env:LOCALAPPDATA\Programs\OpenSCAD\openscad.exe"
    )

    foreach ($cand in $candidates) {
        if (Test-Path $cand) { return $cand }
    }

    return $null
}

# Discover .scad files
$AllFiles = Get-ChildItem -Path $SrcDir -Filter "*.scad" -Recurse -File | Where-Object {
    $rel = $_.FullName.Substring($SrcDir.Length).TrimStart("\", "/")
    $parts = $rel.Split([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    -not ($parts -contains "makerworld" -or $parts -contains ".git" -or $parts -contains "dist" -or $parts -contains ".vscode")
}

if ($Filter) {
    $AllFiles = $AllFiles | Where-Object {
        $rel = $_.FullName.Substring($SrcDir.Length).TrimStart("\", "/")
        $rel.ToLower().Contains($Filter.ToLower())
    }
}

$TotalFiles = ($AllFiles | Measure-Object).Count
Write-Host "Discovered Files:      $TotalFiles .scad file(s)"

if ($TotalFiles -eq 0) {
    Write-Host "`nNo matching .scad files found." -ForegroundColor Yellow
    exit 0
}

if ($DryRun) {
    Write-Host "`n[Dry Run] Planned mirror output structure:" -ForegroundColor Yellow
    foreach ($f in $AllFiles) {
        $rel = $f.FullName.Substring($SrcDir.Length).TrimStart("\", "/")
        $target = Join-Path $DistDir $rel
        Write-Host "  $rel -> $target"
    }
    Write-Host "`nDry run completed." -ForegroundColor Green
    exit 0
}

$OpenSCADExe = Find-OpenSCAD -Custom $OpenSCAD
if (-not $OpenSCADExe) {
    Write-Error "OpenSCAD executable could not be found. Please ensure OpenSCAD is installed or specify -OpenSCAD <path>."
    exit 1
}

Write-Host "OpenSCAD Executable:   $OpenSCADExe"
Write-Host ("-" * 72)

# Clean dist if requested
if ($Clean -and (Test-Path $DistDir)) {
    Write-Host "Cleaning $DistDir ..." -ForegroundColor Yellow
    Remove-Item -Path $DistDir -Recurse -Force
}

if (-not (Test-Path $DistDir)) {
    New-Item -Path $DistDir -ItemType Directory -Force | Out-Null
}

# Configure OPENSCADPATH
$LibPaths = @(
    $SrcDir,
    (Join-Path $env:USERPROFILE "Documents\OpenSCAD\libraries")
)
if ($env:OPENSCADPATH) { $LibPaths += $env:OPENSCADPATH }
$env:OPENSCADPATH = $LibPaths -join [System.IO.Path]::PathSeparator

$StartTime = [System.Diagnostics.Stopwatch]::StartNew()
$SuccessCount = 0
$FailCount = 0
$Index = 0

foreach ($f in $AllFiles) {
    $Index++
    $rel = $f.FullName.Substring($SrcDir.Length).TrimStart("\", "/")
    $target = Join-Path $DistDir $rel
    $targetFolder = Split-Path -Parent $target

    if (-not (Test-Path $targetFolder)) {
        New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $errOutput = ""
    $ok = $false

    try {
        # Primary attempt: --export-format csg -o target.scad
        $proc = Start-Process -FilePath $OpenSCADExe -ArgumentList @("--export-format", "csg", "-o", "`"$target`"", "`"$($f.FullName)`"") -NoNewWindow -PassThru -Wait -RedirectStandardError "$env:TEMP\openscad_err.log"
        $sw.Stop()

        if ($proc.ExitCode -eq 0 -and (Test-Path $target) -and (Get-Item $target).Length -gt 0) {
            $ok = $true
        } else {
            # Fallback attempt: -o target.temp.csg and rename to target.scad
            $tempCsg = [System.IO.Path]::ChangeExtension($target, ".temp.csg")
            $procFallback = Start-Process -FilePath $OpenSCADExe -ArgumentList @("-o", "`"$tempCsg`"", "`"$($f.FullName)`"") -NoNewWindow -PassThru -Wait -RedirectStandardError "$env:TEMP\openscad_err.log"
            if ($procFallback.ExitCode -eq 0 -and (Test-Path $tempCsg)) {
                Move-Item -Path $tempCsg -Destination $target -Force
                $ok = $true
            } else {
                if (Test-Path "$env:TEMP\openscad_err.log") {
                    $errOutput = Get-Content "$env:TEMP\openscad_err.log" -Raw
                }
            }
        }
    } catch {
        $sw.Stop()
        $errOutput = $_.Exception.Message
    }

    $elapsed = [Math]::Round($sw.Elapsed.TotalSeconds, 1)

    if ($ok) {
        $SuccessCount++
        $sizeKb = [Math]::Round((Get-Item $target).Length / 1KB, 1)
        Write-Host ("[{0,2}/{1}] [  OK] {2} ({3}s, {4} KB)" -f $Index, $TotalFiles, $rel, $elapsed, $sizeKb) -ForegroundColor Green
    } else {
        $FailCount++
        Write-Host ("[{0,2}/{1}] [FAIL] {2} ({3}s)" -f $Index, $TotalFiles, $rel, $elapsed) -ForegroundColor Red
        if ($errOutput) {
            $errLines = $errOutput.Trim().Split("`n") | Select-Object -First 3
            foreach ($line in $errLines) {
                Write-Host "         ! $($line.Trim())" -ForegroundColor DarkRed
            }
        }
    }
}

$StartTime.Stop()
$TotalElapsed = [Math]::Round($StartTime.Elapsed.TotalSeconds, 2)

Write-Host ("=" * 72) -ForegroundColor Cyan
Write-Host "Build Complete in $TotalElapsed seconds" -ForegroundColor Cyan
Write-Host "Total: $TotalFiles | Succeeded: $SuccessCount | Failed: $FailCount"
Write-Host "Dist Location: $DistDir"
Write-Host ("=" * 72) -ForegroundColor Cyan

if ($FailCount -gt 0) {
    exit 1
}
exit 0

