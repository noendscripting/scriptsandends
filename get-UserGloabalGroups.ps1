<#
.SYNOPSIS
 The srcipt gets list of all enabled users in the selected domain and their membership in GlobalDomain groups

.DESCRIPTION
  The script gets  a list of enabled users in selectes domian, their SID and SIDHistory and if they are members of Global Groups, the Groups Name, SID and SID history.
  Collected is exported to cvs file.
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
 .PARAMETER outputCsv
  Path to the csv file for export or import.
 .PARAMETER DomainFQDN
  Domains to search


  .EXAMPLE
    .\get-userGloabalGroups -DomainFQDN fabrikan.com -csvFile c:\temp\results.csv




#>

Function get-GroupNameFromSID
{
 #Function converts SID to group name
 param($SID)




}
param(

[Parameter(Mandatory=$true)]
[string]$outputCsv,
[Parameter(Mandatory=$true)]
[string]$DomainFQDN

)


#Creating array to store collected data
$report = @()

#Getting SID of the domain we are going to search
$domainSID = (Get-ADDomain -Server $DomainFQDN  | Select-Object domainSID).DomainSid

#Creating array with list of all known SIDs
[string[]]$knownSIDs = @(
"S-1-0",
"S-1-0-0",
"S-1-1",
"S-1-1-0",
"S-1-2",
"S-1-2-0",
"S-1-2-1",
"S-1-3",
"S-1-3-0",
"S-1-3-1",
"S-1-3-2",
"S-1-3-3",
"S-1-3-4",
"S-1-5-80-0",
"S-1-4",
"S-1-5",
"S-1-5-1",
"S-1-5-2",
"S-1-5-3",
"S-1-5-4",
"S-1-5-6",
"S-1-5-7",
"S-1-5-8",
"S-1-5-9",
"S-1-5-10",
"S-1-5-11",
"S-1-5-12",
"S-1-5-13",
"S-1-5-14",
"S-1-5-15",
"S-1-5-17",
"S-1-5-18",
"S-1-5-19",
"S-1-5-20",
"$($domainSID)-500",
"$($domainSID)-501",
"$($domainSID)-502",
"$($domainSID)-512",
"$($domainSID)-513",
"$($domainSID)-514",
"$($domainSID)-515",
"$($domainSID)-516",
"$($domainSID)-517",
"$($domainSID)-520",
"$($domainSID)-526",
"$($domainSID)-527",
"$($domainSID)-553",
"S-1-5-32-544",
"S-1-5-32-545",
"S-1-5-32-546",
"S-1-5-32-547",
"S-1-5-32-548",
"S-1-5-32-549",
"S-1-5-32-550",
"S-1-5-32-551",
"S-1-5-32-552",
"S-1-5-64-10",
"S-1-5-64-14",
"S-1-5-64-21",
"S-1-5-80",
"S-1-5-80-0",
"S-1-5-83-0",
"S-1-16-0",
"S-1-16-4096",
"S-1-16-8192",
"S-1-16-8448",
"S-1-16-12288",
"S-1-16-16384",
"S-1-16-20480",
"S-1-16-28672",
"S-1-5-32-554",
"S-1-5-32-555",
"S-1-5-32-556",
"S-1-5-32-557",
"S-1-5-32-558",
"S-1-5-32-559",
"S-1-5-32-560"
"S-1-5-32-561",
"S-1-5-32-562",
"$($domainSID)-498",
"$($domainSID)-521",
"S-1-5-32-569",
"$($domainSID)-571",
"$($domainSID)-572",
"S-1-5-32-573",
"S-1-5-32-574",
"$($domainSID)-522",
"S-1-5-32-575",
"S-1-5-32-576",
"S-1-5-32-577",
"S-1-5-32-578",
"S-1-5-32-579",
"S-1-5-32-580"
)
#getting list of enabled users in the domain
$usersToReview = get-aduser -Filter {Enabled -eq $true} -Server $DomainFQDN -Properties memberof,SIDHistory,PrimaryGroupId
  forEach ($userEntry in $usersToReview)
  {
    #Retrieving name of the Primary Group since it does not appear in the MemberOF property.
    $primaryGroupSID = "$($domainSID)-$($userEntry.PrimaryGroupId)"
    $objSID = New-Object System.Security.Principal.SecurityIdentifier( $primaryGroupSID)
    $objAD = $objSID.Translate( [System.Security.Principal.NTAccount])
    $PrimaryGroupName= $objAD.Value.Split("\")[1]

    #Adding Group to the existing list
    $grouplist = $userEntry.MemberOf
    $grouplist.Add($PrimaryGroupName) | Out-Null

    #processing Groups
    ForEach ($groupName in $grouplist)
        {


            $groupProp = Get-ADGroup $groupName -Properties SID,SIDHistory,GroupScope
          #Filetering known Active Directory group and groups not scoped as Global Domain Groups
            If (!($knownSIDs.Contains($groupProp.SID.Value)) -and $groupProp.GroupScope -eq "Global")
            {
                $groupItem = New-Object PSObject
                $groupItem | Add-Member -MemberType NoteProperty -Name "GroupName" -Value $groupProp.Name
                $groupItem | Add-Member -MemberType NoteProperty -Name "GroupSamAcountName" -Value $groupProp.SamAccountName
                $groupItem | Add-Member -MemberType NoteProperty -Name "GroupSID" -Value $groupProp.SID.Value
                $groupItem | Add-Member -MemberType NoteProperty -Name "GroupSIDHistory" -Value ($groupProp.SIDHistory -join ":")
                $memberOF += $userItem
            }


        }


        #Proccesing data into reports
        if ($memberOF.Count -ge 0)
        {

            ForEach ($groupEntry in $memberOF)
            {
                $userItem = New-Object psobject -Property @{
                    "DistinguishedName" = $userEntry.DistinguishedName
                    "Name" = $userEntry.Name
                    "SamAccountName" = $userEntry.SamAccountName
                    "SID"= $userEntry.SID.Value
                    "SIDHistory" = ($userEntry.SIDHistory -join ":")
                }

                $userItem| Add-Member -MemberType NoteProperty -Name "GroupName" -Value $groupEntry.GroupName
                $userItem | Add-Member -MemberType NoteProperty -Name "GroupSamAcountName" -Value $groupEntry.GroupSamAcountName
                $userItem | Add-Member -MemberType NoteProperty -Name "GroupSID" -Value $groupEntry.GroupSID
                $userItem | Add-Member -MemberType NoteProperty -Name "GroupSIDHistory" -Value $groupEntry.GroupSIDHistory
                $report += $userItem
            }

        }
        else
        {
            $userItem = New-Object psobject -Property @{
                    "DistinguishedName" = $userEntry.DistinguishedName
                    "Name" = $userEntry.Name
                    "SamAccountName" = $userEntry.SamAccountName
                    "SID"= $userEntry.SID.Value
                    "SIDHistory" = ($userEntry.SIDHistory -join ":")
                }
                $report += $userItem

        }
  }

#Publishing Report
$report |select-object -Property Name,SamAccountName,DistinguishedName,SID,SIDHistory,GroupName,GroupSamAcountName,GroupSID,GroupSIDHistory |Export-Csv $outputCsv -Force -NoTypeInformation