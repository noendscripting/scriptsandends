<#
.SYNOPSIS  
  The script collects number of token blobs and size from user attributes enabled duirng crednetial romaning
.DESCRIPTION
  Script gets ID of currently logged on user and then collect data from following attributes "name","msPKIAccountCredentials","msPKIRoamingTimeStamp","msPKIDPAPIMasterKeys","samAccountName","UserPrincipalName".
  It dsiplays data from "name","samAccountName" and"UserPrincipalName" and statisctis from "name","msPKIAccountCredentials","msPKIDPAPIMasterKeys".
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
  
  .EXAMPLE
  powershell -executionpolicy bypass -file .\User-CredentialRoamingADSize.ps1
   Starts script for non priveleged user from command prompt
   
#>


$strFilter = "(samAccountName=$($env:USERNAME))"

$objDomain = New-Object System.DirectoryServices.DirectoryEntry

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.PageSize = 1000
$objSearcher.Filter = $strFilter
$objSearcher.SearchScope = "Subtree"
[array]$colProplist = @("name","msPKIAccountCredentials","msPKIRoamingTimeStamp","msPKIDPAPIMasterKeys","samAccountName","UserPrincipalName")
foreach ($i in $colPropList)
{
    $objSearcher.PropertiesToLoad.Add($i) | Out-Null
    
  }

  $colResults = $objSearcher.FindAll()

foreach ($objResult in $colResults)
    {
        write-host "User: $($objResult.Properties.name) | loginId:$($objResult.Properties.samaccountname) | UPN:$($objResult.Properties.userprincipalname)" -ForegroundColor green
        write-host "Total Number of Tokens: $($objResult.Properties.mspkiaccountcredentials.count). Total Size Token Blobs Keys $(($objResult.Properties.mspkiaccountcredentials| measure -Property Length -Sum).sum) bytes" -ForegroundColor green
        write-host "Total Number of DAPI keys: $($objResult.Properties.mspkidpapimasterkeys.Count). Size DPAPI Keys $(($objResult.Properties.mspkidpapimasterkeys | measure -Property Length -Sum).sum) bytes" -ForegroundColor green
        #$objResult.Properties.mspkiroamingtimestamp
        #$objResult.Properties.mspkidpapimasterkeys.Count
     
     }



