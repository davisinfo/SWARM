function Global:Get-DateFiles {
    param (
        [Parameter(Mandatory = $false)]
        [String]$CmdDir
    )
    
    if (Test-Path ".\build\pid") {Remove-Item ".\build\pid\*" -Force | Out-Null}
    else {New-Item -Path ".\build" -Name "pid" -ItemType "Directory" | Out-Null}
    Start-Sleep -S 1
    $PID | Out-File ".\build\pid\miner_pid.txt"
    if ($(arg).Platform -eq "windows") { $host.ui.RawUI.WindowTitle = "SWARM"; }
}

function Global:get-argnotice {
    if ((Test-Path ".\config\parameters\newarguments.json") -or $Debug -eq $true) {
        Global:Write-Log "Detected New Arguments- Changing Parameters" -ForegroundColor Cyan
        Global:Write-Log "These arguments can be found/modified in config < parameters < newarguments.json" -ForegroundColor Cyan
        Start-Sleep -S 2
    }    
}

function Global:Clear-Stats {
    $FileClear = @()
    $FileClear += ".\build\txt\minerstats.txt"
    $FileClear += ".\build\txt\mineractive.txt"
    $FileClear += ".\build\bash\hivecpu.sh"
    $FileClear += ".\build\txt\profittable.txt"
    $FileClear += ".\build\txt\bestminers.txt"
    $FileClear | ForEach-Object { if (Test-Path $_) { Remove-Item $_ -Force } }
}

function Global:Set-NewType {
    $(arg).Type | ForEach-Object {
        if ($_ -eq "amd1") { $_ = "AMD1" }
        if ($_ -eq "nvidia1") { $_ = "NVIDIA1" }
        if ($_ -eq "nvidia2") { $_ = "NVIDIA2" }
        if ($_ -eq "nvidia2") { $_ = "NVIDIA3" }
        if ($_ -eq "cpu") { $_ = "CPU" }
        if ($_ -eq "asic") { $_ = "ASIC" }
    }    
}

function Global:get-NIST {
    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
    try {$WebRequest = Invoke-WebRequest -Uri 'http://nist.time.gov/actualtime.cgi' -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop} catch{Write-Warning "NIST Server Timed Out. Using Local Time"; return Get-Date }
    $milliseconds = [int64](($webRequest.Content -replace '.*timestamp time="|" delay=".*') / 1000)
    $NistTime = (New-Object -TypeName DateTime -ArgumentList (1970, 1, 1)).AddMilliseconds($milliseconds)
    $GetNIST = [System.TimeZoneInfo]::ConvertTimeFromUtc($NistTime, (Get-Timezone))
    return $GetNIST
}