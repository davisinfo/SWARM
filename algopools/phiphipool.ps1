$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$phiphipool_Request = [PSCustomObject]@{ } 

if($(arg).xnsub -eq "Yes"){$X = "#xnsub"}

if ($Name -in $(arg).PoolName) {
    try { $phiphipool_Request = Invoke-RestMethod "https://www.phi-phi-pool.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Global:Write-Log "SWARM contacted ($Name) but there was no response."; return }
 
    if (($phiphipool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Global:Write-Log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }
  
    switch ($(arg).Location) {
        "ASIA" { $region = "asia" }
        "US" { $region = "us" }
        "EUROPE" { $Region = "eu" }
    }
  
    $phiphipool_Request | 
    Get-Member -MemberType NoteProperty -ErrorAction Ignore | 
    Select-Object -ExpandProperty Name | 
    Where-Object { $phiphipool_Request.$_.hashrate -gt 0 } | 
    Where-Object {
        $Algo = $phiphipool_Request.$_.name.ToLower();
        $local:phiphipool_Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name | Where { $Algo -in $global:Config.Pool_Algos.$_.alt_names }
        return $phiphipool_Algorithm
    } |
    ForEach-Object {
        if ($(vars).Algorithm -contains $phiphipool_Algorithm -or $(arg).ASIC_ALGO -contains $phiphipool_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$phiphipool_Algorithm.exclusions -and $phiphipool_Algorithm -notin $(vars).BanHammer) {
                $phiphipool_Port = $phiphipool_Request.$_.port
                $phiphipool_Host = "$($Region).phi-phi-pool.com$X"
                $Divisor = (1000000 * $phiphipool_Request.$_.mbtc_mh_factor)
                $Fees = $phiphipool_Request.$_.fees
                $Workers = $phiphipool_Request.$_.Workers
                $StatPath = ".\stats\($Name)_$($phiphipool_Algorithm)_profit.txt"
                $Hashrate = $phiphipool_Request.$_.hashrate

                if (-not (Test-Path $StatPath)) {
                    $StatAlgo = $phiphipool_Algorithm -replace "`_","`-"
                    $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( [Double]$phiphipool_Request.$_.estimate_last24h / $Divisor * (1 - ($phiphipool_Request.$_.fees / 100)))
                } 
                else {
                    $StatAlgo = $phiphipool_Algorithm -replace "`_","`-"
                    $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( [Double]$phiphipool_Request.$_.estimate_current / $Divisor * (1 - ($phiphipool_Request.$_.fees / 100)))
                }

                if (-not $(vars).Pool_Hashrates.$phiphipool_Algorithm) { $(vars).Pool_Hashrates.Add("$phiphipool_Algorithm", @{ })
                }
                if (-not $(vars).Pool_Hashrates.$phiphipool_Algorithm.$Name) { $(vars).Pool_Hashrates.$phiphipool_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" })
                }

                [PSCustomObject]@{
                    Symbol    = "$phiphipool_Algorithm-Algo"
                    Algorithm = $phiphipool_Algorithm
                    Price     = $Stat.$($(arg).Stat_Algo)
                    Protocol  = "stratum+tcp"
                    Host      = $phiphipool_Host
                    Port      = $phiphipool_Port
                    User1     = $global:Wallets.Wallet1.$($(arg).Passwordcurrency1).address
                    User2     = $global:Wallets.Wallet2.$($(arg).Passwordcurrency2).address
                    User3     = $global:Wallets.Wallet3.$($(arg).Passwordcurrency3).address
                    Pass1     = "c=$($global:Wallets.Wallet1.keys),id=$($(arg).RigName1)"
                    Pass2     = "c=$($global:Wallets.Wallet2.keys),id=$($(arg).RigName2)"
                    Pass3     = "c=$($global:Wallets.Wallet3.keys),id=$($(arg).RigName3)"
                }
            }
        }
    }
}
