<#
DellWarrantyCheck.ps1

#>
$apiKey = 'eb71b74357579b94e257f8284b88db01'
$dellAPIUrl = "https://sandbox.api.dell.com/support/v2/assetinfo/warranty/tags?svctags=${serviceTag}&apikey=${apiKey}"

$bios = Get-WmiObject Win32_SystemEnclosure
$system = Get-WmiObject Win32_ComputerSystem

$serviceTag = $systemBIOS.SerialNumber
$computerName = $systemBIOS.__SERVER

$model = $system.Model
$manufacturer = $system.Manufacturer

if (!($manufacturer -match 'Dell')) 
{
	Write-Error "Error: Computer Not Manufactured By Dell."
} 
else 
{
    $webResponse = Invoke-RestMethod -URI $url -Method GET
    $warrantyList = $req.getassetwarrantyresponse.getassetwarrantyresult.response.dellasset.warranties.warranty
	$dellAsset  = $req.getassetwarrantyresponse.getassetwarrantyresult.response.dellasset

	foreach($warranty in $warranties)
	{
		$deviceAge = [datetime]::ParseExact($dellAsset.shipdate,"yyyy-MM-ddTHH:mm:ss",$null)
		$deviceAge = "{0:N2}" -f (([datetime]::now - $deviceAge).days / 365)
                
		$output = New-Object -Type PSCustomObject
		
		Add-Member -MemberType NoteProperty -Name 'ComputerName' -Value $computerName -InputObject $output
		Add-Member -MemberType NoteProperty -Name 'Model' -Value $model -InputObject $output
		Add-Member -MemberType NoteProperty -Name 'ServiceTag' -Value $serviceTag -InputObject $output
		Add-Member -MemberType NoteProperty -Name 'Age' -Value $age -InputObject $output
	
		# Copy properties from the XML data gotten from Dell.
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