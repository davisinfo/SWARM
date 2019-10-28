function Global:Get-StatsTrex {
    $Request = Global:Get-HTTP -Port $global:Port -Message "/summary"
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To parse API" -ForegroundColor Red }
        if ([Double]$Data.hashrate_minute -ne 0 -or [Double]$Data.accepted_count -ne 0) { 
            $global:RAW = [Double]$Data.hashrate_minute;  
            $global:GPUKHS = [Double]$Data.hashrate_minute / 1000
        }
        Global:Write-MinerData2;
        $Hash = $Data.gpus.hashrate_minute
        try { 
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i) / 1000 
            } 
        }
        catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        $Data.accepted_count | ForEach-Object { $global:MinerACC += $_ }
        $Data.rejected_count | ForEach-Object { $global:MinerREJ += $_ }
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Global:Set-APIFailure; break }
}