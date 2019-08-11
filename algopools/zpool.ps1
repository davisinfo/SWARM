$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Pool_Request = [PSCustomObject]@{ } 

if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" } 

if ($Name -in $(arg).PoolName) {
    try { $Pool_Request = Invoke-RestMethod "http://www.zpool.ca/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { log "SWARM contacted ($Name) but there was no response."; return }
 
    if (($Pool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }

    $Algos = @()
    $Algos += $(vars).Algorithm
    $Algos += $(arg).ASIC_ALGO
    $Algos = $Algos | ForEach-Object { if ($Bad_pools.$_ -notcontains $Name) { $_ } }

    ## Only get algos we need & convert name to universal schema
    $Pool_Sorted = $Pool_Request.PSobject.Properties.Value | Where-Object {[Double]$_.estimate_current -gt 0} | ForEach-Object { 
        $N = $_.Name;
        $_ | Add-Member "Original_Algo" $N
        $_.Name = $global:Config.Pool_Algos.PSObject.Properties.Name | Where { $N -in $global:Config.Pool_Algos.$_.alt_names };
        if ($_.Name) { if ($_.Name -in $Algos -and $Name -notin $global:Config.Pool_Algos.$($_.Name).exclusions -and $_.Name -notin $(vars).BanHammer) { $_ } }
    }

    ## Add 24 hour deviation.
    $Pool_Sorted | ForEach-Object {
        $Raw = shuffle $_.estimate_last24h $_.actual_last24h
        $_ | Add-Member "deviation" $Raw
    }

    Switch ($(arg).Location) {
        "US" { $region = "na" }
        "EUROPE" { $region = "eu" }
        "ASIA" { $region = "sea" }
    }    

    $Pool_Sorted | ForEach-Object {
        $StatAlgo = $_.Name -replace "`_", "`-"
        $StatPath = "$($Name)_$($StatAlgo)_profit"
        if (-not (test-Path ".\stats\$StatPath") ) { $Estimate = [Double]$_.estimate_last24h }
        else { $Estimate = [Double]$_.estimate_current }
    
        $Pool_Port = $_.port
        $Pool_Host = "$($_.Original_Algo).$($region).mine.zpool.ca$X"
        $Divisor = 1000000 * $_.mbtc_mh_factor
        $Hashrate = $_.hashrate_shared
        $previous = [Math]::Max(([Double]$_.actual_last24h * 0.001) / $Divisor * (1 - ($_.fees / 100)), $SmallestValue)
    
        $Stat = Global:Set-Stat -Name $StatPath -HashRate $HashRate -Value ( $Estimate / $Divisor * (1 - ($_.fees / 100))) -Shuffle $_.deviation 
        if (-not $(vars).Pool_Hashrates.$($_.Name)) { $(vars).Pool_Hashrates.Add("$($_.Name)", @{ }) }
        if (-not $(vars).Pool_Hashrates.$($_.Name).$Name) { $(vars).Pool_Hashrates.$($_.Name).Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" })}
        
        $Level = $Stat.$($(arg).Stat_Algo)
        if ($(arg).Historical_Bias -gt 0) {
            $SmallestValue = 1E-20 
            $Level = [Math]::Max($Level + ($Level * $Stat.Deviation), $SmallestValue)
        }

        $Pass1 = $global:Wallets.Wallet1.Keys
        $User1 = $global:Wallets.Wallet1.$($(arg).Passwordcurrency1).address
        $Pass2 = $global:Wallets.Wallet2.Keys
        $User2 = $global:Wallets.Wallet2.$($(arg).Passwordcurrency2).address
        $Pass3 = $global:Wallets.Wallet3.Keys
        $User3 = $global:Wallets.Wallet3.$($(arg).Passwordcurrency3).address

        if ($global:Wallets.AltWallet1.keys) {
            $global:Wallets.AltWallet1.Keys | ForEach-Object {
                if ($global:Wallets.AltWallet1.$_.Pools -contains $Name) {
                    $Pass1 = $_;
                    $User1 = $global:Wallets.AltWallet1.$_.address;
                }
            }
        }
        if ($global:Wallets.AltWallet2.keys) {
            $global:Wallets.AltWallet2.Keys | ForEach-Object {
                if ($global:Wallets.AltWallet2.$_.Pools -contains $Name) {
                    $Pass2 = $_;
                    $User2 = $global:Wallets.AltWallet2.$_.address;
                }
            }
        }
        if ($global:Wallets.AltWallet3.keys) {
            $global:Wallets.AltWallet3.Keys | ForEach-Object {
                if ($global:Wallets.AltWallet3.$_.Pools -contains $Name) {
                    $Pass3 = $_;
                    $User3 = $global:Wallets.AltWallet3.$_.address;
                }
            }
        }

                    
        [PSCustomObject]@{
            Symbol    = "$($_.Name)-Algo"
            Algorithm = "$($_.Name)"
            Price     = $Level
            Protocol  = "stratum+tcp"
            Host      = $Pool_Host
            Port      = $Pool_Port
            User1     = $global:Wallets.Wallet1.$($(arg).Passwordcurrency1).address
            User2     = $global:Wallets.Wallet2.$($(arg).Passwordcurrency2).address
            User3     = $global:Wallets.Wallet3.$($(arg).Passwordcurrency3).address
            Pass1     = "c=$($global:Wallets.Wallet1.keys),id=$($(arg).RigName1)"
            Pass2     = "c=$($global:Wallets.Wallet2.keys),id=$($(arg).RigName2)"
            Pass3     = "c=$($global:Wallets.Wallet3.keys),id=$($(arg).RigName3)"
            Previous  = $previous
        }
    }
}