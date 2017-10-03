<#
DISCLAIMER
    THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
    We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object
    code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software
    product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the
    Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims
    or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
    Please note: None of the conditions outlined in the disclaimer above will supersede the terms and conditions contained within
    the Premier Customer Services Description.
#>


      [Cmdletbinding()]          
          param(     
               $ResourceGroupName = "BaseLab",
               $VmName = "Test-delete")

               
               
                
                $vm = Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VmName
                
                Write-Verbose -Message 'Removing the Azure VM...'
				$null = $vm | Remove-AzureRmVM -Force
				Write-Verbose -Message "Removing the Azure network interface..."
				foreach($vmNiCId in $vm.NetworkProfile.NetworkInterfaces.Id)
				{
				   $netWorkidArray = $vmNiCId.Split("/")
				   Write-Verbose "Proccessing NIC $($netWorkidArray[$netWorkidArray.Count-1])"
				   $vmNic = Get-AzureRmNetworkInterface -Name $netWorkidArray[$netWorkidArray.Count-1] -ResourceGroupName $ResourceGroupName
				   Write-Verbose "Deleting NIC $netWorkidArray[$netWorkidArray.Count-1] "
				   Remove-AzureRmNetworkInterface -Name $netWorkidArray[$netWorkidArray.Count-1] -ResourceGroupName $ResourceGroupName -Force
					
						forEach ($PublicAddressId in $vmNic.IpConfigurations.PublicIPAddress.Id)
						{
							$configUratioinArray =  $PublicAddressId.Split("/")
							Write-Verbose "Deleting Public Ip Addres $($configUratioinArray[$configUratioinArray.Count-1])"
							Remove-AzureRmPublicIpAddress -Name $configUratioinArray[$configUratioinArray.Count-1] -ResourceGroupName $ResourceGroupName          
							Clear-Variable configUratioinArray
							Clear-Variable PublicAddressId
						}
					
					clear-variable netWorkidArray
					Clear-Variable vmNiC
				} 

				## Remove Disks
                import-Module AzureRM.Storage
                if ($vm.StorageProfile.OSDisk.ManagedDisk -eq $null)
                {
				    ## Remove the OS disk
                    Write-Verbose "Unmanaged Disks Identified"
				    Write-Verbose -Message 'Removing OS disk...'
				    $osDiskUri = $vm.StorageProfile.OSDisk.Vhd.Uri
				    $osDiskContainerName = $osDiskUri.Split('/')[-2]
				
				    ## TODO: Does not account for resouce group 
				    $osDiskStorageAcct = Get-AzureRmStorageAccount | Where-Object { $_.StorageAccountName -eq $osDiskUri.Split('/')[2].Split('.')[0] }
				    $osDiskStorageAcct | Remove-AzureStorageBlob -Container $osDiskContainerName -Blob $osDiskUri.Split('/')[-1] -ea Ignore
				
				    #region Remove the status blob
				    Write-Verbose -Message 'Removing the OS disk status blob...'
				    $osDiskStorageAcct | Get-AzureStorageBlob -Container $osDiskContainerName -Blob "$($vm.Name)*.status" | Remove-AzureStorageBlob
				    #endregion
				
				    ## Remove any other attached disks
				    if ($vm.DataDiskNames.Count -gt 0)
				    {
					    Write-Verbose -Message 'Removing data disks...'
					    foreach ($uri in $vm.StorageProfile.DataDisks.Vhd.Uri)
					    {
						    $dataDiskStorageAcct = Get-AzureRmStorageAccount -Name $uri.Split('/')[2].Split('.')[0] -ResourceGroupName $ResourceGroupName
						    $dataDiskStorageAcct | Remove-AzureStorageBlob -Container $uri.Split('/')[-2] -Blob $uri.Split('/')[-1] -ea Ignore
					    }
				    }
                }
                else
                {
                    ## Remove the OS disk
                    Write-Verbose -Message "Managed Disk Identified"
				    Write-Verbose -Message 'Removing OS disk...'
				    $osDisk = $vm.StorageProfile.OSDisk.Name
                    Remove-AzureRmDisk -Name $osDisk -ResourceGroupName $ResourceGroupName -Force

                    ## Remove any other attached disks
				    if ($vm.StorageProfile.DataDisks.Count -gt 0)
				    {
                        Write-Verbose -Message 'Removing data disks...'
                        forEach($Diskname in $vm.StorageProfile.DataDisks.Name)
                        {

                            Remove-AzureRmDisk -Name $Diskname -ResourceGroupName $ResourceGroupName -Force

                        }


                    }
                



                }
