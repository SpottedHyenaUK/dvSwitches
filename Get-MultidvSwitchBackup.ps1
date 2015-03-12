<#

.SYNOPSIS
    Gets an export of multiple vCenter dvSwitch Configurations

.DESCRIPTION
    This script will connect to multiple vCenter servers and get a backup of all dvSwitches. 
    It will take 3 backups: one of PortGroups, one of the dvSwitch and one with both PortGroups and dvSwitch
    these are then saved with the relevant date and name. 

.PARAMETER vcenters
    Path to a CSV file that contains FQDN, Username, Password of a user that has permission to export 
    switch information

.PARAMETER FilePath
    Backup location of the files

.EXAMPLE
    .\Get-dvSwitchBackups.ps1 -vcenters ".\vCenter_Credentials.csv" -FilePath ".\backups"
 
.NOTES
    Script created by Steven Marks from spottedhyena.co.uk
 
#>
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$vcenters,
  [Parameter(Mandatory=$True,Position=1)]
   [string]$FilePath
)
Try {
    #Load Required PowerCLI Plugins 
    If ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null) { Add-PSSnapin VMware.VimAutomation.Core }
    If ((Get-PSSnapin -Name VMware.VimAutomation.Vds -ErrorAction SilentlyContinue) -eq $null) { Add-PSSnapin VMware.VimAutomation.Vds }

    $date=get-date -uformat %d-%m-%Y

    # Import the vCenter Servers
    $csvData = Import-Csv $vCenters

    $csvData | Foreach-Object {

        # Set the working vCenter
        $vCenter = $_.vCenter

        # Connect to the vCenter Server
        $viServer = Connect-VIServer -Server $_.vcenter -User $_.username -Password $_.password
    
        #Get list of dvSwitches
        $switches=get-vdswitch

        foreach ($switch in $switches){
            # Backup each vNetwork Distributed Switch not including the port groups
            export-vdswitch $switch -Withoutportgroups -Description “Backup of $switch without port groups” -Destination “$FilePath\$date.$vcenter.dvSwitch-without-portgroups.zip“ -Force
        
            # Backup each vNetwork Distributed Switch including the port groups
            export-vdswitch $switch -Description “Backup of $switch with port groups” -Destination "$FilePath\$date.$vcenter.dvSwitch-with-portgroups.zip“ -Force
        
            # Backup each port group individually
            get-vdswitch $switch | Get-VDPortgroup | foreach { export-vdportgroup -vdportgroup $_ -Description “Backup of port group $($_.name)” -destination “$FilePath\$date.$vcenter.portgroup-$($_.name).zip“ -Force}
        }
    }
}
Catch{
    # catch any exceptions
}
Finally{
    # Any code that should complete after an exception occurs
}
