﻿<#
.Synopsis
    Script from TechDays Sweden 2016
.DESCRIPTION
    Script from TechDays Sweden 2016
.NOTES
    Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com
    Disclaimer:
    This script is provided "AS IS" with no warranties, confers no rights and 
    is not supported by the authors or Deployment Artist.
.LINK
    http://www.deploymentbunny.com
#>
Function Get-RemoteComputerSystemInfo{
    param(
        $ComputerName
    )

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Function Get-ComputerSystemInfo{
            Write-Host "Getting data from $env:COMPUTERNAME"
            $Index = Get-WmiObject -Class Win32_ReliabilityStabilityMetrics | Select-Object @{N="TimeGenerated"; E={$_.ConvertToDatetime($_.TimeGenerated)}},SystemStabilityIndex | Select-Object -First 1
            $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
            $OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem | Select-Object @{N="LastBootUpTime"; E={$_.ConvertToDatetime($_.LastBootUpTime)}},Version
            $Plupp = [ordered]@{ 
                  ComputerName = $($env:COMPUTERNAME)
                  Index =  $([math]::Round($Index.SystemStabilityIndex))
                  TimeGenerated = $($Index.TimeGenerated)
                  Make = $($ComputerSystem.Manufacturer)
                  Model = $($ComputerSystem.Model)
                  OSVersion = $($OperatingSystem.Version)
                  UpTimeInDays = $([math]::round(((Get-Date) - ($OperatingSystem.LastBootUpTime)).TotalDays))
                  OSDiskFreeSpaceInGB = $([Math]::Round($(((Get-Volume -DriveLetter C).SizeRemaining)/1GB),2))
                  }
            New-Object PSObject -Property $Plupp
        }
        Get-ComputerSystemInfo
    }
}

#Get the servers
Write-Host "Getting Server names"
Import-Module "ActiveDirectory"
$Computers = Get-ADComputer -LDAPFilter "(&(objectCategory=computer)(name=SRV*)(operatingSystem=Windows Server*)(!serviceprincipalname=*MSClusterVirtualServer*)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" 

Write-Host "Found $($Computers.Count)"
Write-Host "Check if they are online"
$ComputersOnline = $Computers.DNShostname | Test-NetConnection -CommonTCPPort WINRM -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Where-Object -Property TcpTestSucceeded -EQ -Value True
Write-Host "Found $($ComputersOnline.Count) that seems to be online"

$TheSadTruth = Foreach($Computer in $ComputersOnline.ComputerName){
    Get-RemoteComputerSystemInfo -ComputerName $Computer
}

$Title = "Cloud"
$Head = "Cloud"
$TheSadTruth | Sort-Object -Property ComputerName | ConvertTo-Html -As Table `
-Title $Title  `
-Head $Head  `
-Body (Get-Date -UFormat "%Y-%m-%d - %T ")  `
-PreContent "<H3>Rel Index from $ENV:USERDNSDOMAIN</H3><P>Generated by Power of the Force</P>"  `
-PostContent "<P>For details, contact support@customer.com.</P>"  `
-Property ComputerName,Make,Model,OSVersion,OSDiskFreeSpaceInGB,UpTimeInDays,Index |
ForEach {
if($_ -like "*<td>10</td>*"){$_ -replace "<tr>", "<tr bgcolor=Lime>"}
elseif($_ -like "*<td>9</td>*"){$_ -replace "<tr>", "<tr bgcolor=Lime>"}
elseif($_ -like "*<td>8</td>*"){$_ -replace "<tr>", "<tr bgcolor=Lime>"}
elseif($_ -like "*<td>7</td>*"){$_ -replace "<tr>", "<tr bgcolor=Aqua>"}
elseif($_ -like "*<td>6</td>*"){$_ -replace "<tr>", "<tr bgcolor=Aqua>"}
elseif($_ -like "*<td>5</td>*"){$_ -replace "<tr>", "<tr bgcolor=Aqua>"}
elseif($_ -like "*<td>4</td>*"){$_ -replace "<tr>", "<tr bgcolor=Aqua>"}
elseif($_ -like "*<td>3</td>*"){$_ -replace "<tr>", "<tr bgcolor=Yellow>"}
elseif($_ -like "*<td>2</td>*"){$_ -replace "<tr>", "<tr bgcolor=Yellow>"}
elseif($_ -like "*<td>1</td>*"){$_ -replace "<tr>", "<tr bgcolor=Yellow>"}
elseif($_ -like "*<td>0</td>*"){$_ -replace "<tr>", "<tr bgcolor=Red>"}
else{$_}
} > C:\inetpub\wwwroot\default.htm 