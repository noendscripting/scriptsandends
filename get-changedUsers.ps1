<#
.SYNOPSIS  
 The srcipt gets list of users and then compares attribute versions with versions availble in PDCe.

.DESCRIPTION
  The script gets a list of enabled users from target server who's properties were changed after specific date.
  Once user list is collected, each user's replictaion metadata is examined and attributed that were updated
  on the source server, compared with attributes of the same user on PDCe. if attribute versions do not match,
  the data will be added to the csv file for further review.
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
 .PARAMETER csvFile
  Path to the csv file for export or import.

  
  .EXAMPLE
    .\compare-Groups.ps1 -csvFile C:\groups.csv
   
#>


param(
[Parameter(Mandatory=$true)]
$csvFile
)


$dcList = @()
$pdce =  ""
$report = @()
[int]$dccount = 0

ForEach($dc in $dcList)

{
    
    $dccount += 1
    Write-Progress -Activity "Processing DC data" -PercentComplete (($dccount/$dcList.Count)*100) -Id 1 -CurrentOperation "users in DC $($dc.Split(".")[0])"
    $user = $null
    $userCount = 0
    $currentDC = Get-ADDomainController -Identity $dc -Server $pdce
     
    [datetime]$whenChanged  = '2017-05-25'

    $users = get-aduser -Filter {whenChanged -ge $whenChanged -and Enabled -eq $true} -Server $currentDC.HostName | select SamAccountName,ObjectGUID
    forEach ($user in $users)
    {
        $userCount += 1
        Write-Progress -Activity "Processing user data" -PercentComplete (($userCount/$users.Count)*100) -Id 2 -CurrentOperation "working on user $($user.SamAccountName.ToUpper())" -ParentId 1
        $metadatresults = $null
        
        $metadatResults = Get-ADReplicationAttributeMetadata -Object $user.ObjectGUID -Server $currentDC.HostName -Filter {LastOriginatingChangeDirectoryServerInvocationId -eq $currentDC.InvocationId -and LastOriginatingChangeTime -ge $whenChanged -and AttributeName -ne "lastLogonTimestamp"} 
        if($metadatResults -ne $null)
        {
            ForEach ($metadataResult in $metadatResults)
            {
                
                $pdceAttribute = Get-ADReplicationAttributeMetadata -Object $user.ObjectGUID -Server $pdce -Filter {AttributeName -eq $metadataResult.AttributeName} 
                if ($metadataResult.Version -eq $pdceAttribute.Version)
                {
                    
                    Write-Host "Find mismatch user $($user.SamAccountName.ToUpper()) in attribute ""$($metadataResult.AttributeName)"". Adding To Report" -ForegroundColor Green
                    if ($metadataResult.AttributeValue.GetType().name -eq "String[]")
                    {

                        $SourceAttributeValue = $metadataResult.AttributeValue -join ";"
                        $PDCeAttributeValue = $pdceAttribute.attributeValue -join ";"
                    }
                    else
                    {
                        $SourceAttributeValue = $metadataResult.AttributeValue 
                        $PDCeAttributeValue = $pdceAttribute.attributeValue

                    }
                    
                    $item = New-Object psobject -Property @{
                    "SourceServer" = $currentDC.HostName.Split(".")[0]
                    "userID" = $user.SamAccountName
                    "AttributeName" = $metadataResult.AttributeName
                    "SourceAttributeValue" = $SourceAttributeValue
                    "PDCeAttributeValue" = $PDCeAttributeValue
                    "SourceLastChangeDate" = $metadataResult.LastOriginatingChangeTime
                    "PDCeLastChangeDate" = $pdceAttribute.LastOriginatingChangeTime
                    "PDCeLastSource" = $pdceAttribute.LastOriginatingChangeDirectoryServerIdentity}

                    

                    $report += $item
                }
            }

         }
            


     }
}



$report | select  SourceServer,userID,AttributeName,SourceAttributeValue,PDCeAttributeValue,SourceLastChangeDate,PDCeLastChangeDate,PDCeLastSource | Export-Csv $csvFile -NoTypeInformation

