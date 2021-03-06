<#
------------------------------------------------------------------------------
 THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
 WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
 LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
 FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR 
 RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

 NAME: DellWarrantyCheck.ps1
 AUTHOR(s): Sean Thomas (sean@anrsolutions.ca)
 CREATED: September 20, 2015
------------------------------------------------------------------------------
 This script is used to pull Dell warranty information; service tag is either 
 supplied (as parameter) or pulled from the computer.
------------------------------------------------------------------------------
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=1)]
    [string]$serviceTag
)

$dellAPIUrl = 'https://sandbox.api.dell.com/support/v2/assetinfo/warranty/tags?svctags='
$apiKey = 'eb71b74357579b94e257f8284b88db01'

if(!$serviceTag)
{
    $systemBIOS = Get-WmiObject Win32_SystemEnclosure
	$system = Get-WmiObject Win32_ComputerSystem
    
    $serviceTag = $systemBIOS.SerialNumber
    $computerName = $systemBIOS.__SERVER
    
    $model = $system.Model
    $manufacturer = $system.Manufacturer
}
else
{
    $serviceTag = $serviceTag
    $computerName = 'Unknown'
    
    $model = 'Unknown'
    $manufacturer = 'Dell'
}

if (!($manufacturer -match 'Dell')) 
{
	Write-Error "Error: Computer Not Manufactured By Dell."
} 
else 
{
	$dellAPIUrl = "${dellAPIUrl}${serviceTag}&apikey=${apiKey}"
    $webResponse = Invoke-RestMethod -URI $dellAPIUrl -Method GET
    $warrantyList = $webResponse.getassetwarrantyresponse.getassetwarrantyresult.response.dellasset.warranties.warranty
	$dellAsset  = $webResponse.getassetwarrantyresponse.getassetwarrantyresult.response.dellasset
	
	if($warrantyList.Count -gt 0)
	{
		foreach($warranty in $warrantyList)
		{
			$deviceAge = [datetime]::ParseExact($dellAsset.shipdate,"yyyy-MM-ddTHH:mm:ss",$null)
			$deviceAge = "{0:N2}" -f (([datetime]::now - $deviceAge).days / 365)
	                
			$output = New-Object -Type PSCustomObject
			
			Add-Member -MemberType NoteProperty -Name 'ComputerName' -Value $computerName -InputObject $output
			Add-Member -MemberType NoteProperty -Name 'Model' -Value $model -InputObject $output
			Add-Member -MemberType NoteProperty -Name 'ServiceTag' -Value $serviceTag -InputObject $output
			Add-Member -MemberType NoteProperty -Name 'Age' -Value $age -InputObject $output
		
			foreach($property in ($warranty | Get-Member -Type Property)) 
			{
				Add-Member -MemberType NoteProperty -Name $property.name `
				-Value $warranty.$($property.name) `
				-InputObject $output
			}
			
			$output.StartDate = [datetime]::ParseExact($output.StartDate,"yyyy-MM-ddTHH:mm:ss",$null)
			$output.EndDate   = [datetime]::ParseExact($output.EndDate,"yyyy-MM-ddTHH:mm:ss",$null) 

			Write-Output $output
		}
	}
	else
	{
		Write-Error "Error: No Warranty Information Returned."
	}
}