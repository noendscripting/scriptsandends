<#
.SYNOPSIS  
  The script collects DNS entries from a specified zone on a specified DNS server into csv file in the same directory
.DESCRIPTION
  Script collect DNS entries other than of SOA and NS type and places them into csv file saved to the same directory from which script is ran.
  The file name format is <dns zone name>-<current date and time>.csv. Warning: this script uses WMI and might cause perfomance problems on servers
  with large number of DNS records and older hardware.
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
 .PARAMETER dnsZone
  Name of the DNS zone from where records are collected
 .PARAMETER DNSServer
  Name of the DNS server where the DNS zone is hosted. Can use "." for local server
  
  .EXAMPLE
  ./get-DNSEntries.ps1 -dnsZone contosoad.com -DNSServer dns1.contoso.com
   
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
    "priority"      = $srcRec.Priority         # Priority for SRV records
    "weight"        = $srcRec.Weight           # Weight for SRV records
    "port"          = $srcRec.Port             # Port for SRV Records
    "PTRDomainName"   = $srcRec.PTRDomainName  # PTRDomainName
    "SrvDomainName" = $srcRec.SrvDomainName

    }
   

    $report += $item

}
$timeStamp = get-date -UFormat %Y%m%d-%I-%M-%S%p
$report | select class,ownerName,containerName,domainName,ttl,recordClass,recordData,SrvDomainName,priority,weight,port,PTRDomainName  | Export-Csv "./$($dnsZone)-$($timeStamp).csv" -Force -NoTypeInformation