$AMDTypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "AMD", ""

    ##Miner Path Information
    if ($amd.phoenix_amd.$ConfigType) { $Path = "$($amd.phoenix_amd.$ConfigType)" }
    else { $Path = "None" }
    if ($amd.phoenix_amd.uri) { $Uri = "$($amd.phoenix_amd.uri)" }
    else { $Uri = "None" }
    if ($amd.phoenix_amd.minername) { $MinerName = "$($amd.phoenix_amd.minername)" }
    else { $MinerName = "None" }
    if ($Platform -eq "linux") { $Build = "Tar" }
    elseif ($Platform -eq "windows") { $Build = "Zip" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "phoenix_amd-$Num"; $Port = "2600$Num"

    Switch ($Num) {
        1 { $Get_Devices = $AMDDevices1 }
    }

    ##Log Directory
    $Log = Join-Path $dir "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") {
        $ClayDevices1 = $Get_Devices -split ","
        $ClayDevices1 = Switch ($ClayDevices1) { "10" { "a" }; "11" { "b" }; "12" { "c" }; "13" { "d" }; "14" { "e" }; "15" { "f" }; "16" { "g" }; "17" { "h" }; "18" { "i" }; "19" { "j" }; "20" { "k" }; default { "$_" }; }
        $ClayDevices1 = $ClayDevices1 | ForEach-Object { $_ -replace ("$($_)", ",$($_)") }
        $ClayDevices1 = $ClayDevices1 -join ""
        $ClayDevices1 = $ClayDevices1.TrimStart(" ", ",")  
        $ClayDevices1 = $ClayDevices1 -replace (",", "")
        $Devices = $ClayDevices1
    }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    $GetConfig = "$dir\config\miners\phoenix_amd.json"
    try { $Config = Get-Content $GetConfig | ConvertFrom-Json }
    catch { Write-Warning "Warning: No config found at $GetConfig" }

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $dir "build\export"

    ##Prestart actions before miner launch
    $Prestart = @()
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $Config.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }

    ##Build Miner Settings
    $Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $MinerAlgo = $_
        $Stat = Get-Stat -Name "$($Name)_$($MinerAlgo)_hashrate"
        $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
            if ($Algorithm -eq "$($_.Algorithm)" -and $Bad_Miners.$($_.Algorithm) -notcontains $Name) {
                if ($Config.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
                if ($_.Worker) { $MinerWorker = "-eworker $($_.Worker) " }
                else { $MinerWorker = "-epsw $($_.$Pass)$($Diff) " }
                [PSCustomObject]@{
                    MName      = $Name
                    Coin       = $Coins
                    Delay      = $Config.$ConfigType.delay
                    Fees       = $Config.$ConfigType.fee.$($_.Algorithm)
                    Symbol     = "$($_.Symbol)"
                    MinerName  = $MinerName
                    Prestart   = $PreStart
                    Type       = $ConfigType
                    Path       = $Path
                    Devices    = $Devices
                    DeviceCall = "claymore"
                    Arguments  = "-platform 1 -mport $Port -mode 1 -allcoins 1 -allpools 1 -epool $($_.Protocol)://$($_.Host):$($_.Port) -ewal $($_.$User) $MinerWorker-wd 0 -logfile `'$(Split-Path $Log -Leaf)`' -logdir `'$(Split-Path $Log)`' -gser 2 -dbg -1 -eres 2 $($Config.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = [PSCustomObject]@{$($_.Algorithm) = $Stat.Day }
                    Quote      = if ($Stat.Day) { $Stat.Day * ($_.Price) }else { 0 }
                    PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                    ocdpm      = if ($Config.$ConfigType.oc.$($_.Algorithm).dpm) { $Config.$ConfigType.oc.$($_.Algorithm).dpm }else { $OC."default_$($ConfigType)".dpm }
                    ocv        = if ($Config.$ConfigType.oc.$($_.Algorithm).v) { $Config.$ConfigType.oc.$($_.Algorithm).v }else { $OC."default_$($ConfigType)".v }
                    occore     = if ($Config.$ConfigType.oc.$($_.Algorithm).core) { $Config.$ConfigType.oc.$($_.Algorithm).core }else { $OC."default_$($ConfigType)".core }
                    ocmem      = if ($Config.$ConfigType.oc.$($_.Algorithm).mem) { $Config.$ConfigType.oc.$($_.Algorithm).mem }else { $OC."default_$($ConfigType)".memory }
                    ocmdpm     = if ($Config.$ConfigType.oc.$($_.Algorithm).mdpm) { $Config.$ConfigType.oc.$($_.Algorithm).mdpm }else { $OC."default_$($ConfigType)".mdpm }
                    ocfans     = if ($Config.$ConfigType.oc.$($_.Algorithm).fans) { $Config.$ConfigType.oc.$($_.Algorithm).fans }else { $OC."default_$($ConfigType)".fans }
                    FullName   = "$($_.Mining)"
                    API        = "claymore"
                    Port       = $Port
                    MinerPool  = "$($_.Name)"
                    Wrap       = $false
                    Wallet     = "$($_.$User)"
                    URI        = $Uri
                    Server     = "localhost"
                    BUILD      = $Build
                    Algo       = "$($_.Algorithm)"
                    Log        = "miner_generated"
                }            
            }
        }
    }
}