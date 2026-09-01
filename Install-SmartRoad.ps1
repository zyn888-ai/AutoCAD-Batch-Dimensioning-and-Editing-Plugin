[CmdletBinding()]
param(
    [switch]$Elevated,
    [switch]$ProbeOnly,
    [string]$OriginalAppData,
    [string]$OriginalLocalAppData
)

$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceBundle = Join-Path $projectDirectory 'SmartRoad.CadDimensionTools.bundle'
$logPath = Join-Path $projectDirectory 'Install-Result.txt'
$pluginVersion = '1.3.1.0'
$registryRoot = 'HKLM:\SOFTWARE\Autodesk\AutoCAD'
$releaseMap = @(
    [pscustomobject]@{ Release = 'R23.0'; Runtime = 'R23'; Years = '2019' },
    [pscustomobject]@{ Release = 'R23.1'; Runtime = 'R23'; Years = '2020' },
    [pscustomobject]@{ Release = 'R24.0'; Runtime = 'R24'; Years = '2021' },
    [pscustomobject]@{ Release = 'R24.1'; Runtime = 'R24'; Years = '2022' }
)
$registeredCommands = @(
    'ZHDIMHELP',
    'ZHDIMABOUT',
    'ZHDIMALIGNED',
    'ZHDIMLINE',
    'ZHDIMANGULAR',
    'ZHDIMRADIUS',
    'ZHDIMDIAMETER',
    'ZHDIMSTYLE',
    'ZHDIMTEXT',
    'ZHDIMJSON',
    'ZHDIMBACKUP',
    'ZHDIMLEARN',
    'ZHDIMPROFILE',
    'ZHDIMOLEINSPECT',
    'ZHDIMANALYZE',
    'ZHDIMAUTO260CHECK',
    'ZHDIMAUTO260',
    'ZHDIMAUTOEXCELCHECK',
    'ZHDIMAUTOEXCEL'
)

if ([string]::IsNullOrWhiteSpace($OriginalAppData)) {
    $OriginalAppData = [Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)
}
if ([string]::IsNullOrWhiteSpace($OriginalLocalAppData)) {
    $OriginalLocalAppData = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
}

trap {
    $errorText = "FAILED`r`n" + ($_ | Out-String)
    try { [System.IO.File]::WriteAllText($logPath, $errorText, (New-Object System.Text.UTF8Encoding($true))) } catch { }
    Write-Error $_
    exit 1
}

function Get-AutoCadInstallations {
    $found = @()
    foreach ($mapping in $releaseMap) {
        $releaseKey = Join-Path $registryRoot $mapping.Release
        if (-not (Test-Path -LiteralPath $releaseKey)) { continue }
        foreach ($productKey in Get-ChildItem -LiteralPath $releaseKey -ErrorAction SilentlyContinue) {
            $properties = Get-ItemProperty -LiteralPath $productKey.PSPath -ErrorAction SilentlyContinue
            $location = [string]$properties.AcadLocation
            if ([string]::IsNullOrWhiteSpace($location)) { continue }
            $fullLocation = [System.IO.Path]::GetFullPath($location)
            if (-not (Test-Path -LiteralPath (Join-Path $fullLocation 'acad.exe'))) { continue }
            $found += [pscustomobject]@{
                Release = $mapping.Release
                Runtime = $mapping.Runtime
                Years = $mapping.Years
                ProductKey = $productKey.PSPath
                ProductName = $productKey.PSChildName
                InstallDirectory = $fullLocation
            }
        }
    }
    return $found
}

$installations = @(Get-AutoCadInstallations)
if ($installations.Count -eq 0) {
    throw 'No supported AutoCAD 2019-2022 64-bit installation was found in the Autodesk registry.'
}

if ($ProbeOnly) {
    $installations | Format-Table Years, Release, ProductName, InstallDirectory -AutoSize
    exit 0
}

$runningAutoCad = @(Get-Process -Name 'acad' -ErrorAction SilentlyContinue)
if ($runningAutoCad.Count -gt 0) {
    throw 'Close every AutoCAD window, save all drawings, and run the installer again. Updating a loaded plug-in is unsafe.'
}

