$now = get-date
write-host "$(get-date) - --------------------------------------------------------------------"
write-host "$(get-date) - Example Azure Script starts $now (demo purposes only)"
write-host "$(get-date) - --------------------------------------------------------------------"

$resourceGroupName = "noobExample_RG"
$location = "northeurope"
$myStorageAcctName = "noobexamplestorage"
$adminAcctName = "noobAdmin"
Write-host "Enter a Password which you can use to logon to the new VMs with:"
$adminAccPassword = read-host
$baseVMName = "WIN-NOOB-"
$totalServers = 3

# login
login-azurermaccount

# resource group, ties related resources together (i can delete it all with one command later for example). 
write-host "$(get-date) - create resource group"
$resourceGroup = new-azurermresourcegroup -name $resourceGroupName -location $location

# storage account, lump of storage space offered by MS (can be used as internet accessible file share, or diagnostic storage area, or SQL db location etc...)
write-host "$(get-date) - create storage acct"
$myStorageAcct = New-AzureRmStorageAccount -resourceGroupName $resourceGroupName -name $myStorageAcctName -SkuName "Standard_LRS" -kind "Storage" -Location $location

# virtual network which all our VMs will end up. (we can setup site to site VPNs to extend our network into the cloud and section 
# that off from the internet if we want, but this just sets up a simple network
write-host "$(get-date) - create virtual network"
$mySubnet = New-AzureRmVirtualNetworkSubnetConfig -Name "mySubnet" -AddressPrefix 10.0.0.0/24

# subnet inside the virtual network setup
write-host "$(get-date) - create subnet in vnet"
$myVnet = New-AzureRmVirtualNetwork -Name "myVnet" -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $mySubnet

# setup a public ip that'd host our website/external service or whatever. 
write-host "$(get-date) - create a public ip"
$myPublicIp = New-AzureRmPublicIpAddress -Name "myPublicIp" -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic


# setup a VM or two....first grab a credential that will end up being our local admin..
write-host "$(get-date) - set admin credential details to create"
$secpasswd = ConvertTo-SecureString $adminAccPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($adminAcctName, $secpasswd)

# I'm going to setup 5 vms. 
write-host "$(get-date) - setup $totalServers VMs (took 30 mins in serial (6mins per VM))"

foreach ($number in 1..$totalServers){ 

      # setting up a network interface for our VM  
      write-host "$(get-date) - --------- (VM $number) -----------"
      write-host "$(get-date) - create a NIC for VM"
      $myNIC = New-AzureRmNetworkInterface -Name "myNIC$number" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $myVnet.Subnets[0].Id 

      $vmName = "$baseVMName$number"

     # create a "configuration" object to hold common values for our VM. 
      $myVm = New-AzureRmVMConfig -VMName $vmName -VMSize "Standard_A1"

      $myVm = Set-AzureRmVMOperatingSystem -VM $myVm -Windows -ComputerName "myVM" -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

      $myVm = Set-AzureRmVMSourceImage -VM $myVm -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2016-Datacenter" -Version "latest"

      $myVm = Add-AzureRmVMNetworkInterface -VM $myVm -Id $myNIC.Id

      #setup the disk the VM will use.
      $blobPath = "vhds/$vmName-myOsDisk.vhd"
      write-host "$(get-date) -    Blob Path: $blobPath"
      $osDiskUri = $myStorageAcct.PrimaryEndpoints.Blob.ToString() +$blobPath
      write-host "$(get-date) -    osDiskUri: $osDiskUri"

      $vm = Set-AzureRmVMOSDisk -VM $myVm -Name "myOsDisk$number" -VhdUri $osDiskUri -CreateOption fromImage

      #Do it. Create them
      New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $myVM

}
$now2 = get-date
# write out how long it took. 
write-host "$(get-date) - finished. Took $(($now2 - $now).minutes) minute(s) and $(($now2 - $now).seconds) second(s)"








