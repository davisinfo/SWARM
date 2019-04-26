
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$nicehash_Request = [PSCustomObject]@{ } 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
if ($Poolname -eq $Name) {
    try { $nicehash_Request = Invoke-RestMethod "https://api.nicehash.com/api?method=simplemultialgo.info" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Log "SWARM contacted ($Name) but there was no response."; return }
 
    if (($nicehash_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    } 
  
    Switch ($Location) {
        "US" { $Region = "usa" }
        "ASIA" { $Region = "hk" }
        "EUROPE" { $Region = "eu" }
    }

    $nicehash_Request.result | 
    Select-Object -ExpandProperty simplemultialgo | 
    Where-Object paying -ne 0 | 
    Where-Object { $Naming.$($_.Name) } | 
    ForEach-Object {
    
        $nicehash_Algorithm = $_.name.ToLower()

        if ($Algorithm -contains $nicehash_Algorithm -or $ASIC_ALGO -contains $nicehash_Algorithm) {
            if ($Bad_pools.$nicehash_Algorithm -notcontains $Name) {

                ## Nicehash 'Gets' you with the fees. If you read the fine print,
                ## If you do not use a nicehash wallet- Your total fee will end up
                ## becoming 5%. If you use a nicehash wallet, the fee is variable,
                ## but usually around 2%.
            
                if (-not $Nicehash_Wallet1) { $NH_Wallet1 = $Wallet1; [Double]$Fee = 5; }else { $NH_Wallet1 = $Nicehash_Wallet1; [Double]$Fee = $NiceHash_Fee }
                if (-not $Nicehash_Wallet2) { $NH_Wallet2 = $Wallet2; [Double]$Fee = 5; }else { $NH_Wallet2 = $Nicehash_Wallet2; [Double]$Fee = $NiceHash_Fee }
                if (-not $Nicehash_Wallet3) { $NH_Wallet3 = $Wallet3; [Double]$Fee = 5; }else { $NH_Wallet3 = $Nicehash_Wallet3; [Double]$Fee = $NiceHash_Fee }

                $nicehash_Host = "$($_.name).$Region.nicehash.com"
                $nicehash_excavator = "nhmp.$Region.nicehash.com"
                $nicehash_Port = $_.port
                $Divisor = 1000000000

                ## Nicehash is pretty straightforward being PPS. In
                ## My experience, whatever they state is return- Is
                ## usually pretty close to actual.

                $Stat = Set-Stat -Name "$($Name)_$($Nicehash_Algorithm)_profit" -Value ([Double]$_.paying / $Divisor * (1 - ($Fee / 100)))
     
                [PSCustomObject]@{
                    Priority  = $Priorities.Pool_Priorities.$Name
                    Coin      = "No"
                    Excavator = $nicehash_excavator
                    Symbol    = "$nicehash_Algorithm-Algo"
                    Mining    = $nicehash_Algorithm
                    Algorithm = $nicehash_Algorithm
                    Price     = $Stat.$Stat_Algo
                    Protocol  = "stratum+tcp"
                    Host      = $nicehash_Host
                    Port      = $nicehash_Port
                    User1     = "$NH_Wallet1.$Rigname1"
                    User2     = "$NH_Wallet2.$Rigname2"
                    User3     = "$NH_Wallet3.$Rigname3"
                    CPUser    = "$NH_Wallet1.$Rigname1"
                    CPUPass   = "x"
                    Pass1     = "x"
                    Pass2     = "x"
                    Pass3     = "x"
                    Location  = $Location
                    SSL       = $false
                }
            }
        }
    }
}
