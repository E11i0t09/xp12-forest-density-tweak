<#
  XP12 Forest Density Tweak  -  Vanilla / simHeaven edition
  Version 1.0 (2026-10-13)

  Makes X-Plane 12 forests denser by lowering the SPACING (tree distance) value
  in the forest definition files (.for). The vegetation slider in X-Plane can
  never exceed the density defined there, so this is the actual limit.

  Edition: Vanilla X-Plane 12 and simHeaven X-World.
  Folder changed: Resources\default scenery\1200 forests
  (simHeaven X-World links its forests to exactly these default files.)

  What it does
  - SPACING and RANDOM are multiplied by a factor (default 0.7 = ~2x trees per area).
    RANDOM is scaled too, so the trees keep the same relative irregularity instead
    of clumping together.
  - Files with SPACING <= 3.1 m (grass, shrubs, hedges) are left untouched.
  - Only the header lines are changed; the 3D tree meshes are copied byte for byte.
  - Every original line is logged in <X-Plane>\ForestDensityTweak\backup.log,
    so "Restore" puts back the exact original values.
  - Both editions (Vanilla/simHeaven and Global Forests v2) share this log, so
    running both never scales the default forests twice.

  After an X-Plane or Global Forests update the updated files are original again.
  Just run "Apply" once more: the script detects this and re-applies the tweak.

  Performance: more trees cost GPU time. Start with 0.7, go to 0.8 if FPS drop
  too much, 0.6 only on strong GPUs. Use at your own risk.
#>

$ErrorActionPreference = 'Stop'
$Edition    = 'Default'          # 'Default' or 'GFv2'
$Title      = 'Vanilla / simHeaven edition'
$Threshold  = 3.1
$DefaultFac = 0.7
$Inv        = [Globalization.CultureInfo]::InvariantCulture
$Latin1     = [Text.Encoding]::GetEncoding(28591)   # 1:1 byte <-> char, keeps files byte-exact
$LineRx     = [regex]'(?m)^([ \t]*)(SPACING|RANDOM)([ \t]+)([0-9]*\.?[0-9]+)([ \t]+)([0-9]*\.?[0-9]+)'
$HeaderEnd  = [regex]'(?m)^[ \t]*(TREE|TREE2|MESH|MESH_3D|GROUP)\b'

function Fmt([double]$v) { $v.ToString('0.###', $Inv) }

# ---------------------------------------------------------------- X-Plane path
function Test-XP($p) { $p -and (Test-Path -LiteralPath (Join-Path $p 'X-Plane.exe')) -and (Test-Path -LiteralPath (Join-Path $p 'Resources/default scenery')) }

