<#
.SYNOPSIS  
  The script add DNS entries into sepcified DNS Zone from a provide csv file
.DESCRIPTION
  Script adds DNS entries other than of SOA and NS type from formatted csv file.
  Warning: this script uses WMI and might cause perfomance problems on servers   with large number of DNS records and older hardware.
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
 .PARAMETER csvFile
  Path to the CSV file with DNS record information
  
  .EXAMPLE
  ./get-DNSEntries.ps1 -dnsZone contosoad.com -DNSServer dns1.contoso.com -csvFile c:\dnsentries.csv
   
#>

[CmdletBinding()]

param(
[Parameter(Mandatory=$true)]
[string]$csvFile,
[Parameter(Mandatory=$true)]
[string]$DNSserver,
[Parameter(Mandatory=$true)]
[string]$dnsZone
)

$records = Import-Csv -Path $csvFile


$CurrentDNSconfig = Get-WMIObject -ComputerName $DNSserver  -Namespace 'root\MicrosoftDNS' -Class MicrosoftDNS_ResourceRecord |? {$_.ContainerName -eq $dnsZone}
if($CurrentDNSconfig -eq $null)
{

 Write-Host "$($dnsZone) DNS Zone not found on server $($DNSserver) please create zone and re-run the script"
 exit


}


ForEach ($srcRec in $Records) {            
            
    # Echo the source record data for logging            
    $srcRec            
            
    $class         = $srcRec.class          # A, CNAME, PTR, etc.            
    $ownerName     = $srcRec.OwnerName        # Name column in DNS GUI, FQDN            
    $containerName = $srcRec.ContainerName    # Zone FQDN            
    $domainName    = $srcRec.DomainName       # Zone FQDN            
    $ttl           = $srcRec.TTL              # TTL            
    $recordClass   = $srcRec.RecordClass      # Usually 1 (IN)            
    $recordData    = $srcRec.RecordData       # Data column in DNS GUI, value            
            
    # Dynamically create a new record of the appropriate type (class)            
    $destRec = [WmiClass]"\\$dnsServer\root\MicrosoftDNS:$class"            
                
    # The CreateInstanceFromPropertyData method varies slightly based on the            
    # record type (class).            
    Switch ($class) {            
        MicrosoftDNS_AType {            
            $destRec.CreateInstanceFromPropertyData($destServer, $dnsZone,$ownerName, $recordClass, $ttl, $recordData)            
        }            
        MicrosoftDNS_CNAMEType {            
            $destRec.CreateInstanceFromPropertyData($destServer, $dnsZone, $ownerName, $recordClass, $ttl, $recordData)            
        }            
        MicrosoftDNS_MXType {            
            $preference   = $srcRec.Preference            
            $mailExchange = $srcRec.MailExchange            
            $destRec.CreateInstanceFromPropertyData($destServer, $dnsZone,$ownerName, $recordClass, $ttl, $preference, $mailExchange)            
        }            
        MicrosoftDNS_SRVType { 
            
            $priority   = $srcRec.Priority            
            $weight     = $srcRec.Weight            
            $port       = $srcRec.Port
            $SrvDomainName = $srcRec.SRVDomainName           
            $destRec.CreateInstanceFromPropertyData($destServer, $dnsZone, $ownerName, $recordClass, $ttl, $priority, $weight, $port,$SrvDomainName)            
        }            
        MicrosoftDNS_PTRType {            
            $PTRDomainName   = $srcRec.PTRDomainName            
            $destRec.CreateInstanceFromPropertyData($destServer, $dnsZone,$ownerName, $recordClass, $ttl, $PTRDomainName)            
        }            
    }            
}            
