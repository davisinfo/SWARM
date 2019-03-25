function Get-StatsEnergiminer {
    $Request = $null; try {$Request = Get-Content ".\logs\$MinerType.log" -ErrorAction Stop}catch {}
    if ($Request) {
        $Data = $Request | Select-String "Mh/s" | Select -Last 1
        $Data = $Data -split " "
        $MHS = 0
        $MHS = $Data | Select-String -Pattern "Mh/s" -AllMatches -Context 1, 0 | % {$_.Context.PreContext[0]}
        $MHS = $MHS -replace '\x1b\[[0-9;]*m', ''
        $global:BRAW = [Double]$MHS * 1000000
        Write-MinerData2;
        $global:BKHS += [Double]$MHS * 1000
        $Hash = $null; $Hash = $Data | Select-String -Pattern "GPU/" -AllMatches -Context 0, 1
        $Hash = $Hash -replace '\x1b\[[0-9;]*m', '' | % {$_ -split ' ' | Select -skip 3 -first 1}
        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i)}}catch {Write-Host "Failed To parse GPU Threads" -ForegroundColor Red};
        $global:BMinerACC = $($Request | Select-String "Accepted").count
        $global:BMinerREJ = $($Request | Select-String "Rejected").count
        $global:BACC += $MinerACC
        $global:BREJ += $MinerREJ
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
        $global:BALGO += "$MinerAlgo"
    }
    else {Set-APIFailure; break}
}