function Find-XPlane {
    if (Test-XP $PSScriptRoot) { return $PSScriptRoot }
    $cands = @()
    $inst = if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'x-plane_install_12.txt' } else { '' }
    if ($inst -and (Test-Path -LiteralPath $inst)) {
        foreach ($l in Get-Content -LiteralPath $inst) {
            $p = $l.Trim().TrimEnd('\', '/')
            if (Test-XP $p) { $cands += $p }
        }
    }
    $cands = @($cands | Select-Object -Unique)
    if ($cands.Count -eq 1) {
        $a = Read-Host "X-Plane 12 found at '$($cands[0])'. Use it? [Y/n]"
        if ($a -eq '' -or $a -match '^[yYjJ]') { return $cands[0] }
    } elseif ($cands.Count -gt 1) {
        Write-Host 'Several X-Plane 12 installations found:'
        for ($i = 0; $i -lt $cands.Count; $i++) { Write-Host "  [$($i+1)] $($cands[$i])" }
        $a = Read-Host 'Number (or Enter to type a path)'
        if ($a -match '^\d+$' -and [int]$a -ge 1 -and [int]$a -le $cands.Count) { return $cands[[int]$a - 1] }
    }
    while ($true) {
        $p = (Read-Host 'Path to your X-Plane 12 folder (contains X-Plane.exe)').Trim('"', ' ').TrimEnd('\')
        if (Test-XP $p) { return $p }
        Write-Host '  -> X-Plane.exe / Resources\default scenery not found there.' -ForegroundColor Yellow
    }
}

function Get-Targets($xp) {
    $t = @()
    $def = Join-Path $xp 'Resources/default scenery/1200 forests'
    if (-not (Test-Path -LiteralPath $def)) { throw "Default forest folder not found: $def" }
    $t += (Get-Item -LiteralPath $def).FullName
    if ($Edition -eq 'GFv2') {
        $gf = @(Get-ChildItem -LiteralPath (Join-Path $xp 'Custom Scenery') -Directory |
                Where-Object { $_.Name -match '^Global[ _-]?Forests' -and $_.Name -match 'v2' })
        if ($gf.Count -eq 0) { throw "No 'Global_Forests_v2' folder found in Custom Scenery. Use the Vanilla/simHeaven edition instead." }
        $t += $gf | ForEach-Object { $_.FullName }
    }
    return $t
}

# ---------------------------------------------------------------- backup log
function Get-LogPath($xp) {
    $d = Join-Path $xp 'ForestDensityTweak'
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
    Join-Path $d 'backup.log'
}

function Read-Log($log) {
    $h = @{}
    if (Test-Path -LiteralPath $log) {
        foreach ($l in [IO.File]::ReadAllLines($log)) {
            if ($l.Trim()) { $e = $l | ConvertFrom-Json; $h[$e.f] = $e }   # last entry per file wins
        }
    }
    return $h
}

# ---------------------------------------------------------------- file helpers
function Read-For($path, [switch]$HeaderOnly) {
    if ($HeaderOnly) {
        # status checks only need the first few KB - don't read the 3D meshes
        $fs = [IO.File]::OpenRead($path)
        try { $buf = New-Object byte[] ([Math]::Min($fs.Length, 65536)); $got = 0
              while ($got -lt $buf.Length) { $k = $fs.Read($buf, $got, $buf.Length - $got); if ($k -le 0) { break }; $got += $k } }
        finally { $fs.Close() }
        $bytes = $buf
    } else { $bytes = [IO.File]::ReadAllBytes($path) }
    $n     = [Math]::Min($bytes.Length, 65536)
    $text  = $Latin1.GetString($bytes, 0, $n)
    $m     = $HeaderEnd.Match($text)
    $hlen  = if ($m.Success) { $m.Index } else { $n }
    $head  = $text.Substring(0, $hlen)
    $lines = @($LineRx.Matches($head) | ForEach-Object { $_.Value })
    [pscustomobject]@{ Bytes = $bytes; HeadLen = $hlen; Head = $head; Lines = $lines }
}

function Write-For($path, $fo, [string]$newHead) {
    $hb  = $Latin1.GetBytes($newHead)
    $out = New-Object byte[] ($hb.Length + $fo.Bytes.Length - $fo.HeadLen)
    [Array]::Copy($hb, 0, $out, 0, $hb.Length)
    [Array]::Copy($fo.Bytes, $fo.HeadLen, $out, $hb.Length, $fo.Bytes.Length - $fo.HeadLen)
    $tmp = "$path.fdt_tmp"
    [IO.File]::WriteAllBytes($tmp, $out)
    [IO.File]::Replace($tmp, $path, [NullString]::Value)   # atomic swap, never a half-written .for
}

function Get-MinSpacing([string]$head) {
    $v = @($LineRx.Matches($head) | Where-Object { $_.Groups[2].Value -eq 'SPACING' } |
           ForEach-Object { [Math]::Min([double]::Parse($_.Groups[4].Value, $Inv), [double]::Parse($_.Groups[6].Value, $Inv)) })
    if ($v.Count -eq 0) { return 0 }
    ($v | Measure-Object -Minimum).Minimum
}

function Same($a, $b) { ($a -join "`n") -eq ($b -join "`n") }

function Get-State($fo, $e) {
    if (-not $e) { return 'original' }
    if (Same $fo.Lines $e.n) { return 'tweaked' }
    return 'original'     # restored by an update (or changed by the author) -> treat as original
}

function Get-Files($targets) {
    foreach ($t in $targets) { Get-ChildItem -LiteralPath $t -Recurse -File -Filter '*.for' }
}

function Rel($xp, $full) { $full.Substring($xp.Length).TrimStart('\', '/') }

# ---------------------------------------------------------------- actions
function Show-Status($xp, $targets) {
    $log = Read-Log (Get-LogPath $xp)
    $c = @{ tweaked = 0; original = 0; skipped = 0 }; $fac = @{}
    $files = @(Get-Files $targets); $i = 0
    foreach ($f in $files) {
        $i++; if ($i % 50 -eq 0) { Write-Progress -Activity 'Checking' -Status "$i / $($files.Count)" -PercentComplete (100 * $i / $files.Count) }
        $fo = Read-For $f.FullName -HeaderOnly
        $e  = $log[(Rel $xp $f.FullName)]
        $s  = Get-State $fo $e
        if ($s -eq 'tweaked') { $c.tweaked++; $fac[[string]$e.x] = 1 }
        else {
            if ((Get-MinSpacing $fo.Head) -le $Threshold) { $c.skipped++ }
            else { $c.original++ }
        }
    }
    Write-Progress -Activity 'Checking' -Completed
    Write-Host ''
    Write-Host "  Forest files checked : $($files.Count)"
    Write-Host "  Tweaked              : $($c.tweaked)" -ForegroundColor Green -NoNewline
    if ($fac.Count) { Write-Host "   (factor $($fac.Keys -join ', '))" } else { Write-Host '' }
    Write-Host "  Original (tweakable) : $($c.original)"
    Write-Host "  Grass/shrubs (kept)  : $($c.skipped)"
    return $c
}

function Invoke-Apply($xp, $targets) {
    $logPath = Get-LogPath $xp
    $log = Read-Log $logPath
    $a = Read-Host "Factor (0.4 - 1.0, Enter = $DefaultFac; lower = denser)"
    if ($a.Trim() -eq '') { $fac = $DefaultFac }
    else {
        $fac = 0.0
        if (-not [double]::TryParse($a.Replace(',', '.'), [Globalization.NumberStyles]::Float, $Inv, [ref]$fac) -or $fac -lt 0.4 -or $fac -ge 1.0) {
            Write-Host '  Invalid factor.' -ForegroundColor Yellow; return
        }
    }
    $files = @(Get-Files $targets)
    # refuse mixing factors: files already tweaked with another factor must be restored first
    foreach ($f in $files) {
        $e = $log[(Rel $xp $f.FullName)]
        if ($e -and [double]$e.x -ne $fac) {
            $fo = Read-For $f.FullName -HeaderOnly
            if ((Get-State $fo $e) -eq 'tweaked') {
                Write-Host "  Forests are already tweaked with factor $($e.x). Run 'Restore' first, then apply $fac." -ForegroundColor Yellow
                return
            }
        }
    }
    $sw = New-Object IO.StreamWriter($logPath, $true, (New-Object Text.UTF8Encoding($false)))
    $sw.AutoFlush = $true
    $done = 0; $already = 0; $skip = 0; $i = 0
    try {
        foreach ($f in $files) {
            $i++; if ($i % 25 -eq 0) { Write-Progress -Activity "Applying factor $fac" -Status "$i / $($files.Count)" -PercentComplete (100 * $i / $files.Count) }
            $rel = Rel $xp $f.FullName
            $fo  = Read-For $f.FullName -HeaderOnly
            if ((Get-State $fo $log[$rel]) -eq 'tweaked') { $already++; continue }
            if ((Get-MinSpacing $fo.Head) -le $Threshold) { $skip++; continue }
            $fo  = Read-For $f.FullName
            $newHead = $LineRx.Replace($fo.Head, {
                param($m)
                $m.Groups[1].Value + $m.Groups[2].Value + $m.Groups[3].Value +
                (Fmt ([double]::Parse($m.Groups[4].Value, $Inv) * $fac)) + $m.Groups[5].Value +
                (Fmt ([double]::Parse($m.Groups[6].Value, $Inv) * $fac))
            })
            $newLines = @($LineRx.Matches($newHead) | ForEach-Object { $_.Value })
            # log first, then write: an interruption can never lead to double scaling
            $sw.WriteLine((@{ f = $rel; x = $fac; o = [string[]]$fo.Lines; n = [string[]]$newLines } | ConvertTo-Json -Compress))
            Write-For $f.FullName $fo $newHead
            $done++
        }
    } finally { $sw.Close(); Write-Progress -Activity 'Applying' -Completed }
    Write-Host ''
    Write-Host "  Tweaked now          : $done" -ForegroundColor Green
    Write-Host "  Already tweaked      : $already"
    Write-Host "  Grass/shrubs (kept)  : $skip"
}

function Invoke-Restore($xp, $targets) {
    $logPath = Get-LogPath $xp
    $log = Read-Log $logPath
    if ($log.Count -eq 0) { Write-Host '  Nothing to restore (no backup log).'; return }
    $files = @(Get-Files $targets); $done = 0; $i = 0
    foreach ($f in $files) {
        $i++; if ($i % 25 -eq 0) { Write-Progress -Activity 'Restoring' -Status "$i / $($files.Count)" -PercentComplete (100 * $i / $files.Count) }
        $rel = Rel $xp $f.FullName; $e = $log[$rel]
        if (-not $e) { continue }
        $fo = Read-For $f.FullName
        if ((Get-State $fo $e) -ne 'tweaked') { $log.Remove($rel); continue }
        $orig = @($e.o)
        $parts = $LineRx.Matches($fo.Head); $sb = New-Object Text.StringBuilder; $pos = 0
        for ($j = 0; $j -lt $parts.Count -and $j -lt $orig.Count; $j++) {
            [void]$sb.Append($fo.Head.Substring($pos, $parts[$j].Index - $pos)); [void]$sb.Append($orig[$j]); $pos = $parts[$j].Index + $parts[$j].Length
        }
        [void]$sb.Append($fo.Head.Substring($pos))
        Write-For $f.FullName $fo $sb.ToString()
        $log.Remove($rel); $done++
    }
    Write-Progress -Activity 'Restoring' -Completed
    # keep log entries of files outside this edition's folders (e.g. GFv2 when running the Default edition)
    $keep = @($log.Values | Where-Object { $p = Join-Path $xp $_.f; -not (@($targets | Where-Object { $p.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }).Count) })
    [IO.File]::WriteAllLines($logPath, [string[]]@($keep | ForEach-Object { $_ | ConvertTo-Json -Compress }), (New-Object Text.UTF8Encoding($false)))
    Write-Host ''
    Write-Host "  Restored             : $done files" -ForegroundColor Green
}

# ---------------------------------------------------------------- main
try {
    Write-Host ''
    Write-Host "  XP12 Forest Density Tweak - $Title" -ForegroundColor Cyan
    Write-Host '  ------------------------------------------------------------'
    $xp = (Get-Item -LiteralPath (Find-XPlane)).FullName.TrimEnd('\', '/')
    $targets = Get-Targets $xp
    Write-Host "  X-Plane : $xp"
    foreach ($t in $targets) { Write-Host "  Folder  : $(Rel $xp $t)" }
    if (Get-Process -Name 'X-Plane' -ErrorAction SilentlyContinue) {
        Write-Host '  X-Plane is running - please close it first.' -ForegroundColor Yellow
    }
    [void](Show-Status $xp $targets)
    while ($true) {
        Write-Host ''
        Write-Host '  [1] Apply   [2] Restore original   [3] Status   [Q] Quit'
        switch -Regex (Read-Host '  Choice') {
            '^1$'    { Invoke-Apply   $xp $targets }
            '^2$'    { Invoke-Restore $xp $targets }
            '^3$'    { [void](Show-Status $xp $targets) }
            '^[qQ]$' { return }
        }
    }
} catch {
    Write-Host ''
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
