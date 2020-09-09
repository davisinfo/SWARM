<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#> 

function Global:Start-Webcommand {
    Param(
        [Parameter(Mandatory = $false)]
        [Object]$Command,
        [Parameter(Mandatory = $false)]
        [string]$swarm_message,
        [Parameter(Mandatory = $false)]
        [string]$WebSite
    )

    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
    Set-Location $($(vars).dir)

    switch ($WebSite) {
        "HiveOS" { $Param = "hive_params" }
        "Swarm" { $Param = "SWARM_Params" }
    }

    ## Make sure env is set:
    $Path = $env:Path -split ";"
    if ("$($(vars).dir)\build\cmd" -notin $Path) { $env:Path += ";$($(vars).dir)\build\cmd" }        

    
    Switch ($Command.result.command) {

        "autofan" {
            $method = "message"
            $messagetype = "success"
            $Data = "Autofan config applied"
            $Command.result.autofan | ConvertTo-Json -Depth 10 | Set-Content ".\config\parameters\autofan.json"
            $DoResponse = Global:Set-Response -Method $method -messagetype $messagetype -Data $data -Site $WebSite
            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
            $SendResponse = Invoke-RestMethod "$($global:config.$Param.Mirror)/worker/api" -TimeoutSec 10 -Method POST -Body $DoResponse -ContentType 'application/json'
            $trigger = "exec"
            $Enabled = $(Get-Content ".\config\parameters\autofan.json" | ConvertFrom-Json | ConvertFrom-StringData).ENABLED
            if ($Enabled -eq 1) {
                $ID = ".\build\pid\autofan.txt"
                if (Test-Path $ID) { $Agent = Get-Content $ID }
                if ($Agent) { $BackGroundID = Get-Process | Where-Object id -eq $Agent}
                if (-not $BackGroundId -or $BackGroundID.name -ne "pwsh") {
                    Write-Host "Starting Autofan" -ForeGroundColor Cyan              
                    $BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
                    $command = Start-Process "pwsh" -WorkingDirectory "$($(vars).dir)\build\powershell\scripts" -ArgumentList "-executionpolicy bypass -NoExit -windowstyle minimized -command `"&{`$host.ui.RawUI.WindowTitle = `'AutoFan`'; &.\autofan.ps1 -WorkingDir `'$($(vars).dir)`'}`"" -WindowStyle Minimized -PassThru -Verb Runas
                    $command.ID | Set-Content ".\build\pid\autofan.txt"
                    $BackgroundTimer.Restart()
                    do {
                        Start-Sleep -S 1
                        Write-Host "Getting Process ID for AutoFan"
                        $ProcessId = if (Test-Path ".\build\pid\autofan.txt") { Get-Content ".\build\pid\autofan.txt" }
                        if ($null -ne $ProcessID) { $Process = Get-Process | Where-Object Id -eq $ProcessId }
                    }until($null -ne $ProcessId -or ($BackgroundTimer.Elapsed.TotalSeconds) -ge 10)  
                    $BackgroundTimer.Stop()
                }
            }
            else {
                Write-Host "Stopping Autofan" -ForegroundColor Cyan
                $ID = ".\build\pid\autofan.txt"
                if (Test-Path $ID) { $Agent = Get-Content $ID }
                if ($Agent) { $BackGroundID = Get-Process | Where-Object id -eq $Agent }
                if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }                   
            }
        }

        "timeout" {
            $method = "message"
            $messagetype = "warning"
            $data = $swarm_message
            $DoResponse = Global:Set-Response -Method $method -messagetype $messagetype -Data $data -Site $WebSite
            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
            $SendResponse = Invoke-RestMethod "$($global:config.$Param.Mirror)/worker/api" -TimeoutSec 10 -Method POST -Body $DoResponse -ContentType 'application/json'
            $trigger = "exec"
        }
    
        "OK" { $trigger = "stats" }
  
        "reboot" {
            $method = "message"
            $messagetype = "success"
            $data = "Rebooting"
            $DoResponse = Global:Set-Response -Method $method -messagetype $messagetype -Data $data -CommandID $command.result.id -Site $WebSite
            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
            $SendResponse = Invoke-RestMethod "$($global:config.$Param.Mirror)/worker/api" -TimeoutSec 10 -Method POST -Body $DoResponse -ContentType 'application/json'
            Write-Host $method $messagetype $data
            $trigger = "reboot"
            $MinerFile = Get-Content ".\build\pid\miner_pid.txt"
            if ($MinerFile) { $MinerId = Get-Process | Where-Object Id -eq $MinerFile }
            if ($MinerId) {
                Stop-Process $MinerId
                Start-Sleep -S 3
            }
            Start-Process "pwsh" -ArgumentList "-executionpolicy bypass -windowstyle maximized -command `".\build\powershell\scripts\reboot.ps1`""
            exit
        }

        "exec" {
            $method = "message"
            $messagetype = "info"
            $data = "$($command.result.exec)"
            Invoke-Expression $Data | Tee-Object -Variable payload
            $line = @()
            $payload | ForEach-Object { $line += "$_`n" }
            $payload = $line
            $DoResponse = Global:Set-Response -Method $method -messagetype $messagetype -Data $data -CommandID $command.result.id -Payload $payload -Site $WebSite
            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
            $SendResponse = Invoke-RestMethod "$($global:config.$Param.Mirror)/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
            Write-Host $method $messagetype $data
        }
        
        "nvidia_oc" {
            $method = "message"
            $messagetype = "success"
            $data = "Nvidia settings applied"
            Start-NVIDIAOC $Command.result.nvidia_oc
            $getpayload = Get-Content ".\debug\ocnvidia.txt"
            $line = @()
            $getpayload | ForEach-Object { $line += "$_`n" }
            $payload = $line
            $DoResponse = Global:Set-Response -Method $method -messagetype $messagetype -Data $data -CommandID $command.result.id -Payload $payload -Site $WebSite
            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
            $SendResponse = Invoke-RestMethod "$($global:config.$Param.Mirror)/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
            Write-Host $method $messagetype $data
            $trigger = "exec"
        }
  
        "amd_oc" {
            $method = "message"
            $messagetype = "success"
            $data = "AMD settings applied"
            Start-AMDOC $Command.result.amd_oc
            $getpayload = Get-Content ".\debug\ocamd.txt"
            $line = @()
            $getpayload | ForEach-Object { $line += "$_`n" }
            $payload = $line
            $DoResponse = Global:Set-Response -Method $method -messagetype $messagetype -Data $data -CommandID $command.result.id -Payload $payload -Site $WebSite
            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
            $SendResponse = Invoke-RestMethod "$($global:config.$Param.Mirror)/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
            Write-Host $method $messagetype $data
            $trigger = "exec"
        }
  
        "config" {
            $Command.result | ConvertTo-Json | Set-Content ".\debug\swarmconfig.txt"
            if ($command.result.config) {
                $rig = [string]$command.result.config | ConvertFrom-StringData
                $Worker = $rig.WORKER_NAME -replace "`"", ""
                $Pass = $rig.RIG_PASSWD -replace "`"", ""
                $mirror = $rig.HIVE_HOST_URL -replace "`"", ""
                $hiveWorkerID = $rig.RIG_ID
                $NewHiveKeys = @{ }
                $NewHiveKeys.Add("Worker", "$Worker")
                $NewHiveKeys.Add("Password", "$Pass")
                $NewHiveKeys.Add("Id", "$hiveWorkerID")
                $NewHiveKeys.Add("Mirror", "$mirror")
                if (Test-Path ".\config\parameters\$($Param)_keys.json") { $OldHiveKeys = Get-Content ".\config\parameters\$($Param)_keys.json" | ConvertFrom-Json }
                if ($OldHiveKeys) {
                    if ($NewHiveKeys.Password -ne $OldHiveKeys.Password) {
                        Write-Warning "Detected New Password"
                        $method = "message"
                        $messagetype = "warning"
                        $data = "Password change received, wait for next message..."
                        $DoResponse = Global:Set-Response -Method $method -messagetype $messagetype -Data $data -CommandID $command.result.id -Site $WebSite
                        $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                        $SendResponse = Invoke-RestMethod "$($global:config.$Param.Mirror)/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                        $SendResponse
                        $DoResponse = @{method = "password_change_received"; params = @{rig_id = $global:config.$Param.Id; passwd = $global:config.$Param.Password }; jsonrpc = "2.0"; id = "0" }
                        $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                        $Send2Response = Invoke-RestMethod "$($global:config.$Param.Mirror)/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                    }
                }
                $NewHiveKeys | ConvertTo-Json | Set-Content ".\config\parameters\$($Param)_keys.json"        
            }
  
            if ($Command.result.wallet) {
                $method = "message"
                $messagetype = "success"
                $data = "Rig config changed"
                $arguments = [string]$Command.result.wallet | ConvertFrom-StringData
                if($arguments.CUSTOM_USER_CONFIG) {
                    ## Remove the "'" at front and end.
                    $arguments = $arguments.CUSTOM_USER_CONFIG.TrimStart("'").TrimEnd("'");

                } else {
                    Write-Log "Warning: No CUSTOM_USER_CONFIG found!" -ForegroundColor Red
                    Write-Log "Make sure you are using a Custom User Config section in HiveOS" -ForegroundColor Red
                }
                try { $test = "$arguments" | ConvertFrom-Json; if ($test) { $isjson = $true } } catch { $isjson = $false }
                if ($isjson) {
                    $Params = @{ }
                    $test.PSObject.Properties.Name | Foreach-Object -Object  { $Params.Add("$($_)", $test.$_) }
                    $Defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json
                    $Defaults.PSObject.Properties.Name | Foreach-Object -Object  { if ($_ -notin $Params.keys) { $Params.Add("$($_)", $Defaults.$_) } }

                }
                else {
                    $argjson = @{}
                    $arguments = $arguments -split " -"
                    $arguments = $arguments | Foreach-Object -Object  { $_.trim(" ") }
                    $arguments = $arguments | Foreach-Object -Object  { $_.trimstart("-") }
                    $arguments | Foreach-Object -Object  { $argument = $_ -split " " | Select-Object  -first 1; $argparam = $_ -split " " | Select-Object  -last 1; $argjson.Add($argument, $argparam); }
                    $argjson = $argjson | ConvertTo-Json | ConvertFrom-Json
  
                    $Defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json   
                    $Params = @{ }
  
                    $Defaults | Get-Member -MemberType NoteProperty | Select-Object  -ExpandProperty Name | Foreach-Object -Object  { $Params.Add("$($_)", $Defaults.$_) }
  
                    $argjson | Get-Member -MemberType NoteProperty | Select-Object  -ExpandProperty Name | Foreach-Object -Object  {
                        if ($argjson.$_ -ne $Params.$_) {
                            switch ($_) {
                                default { $Params.$_ = $argjson.$_ }
                                "Bans" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_.replace('cnight','cryptonight') }; $Params.$_ = $NewParamArray }
                                "Coin" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "Algorithm" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "GPUDevices3" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "GPUDevices2" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "GPUDevices1" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "Asic_Algo" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "Asic_IP" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "optional" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "Type" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "Poolname" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "Currency" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "PasswordCurrency1" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "PasswordCurrency2" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "PasswordCurrency3" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                "coin_params" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach-Object  { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                            }
                        }
                    }
                }
  
                $DoResponse = Global:Set-Response -Method $method -messagetype $messagetype -Data $data -CommandID $command.result.id -Site $WebSite
                $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                $SendResponse = Invoke-RestMethod "$($global:config.$Param.Mirror)/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                $SendResponse
                $Params | convertto-Json | Out-File ".\config\parameters\newarguments.json"
            }            $trigger = "config"
        }
  
    }
    if (Test-Path ".\debug\get.txt") { Clear-Content ".\debug\get.txt" }
    $trigger
}