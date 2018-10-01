#This Script should be executed from the a desktop with the MSOL tools installed#

Write-Host "This Script should be executed from the a desktop with the MSOL tools installed"

$path = Get-Location
$csvImport = "C:\Migration\ADUsers.csv"
$csv = Import-Csv $csvImport
$logFolder = "C:\migration\"+(get-date -Format ddmmyy)
$logpath = "C:\Migration\"+(get-date -Format ddmmyy)+"\Office365-PreMigration95.txt"
New-Item -ItemType Directory -Path $logFolder

$targetDomain = Read-Host "Select the Exchange Online domain to migrate ? [Default : reliancecloud.onmicrosoft.com] "
if ($targetDomain -like ""){$targetDomain = "reliancecloud.onmicrosoft.com"}
$RemoteHost = Read-Host "Select Exchange default source domain ? [Default : mail3.reliancecomfort.com] " 
if ($RemoteHost -like ""){$RemoteHost = "mail3.reliancecomfort.com"}
$O365cred = Get-Credential -Message "Cloud Office 365 administrative user" -UserName "plrodrigue@reliancecloud.onmicrosoft.com"
$Localcred = Get-Credential -Message "Local Exchange administrative user" -UserName "RELIANCECOMFORT\"

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $O365cred -Authentication Basic -AllowRedirection
Import-PSSession $Session


$csv | ForEach-Object {
    write-host "User migration started for : " $_.SamAccountName
#    New-MoveRequest -Identity $_.SamAccountName -Remote -RemoteHostName $RemoteHost -TargetDeliveryDomain $targetDomain -RemoteCredential $Localcred -BadItemLimit 20 -AcceptLargeDataLoss -SuspendWhenReadyToComplete | Out-Null
    Remove-MoveRequest -Identity $_.SamAccountName -Confirm:$false
	New-MoveRequest -Identity $_.SamAccountName -OutBound -RemoteHostName $RemoteHost -TargetDeliveryDomain $targetDomain -RemoteCredential $Localcred -BadItemLimit 20 -AcceptLargeDataLoss -SuspendWhenReadyToComplete -RemoteTargetDatabase ‘MountPoint3-DB14’
	$log = "User migration started for : " + $_.SamAccountName
    Add-Content -value $log -path $logpath
}

Read-Host "Press Enter to Exit Script"