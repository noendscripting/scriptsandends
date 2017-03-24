<#
DISCLAIMER
    This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
    THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
    We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object
    code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software
    product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the
    Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims
    or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
    Please note: None of the conditions outlined in the disclaimer above will supersede the terms and conditions contained
    within the Premier Customer Services Description.
    #>


#chnage 
Function On-Load
{
    
    Import-Module Azure
    Set-StrictMode -Version 3
    $subList = (Get-AzureRmSubscription | Where-Object {$_.State -ne "Disabled"} -ErrorAction Stop).SubscriptionName 
    $DropDownSubscription.Items.AddRange($subList)

}

Function get-ResourceGroups
{
    $richTextBox1.AppendText("$($DropDownSubscription.SelectedItem) subscription selected`n")
    $richTextBox1.AppendText("Getting List of Resource Groups`n")
    $DropDownRG.Items.Clear()
    Select-AzureRmSubscription -SubscriptionName $DropDownSubscription.SelectedItem | Out-Null
    
    $resourceGroups = Get-AzureRmResourceGroup | Select-Object ResourceGroupName, Location
    $DropDownRG.Items.AddRange($resourceGroups)
    $DropDownRG.DisplayMember = "ResourceGroupName"
    $RGSectionLabel.Visible = $true
    $DropDownRG.Visible = $true


}

Function get-storage
{
   $DropDownStorage.Items.Clear()
   
   $item = $DropDownRG.SelectedItem
   $richTextBox1.AppendText("Getting list of Storage Accounts in $($item.location.ToString().toUpper()) region`n")
   $storageAccounts = (Get-AzureRmStorageAccount | Where-Object {$_.PrimaryLocation -eq $item.location.ToString()}).StorageAccountName
   $DropDownStorage.Items.AddRange($storageAccounts)
   $DropDownStorage.Visible = $true
   $StorageSectionLabel.Visible = $true

}

Function get-vnet
{
     
     $DropDownVNET.Items.Clear()
     $richTextBox1.AppendText("Getting list of VirtualNetworks in $($item.location.ToString().toUpper()) region`n")
     $item = $DropDownRG.SelectedItem
     $virtualNetworks = (Get-AzureRmVirtualNetwork | Where-Object {$_.Location -eq $item.location.ToString()}).Name
     $DropDownVNET.Items.AddRange($virtualNetworks)
     $DropDownVNET.DisplayMember = "Name"
     $DropDownVNET.Visible = $true
     $vNetSectionLabel.Visible = $true

}

Function get-subnets
{
    $DropDownSubnet.items.clear()
    $richTextBox1.AppendText("Getting list of Subnets in $($DropDownVNET.SelectedItem) region`n")
    $virtualSubnets = (Get-AzureRmVirtualNetwork -Name $DropDownVNET.SelectedItem -ResourceGroupName $DropDownRG.SelectedItem.ResourceGroupName).Subnets.Name
    $DropDownSubnet.Items.AddRange($virtualSubnets)
    $DropDownSubnet.visible=$true
    $SubnetSectionLabel.Visible = $true
   


}

Function enable-VMproperties
{
   
  $DropDownSize.items.addrange(@("Standard_D2_v2","Standard_F2"))
  $DropDownEnv.items.addrange(@("Development","QA","Production","Test"))
  $DropDownImage.Items.AddRange(@("goldenimage-osDisk.c49a2a0e-c826-493d-9543-7689499b2e4b.vhd"))
  $DropDownSize.Visible = $true
  $SizeSectionLabel.Visible = $true
  $DropDownEnv.visible= $true
  $EnvSectionLabel.Visible = $true
  $ImageSectionLabel.Visible = $true
  $DropDownImage.Visible = $true
  $CurrentTemplateLabel.Visible = $true
  $CurrentTemplatePath.Visible = $true
  $BrowseCurrentButton.Visible = $true
  $RunButton.Visible = $true
  $VMNameSectionLabel.Visible = $true
  $VMPrexixTextBox.Visible = $true

}


Function get-filename 
{
    $browse = new-object windows.Forms.OpenFileDialog
    $browse.Filter="JSON Files (*.JSON)|*.JSON"
    $browse.ShowDialog()
    $filepath = join-path -Path $browse.FileName -ChildPath $browse.SafeFileName
    $CurrentTemplatePath.text = $browse.FileName
}