$runtimeSources = @{
    R23 = Join-Path $sourceBundle 'Contents\Windows\R23\SmartRoad.CadDimensionTools.R23.v1.3.1.dll'
    R24 = Join-Path $sourceBundle 'Contents\Windows\R24\SmartRoad.CadDimensionTools.R24.v1.3.1.dll'
}
$dataSource = Join-Path $sourceBundle 'Contents\Data\traffic_1_260.json'
foreach ($requiredFile in @($runtimeSources.R23, $runtimeSources.R24, $dataSource)) {
    if (-not (Test-Path -LiteralPath $requiredFile)) {
        throw ('The installation package is incomplete. Missing: ' + $requiredFile)
    }
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdministrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdministrator) {
    if ($Elevated) { throw 'Administrator elevation was requested but not granted.' }
    $safeScript = $PSCommandPath.Replace('"', '""')
    $safeAppData = $OriginalAppData.Replace('"', '""')
    $safeLocalAppData = $OriginalLocalAppData.Replace('"', '""')
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $safeScript +
        '" -Elevated -OriginalAppData "' + $safeAppData +
        '" -OriginalLocalAppData "' + $safeLocalAppData + '"'
    $process = Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -Verb RunAs -Wait -PassThru -WindowStyle Normal
    exit $process.ExitCode
}

$installed = @()
foreach ($installation in $installations) {
    $runtimeFileName = 'SmartRoad.CadDimensionTools.' + $installation.Runtime + '.v1.3.1.dll'
    $runtimeSource = $runtimeSources[$installation.Runtime]

    # Store the runtime below the actual AutoCAD installation directory. AutoCAD's
    # install directory and its subfolders are implicitly trusted by SECURELOAD.
    $pluginRoot = Join-Path $installation.InstallDirectory 'SmartRoadPlugins\SmartRoad.CadDimensionTools'
    $runtimeTargetDirectory = Join-Path $pluginRoot $installation.Runtime
    $dataTargetDirectory = Join-Path $pluginRoot 'Data'
    New-Item -ItemType Directory -Path $runtimeTargetDirectory -Force | Out-Null
    New-Item -ItemType Directory -Path $dataTargetDirectory -Force | Out-Null

    $runtimeTarget = Join-Path $runtimeTargetDirectory $runtimeFileName
    Unblock-File -LiteralPath $runtimeSource -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath $runtimeSource -Destination $runtimeTarget -Force
    Copy-Item -LiteralPath $dataSource -Destination (Join-Path $dataTargetDirectory 'traffic_1_260.json') -Force
    Unblock-File -LiteralPath $runtimeTarget -ErrorAction SilentlyContinue

    $copyrightSource = Join-Path $projectDirectory 'COPYRIGHT.txt'
    if (Test-Path -LiteralPath $copyrightSource) {
        Copy-Item -LiteralPath $copyrightSource -Destination (Join-Path $pluginRoot 'COPYRIGHT.txt') -Force
    }

    # Autodesk's documented managed demand-load registration.
    $applicationsKey = Join-Path $installation.ProductKey 'Applications'
    $applicationKey = Join-Path $applicationsKey 'SmartRoad.CadDimensionTools'
    New-Item -Path $applicationKey -Force | Out-Null
    New-ItemProperty -LiteralPath $applicationKey -Name 'DESCRIPTION' -Value 'SmartRoad CAD Dimension Tools - SEU-Ni Zongyu' -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath $applicationKey -Name 'LOADCTRLS' -Value 14 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -LiteralPath $applicationKey -Name 'LOADER' -Value $runtimeTarget -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath $applicationKey -Name 'MANAGED' -Value 1 -PropertyType DWord -Force | Out-Null
    $commandsKey = Join-Path $applicationKey 'Commands'
    New-Item -Path $commandsKey -Force | Out-Null
    foreach ($commandName in $registeredCommands) {
        New-ItemProperty -LiteralPath $commandsKey -Name $commandName -Value $commandName -PropertyType String -Force | Out-Null
    }

    $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $runtimeSource).Hash
    $targetHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $runtimeTarget).Hash
    if ($sourceHash -ne $targetHash) { throw ('Runtime verification failed: ' + $runtimeTarget) }
    $actualVersion = [Reflection.AssemblyName]::GetAssemblyName($runtimeTarget).Version.ToString()
    if ($actualVersion -ne $pluginVersion) { throw ('Unexpected runtime version at ' + $runtimeTarget + ': ' + $actualVersion) }
    $registration = Get-ItemProperty -LiteralPath $applicationKey
    if ([string]$registration.LOADER -ne $runtimeTarget -or [int]$registration.MANAGED -ne 1 -or [int]$registration.LOADCTRLS -ne 14) {
        throw ('AutoCAD demand-load registration verification failed: ' + $applicationKey)
    }
    $registeredCommandValues = Get-ItemProperty -LiteralPath $commandsKey
    foreach ($commandName in $registeredCommands) {
        if ([string]$registeredCommandValues.$commandName -ne $commandName) {
            throw ('AutoCAD command registration verification failed for ' + $commandName + ': ' + $commandsKey)
        }
    }

    $installed += [pscustomobject]@{
        AutoCAD = $installation.Years
        Runtime = $installation.Runtime
        Directory = $pluginRoot
        Loader = $runtimeTarget
        Registry = $applicationKey
        Version = $actualVersion
        Verified = $true
    }
}

