# Pure Disk Reporter
# For vSphere 6.5
# Written by Joshua Woleben
# 4/18/19
# Requirements:
# PowerCLI for VMware


# Import required modules
Import-Module VMware.VimAutomation.Core

$csv = @()
######## MAIN FUNCTION ##########

# Define a gigabyte in bytes
$gb = 1073741824
$TranscriptFile = "C:\Temp\PureReport_$(get-date -f MMddyyyyHHmmss).txt"
Start-Transcript -Path $TranscriptFile
Write-Output "Initializing..."

# Define connections to establish
$pure_arrays = @("purearray1","purearray2")
$vcenter_servers = @("vcenter1","vcenter2")

$vsphere_host = $vcenter_servers[0]

# Gather authentication credentials
Write-Output "Please enter the following credentials: `n`n"

# Collect vSphere credentials
Write-Output "`n`nvSphere credentials:`n"
$vsphere_user = Read-Host -Prompt "vSphere user: "
$vsphere_pwd = Read-Host -Prompt "Enter the password for connecting to vSphere: " -AsSecureString
   

# Create credential objects for all layers
$vsphere_creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $vsphere_user,$vsphere_pwd -ErrorAction Stop

# Create connections
Connect-VIServer -Server $vsphere_host -Credential $vsphere_creds -ErrorAction Stop

# $pure_connect = New-PfaArray -EndPoint $pure_array -Credentials $pure_creds -IgnoreCertificateError -ErrorAction Stop
   
$vm_inventory = Get-VM

# Write header
$csv += "VM Name, Operating System, Disk Name, Space Used (GB), Underlying Disk/Datastore, DiskType, Notes"
 
$vm_inventory | ForEach-Object -Process {

    $current_host = $_
    $current_vm = Get-VMGuest -VM $_
    $hostname = ($current_vm | Select -ExpandProperty HostName)
    $operating_system = ($current_vm | Select -ExpandProperty OSFullName)
    $notes = ($current_host | Select -ExpandProperty Notes) -replace '\n',' '

    $all_drives = Get-HardDisk -VM $current_host

    ForEach ($current_disk in $all_drives) {
        $disk_name = ($current_disk | Select -ExpandProperty Name)
        $space_used = ($current_disk | Select -ExpandProperty CapacityGB)
        $filename = $current_disk.FileName
        $datastore = $filename.split("]")[0].split("[")[1]
        $disk_type = ($current_disk | Select -ExpandProperty DiskType)

#        $datastore_object = Get-Datastore -Name $datastore
#        $scsi_info = Get-ScsiLun -Datastore $datastore_object
#        $scsi_path_info = Get-ScsiLunPath -ScsiLun $scsi_info

#        $san_id = ($scsi_path_info | Select -ExpandProperty SanId)
#        if ($san_id -eq $null) {
            $san_id = ($scsi_info | Select -ExpandProperty CanonicalName | Select -First 1) #(($scsi_info | Select -ExpandProperty Vendor) + " " + ($scsi_info | Select -ExpandProperty Model))
#        }

        $line = ($hostname + ", " + $operating_system + ", " + $disk_name + ", " + $space_used + ", " + $datastore + ", " + $disk_type + ", " + $notes)
        $csv += $line
        Write-Output $line

    }


}
$csv | Out-File "C:\Temp\disk_report.csv" -Encoding ascii
