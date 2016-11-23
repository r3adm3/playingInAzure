$now = get-date
write-host "Example Azure Script starts $now (demo purposes only)"

# login
login-azurermaccount

# resource group, ties related resources together (i can delete it all with one command later for example). 
write-host "create resource group"
$resourceGroup = new-azurermresourcegroup -name wed_Example_RG -location northeurope

# storage account, lump of storage space offered by MS (can be used as internet accessible file share, or diagnostic storage area, or SQL db location etc...)
write-host "create storage acct"
$myStorageAcct = New-AzureRmStorageAccount -resourceGroupName wed_Example_RG -name wedstorageacctaf -SkuName "Standard_LRS" -kind "Storage" -Location northeurope

# virtual network which all our VMs will end up. (we can setup site to site VPNs to extend our network into the cloud and section 
# that off from the internet if we want, but this just sets up a simple network
write-host "create virtual network"
$mySubnet = New-AzureRmVirtualNetworkSubnetConfig -Name "mySubnet" -AddressPrefix 10.0.0.0/24

# subnet inside the virtual network setup
write-host "create subnet in vnet"
$myVnet = New-AzureRmVirtualNetwork -Name "myVnet" -ResourceGroupName wed_Example_RG -Location northeurope -AddressPrefix 10.0.0.0/16 -Subnet $mySubnet

# setup a public ip that'd host our website/external service or whatever. 
write-host "create a public ip"
$myPublicIp = New-AzureRmPublicIpAddress -Name "myPublicIp" -ResourceGroupName wed_Example_RG -Location northeurope -AllocationMethod Dynamic


# setup a VM or two....first grab a credential that will end up being our local admin..
write-host "ask for admin credential details to create"
$cred = Get-Credential -Message "Type the name and password of the local administrator account."

# I'm going to setup 5 vms. 
write-host "setup 5 VMs (took 30 mins in serial)"
foreach ($number in 1..5){ 

      # setting up a network interface for our VM  
      write-host "--------- (VM $number) -----------"
      write-host "create a NIC for VMs $(get-date)"
      $myNIC = New-AzureRmNetworkInterface -Name "myNIC$number" -ResourceGroupName wed_Example_RG -Location northeurope -SubnetId $myVnet.Subnets[0].Id 

      $vmName = "myName$number"

     # create a "configuration" object to hold common values for our VM. 
      $myVm = New-AzureRmVMConfig -VMName $vmName -VMSize "Standard_A1"

      $myVm = Set-AzureRmVMOperatingSystem -VM $myVm -Windows -ComputerName "myVM" -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

      $myVm = Set-AzureRmVMSourceImage -VM $myVm -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version "latest"

      $myVm = Add-AzureRmVMNetworkInterface -VM $myVm -Id $myNIC.Id

      #setup the disk the VM will use.
      $blobPath = "vhds/myOsDisk$number.vhd"
      write-host "   Blob Path: $blobPath"
      $osDiskUri = $myStorageAcct.PrimaryEndpoints.Blob.ToString() +$blobPath
      write-host "   osDiskUri: $osDiskUri"

      $vm = Set-AzureRmVMOSDisk -VM $myVm -Name "myOsDisk$number" -VhdUri $osDiskUri -CreateOption fromImage

      #Do it. Create them
      New-AzureRmVM -ResourceGroupName wed_example_RG -Location northeurope -VM $myVM

}
$now = get-date
write-host "finished $now"








