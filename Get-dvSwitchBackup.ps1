<#

.SYNOPSIS
    Sets the resource pool shares per VM

.DESCRIPTION
    This script will connect to your vCenter server and scan the resource pools.
    It will ask for a per VM share value for CPU and RAM, these will then be calculated together and set on the 
    resource pools giving the correct shares value

.PARAMETER vcenter
    FQDN for your vCenter server
.PARAMETER FilePath
    Backup location of the files

.EXAMPLE
    ./Get-dvSwitchBackups.ps1 -vcenter "vcenter.domain.com"
 
.NOTES
    Script created by Steven Marks from spottedhyena.co.uk
 
#>
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$vcenter,
  [Parameter(Mandatory=$True,Position=1)]
   [string]$FilePath
)
Try {
    #Load Required PowerCLI Plugins 
    If ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null) { Add-PSSnapin VMware.VimAutomation.Core }
    If ((Get-PSSnapin -Name VMware.VimAutomation.Vds -ErrorAction SilentlyContinue) -eq $null) { Add-PSSnapin VMware.VimAutomation.Vds }

    $date=get-date -uformat %d-%m-%Y

    #Get Credentials
    $cred = Get-Credential
    Connect-VIServer $vcenter -Credential $cred
    
    #Get list of dvSwitches
    $switches=get-vdswitch

    foreach ($switch in $switches){
        # Backup each vNetwork Distributed Switch not including the port groups
        export-vdswitch $switch -Withoutportgroups -Description “Backup of $switch without port groups” -Destination “$FilePath\$date.dvSwitch-without-portgroups.zip“ -Force
        
        # Backup each vNetwork Distributed Switch including the port groups
        export-vdswitch $switch -Description “Backup of $switch with port groups” -Destination "$FilePath\$date.dvSwitch-with-portgroups.zip“ -Force
        
        # Backup each port group individually
        get-vdswitch $switch | Get-VDPortgroup | foreach { export-vdportgroup -vdportgroup $_ -Description “Backup of port group $($_.name)” -destination “$FilePath\$date.portgroup-$($_.name).zip“ -Force}
    }
}
Catch{
    # catch any exceptions
}
Finally{
    # Any code that should complete after an exception occurs
}
