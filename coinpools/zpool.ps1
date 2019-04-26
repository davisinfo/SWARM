$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$zpool_Request = [PSCustomObject]@{ }
$zpool_Sorted = [PSCustomObject]@{ }
$zpool_UnSorted = [PSCustomObject]@{ }

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

if ($Poolname -eq $Name) {
    try { $zpool_Request = Invoke-RestMethod "https://zpool.ca/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch {
        Write-Log "SWARM contacted ($Name) for a failed API check. (Coins)"; 
        return
    }

    if (($zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    }

    Switch ($Location) {
        "US" { $region = "na" }
        "EUROPE" { $region = "eu" }
        "ASIA" { $region = "sea" }
    }
   
    $zpool_Request.PSObject.Properties.Name | ForEach-Object { $zpool_Request.$_ | Add-Member "sym" $_ }
    $zpoolAlgos = @()
    $zpoolAlgos += $Algorithm
    $zpoolAlgos += $ASIC_ALGO

    $Algos = $zpoolAlgos | ForEach-Object { if ($Bad_pools.$_ -notcontains $Name) { $_ } }
    $zpool_Request.PSObject.Properties.Value | % { $_.Estimate = [Decimal]$_.Estimate }

    $Algos | ForEach-Object {
    
        $Selected = $_

        $Best = $zpool_Request.PSObject.Properties.Value | 
        Where-Object Algo -eq $Selected | 
        Where-Object Algo -in $global:FeeTable.zpool.keys | 
        Where-Object Algo -in $global:divisortable.zpool.Keys | 
        Where-Object estimate -gt 0 | 
        Where-Object hashrate -ne 0 | 
        Sort-Object Price -Descending |
        Select-Object -First 1

        if ($Best -ne $null) { $zpool_Sorted | Add-Member $Best.sym $Best -Force }
    }

    if ($Stat_All -eq "Yes") {

        $Algos | ForEach-Object {

            $NotBest = $zpool_Request.PSObject.Properties.Value | 
            Where-Object Algo -eq $Selected | 
            Where-Object Algo -in $global:FeeTable.zpool.keys | 
            Where-Object Algo -in $global:divisortable.zpool.Keys | 
            Where-Object estimate -gt 0 | 
            Where-Object hashrate -ne 0 | 
            Sort-Object Price -Descending |
            Select-Object -Skip 1

            if ($NotBest -ne $null) { $NotBest | ForEach-Object { $zpool_UnSorted | Add-Member $_.sym $_ -Force } }

        }

        $zpool_UnSorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {
            $zpool_Algorithm = $zpool_UnSorted.$_.algo.ToLower()
            $zpool_Symbol = $zpool_UnSorted.$_.sym.ToUpper()
            $Fees = [Double]$global:FeeTable.zpool.$zpool_Algorithm
            $Estimate = [Double]$zpool_UnSorted.$_.estimate * 0.001
            $Divisor = (1000000 * [Double]$global:DivisorTable.zpool.$zpool_Algorithm)
            $Workers = [Double]$zpool_UnSorted.$_.Workers * 0.001
            $Cut = ConvertFrom-Fees $Fees $Workers $Estimate
            try { $Stat = Set-Stat -Name "$($Name)_$($zpool_Symbol)_coin_profit" -Value ([Double]$Cut / $Divisor) }catch { Write-Log "Failed To Calculate Stat For $zpool_Symbol" }
        }
    }

    $zpool_Sorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

        $zpool_Algorithm = $zpool_Sorted.$_.algo.ToLower()
        $zpool_Symbol = $zpool_Sorted.$_.sym.ToUpper()
        $zpool_Coin = $zpool_Sorted.$_.Name.Tolower()
        $zpool_Port = $zpool_Sorted.$_.port
        $Zpool_Host = "$($ZPool_Algorithm).$($region).mine.zpool.ca"
        $Fees = [Double]$global:FeeTable.zpool.$zpool_Algorithm
        $Workers = $zpool_Sorted.$_.Workers
        $Estimate = [Double]$zpool_Sorted.$_.estimate * 0.001
        $Divisor = (1000000 * [Double]$global:DivisorTable.zpool.$zpool_Algorithm)

        $Cut = ConvertFrom-Fees $Fees $Workers $Estimate

        $Stat = Set-Stat -Name "$($Name)_$($zpool_Symbol)_coin_profit" -Value ([Double]$Cut / $Divisor)

        $Pass1 = $global:Wallets.Wallet1.Keys
        $User1 = $global:Wallets.Wallet1.$Passwordcurrency1.address
        $Pass2 = $global:Wallets.Wallet2.Keys
        $User2 = $global:Wallets.Wallet2.$Passwordcurrency2.address
        $Pass3 = $global:Wallets.Wallet3.Keys
        $User3 = $global:Wallets.Wallet3.$Passwordcurrency3.address

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
                
        if ($global:All_AltWallets) {
            $global:All_AltWallets | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                if ($_ -eq $zpool_Symbol) {
                    $Pass1 = $zpool_Symbol
                    $User1 = $global:All_AltWallets.$_
                    $Pass2 = $zpool_Symbol
                    $User2 = $global:All_AltWallets.$_
                    $Pass3 = $zpool_Symbol
                    $User3 = $global:All_AltWallets.$_
                }
            }
        }

        [PSCustomObject]@{
            Priority  = $Priorities.Pool_Priorities.$Name
            Symbol    = "$zpool_Symbol-Coin"
            Mining    = $zpool_Algorithm
            Algorithm = $zpool_Algorithm
            Price     = $Stat.$Stat_Coin
            Protocol  = "stratum+tcp"
            Host      = $zpool_Host
            Port      = $zpool_Port
            User1     = $User1
            User2     = $User2
            User3     = $User3
            CPUser    = $User1
            CPUPass   = "c=$Pass1,zap=$zpool_Symbol,id=$Rigname1"
            Pass1     = "c=$Pass1,zap=$zpool_Symbol,id=$Rigname1"
            Pass2     = "c=$Pass2,zap=$zpool_Symbol,id=$Rigname2"
            Pass3     = "c=$Pass3,zap=$zpool_Symbol,id=$Rigname3"
            Location  = $Location
            SSL       = $false
        } 
    }
}