# Older builds used the per-user Autodesk ApplicationPlugins folder. Archive that
# bundle only after the new runtime and registration have both passed verification,
# preventing duplicate command registration on the next AutoCAD start.
$legacyArchives = @()
$expectedLegacyBundle = [System.IO.Path]::GetFullPath((Join-Path $OriginalAppData 'Autodesk\ApplicationPlugins\SmartRoad.CadDimensionTools.bundle'))
$appDataRoot = [System.IO.Path]::GetFullPath($OriginalAppData).TrimEnd('\') + '\'
if (-not $expectedLegacyBundle.StartsWith($appDataRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'The legacy plug-in path did not resolve below the original user AppData directory.'
}
if (Test-Path -LiteralPath $expectedLegacyBundle) {
    $legacyBackupRoot = [System.IO.Path]::GetFullPath((Join-Path $OriginalLocalAppData 'SEU-NiZongyu\SmartRoad\LegacyPluginBackups'))
    $localAppDataRoot = [System.IO.Path]::GetFullPath($OriginalLocalAppData).TrimEnd('\') + '\'
    if (-not $legacyBackupRoot.StartsWith($localAppDataRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'The legacy backup path did not resolve below the original user LocalAppData directory.'
    }
    New-Item -ItemType Directory -Path $legacyBackupRoot -Force | Out-Null
    $legacyDestination = Join-Path $legacyBackupRoot ('SmartRoad.CadDimensionTools.bundle_before_v1.3.1_' + (Get-Date -Format 'yyyyMMdd_HHmmss_fff'))
    Move-Item -LiteralPath $expectedLegacyBundle -Destination $legacyDestination
    $legacyArchives += $legacyDestination
}

$logLines = @(
    'SUCCESS',
    ('Version=' + $pluginVersion),
    ('InstalledAt=' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
)
$logLines += $legacyArchives | ForEach-Object { 'ArchivedLegacyBundle=' + $_ }
foreach ($item in $installed) {
    $logLines += ('AutoCAD=' + $item.AutoCAD + '; Runtime=' + $item.Runtime + '; Loader=' + $item.Loader + '; Registry=' + $item.Registry + '; Verified=True')
}
[System.IO.File]::WriteAllLines($logPath, $logLines, (New-Object System.Text.UTF8Encoding($true)))

Write-Host ''
Write-Host 'Copyright (C) 2026 SEU-Ni Zongyu' -ForegroundColor Cyan
Write-Host 'Installation completed for:' -ForegroundColor Green
$installed | Format-Table AutoCAD, Runtime, Version, Verified, Directory -AutoSize
Write-Host ('Verification log: ' + $logPath)
Write-Host 'Restart every running AutoCAD instance, then run ZHDIMHELP.' -ForegroundColor Yellow
