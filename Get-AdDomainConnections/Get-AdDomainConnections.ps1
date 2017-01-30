<#  
.SYNOPSIS  
  The script uses portquery command utility to verify connectivity to domains controllers
.DESCRIPTION
  This script takes name of the destination host(s) and runs PortQry.exe through the range known ports for AD Controller.
  The script must have PortQry.exe and config.json in the same directory as the script.
DISCLAIMER
     THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
    We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object
    code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software
    product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the
    Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims
    or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
    Please note: None of the conditions outlined in the disclaimer above will supersede the terms and conditions contained within the Premier Customer Services Description.
 

.EXAMPLE
   Run script from command line to test one server with default logging and no report file
   Get-AdDomainConnections.ps1 -Servers Server1 
.EXAMPLE
   Run script from command line to test multiple computers with default logging and no report file
   Get-AdDomainConnections.ps1 -Servers “Server1”,”Server2”
.EXAMPLE
  Run script from command line to test multiple servers from a text file with custom logging and no report file
   Get-AdDomainConnections.ps1 -Servers (get-content c:\list.txt) -log c:\output.log
.EXAMPLE
  Run script from command line to test multiple servers from a text file with custom logging and report file
   Get-AdDomainConnections.ps1 -Servers (get-content c:\list.txt) -log c:\output.log -report $true -csvfile c:\output.csv

  .NOTES
 
   

  
    
#>

param(
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string[]]$Servers,
[string]$log,
[string]$report, 
[string]$csvfile  
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


#setting final resuts array and default values 
$result = @()
$PSDefaultParameterValues = @{

"write-log:severity"="INFO";
"write-log:logfile"="$($env:ALLUSERSPROFILE)\GetADDomainconnection.log"
}

if ($log.Length -ne 0)
{
 if(Test-Path (split-path $log -parent) | Out-Null)
 {
    $PSDefaultParameterValues["write-log:logfile"]=$log
    write-log "Setting location of log file to $($log)"

 }
 else
 {
    write-log "Custom log is not found setting log to   $($env:ALLUSERSPROFILE)\GetADDomainconnection.log"
 }

}
trap{ write-log -message $_.Exception -severity "ERROR" -logfile $auditLog;break;}


write-log "Running Pre-requsits check"

if(!(Test-Path .\PortQry.exe))
{

    Write-log "PortQry.exe not found! PortQry.exe must be in the director as script.`nTerminating script" -severity ERROR
    break

}
elseif (!(Test-Path .\config.json))
{


    write-log "File config.json1 not found! config.json must be in the director as script.`nTerminating script" -severity ERROR
    break

}

if ($report -eq $true -and $csvfile.Length -ne 0)
{

   write-log "Report file information is missing`n Terminating script" -severity ERROR
    break

}

#getting list of ports to query from configuration file
$queryList = (Get-Content .\config.json) -join "" | ConvertFrom-Json

# starting to proccess servers
Foreach ($server in $Servers)
{
    write-log "Starting connectivity tests server $($server)"
    #testing ports 
    ForEach ($service in $queryList)
    {  
        $processe = $null
        $status = $null
        
        $process = .\PortQry.exe -n $($Server) -p $($service.protocol) -e $($service.value)

   #analazing results 
        switch($LASTEXITCODE)
        {
            0 {$status = "OK"}
            2 {$status = "FILTERED"}
            3 { write-log "$($process)" -severity ERROR
                $status = "FAIL"
              }


        }
        #adding data to text log
        write-log "Tested $($server) service $($service.Name) port $($service.Value) type $($service.Protocol).Status: $($status)"
 
        $item = New-Object psobject -Property @{
        "Source" = $env:COMPUTERNAME
        "Destination" = $Server
        "NAME" = $service.Name
        "Protocol" = $service.Protocol
        "Port" = $service.Value
        "Status" = $status
        }
        #adding data to results object
        $result += $item
    }
}
#creating final report 

if ($report -eq $true) 
{
 $result | select Source,Destination,Name,Protocol,Port,Status | Export-Csv $csvfile -NoTypeInformation

}