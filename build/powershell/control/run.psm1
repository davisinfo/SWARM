function Global:Stop-ActiveMiners {
    $(vars).ActiveMinerPrograms | ForEach-Object {
           
        ##Miners Not Set To Run
        if ($_.BestMiner -eq $false) {
        
            if ($(arg).Platform -eq "windows") {
                if ($_.XProcess -eq $Null -and $_.Status -ne "Idle") { $_.Status = "Failed" }
                elseif ($_.XProcess.HasExited -eq $false) {
                    $_.Active += (Get-Date) - $_.XProcess.StartTime
                    if ($_.Type -notlike "*ASIC*") {
                        $Num = 0
                        $Sel = $_
                        if ($Sel.XProcess.Id) {
                            $Childs = Get-Process | Where { $_.Parent.Id -eq $Sel.XProcess.Id }
                            Write-Log "Closing all Previous Child Processes For $($Sel.Type)" -ForeGroundColor Cyan
                            $Child = $Childs | % {
                                $Proc = $_; 
                                Get-Process | Where { $_.Parent.Id -eq $Proc.Id } 
                            }
                        }
                        do {
                            $Sel.XProcess.CloseMainWindow() | Out-Null
                            Start-Sleep -S 1
                            $Num++
                            if ($Num -gt 5) {
                                Write-Log "SWARM IS WAITING FOR MINER TO CLOSE. IT WILL NOT CLOSE" -ForegroundColor Red
                            }
                            if ($Num -gt 180) {
                                if ($(arg).Startup -eq "Yes") {
                                    $HiveMessage = "2 minutes miner will not close - Restarting Computer"
                                    $HiveWarning = @{result = @{command = "timeout" } }
                                    if ($(vars).WebSites) {
                                        $(vars).WebSites | ForEach-Object {
                                            $Sel = $_
                                            try {
                                                Global:Add-Module "$($(vars).web)\methods.psm1"
                                                Global:Get-WebModules $Sel
                                                $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                                            }
                                            catch { Global:Write-Log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                                            Global:Remove-WebModules $sel
                                        }
                                    }
                                    Global:Write-Log "$HiveMessage" -ForegroundColor Red
                                }
                                Restart-Computer
                            }
                        }Until($false -notin $Child.HasExited)
                        if ($Sel.SubProcesses -and $false -in $Sel.SubProcesses.HasExited) { 
                            $Sel.SubProcesses | % { $Check = $_.CloseMainWindow(); if ($Check -eq $False) { Stop-Process -Id $_.Id } }
                        }
                    }
                    else { $_.Xprocess.HasExited = $true; $_.XProcess.StartTime = $null }
                    $_.Status = "Idle"
                }
            }

            if ($(arg).Platform -eq "linux") {
                if ($_.XProcess -eq $Null -and $_.Status -ne "Idle") { $_.Status = "Failed" }
                else {
                    if ($_.Type -notlike "*ASIC*") {
                        $MinerInfo = ".\build\pid\$($_.InstanceName)_info.txt"
                        if (Test-Path $MinerInfo) {
                            $_.Status = "Idle"
                            $global:PreviousMinerPorts.$($_.Type) = "($_.Port)"
                            $MI = Get-Content $MinerInfo | ConvertFrom-Json
                            $PIDTime = [DateTime]$MI.start_date
                            $Exec = Split-Path $MI.miner_exec -Leaf
                            $_.Active += (Get-Date) - $PIDTime
                            $Proc = Start-Process "start-stop-daemon" -ArgumentList "--stop --name $Exec --pidfile $($MI.pid_path) --retry 5" -PassThru
                            $Proc | Wait-Process
                        }
                    }
                    else { $_.Xprocess.HasExited = $true; $_.XProcess.StartTime = $null; $_.Status = "Idle" }
                }
            }
        }
    }
}

function Global:Start-NewMiners {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Reason
    )

    $ClearedOC = $false
    $WebSiteOC = $False
    $OC_Success = $false

    $(vars).BestActiveMIners | ForEach-Object {
        $Miner = $_

        if ($null -eq $Miner.XProcess -or $Miner.XProcess.HasExited -and $(arg).Lite -eq "No") {
            Global:Add-Module "$($(vars).control)\launchcode.psm1"
            Global:Add-Module "$($(vars).control)\config.psm1"

            $global:Restart = $true
            if ($Miner.Type -notlike "*ASIC*") { Start-Sleep -S $Miner.Delay }
            $Miner.InstanceName = "$($Miner.Type)-$($(vars).Instance)"
            $Miner.Instance = $(vars).Instance
            $Miner.Activated++
            $(vars).Instance++

            ##First Do OC
            if ($Reason -eq "Launch") {
                if ($(vars).WebSites -and $(vars).WebSites -ne "") {
                    $GetNetMods = @($(vars).NetModules | Foreach { Get-ChildItem $_ })
                    $GetNetMods | ForEach-Object { Import-Module -Name "$($_.FullName)" }
                    $(vars).WebSites | ForEach-Object {
                        switch ($_) {
                            "HiveOS" {
                                if ($(arg).API_Key -and $(arg).API_Key -ne "") {
                                    if ($WebSiteOC -eq $false) {
                                        if ($Miner.Type -notlike "*ASIC*" -and $Miner.Type -like "*1*") {
                                            $OC_Success = Global:Start-HiveTune $Miner.Algo
                                            $WebSiteOC = $true
                                        }
                                    }
                                }
                            }
                            "SWARM" {
                                $WebSiteOC = $true
                            }
                        }
                    }
                    $GetNetMods | ForEach-Object { Remove-Module -Name "$($_.BaseName)" }
                }
                if ($OC_Success -eq $false -and $WebSiteOC -eq $false) {
                    if ($ClearedOC -eq $False) {
                        $OCFile = ".\build\txt\oc-settings.txt"
                        if (Test-Path $OCFile) { Clear-Content $OcFile -Force; "Current OC Settings:" | Set-Content $OCFile }
                        $ClearedOC = $true
                    }
                }
                elseif ($OC_Success -eq $false -and $WebSiteOC -eq $false -and $Miner.Type -notlike "*ASIC*" -and $(Get-Content ".\config\oc\oc-defaults.json" | ConvertFrom-Json).card -ne "") {
                    Global:Write-Log "Starting SWARM OC" -ForegroundColor Cyan
                    Global:Add-Module "$($(vars).control)\octune.psm1"
                    Global:Start-OC($Miner)
                    Remove-Module -name octune
                    $OC_Success = $true
                }
            }

            ##Kill Open Miner Windows That May Still Be Open
            if ($IsWindows) {
                if ($_.Type -notlike "*ASIC*") {
                    $Num = 0
                    $Sel = $_
                    if ($Sel.XProcess.Id -ne $null) {
                        $Childs = Get-Process | Where { $_.Parent.Id -eq $Sel.XProcess.Id }
                        Write-Log "Closing all Previous Child Processes For $($Sel.Type)" -ForeGroundColor Cyan
                        $Child = $Childs | % {
                            $Proc = $_; 
                            Get-Process | Where { $_.Parent.Id -eq $Proc.Id } 
                        }
                    }
                    if ($Sel.HasExited -eq $false) {
                        do {
                            $Sel.XProcess.CloseMainWindow() | Out-Null
                            Start-Sleep -S 1
                            $Num++
                            if ($Num -gt 5) {
                                Write-Log "SWARM IS WAITING FOR MINER TO CLOSE. IT WILL NOT CLOSE" -ForegroundColor Red
                            }
                            if ($Num -gt 180) {
                                if ($(arg).Startup -eq "Yes") {
                                    $HiveMessage = "2 minutes miner will not close - Restarting Computer"
                                    $HiveWarning = @{result = @{command = "timeout" } }
                                    if ($(vars).WebSites) {
                                        $(vars).WebSites | ForEach-Object {
                                            $Sel = $_
                                            try {
                                                Global:Add-Module "$($(vars).web)\methods.psm1"
                                                Global:Get-WebModules $Sel
                                                $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                                            }
                                            catch { Global:Write-Log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                                            Global:Remove-WebModules $sel
                                        }
                                    }
                                    Global:Write-Log "$HiveMessage" -ForegroundColor Red
                                }
                                Restart-Computer
                            }
                        }Until($false -notin $Child.HasExited)
                    }
                    if ($Sel.SubProcesses -and $false -in $Sel.SubProcesses.HasExited) { 
                        $Sel.SubProcesses | % { $Check = $_.CloseMainWindow(); if ($Check -eq $False) { Stop-Process -Id $_.Id } }
                    }
                }
            }

            ##Launch Miners
            Global:Write-Log "Starting $($Miner.InstanceName)"
            if ($Miner.Type -notlike "*ASIC*") {
                $Miner.Xprocess = Global:Start-LaunchCode $Miner
                if ($IsWindows) {
                    $(vars).QuickTimer.restart()
                    do {
                        $Miner.SubProcesses = if ($Miner.Xprocess.Id) { Get-Process | Where { $_.Parent.ID -eq $Miner.Xprocess.Id } } else { $Null }
                        if ($Miner.Subprocesses) {
                            $Miner.SubProcesses = $Miner.SubProcesses | % { $Cur = $_.id; Get-Process | Where $_.Parent.ID -eq $Child | Where ProcessName -eq $Miner.MinerName.Replace(".exe", "") }
                        }
                        Write-Log "Getting Process Id For $($Miner.Name)"
                        Start-Sleep -S 1
                    }Until($Null -ne $Miner.SubProcesses -or $(vars).QuickTimer.Elapsed.TotalSeconds -ge 5)
                }
            }
            else {
                if ($(vars).ASICS.$($Miner.Type).IP) { $AIP = $(vars).ASICS.$($Miner.Type).IP }
                else { $AIP = "localhost" }
                $Miner.Xprocess = Global:Start-LaunchCode $Miner $AIP
            }

            ##Confirm They are Running
            if ($Miner.XProcess -eq $null -or $Miner.Xprocess.HasExited -eq $true) {
                $Miner.Status = "Failed"
                $global:NoMiners = $true
                Global:Write-Log "$($Miner.MinerName) Failed To Launch" -ForegroundColor Darkred
            }
            else {
                $Miner.Status = "Running"
                if ($Miner.Type -notlike "*ASIC*") { Global:Write-Log "Process Id is $($Miner.XProcess.ID)" }
                Global:Write-Log "$($Miner.MinerName) Is Running!" -ForegroundColor Green
                $(vars).current_procs += $Miner.Xprocess.ID
            }
        }
    }
    if ($Reason -eq "Restart" -and $global:Restart -eq $true) {
        Global:Write-Log "

    //\\  _______
   //  \\//~//.--|
   Y   /\\~~//_  |
  _L  |_((_|___L_|
 (/\)(____(_______)        

Waiting 20 Seconds For Miners To Fully Load

" 
        Start-Sleep -s 20
        $global:Restart = $false
    }
}