Function Create-VM
{
    
    Select-AzureRmSubscription -SubscriptionName $DropDownSubscription.SelectedItem | Out-Null
    $templateParameters = New-Object -TypeName Hashtable
    #$vmname = "$($VMPrexixTextBox.Text)$($DropDownEnv.selecteditem.toString().Substring(0,1))$(Get-Random -minimum 100 -maximum 999)"
    [bool]$namecheck =$false
    $richTextBox1.AppendText("Checking if VM with the name $($vmname.toUpper()) already exists`n")
    Do{
     $vmName = $VMPrexixTextBox.Text
     [bool]$namecheck = $false
     $vmTest = Get-AzureRmVm |?{$_.Name -eq $vmName} =
     if ($vmTest -eq $null)
     {
        $namecheck = $true
     }
     else
     {
       $richTextBox1.AppendText("Machine $($vmName) already exists`nExiting script`n") 
        exit

     }
   
    }until ($namecheck)
    $vNetRG = (Get-AzureRmVirtualNetwork | ?{$_.Name -eq $DropDownVNET.SelectedItem}).ResourceGroupName

    $templateParameters.Add("virtualMachineName",$vmName)
    $templateParameters.Add("location",$DropDownRG.SelectedItem.location)
    $templateParameters.Add("adminUsername","vadmin")
    $templateParameters.Add("storageAccountName",$DropDownStorage.selectedItem)
    $templateParameters.Add("virtualNetworkName",$DropDownVNET.SelectedItem)
    $templateParameters.Add("adminPassword","Test@2016")
    $templateParameters.Add("subnetName",$DropDownSubnet.SelectedItem)
    $templateParameters.Add("customImageName",$DropDownImage.SelectedItem)
    $templateParameters.Add("virtualNetResourceGroupName",$vNetRG)
    $templateParameters.Add("virtualMachineSize",$DropDownSize.SelectedItem)
    $richTextBox1.AppendText("Launching build with following parameters")
    forEach ($parameter in $templateParameters)
    {
        $richTextBox1.AppendText("$($parameter.key):$($parameter.value)'n")

    }
    
    $deployResult = New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $CurrentTemplatePath.Text).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) -ResourceGroupName $DropDownRG.SelectedItem.ResourceGroupName -TemplateFile $CurrentTemplatePath.Text -TemplateParameterObject $templateParameters -Verbose -ErrorAction Stop

    $richTextBox1.AppendText($deployResult.ToString())
    if ($deployResult.ProvisioningState -eq "failed")
    {

        break 

    }
    $nicData = Get-AzureRmNetworkInterface -ResourceGroupName baselab -Name $deployResult.Outputs.get_item("nic").value
    $nicData.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
    $nicSetresult = Set-AzureRmNetworkInterface -NetworkInterface $nicData


}



[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
$Form = New-Object System.Windows.Forms.Form
$Form.width = 400
$Form.height = 800
$Form.Text = ”Azure VM Build Assembler”
#$Form.BackColor = "Teal"
$Form.MaximizeBox = $false


$SubscriptionSectionLabel = new-object System.Windows.Forms.Label
$SubscriptionSectionLabel.Location = new-object System.Drawing.Size(120,10)
$SubscriptionSectionLabel.size = new-object System.Drawing.Size(160,20)
$SubscriptionSectionLabel.Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold)
$SubscriptionSectionLabel.BorderStyle = 0
$SubscriptionSectionLabel.Text = "Select Subscription"
$Form.Controls.Add($SubscriptionSectionLabel)

$DropDownSubscription = new-object System.Windows.Forms.ComboBox
$DropDownSubscription.Location = new-object System.Drawing.Size(30,30)
$DropDownSubscription.Size = new-object System.Drawing.Size(300,20)
$DropDownSubscription.add_SelectedValueChanged({get-ResourceGroups})
$Form.Controls.Add($DropDownSubscription)

$RGSectionLabel = new-object System.Windows.Forms.Label
$RGSectionLabel.Location = new-object System.Drawing.Size(110,60)
$RGSectionLabel.size = new-object System.Drawing.Size(160,20)
$RGSectionLabel.Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold)
$RGSectionLabel.BorderStyle = 0
$RGSectionLabel.Text = "Select Resource Group"
$RGSectionLabel.Visible = $false
$Form.Controls.Add($RGSectionLabel)

