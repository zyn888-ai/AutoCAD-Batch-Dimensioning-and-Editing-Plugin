[CmdletBinding()]
param([switch]$Elevated)

$ErrorActionPreference = 'Stop'
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$logPath = Join-Path $scriptDirectory 'Repair-Result.txt'
$registryRoot = 'HKLM:\SOFTWARE\Autodesk\AutoCAD'
$releaseMap = @('R23.0', 'R23.1', 'R24.0', 'R24.1')
$commands = @(
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

trap {
    try {
        [IO.File]::WriteAllText($logPath, "FAILED`r`n" + ($_ | Out-String), (New-Object Text.UTF8Encoding($true)))
    } catch { }
    Write-Error $_
    exit 1
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdministrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdministrator) {
    if ($Elevated) { throw 'Administrator elevation was requested but not granted.' }
    $safeScript = $PSCommandPath.Replace('"', '""')
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $safeScript + '" -Elevated'
    $process = Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -Verb RunAs -Wait -PassThru -WindowStyle Normal
    exit $process.ExitCode
}

$repaired = @()
foreach ($release in $releaseMap) {
    $releaseKey = Join-Path $registryRoot $release
    if (-not (Test-Path -LiteralPath $releaseKey)) { continue }
    foreach ($productKey in Get-ChildItem -LiteralPath $releaseKey -ErrorAction SilentlyContinue) {
        $applicationKey = Join-Path $productKey.PSPath 'Applications\SmartRoad.CadDimensionTools'
        if (-not (Test-Path -LiteralPath $applicationKey)) { continue }

        $application = Get-ItemProperty -LiteralPath $applicationKey
        $loader = [string]$application.LOADER
        if ([string]::IsNullOrWhiteSpace($loader) -or -not (Test-Path -LiteralPath $loader)) {
            throw ('The registered SmartRoad LOADER is missing: ' + $loader)
        }
        $version = [Reflection.AssemblyName]::GetAssemblyName($loader).Version.ToString()
        if ($version -ne '1.3.1.0') {
            throw ('The installed plug-in is not v1.3.1.0. Run the full installer first: ' + $loader)
        }

        New-ItemProperty -LiteralPath $applicationKey -Name 'LOADCTRLS' -Value 14 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -LiteralPath $applicationKey -Name 'MANAGED' -Value 1 -PropertyType DWord -Force | Out-Null
        $commandsKey = Join-Path $applicationKey 'Commands'
        New-Item -Path $commandsKey -Force | Out-Null
        foreach ($command in $commands) {
            New-ItemProperty -LiteralPath $commandsKey -Name $command -Value $command -PropertyType String -Force | Out-Null
        }

        $values = Get-ItemProperty -LiteralPath $commandsKey
        foreach ($command in $commands) {
            if ([string]$values.$command -ne $command) {
                throw ('Command mapping verification failed: ' + $command)
            }
        }
        $repaired += [pscustomobject]@{
            Release = $release
            Product = $productKey.PSChildName
            Version = $version
            Loader = $loader
            Commands = $commands.Count
        }
    }
}

if ($repaired.Count -eq 0) {
    throw 'No installed SmartRoad v1.3.1 registration was found. Run the full installer first.'
}

$lines = @('SUCCESS', ('RepairedAt=' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')))
foreach ($item in $repaired) {
    $lines += ('Release=' + $item.Release + '; Product=' + $item.Product + '; Version=' + $item.Version + '; Commands=' + $item.Commands + '; Loader=' + $item.Loader)
}
[IO.File]::WriteAllLines($logPath, $lines, (New-Object Text.UTF8Encoding($true)))

Write-Host ''
Write-Host 'COMMAND REGISTRATION REPAIR SUCCEEDED.' -ForegroundColor Green
$repaired | Format-Table Release, Product, Version, Commands, Loader -AutoSize
Write-Host ('Verification log: ' + $logPath)
Write-Host 'Close every AutoCAD window and restart AutoCAD before testing ZHDIMHELP.' -ForegroundColor Yellow

