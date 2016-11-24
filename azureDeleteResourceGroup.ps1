$now = get-date
write-host "$(get-date) - --------------------------------------------------------------------"
write-host "$(get-date) - Del Resource Group Script starts $now (demo purposes only)"
write-host "$(get-date) - --------------------------------------------------------------------"

$resourceGroupName = "noobExample_RG"

# login
login-azurermaccount

# resource group, ties related resources together (i can delete it all with one command later for example). 
write-host "$(get-date) - delete resource group"
remove-azurermresourcegroup -name $resourceGroupName -force

$now2 = get-date
# write out how long it took. 
write-host "$(get-date) - finished. Took $(($now2 - $now).minutes) minute(s) and $(($now2 - $now).seconds) second(s)"