$DropDownRG = new-object System.Windows.Forms.ComboBox
$DropDownRG.Location = new-object System.Drawing.Size(30,80)
$DropDownRG.Size = new-object System.Drawing.Size(300,20)
$DropDownRG.add_SelectedValueChanged({get-storage})
$DropDownRG.Visible = $false
$Form.Controls.Add($DropDownRG)

$StorageSectionLabel = new-object System.Windows.Forms.Label
$StorageSectionLabel.Location = new-object System.Drawing.Size(110,100)
$StorageSectionLabel.size = new-object System.Drawing.Size(160,20)
$StorageSectionLabel.Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold)
$StorageSectionLabel.BorderStyle = 0
$StorageSectionLabel.Text = "Select Storage"
$StorageSectionLabel.Visible = $false
$Form.Controls.Add($StorageSectionLabel)

$DropDownStorage = new-object System.Windows.Forms.ComboBox
$DropDownStorage.Location = new-object System.Drawing.Size(30,120)
$DropDownStorage.Size = new-object System.Drawing.Size(300,20)
$DropDownStorage.add_SelectedValueChanged({get-vnet})
$DropDownStorage.Visible = $false
$Form.Controls.Add($DropDownStorage)

$vNetSectionLabel = new-object System.Windows.Forms.Label
$vNetSectionLabel.Location = new-object System.Drawing.Size(110,140)
$vNetSectionLabel.size = new-object System.Drawing.Size(160,20)
$vNetSectionLabel.Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold)
$vNetSectionLabel.BorderStyle = 0
$vNetSectionLabel.Text = "Select VNET"
$vNetSectionLabel.Visible = $false
$Form.Controls.Add($vNetSectionLabel)

$DropDownVNET = new-object System.Windows.Forms.ComboBox
$DropDownVNET.Location = new-object System.Drawing.Size(30,160)
$DropDownVNET.Size = new-object System.Drawing.Size(300,20)
$DropDownVNET.add_SelectedValueChanged({get-subnets})
$DropDownVNET.Visible = $false
$Form.Controls.Add($DropDownVNET)

$SubnetSectionLabel = new-object System.Windows.Forms.Label
$SubnetSectionLabel.Location = new-object System.Drawing.Size(110,180)
$SubnetSectionLabel.size = new-object System.Drawing.Size(160,20)
$SubnetSectionLabel.Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold)
$SubnetSectionLabel.BorderStyle = 0
$SubnetSectionLabel.Text = "Select Subnet"
$SubnetSectionLabel.Visible = $false
$Form.Controls.Add($SubnetSectionLabel)

$DropDownSubnet = new-object System.Windows.Forms.ComboBox
$DropDownSubnet.Location = new-object System.Drawing.Size(30,200)
$DropDownSubnet.Size = new-object System.Drawing.Size(300,20)
$DropDownSubnet.add_SelectedValueChanged({enable-VMproperties})
$DropDownSubnet.Visible = $false
$Form.Controls.Add($DropDownSubnet)

$SizeSectionLabel = new-object System.Windows.Forms.Label
$SizeSectionLabel.Location = new-object System.Drawing.Size(110,220)
$SizeSectionLabel.size = new-object System.Drawing.Size(160,20)
$SizeSectionLabel.Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold)
$SizeSectionLabel.BorderStyle = 0
$SizeSectionLabel.Text = "Select VM Size"
$SizeSectionLabel.Visible = $false
$Form.Controls.Add($SizeSectionLabel)

$DropDownSize = new-object System.Windows.Forms.ComboBox
$DropDownSize.Location = new-object System.Drawing.Size(30,240)
$DropDownSize.Size = new-object System.Drawing.Size(300,20)
$DropDownSize.Visible = $false
$Form.Controls.Add($DropDownSize)

$EnvSectionLabel = new-object System.Windows.Forms.Label
$EnvSectionLabel.Location = new-object System.Drawing.Size(110,260)
$EnvSectionLabel.size = new-object System.Drawing.Size(160,20)
$EnvSectionLabel.Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold)
$EnvSectionLabel.BorderStyle = 0
$EnvSectionLabel.Text = "Select Envinroment"
$EnvSectionLabel.Visible = $false
$Form.Controls.Add($EnvSectionLabel)

