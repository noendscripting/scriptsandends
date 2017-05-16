<#  
.SYNOPSIS  
  This script collects DNS entries from a specifcied DNS zone on a specified server and then outputs them into csv file
.DESCRIPTION
  This script uses WMI class MicrosoftDNS_ResourceRecord to collect all records off Windows DNS server, except for NS and SOA types.
  The script, then creates a csv file in the same directory, from which it runs to csv file. The csv file can be used to reinset these records back into DNS
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
    
.PARAMETER DNSZone
 Name of the DNS zone like contoso.com
.PARAMETER DNSServer
Name of the DNS server that hosts the zone
.EXAMPLE
   Run script from command line
   ./get-DNSEntries.ps1 -DNSZome contoso.com -DNSserver myserver 

  
    
#>




[CmdletBinding()]
param(
[Parameter(Mandatory=$true)]
[string]$dnsZone,
[Parameter(Mandatory=$true)]
[string]$DNSserver

)


$report = @()

$DNSList = Get-WMIObject -ComputerName $DNSserver  -Namespace 'root\MicrosoftDNS' -Class MicrosoftDNS_ResourceRecord |? {($_.ContainerName -eq $dnsZone) -and ($_.__Class -ne "MicrosoftDNS_NSType") -and  ($_.__Class -ne "MicrosoftDNS_SOAType")}

ForEach($srcRec in $DnsList)
{
    $item = New-Object psobject -Property @{
    "class"         = $srcRec.__CLASS          # A, CNAME, PTR, etc.            
    "ownerName"     = $srcRec.OwnerName        # Name column in DNS GUI, FQDN            
    "containerName" = $srcRec.ContainerName    # Zone FQDN            
    "domainName"    = $srcRec.DomainName       # Zone FQDN            
    "ttl"           = $srcRec.TTL              # TTL            
    "recordClass"   = $srcRec.RecordClass      # Usually 1 (IN)            
    "recordData"    = $srcRec.RecordData       # Data column in DNS GUI, value            

    }

    $report += $item

}
$timeStamp = get-date -UFormat %Y%m%d-%I-%M-%S%p
$report | Export-Csv "./$($dnsZone)-$($timeStamp).csv" -Force -NoTypeInformation