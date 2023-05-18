az account set --subscription "<Your Subscription Details here>"
#ProvideRequiredData
RG="<Your RG Name will be here>"
DES="<disk encryption set to be added to disks>"
disks=`az disk list --resource-group IBCI-PROD-WB-MISRG --query "[].name" --output tsv` #it will get all disks in mentioned RG
#disks=`az disk list --resource-group IBCI-PROD-WB-MISRG --query "[].name" --query "[?contains(name,'osdisk')].name" --output tsv` #if we require only os disks then we can query.
#for loop on all disks in mentioned resourcegroup
for disk in $disks
do
#first we require to detach disks from vm in order to do changes in encryption property. in case of os disk we require to dallocate vm first and then detatch disk
#fetch vm name to attach detatch. require to update encryption property.
vmName=$(az disk show --name $disk --resource-group $RG --query "managedBy" --output tsv | awk -F '/' '{print $NF}')
echo "Action Started for VM: $vmName and Disk: $disk"
#below command will detatch disk from vm.
echo "VM Deallocate and disk detach in progress"
az vm deallocate --resource-group $RG --name $vmName
sleep 5
az vm disk detach --vm-name $vmName --name $disk --resource-group $RG
#it will update encryption settings of disk
az disk update --name $disk --resource-group $RG --encryption-type EncryptionAtRestWithCustomerKey --disk-encryption-set $DES
echo "Encryption added to $disk"
#below command will attach disk to vm respectively.
az vm disk attach --vm-name $vmName --diskName $disk --resource-group $RG
#will start vm once activity done.
az vm start --resource-group $RG --name $vmName
echo "Disk Attach and VM Start."
echo "___________________"
sleep 5
done