$DropDownEnv = new-object System.Windows.Forms.ComboBox
$DropDownEnv.Location = new-object System.Drawing.Size(30,280)
$DropDownEnv.Size = new-object System.Drawing.Size(300,20)
$DropDownEnv.Visible = $false
$Form.Controls.Add($DropDownEnv)

$ImageSectionLabel = new-object System.Windows.Forms.Label
$ImageSectionLabel.Location = new-object System.Drawing.Size(110,300)
$ImageSectionLabel.size = new-object System.Drawing.Size(160,20)
$ImageSectionLabel.Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold)
$ImageSectionLabel.BorderStyle = 0
$ImageSectionLabel.Text = "Select Image"
$ImageSectionLabel.Visible = $false
$Form.Controls.Add($ImageSectionLabel)

$DropDownImage = new-object System.Windows.Forms.ComboBox
$DropDownImage.Location = new-object System.Drawing.Size(30,320)
$DropDownImage.Size = new-object System.Drawing.Size(300,20)
$DropDownImage.Visible = $false
$Form.Controls.Add($DropDownImage)

$CurrentTemplateLabel = new-object System.Windows.Forms.Label
$CurrentTemplateLabel.Location = new-object System.Drawing.Size(30,340)
$CurrentTemplateLabel.size = new-object System.Drawing.Size(175,20)
$CurrentTemplateLabel.Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold)
$CurrentTemplateLabel.Text = "Select Path To Template"
$CurrentTemplateLabel.Visible = $false
$Form.Controls.Add($CurrentTemplateLabel)

$CurrentTemplatePath = New-Object system.Windows.Forms.TextBox
$CurrentTemplatePath.Location = New-Object system.Drawing.Size(30,360)
$CurrentTemplatePath.size = New-Object system.drawing.Size(250,30)
$CurrentTemplatePath.Visible = $false
$CurrentTemplatePath.MaxLength = 0
$Form.Controls.Add($CurrentTemplatePath)

$BrowseCurrentButton = new-object System.Windows.Forms.Button
$BrowseCurrentButton.Location = new-object System.Drawing.Size(280,360)
$BrowseCurrentButton.Size = new-object System.Drawing.Size(80,20)
$BrowseCurrentButton.Text = "GetTemplate"
$BrowseCurrentButton.Add_Click({get-filename})
$BrowseCurrentButton.Visible = $false
$form.Controls.Add($BrowseCurrentButton)
$form.Controls.Add($Button)

$VMNameSectionLabel = new-object System.Windows.Forms.Label
$VMNameSectionLabel.Location = new-object System.Drawing.Size(110,380)
$VMNameSectionLabel.size = new-object System.Drawing.Size(160,20)
$VMNameSectionLabel.Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold)
$VMNameSectionLabel.BorderStyle = 0
$VMNameSectionLabel.Text = "Type VM name"
$VMNameSectionLabel.Visible = $false
$Form.Controls.Add($VMNameSectionLabel)

$VMPrexixTextBox = New-Object system.Windows.Forms.TextBox
$VMPrexixTextBox.Location = New-Object system.Drawing.Size(30,400)
$VMPrexixTextBox.size = New-Object system.drawing.Size(200,30)
$VMPrexixTextBox.Visible = $false
$VMPrexixTextBox.MaxLength = 0
$Form.Controls.Add($VMPrexixTextBox)

$RunButton = new-object System.Windows.Forms.Button
$RunButton.Location = new-object System.Drawing.Size(30,500)
$RunButton.Size = new-object System.Drawing.Size(100,20)
$RunButton.Text = "Build Server"
$RunButton.Add_Click({Create-VM})
$RunButton.Visible = $false
$form.Controls.Add($RunButton)

$richTextBox1 = New-Object System.Windows.Forms.RichTextBox
$richTextBox1.Location = new-object System.Drawing.Size(5,530)
$richTextBox1.Size = new-object System.Drawing.Size(375,225)
$richTextBox1.DataBindings.DefaultDataSourceUpdateMode = 0
$richTextBox1.Text = ""
$richTextBox1.font = New-Object System.Drawing.Font("Arial",10)


$Form.Controls.Add($richTextBox1)
$Form.add_Load({On-Load})
$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog()