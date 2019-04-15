$CPUTypes | ForEach-Object {
    
    $ConfigType = $_;

    ##Miner Path Information
    if ($cpu.bubasik.$ConfigType) { $Path = "$($cpu.bubasik.$ConfigType)" }
    else { $Path = "None" }
    if ($cpu.bubasik.uri) { $Uri = "$($cpu.bubasik.uri)" }
    else { $Uri = "None" }
    if ($cpu.bubasik.minername) { $MinerName = "$($cpu.bubasik.minername)" }
    else { $MinerName = "None" }
    if ($Platform -eq "linux") { $Build = "Tar" }
    elseif ($Platform -eq "windows") { $Build = "Zip" }

    $Name = "bubasik";

    ##Log Directory
    $Log = Join-Path $dir "logs\$ConfigType.log"

    ##Parse -CPUThreads
    if ($CPUThreads -ne '') { $Devices = $CPUThreads }

    ##Get Configuration File
    $GetConfig = "$dir\config\miners\bubasik.json"
    try { $Config = Get-Content $GetConfig | ConvertFrom-Json }
    catch { Write-Warning "Warning: No config found at $GetConfig" }

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $dir "build\export"

    ##Prestart actions before miner launch
    $BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
    $Prestart = @()
    if (Test-Path $BE) { $Prestart += "export LD_PRELOAD=libcurl.so.4.5.0" }
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $Config.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }

    $Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $MinerAlgo = $_
        $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
            if ($Algorithm -eq "$($_.Algorithm)" -and $Bad_Miners.$($_.Algorithm) -notcontains $Name) {
                if ($Config.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
                [PSCustomObject]@{
                    MName      = $Name
                    Coin       = $Coins
                    Delay      = $Config.$ConfigType.delay

                    Symbol     = "$($($_.Algorithm))"
                    MinerName  = $MinerName
                    Prestart   = $PreStart
                    Type       = $ConfigType
                    Path       = $Path
                    Devices    = $Devices
                    DeviceCall = "cpuminer-opt"
                    Arguments  = "-a $($Config.$ConfigType.naming.$($_.Algorithm)) -o stratum+tcp://$($_.Host):$($_.Port) -b 0.0.0.0:10001 -u $($_.User1) -p $($_.Pass1)$($Diff) $($Config.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) }
                    Quote      = if ($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)) { $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) * ($_.Price) }else { 0 }
                    PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                    MinerPool  = "$($_.Name)"
                    FullName   = "$($_.Mining)"
                    Port       = 10001
                    API        = "cpuminer"
                    Wallet     = "$($_.$User)"
                    URI        = $Uri
                    Server     = "localhost"
                    BUILD      = $Build
                    PoolType   = "AlgoPools"
                    Algo       = "$($_.Algorithm)"
                    Log        = $Log 
                }            
            }
        }     
    }
}