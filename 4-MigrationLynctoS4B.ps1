#This Script should be executed from the server p-lyncfe01.reliancecomfort.com#

Write-Host "This Script should be executed from the server p-lyncfe01.reliancecomfort.com"

$path = Get-Location
$csvImport = "C:\Migration\ADUsers.csv"
$csv = Import-Csv $csvImport
$logFolder = "C:\migration\"+(get-date -Format ddmmyy)
New-Item -ItemType Directory -Path $logFolder
$logpath = "C:\Migration\"+(get-date -Format ddmmyy)+"\Office365-UserConfiguration.txt"
$logpath = "C:\Migration\"+(get-date -Format ddmmyy)+"\Office365-SkypeMigration.txt"

$O365cred = Get-Credential -Message "Cloud Office 365 administrative user" -UserName "plrodrigue@reliancecloud.onmicrosoft.com"

$csv | ForEach-Object {
       $log = "Mailbox release for user : " + $_.SamAccountName
       Move-CsUser $_.SamAccountName -Target sipfed.online.lync.com -Credential $O365cred -Confirm:$false
 }

 Read-Host "Press Enter to Exit Script"