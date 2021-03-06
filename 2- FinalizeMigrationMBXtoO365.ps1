#This Script should be executed from the a desktop with the MSOL tools installed#

Write-Host "This Script should be executed from the a desktop with the MSOL tools installed"
Import-Module activedirectory

$path = Get-Location
$csvImport = "C:\Migration\ADUsers.csv"
$csv = Import-Csv $csvImport
$logFolder = "C:\migration\"+(get-date -Format ddmmyy)
New-Item -ItemType Directory -Path $logFolder
$logpath = "C:\Migration\"+(get-date -Format ddmmyy)+"\Office365-MigrationCompletion.txt"

$O365cred = Get-Credential -Message "Cloud Office 365 administrative user" -UserName "plrodrigue@reliancecloud.onmicrosoft.com"
$RelCorpCred = Get-Credential -Message "Reliance.corp administrative user" -UserName "RELIANCE\plrodrigue"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $O365cred -Authentication Basic -AllowRedirection
Import-PSSession $Session

$csv | ForEach-Object {
        $data = Get-MoveRequest $_.PrimarySMTP
        if ($data.Status -like "AutoSuspended"){
            $log = "Mailbox release for user : " + $_.SamAccountName
            Resume-MoveRequest $_.PrimarySMTP
            $User = $_
            Add-ADGroupMember -Server p-rcorp-dc1.reliance.corp -Identity Cloud-O365 -Credential $RelCorpCred -members $_.SamAccountName
            Add-ADGroupMember -Server p-rcorp-dc1.reliance.corp -Identity Cloud-O365-Skype -Credential $RelCorpCred -members $_.SamAccountName
            Add-ADGroupMember -Server p-rcorp-dc1.reliance.corp -Identity Veam_O365_GR_1 -Credential $RelCorpCred -members $_.SamAccountName
           
        }
        else{
            Write-Host "!!The user mailbox " $_.SamAccountName " is not ready to be migrated!!" -ForegroundColor White -BackgroundColor Red
            $log = "!!The user mailbox "+ $_.SamAccountName +" is not ready to be migrated!"+ $data.status
        }

    Add-Content -value $log -path $logpath
}

Read-Host "Press Enter to Exit Script"