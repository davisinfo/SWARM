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

function start-update {
    param (
        [Parameter(Mandatory = $true)]
        [String]$Update,
        [Parameter(Mandatory = $true)]
        [String]$Dir,
        [Parameter(Mandatory = $true)]
        [String]$Platforms
    )

    $Location = split-Path $Dir
    $StartUpdate = $True
    if ($Platforms -eq "linux" -and $Update -eq "No") {$StartUpdate = $false}

    if ($StartUpdate -eq $true) {
        $PreviousVersions = @()
        $PreviousVersions += "SWARM.1.9.2"
        $PreviousVersions += "SWARM.1.9.3"
        $PreviousVersions += "SWARM.1.9.4"
        $PreviousVersions += "SWARM.1.9.5"
        $PreviousVersions += "SWARM.1.9.6"
        $PreviousVersions += "SWARM.1.9.7"
        $PreviousVersions += "SWARM.1.9.8"
        $PreviousVersions += "SWARM.1.9.9"
        $PreviousVersions += "SWARM.2.0.0"
        $PreviousVersions += "SWARM.2.0.1"
        $PreviousVersions += "SWARM.2.0.2"
        $PreviousVersions += "SWARM.2.0.3"
        $PreviousVersions += "SWARM.2.0.4"
        $PreviousVersions += "SWARM.2.0.5"
        $PreviousVersions += "SWARM.2.0.6"
        $PreviousVersions += "SWARM.2.0.7"
        $PreviousVersions += "SWARM.2.0.8"
        $PreviousVersions += "SWARM.2.0.9"
        $PreviousVersions += "SWARM.2.1.0"
        $PreviousVersions += "SWARM.2.1.1"
        $PreviousVersions += "SWARM.2.1.2"
        $PreviousVersions += "SWARM.2.1.3"
        $PreviousVersions += "SWARM.2.1.4"
        $PreviousVersions += "SWARM.2.1.5"

        Write-Host "User Specfied Updates: Searching For Previous Version" -ForegroundColor Yellow
        Write-Host "Check $Location For any Previous Versions"

        $PreviousVersions | foreach {
            $PreviousPath = Join-Path "$Location" "$_"
            if (Test-Path $PreviousPath) {
                Write-Host "Detected Previous Version"
                Write-Host "Previous Version is $($PreviousPath)"
                Write-Host "Gathering Old Version Config And HashRates- Then Deleting"
                Start-Sleep -S 10
                $ID = ".\build\pid\background_pid.txt"
                if ($Platforms -eq "windows") {Start-Sleep -S 10}
                if ($Platforms -eq "windows") {
                    Write-Host "Stopping Previous Agent"
                    if (Test-Path $ID) {$Agent = Get-Content $ID}
                    if ($Agent) {$BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue}
                    if ($BackGroundID.name -eq "powershell") {Stop-Process $BackGroundID | Out-Null}
                }
                $OldBackup = Join-Path $PreviousPath "backup"
                $OldTime = Join-Path $PreviousPath "build\data"
                $OldConfig = Join-Path $PreviousPath "config"
                $OldTimeout = Join-Path $PreviousPath "timeout"
                if (-not (Test-Path "backup")) {New-Item "backup" -ItemType "directory"  | Out-Null }
                if (-not (Test-Path "stats")) {New-Item "stats" -ItemType "directory"  | Out-Null }
                if (Test-Path $OldBackup) {
                    Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\stats"
                    Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\backup"
                }
                #if(Test-Path $OldTime){Get-ChildItem -Path "$($OldTime)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\build\data"}
                if (Test-Path $OldTimeout) {
                    if (-not (Test-Path ".\timeout")) {New-Item "timeout" -ItemType "directory" | Out-Null }
                    if (-not (Test-Path ".\timeout\algo_block")) {New-Item ".\timeout\algo_block" -ItemType "directory" | Out-Null }
                    if (-not (Test-Path ".\timeout\pool_block")) {New-Item ".\timeout\pool_block" -ItemType "directory" | Out-Null }
                    if (Test-Path "$OldTimeout\algo_block") {Get-ChildItem -Path "$($OldTimeout)\algo_block" -Include *.txt, *.conf -Recurse | Copy-Item -Destination ".\timeout\algo_block"}
                    if (Test-Path "$OldTimeout\algo_block") {Get-ChildItem -Path "$($OldTimeout)\pool_block" -Include *.txt, *.conf -Recurse | Copy-Item -Destination ".\timeout\pool_block"}
                    Get-ChildItem -Path "$($OldTimeout)\*" -Include *.txt | Copy-Item -Destination ".\timeout"
                }
                $Jsons = @("miners", "oc", "power", "pools", "asic", "wallets")
                $UpdateType = @("CPU", "AMD1", "NVIDIA1", "NVIDIA2", "NVIDIA3")
                $Jsons | foreach {
                    $OldJson_Path = Join-Path $OldConfig "$($_)";
                    $NewJson_Path = Join-Path ".\config" "$($_)";
                    $GetOld_Json = Get-ChildItem $OldJson_Path;
                    $GetOld_Json = $GetOld_Json.Name
                    $GetOld_Json | foreach {
                        $ChangeFile = $_
                        $OldJson = Join-Path $OldJson_Path "$ChangeFile";
                        $NewJson = Join-Path $NewJson_Path "$ChangeFile";
                        if ($ChangeFile -ne "new_sample.json" -and $ChangeFile -ne "sgminer-kl.json" -and $ChangeFile -ne "vega-oc.json") {
                            $JsonData = Get-Content $OldJson;
                            Write-Host "Pulled $OldJson"
                            $Data = $JsonData | ConvertFrom-Json;

                            if ($ChangeFile -eq "pool-algos.json") {
                              $Data | Add-Member "yespowerr16" @{"hiveos_name" = "yespowerr16"; "pools_to_exclude" = @("add pools here","comma seperated"); "miners_to_exclude" = @("add miners here","comma seperate")} -ErrorAction SilentlyContinue
                              $Data | Add-Member "yespowerr8" @{"hiveos_name" = "yespowerr8"; "pools_to_exclude" = @("add pools here","comma seperated"); "miners_to_exclude" = @("add miners here","comma seperate")} -ErrorAction SilentlyContinue
                            }

                            if ($ChangeFile -eq "cryptodredge.json") {
                                $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                    ##2.1.3
                                    if ($_ -ne "name") {
                                        $Data.$_.commands| Add-Member "argon2d-dyn" "" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "argon2d-dyn" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "argon2d-dyn" "argon2d" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "argon2d-dyn" @{Power = ""; Core = ""; Memory = ""; Fans = ""} -ErrorAction SilentlyContinue

                                        $Data.$_.commands| Add-Member "grincuckaroo29" "" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "grincuckaroo29" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "grincuckaroo29" "cuckaroo29" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "grincuckaroo29" @{Power = ""; Core = ""; Memory = ""; Fans = ""} -ErrorAction SilentlyContinue
                                    }
                                }
                            }

                            if ($ChangeFile -eq "gminer_amd.json") {
                                $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                    ##2.1.3
                                    if ($_ -ne "name") {

                                        $Data.$_.commands| Add-Member "beam" "--algo 150_5 --pers auto" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "beam" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "beam" "beam" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "beam"  @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue

                                        $Data.$_.commands| Add-Member "grincuckaroo29" "--algo grin29" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "grincuckaroo29" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "grincuckaroo29" "grincuckaroo29" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "grincuckaroo29"  @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue

                                        $Data.$_.commands| Add-Member "equihash-btg" "--algo 144_5 --pers BgoldPoW" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "equihash-btg" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "equihash-btg" "equihash-btg" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "equihash-btg"  @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue

                                        $Data.$_.commands| Add-Member "equihash192" "--algo 192_7 --pers auto" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "equihash192" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "equihash192" "equihash192" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "equihash192"  @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue

                                        $Data.$_.commands| Add-Member "equihash144" "--algo 144_5 --pers auto" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "equihash144" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "equihash144" "equihash144" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "equihash144"  @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue

                                        $Data.$_.commands| Add-Member "equihash210" "--algo 210_9 --pers auto" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "equihash210" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "equihash210" "equihash210" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "equihash210"  @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue

                                        $Data.$_.commands| Add-Member "equihash200" "--algo 200_9 --pers auto" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "equihash200" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "equihash200" "equihash200" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "equihash200"  @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue

                                        $Data.$_.commands| Add-Member "zhash" "--algo 144_5 --pers auto" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "zhash" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "zhash" "zhash" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "zhash"  @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue

                                    }
                                }
                            }

                            if($ChangeFile -eq "pool-algos.json") {
                                    $Data.veil.hiveos_name = "veil"
                            }

                            if ($ChangeFile -eq "bubasik.json") {
                                $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                    ##2.1.3
                                    if ($_ -ne "name") {
                                        $Data.$_.commands| Add-Member "yespowerr16" "" -ErrorAction SilentlyContinue -Force
                                        $Data.$_.difficulty | Add-Member "yespowerr16" "" -ErrorAction SilentlyContinue -Force
                                        $Data.$_.naming | Add-Member "yespowerr16" "yespowerr16" -ErrorAction SilentlyContinue -Force

                                        $Data.$_.commands| Add-Member "yespowerr16" "" -ErrorAction SilentlyContinue -Force
                                        $Data.$_.difficulty | Add-Member "yespowerr16" "" -ErrorAction SilentlyContinue -Force
                                        $Data.$_.naming | Add-Member "yespowerr16" "yespowerr16" -ErrorAction SilentlyContinue -Force

                                        $Data.$_.commands| Add-Member "yescryptr8" "" -ErrorAction SilentlyContinue -Force
                                        $Data.$_.difficulty | Add-Member "yescryptr8" "" -ErrorAction SilentlyContinue -Force
                                        $Data.$_.naming | Add-Member "yescryptr8" "yescryptr8" -ErrorAction SilentlyContinue -Force

                                        $Data.$_.commands| Add-Member "yescryptr32" "" -ErrorAction SilentlyContinue -Force
                                        $Data.$_.difficulty | Add-Member "yescryptr32" "" -ErrorAction SilentlyContinue -Force
                                        $Data.$_.naming | Add-Member "yescryptr32" "yescryptr32" -ErrorAction SilentlyContinue -Force

                                        $Data.$_.commands| Add-Member "argon2d-dyn" "" -ErrorAction SilentlyContinue -Force
                                        $Data.$_.difficulty | Add-Member "argon2d-dyn" "" -ErrorAction SilentlyContinue -Force
                                        $Data.$_.naming | Add-Member "argon2d-dyn" "argon2d500" -ErrorAction SilentlyContinue -Force
                                    }
                                }
                            }

                            if ($ChangeFile -eq "wallets.json") {
                                $Data | Add-Member "All_AltWallets" @{"add coin symbol here" = "Add Its Address Here";"add another coin symbol here"="Add Its Address Here"} -ErrorAction SilentlyContinue
                            }
                            

                            if ($ChangeFile -eq "xmr-stak.json") {
                                $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                    ##2.0.7
                                    if ($_ -ne "name") {
                                        $Data.$_.commands| Add-Member "cryptonightgpu" "" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "cryptonightgpu" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "cryptonightgpu" "cryptonight_gpu" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "cryptonightgpu" @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue         

                                        $Data.$_.commands| Add-Member "cryptonightsuperfast" "" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "cryptonightsuperfast" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "cryptonightsuperfast" "cryptonight_superfast" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "cryptonightsuperfast" @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue
                                    }
                                }
                            }
                            if ($ChangeFile -eq "xmrig.json") {
                                $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                    ##2.0.7
                                    if ($_ -ne "name") {
                                        $Data.$_.commands| Add-Member "cryptonightr" "" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "cryptonightr" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "cryptonightr" "cn/r" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "cryptonightr" @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue         
                                    }
                                }
                            }
                            if ($ChangeFile -eq "wildrig.json") {
                                $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                    if ($_ -ne "name") {
                                        ##2.0.5
                                        $Data.$_.commands| Add-Member "rainforest" "" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "rainforest" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "rainforest" "rainforest" -Force -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "rainforest" @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue


                                    }
                                }
                            }
                            if ($ChangeFile -eq "phoenix_amd.json") {
                                $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                    if ($_ -ne "name") {
                                        ##2.0.1 
                                        $Data.$_.commands."ethash" = "-proto 2 -rate 1"
                                        $Data.$_.commands."daggerhashimoto" = "-proto 4 -stales 0"
                                        $Data.$_.commands."dagger" = "-proto 2"
                                    }
                                }
                            }

                            if ($ChangeFile -eq "teamredminer.json") {
                                $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                    if ($_ -ne "name") {
                                        ##2.0.5
                                        $Data.$_.commands| Add-Member "cryptonightr" "" -ErrorAction SilentlyContinue
                                        $Data.$_.difficulty | Add-Member "cryptonightr" "" -ErrorAction SilentlyContinue
                                        $Data.$_.naming | Add-Member "cryptonightr" "cnr" -ErrorAction SilentlyContinue
                                        $Data.$_.oc | Add-Member "cryptonightr" @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue
                                    }
                                }
                            }

                            $Data | ConvertTo-Json -Depth 3 | Set-Content $NewJson;
                            Write-Host "Wrote To $NewJson"
                        }
                    }
                }
                $NameJson_Path = Join-Path ".\config" "miners";
                $GetOld_Json = Get-ChildItem $NameJson_Path;
                $GetOld_Json = $GetOld_Json.Name
                $GetOld_Json | foreach {
                    $ChangeFile = $_
                    $NewName = $ChangeFile -Replace ".json", "";
                    $NameJson = Join-Path ".\config\miners" "$ChangeFile";
                    $JsonData = Get-Content $NameJson;
                    Write-Host "Pulled $NameJson"
                    $Data = $JsonData | ConvertFrom-Json;
                    $Data | Add-Member "name" "$NewName" -ErrorAction SilentlyContinue
                    $Data | ConvertTo-Json -Depth 3 | Set-Content $NameJson;
                    Write-Host "Wrote To $NameJson"
                }
                Remove-Item $PreviousPath -recurse -force
            }
        }
    }
}
