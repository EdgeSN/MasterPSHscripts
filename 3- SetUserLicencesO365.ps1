#This Script should be executed from the a desktop with the MSOL tools installed#

Write-Host "This Script should be executed from the a desktop with the MSOL tools installed"

$path = Get-Location
$csvImport = "C:\Migration\ADUsers.csv"
$csv = Import-Csv $csvImport
$logFolder = "C:\migration\"+(get-date -Format ddmmyy)
New-Item -ItemType Directory -Path $logFolder
$logpath = "C:\Migration\"+(get-date -Format ddmmyy)+"\Office365-UserConfiguration.txt"
$log = @()

$O365cred = Get-Credential -Message "Cloud Office 365 administrative user" -UserName "plrodrigue@reliancecloud.onmicrosoft.com"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $O365cred -Authentication Basic -AllowRedirection
Import-PSSession $Session


#Connecting to Office365 AD
Connect-MsolService -Credential $O365cred

$csv | ForEach-Object {
    $log = "*******************************************`n"
    $log += "Settings configuration for user : " + $_.SamAccountName + "`n"
    $data = Get-User $_.PrimarySMTP | select UserPrincipalName,DisplayName

    Set-MsolUser -UserPrincipalName $data.userprincipalname -UsageLocation "CA"
    if($_.License -like "F1"){
        $x = New-MsolLicenseOptions -AccountSkuId "reliancecloud:DESKLESSPACK" -DisabledPlans "BPOS_S_TODO_FIRSTLINE","FORMS_PLAN_K","STREAM_O365_K","FLOW_O365_S1","POWERAPPS_O365_S1","TEAMS1","Deskless","MCOIMP","SHAREPOINTWAC","SWAY","INTUNE_O365","SHAREPOINTDESKLESS"
        Set-MsolUserLicense -UserPrincipalName $data.UserPrincipalName -AddLicenses "reliancecloud:DESKLESSPACK" -LicenseOptions $x
        $log += "License reliancecloud:DESKLESSPACK added for :" + $data.userprincipalname + "`n"
        Set-Mailbox -Identity $data.UserPrincipalName -RetentionPolicy "F1 Reliance Delete Policy"
	    $log += "2 years Retention policy applied for user : " + $_.SamAccountName + "`n"
        $log += "*******************************************`n"
        $log = $log -split "`n"
        Invoke-Expression "C:\migration\EnableRemoteArchive.ps1 -Identity $data.UserPrincipalName"
    }
    elseif($_.License -like "E3") {
        $x = New-MsolLicenseOptions -AccountSkuId "reliancecloud:ENTERPRISEPACK" -DisabledPlans "BPOS_S_TODO_2","FORMS_PLAN_E3","FLOW_O365_P2","Deskless","FLOW_O365_P2","POWERAPPS_O365_P2","TEAMS1","PROJECTWORKMANAGEMENT","SWAY","INTUNE_O365","RMS_S_ENTERPRISE","YAMER_ENTERPRISE","SHAREPOINTWAC","SHAREPOINTENTERPRISE"
        Set-MsolUserLicense -UserPrincipalName $data.UserPrincipalName -AddLicenses "reliancecloud:ENTERPRISEPACK" -LicenseOptions $x
        $log += "License reliancecloud:ENTERPRISEPACK added for : " + $data.userprincipalname + "`n"
        Set-Mailbox -Identity $data.UserPrincipalName -RetentionPolicy "Enterprise Reliance Archive Policy"
	    $log += "2 years Retention policy applied for user : " + $_.SamAccountName + "`n"
        $log += "*******************************************`n"
        Invoke-Expression "C:\migration\EnableRemoteArchive.ps1 -Identity $data.UserPrincipalName"
    }
    elseif($_.License -like "Shared") {
        Set-Mailbox $data.userprincipalname -Type Shared
    }
    Set-MailboxRegionalConfiguration -Identity $data.UserPrincipalName -Language en-CA -LocalizeDefaultFolderName -TimeZone "Eastern Standard Time" 
    $log += "Regional configuration for user : " + $_.SamAccountName + "`n"
    $log = $log -split "`n"
    
    Set-CASMailbox -ActiveSyncEnabled $false -Identity $data.UserPrincipalName
    $log += "Disabling Exchange Active Sync for user : " + $_.SamAccountName + "`n"
    $log = $log -split "`n"

    Add-Content -value $log -path $logpath
	
}



Invoke-Expression -Command "Get-Mailbox -identity dsuciu" 

Read-Host "Press Enter to Exit Script"