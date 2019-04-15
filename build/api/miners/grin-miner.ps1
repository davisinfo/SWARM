function Get-StatsGrinMiner {
    try { $Request = Get-Content ".\logs\$MinerType.log" -ErrorAction SilentlyContinue }catch { Write-Host "Failed to Read Miner Log"; break }
    if ($Request) {
        $Hash = @()
        $Devices | ForEach-Object {
            $DeviceData = $Null
            $DeviceData = $Request | Select-String "Device $($_)" | ForEach-Object { $_ | Select-String "Graphs per second: " } | Select-Object -Last 1
            $DeviceData = $DeviceData -split "Graphs per second: " | Select-Object -Last 1 | ForEach-Object { $_ -split " - Total" | Select-Object -First 1 }
            if ($DeviceData) { $Hash += [Double]$DeviceData / 1000 ; $global:RAW += [Double]$DeviceData; $global:GPUKHS += [Double]$DeviceData / 1000 }
            else { $Hash += 0; $global:RAW += 0; $global:GPUKHS += 0 }
        }
        Write-MinerData2;
        try { 
            for ($i = 0; $i -lt $Devices.Count; $i++) { 
                $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) 
            }
        }
        catch { Write-Host "Failed To parse GPU Threads" -ForegroundColor Red };
        $global:MinerACC = $($Request | Select-String "Share Accepted!!").count
        $global:MinerREJ = $($Request | Select-String "Failed to submit a solution").count
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Set-APIFailure }
}