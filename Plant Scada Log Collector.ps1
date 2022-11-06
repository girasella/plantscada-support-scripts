Function Parse-IniFile ($file) {
  $ini = @{}

  # Create a default section if none exist in the file. Like a java prop file.
  $section = "NO_SECTION"
  $ini[$section] = @{}

  switch -regex -file $file {
    "^\[(.+)\]$" {
      $section = $matches[1].Trim()
      $ini[$section] = @{}
    }
    "^\s*([^#].+?)\s*=\s*(.*)" {
      $name,$value = $matches[1..2]
      # skip comments that start with semicolon:
      if (!($name.StartsWith(";"))) {
        $ini[$section][$name] = $value.Trim()
      }
    }
  }
  $ini
}

$currentDateTime = Get-Date -Format 'yyyy-MM-dd_HH.mm.ss'
$supportFolder = "$currentDateTime $(hostname) Aveva Support"
mkdir $supportFolder | Out-Null

start-transcript -append -path "$supportFolder\scriptLog.log"

echo "Support Folder created: $supportFolder"

$CitectInstallKey = ls 'HKLM:\SOFTWARE\WOW6432Node\Citect\SCADA Installs' | Select-Object -first 1
$iniFile = $CitectInstallKey | Get-ItemPropertyValue -Name DefaultINIPath
echo "citect.ini file path: $iniFile"
$binFolder = $CitectInstallKey | Get-ItemPropertyValue -Name BinFolder
echo "Bin folder Path: $binFolder"

echo "Parsing citect.ini file..."
$iniConfig = Parse-IniFile($iniFile)

$LogsFolder = $iniConfig['ctEdit']['Logs']
echo "ctLogs folder: $LogsFolder"
$aaLogsFolder = "$env:ProgramData\ArchestrA\LogFiles"
echo "Archestra logs folder: $aaLogsFolder"

echo "Copying ctLogs folder..."
Copy-Item $LogsFolder "$supportFolder\ctLogs" -Recurse
echo "Copying citect.ini..."
Copy-item $iniFile "$supportFolder\ctLogs"
echo "Copying aaLogs folder..."
Copy-Item $aaLogsFolder "$supportFolder\aaLogs" -Recurse

mkdir "$supportFolder\regInfo" | Out-Null
echo "Exporting AVEVA registry keys..."
reg export 'HKLM\SOFTWARE\WOW6432Node\AVEVA' "$supportFolder\regInfo\AVEVA.reg"
echo "Exporting ArchestrA registry keys..."
reg export 'HKLM\SOFTWARE\WOW6432Node\ArchestrA' "$supportFolder\regInfo\ArchestrA.reg"
echo "Exporting Citect registry keys..."
reg export 'HKLM\SOFTWARE\WOW6432Node\Citect' "$supportFolder\regInfo\Citect.reg"


mkdir "$supportFolder\winLogs" | out-null

echo "Exporting Windows Event Logs..."
wevtutil epl System "$supportFolder\winLogs\System.evtx"
wevtutil epl Application "$supportFolder\winLogs\Application.evtx"
wevtutil epl Security "$supportFolder\winLogs\Security.evtx"

echo "Exporting Process data..."
Get-Process |  Select-Object -Property Id,Name,Product, Description, Company, FileVersion,StartTime,PrivateMemorySize,Handles,CPU,Path | Export-Csv -Path "$supportFolder\winLogs\Processes.csv" -Delimiter ',' -NoTypeInformation
echo "Exporting TCP Connections data..."
Get-NetTCPConnection | Sort-Object -Property LocalPort | Select-Object -property OwningProcess,LocalAddress,LocalPort,RemoteAddress,RemotePort,State | Export-Csv -Path "$supportFolder\winLogs\TCPConnections.csv" -Delimiter ',' -NoTypeInformation
echo "Exporting Windows Defender settings..."
Get-MpPreference > "$supportFolder\winLogs\AV_Settings.txt"
echo "Exporting Network configuration..."
Get-NetIPConfiguration -detailed > "$supportFolder\winLogs\NetworkConfiguration.txt"
echo "Exporting System information..."
Get-ComputerInfo > "$supportFolder\winLogs\SystemInfo.txt"

Stop-Transcript

Compress-Archive "$supportFolder\*" "$supportFolder.zip" 

Remove-Item $supportFolder -Recurse







