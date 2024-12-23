# URL k PowerShell skriptu
$scriptUrl = "https://raw.githubusercontent.com/ProgramZelva-dev/ProgramZelva-ToolBox/main/devtool.ps1"

# Stažení PowerShell skriptu z URL
$scriptContent = Invoke-WebRequest -Uri $scriptUrl -Method Get

# Uložení skriptu do dočasného souboru
$tempScriptPath = [System.IO.Path]::GetTempFileName() + ".ps1"
$scriptContent.Content | Out-File -FilePath $tempScriptPath

# Spuštění staženého skriptu v novém PowerShell okně
Start-Process powershell -ArgumentList '-NoExit', '-Command', "& { . '$tempScriptPath' }"
