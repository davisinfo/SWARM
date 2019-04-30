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

function start-log {
    param (
        [Parameter(Mandatory = $false)]
        [String]$Platforms,
        [Parameter(Mandatory = $false)]
        [String]$HiveOS,
        [Parameter(Mandatory = $false)]
        [int]$Number
    )
    #Start the log
    if (-not (Test-Path "logs")) {New-Item "logs" -ItemType "directory" | Out-Null; Start-Sleep -S 1}
    if (Test-Path ".\logs\*active*") {
        Set-Location ".\logs"
        $OldActiveFile = Get-ChildItem "*active*" -Force
        $OldActiveFile | Foreach {
            $RenameActive = $_ -replace ("-active", "")
            if (Test-Path $RenameActive) {Remove-Item $RenameActive -Force}
            Rename-Item $_ -NewName $RenameActive -force
        } 
        Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
    }
    $global:logname = Join-Path $dir "logs\miner$($Number)-active.log"
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
}

function write-log {
    param (
        [Parameter(Mandatory=$false, Position=0)]
        [string]$In,
        [Parameter(Mandatory=$false)]
        [string]$ForeGroundColor,
        [Parameter(Mandatory=$false)]
        [string]$ForeGround,
        [Parameter(Mandatory=$false)]
        [switch]$NoNewLine,
        [Parameter(Mandatory=$false)]
        [switch]$Start,
        [Parameter(Mandatory=$false)]
        [switch]$End
    )
    
    $Date = (Get-Date)
    $File = $global:logname

    if($ForeGround){$Color = $ForeGround}
    if($ForeGroundColor){$Color = $ForeGroundColor}

    if($NoNewLine) {
        if($Start){Add-Content -Path $File -Value "[$Date]`: " -NoNewline}
        Add-Content -Path $file -Value "$In" -NoNewline
    } 
    else {
        if($End){Add-Content -Path $file -Value "$In"}
        else{Add-Content -Path $file -Value "[$Date]`: $In"}
    }


    if($NoNewLine) {
        if($ForeGroundColor -or $ForeGround) {
            if($Start){Write-Host "[$Date]`: " -NoNewline}
            Write-Host $In -ForeGroundColor $Color -NoNewline
        } 
        else {
            if($Start){Write-Host "[$Date]`: " -NoNewline}
            Write-Host $In -NoNewline
        }
    }
    else {
        if($ForeGroundColor -or $ForeGround) {
            if($End){Write-Host "$In" -ForeGroundColor $Color}
            else{
            Write-Host "[$Date]`: " -NoNewline
            Write-Host "$In" -ForegroundColor $Color
            }
        }
        else {
            if($End){Write-Host "$In"}
            else{
            Write-Host "[$Date]`: " -NoNewline
            Write-Host "$In"
            }
        }
    }

}