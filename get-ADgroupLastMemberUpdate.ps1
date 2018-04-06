<#
.SYNOPSIS
 The srcipt gets list of groups in a given domain(s) and returns the last change

.DESCRIPTION
  The script gets  a list of groups that were changed, since they were created and  are marked crtical by AD. Each group is then examined for the last "member"
  atrribute change and object and date recorded and exported to cvs file.
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
 .PARAMETER Domains
  List of .domains to search


  .EXAMPLE
    .\get-ADgroupLastMemberUpdate.ps1 -Domains fabrikan.com -csvFile c:\temp\results.csv
  Get list of groups from a single domain
  .EXAMPLE
  .\get-ADgroupLastMemberUpdate.ps1 -Domains "fabrikan.com","contosoad.com" -csvFile c:\temp\results.csv
  Get list of groups from multiple domains
  .EXAMPLE
   .\get-ADgroupLastMemberUpdate.ps1 -Domains (get-content c:\temp\domainlist.txt) -csvFile c:\temp\results.csv
  Get domain names from a list and get list of groups in each


#>



param(
[parameter(Mandatory=$true)]
[string[]]$Domains,
[parameter(Mandatory=$true)]
[string]$CVSFile

)
function write-log
{


param(
    [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
    $message,
    [ValidateSet("ERROR","INFO","WARN")]
    $severity,
    $logfile

)
$ErrorActionPreference = "Stop"
$WhatIfPreference=$false
$timeStamp = get-date -UFormat %Y%m%d-%I:%M:%S%p
switch ($severity)
 {

  "INFO" {$messageColor = "Green"}
  "ERROR" {$messageColor = "Red"}
  "WARN" {$messageColor = "Yellow"}

 }
 Write-Host "$($timeStamp) $($severity) $($message)" -ForegroundColor $messageColor
 if ($logfile.length -ge 0)
 {
    write-output "$($timeStamp) $($severity) $($message)" | Out-File -FilePath $logfile -Encoding ascii -Append
 }
}

$PSDefaultParameterValues = @{

    "write-log:severity"="INFO";
    "write-log:logfile"="$($env:ALLUSERSPROFILE)\(($MyInvocation.MyCommand.Name).Split(".")[0]).log"
    }
Trap{write-log $Error[0] -severity ERROR}
write-log "Starting script. Run log will be written to $($env:ALLUSERSPROFILE)\(($MyInvocation.MyCommand.Name).Split(".")[0]).log"
$report = @()
[int]$domainCount = 0
ForEach ($domain in $domains)
{   Write-Progress -Activity "Searching domain $(domain)" -PercentComplete (($domain/$domains.Count)*100) -Id 1 -CurrentOperation "Processing Groups"
    $domainController = (Get-ADDomainController -DomainName $domain -Discover -ErrorAction Stop).HostName[0]
    $groupList =  Get-ADGroup -Server $domainController -Filter * -Properties ObjectGUID,Name,DistinguishedName,whenChanged,whenCreated,isCriticalSystemObject |Where-Object{$_.whenChanged -ne $_.whenCreated -and $_.isCriticalSystemObject -ne $true} | select-Object ObjectGUID,Name,DistinguishedName,whenChanged
    Foreach ($group in $groupList)
    {
        [int]$groupCount = 0
        Write-Progress -Activity "Getting member attribute change from metadata" -PercentComplete (($domain/$groupList.Count)*100) -Id 2 -CurrentOperation "Processing group $($group.name)"
        $output = Get-ADReplicationAttributeMetadata -Object $group.ObjectGUID.Guid -Server $domainController -ShowAllLinkedValues -Properties member -ErrorAction Stop | Sort-Object LastOriginatingChangeTime -Descending | select-object -Property AttributeValue, LastOriginatingChangeTime -First 1
        $item = New-Object psobject -Property @{
        "GroupName"=$group.Name
        "LastChange" = $output.AttributeValue
        "DateUTC" = $output.LastOriginatingChangeTime
        }
        $report += $item
        $groupCount + 1
        Clear-Variable item,output
    }

    Clear-Variable grouplist,domainController
    $domainCount + 1
}

$report | Select-Object GroupName,LastChange,DateUTC | Sort-Object DateUTC -Descending | Export-Csv -Path $CVSFile -NoTypeInformation -ErrorAction Stop

$ErrorActionPreference = "Continue"