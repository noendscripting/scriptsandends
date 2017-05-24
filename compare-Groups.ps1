<#
.SYNOPSIS  
 The srcipt collects group membership and compares it to previusly generated export.
.DESCRIPTION
  Script collect group membership and then either exports it to csv file or compares it with previously generated export file.
  Script outputs mismatches on screen  if any and gives option to save output to a csv file
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
 .PARAMETER export
  Can be true or false, default false. When set to true exports group membership data to the provides csv file
 .PARAMETER compare
  Can be true or false, default false. When set to true compares current group membership with export file generated earlier
 .PARAMETER csvFile
  Path to the csv file for export or import.

  
  .EXAMPLE
    .\compare-Groups.ps1 -export $true -csvFile C:\groups.csv
    Exports groups membership details to a file
  .EXAMPLE
    .\compare-Groups.ps1 -compare $true -csvFile C:\groups.csv 
    Compares current groups members with export from generated report
  
   
#>


param(
[bool]$export = $false,
[bool]$compare = $false,
[Parameter(Mandatory=$true)]
[string]$csvFile

)


Function Get-Members
{
    $report = @()
$groups = (Get-ADGroup -Filter *).distinguishedName

forEach ($group in $groups)

{   
    $members = $null
    $members = Get-ADGroupMember $group
    if ($members -ne $null)
    {
        
        
        Foreach ( $member in $members)
        {
            $item = New-Object psobject -Property @{
            "Group" = $group
            "DN" = $member.distinguishedName
            "SID" = $member.SID
            "DC" = $env:COMPUTERNAME
            "ID" = $member.SamAccountName
            }
           $report += $item
        }
     
        
    }

    }

    return $report
}
    
  
  if ($export -and $compare)
  {

    Write-Error "Both export and compare options selected. Please rerun the script and select one or the other`nExiting script"
    break

  }


if ($export)
{


   Get-Members |  Export-Csv  $csvFile -NoTypeInformation

   break

}


if ($compare)
{
    $compareReport = @()
    $groupDump = Import-Csv C:\Packages\groups.csv
    $currentGroups = Get-Members
    $groups = ($currentGroups | select group -Unique).group
    ForEach ($group in $groups)
    {
     $referenceMembers = ($groupDump |?{$_.GRoup -eq $group}).SID
     $currentMembers =  ($currentGroups |?{$_.GRoup -eq $group}).SID
     $compareResult = $null   
     $compareResult =  Compare-Object $currentMembers -DifferenceObject $referenceMembers #| ft inputobject, @{n="DC";e={ if ($_.SideIndicator -eq '=>') { $groupDump.DC }  else { $env:COMPUTERNAME } }} | Out-File C:\Packages\compare.txt
     if ($compareResult -ne $null)
     {
         Write-verbose "Bad $($group)"
         if ($compareResult.SideIndicator -eq '=>')
         {

           $Exists = "Export"
           $Missing = "CurrentDC"

         }
         Else
         {
             $Exists = "CurrentDC"
             $Missing = "Export"
         }
         $mismatchItem = New-Object psobject -Property @{
         "GroupName" = $group
         "UserID" = ($currentMembers =  ($currentGroups |?{$_.SID -eq $compareResult.InputObject }) | select ID -Unique ).ID
         "SID" = $compareResult.InputObject
         "MissingIN" = $Missing
         "PresentIN" = $Exists 

         }

         
         $compareReport += $mismatchItem
     }
     Else
     {
        Write-Verbose "Good $($group)"
     }
        
        
    


   
  }
  $compareReport | Format-Table GroupName,UserId,SID,PresentIN,MissingIN

  $outputCSV = Read-Host "Type path to the output csv file if you want to save results. Otherwise hit enter to exit script"
  if ($outputCSV.Length -ne 0)
  {

  $compareReport | select GroupName,UserId,SID,PresentIN,MissingIN | Export-Csv $outputCSV -NoTypeInformation

  }

   break
}





