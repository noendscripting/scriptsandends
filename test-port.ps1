
<#  
.SYNOPSIS  
  The script replaces functionality of telnet.
.DESCRIPTION
  This script takes name of the destination host and port and outputs "OK" or "FAIL" depending on results
  The srcipt can be run from command line, as a job or via WinRM from remote compute.
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
    
.PARAMETER -hostname
 Name
.EXAMPLE
   Run script from command line
   test-port.ps1 -host Server1 -port 53
.EXAMPLE
   Test specific port on multiple computers by passing host from file
   get-content c:\list.txt | test-port.ps1 -host $_ -port 53
.EXAMPLE
  Run script via WinRM to test port conenctivity from Server 1 to Server 2
  invoke-command -computername Server1 -File test-ping.ps1 -ArgumentList "Server2", "53"
  .NOTES
    
   

  
    
#>

param(
[Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
[string]$hostname,
[Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=1)]
[string]$port

)



Try
{
    $scope=New-Object net.sockets.tcpclient($hostname,$port)
    if ($scope.Connected -eq $true)
    {
        write-output "$($env:computername),$($hostname),$($port),OK"
    }
    
    
    }
    catch
    {
        write-output "$($env:computername),$($hostname),$($port),FAILED"
    }