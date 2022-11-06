$currentDateTime = Get-Date -Format 'yyyy-MM-dd_HH.mm.ss'
$supportFolder = "$currentDateTime $(hostname) Anywhere Aveva Support"

if (Test-Path 'HKLM:\SOFTWARE\Ericom Software') {
    echo "Exporting Anywhere registry keys..."
    mkdir "$supportFolder\regInfo" | Out-Null
    reg export 'HKLM\SOFTWARE\Ericom Software' "$supportFolder\regInfo\Anywhere.reg"

    $anywhereServerFolder = Get-ItemProperty 'HKLM:\SOFTWARE\Ericom Software\Access Server\Current' | Get-ItemPropertyValue -Name 'Executable Path'
    $anywhereServerFolder = Split-Path -Path $anywhereServerFolder

    mkdir "$supportFolder\anywhereLogs" | Out-Null
    mkdir "$supportFolder\anywhereLogs\Server" | Out-Null
    echo "Copying Anywhere Server logs folder..."
    Copy-Item "$anywhereServerFolder\Logs" "$supportFolder\anywhereLogs\Server" -Recurse
    $launcherFolder = Split-Path $anywhereServerFolder.replace(${env:ProgramFiles(x86)},$env:APPDATA)
    if (test-path $launcherFolder) {
        mkdir "$supportFolder\anywhereLogs\Launcher" | out-null
        echo "Copying Anywhere Launcher logs folder..."
        Copy-Item $launcherFolder "$supportFolder\anywhereLogs\Launcher" -Recurse
    }
}