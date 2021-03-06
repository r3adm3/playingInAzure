﻿$now = get-date
write-host "$(get-date) - --------------------------------------------------------------------"
write-host "$(get-date) -  Starts all VMs in a resource Group starts $now (demo purposes only)"
write-host "$(get-date) - --------------------------------------------------------------------"

$resourceGroupName = "noobExample_RG"

# login
write-host "Already logged in (y to bypass logon)?"
$alreadyloggedin = read-host
if ($alreadyloggedin -ne "y") {
    login-azurermaccount
}


$vms = get-AzureRMVM -ResourceGroupName $resourceGroupName

foreach ($vm in $vms) {

    # get current state of VM
    $vmStatus = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $vm.Name -Status | select -ExpandProperty Statuses | ?{ $_.Code -match "PowerState" } | select -ExpandProperty DisplayStatus
    write-host "$(get-date) - $($vm.name) status is $vmStatus"

    # if its running stop it. If its already stopped don't bother.
    if ($vmStatus.ToString() -eq "VM running") {
       write-host "$(get-date) - $($vm.name) already running"
    } else {
       write-host "$(get-date) - starting $($vm.name)"
       start-azurermvm -ResourceGroupName $resourceGroupName -Name $vm.Name
    }

}


$now2 = get-date
# write out how long it took. 
write-host "$(get-date) - finished. Took $(($now2 - $now).hours) hour(s), $(($now2 - $now).minutes) minute(s) and $(($now2 - $now).seconds) second(s)"








