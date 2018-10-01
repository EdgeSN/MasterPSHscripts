$O365cred = Get-Credential #office365 credentials
Import-Module activedirectory
$ADusers = Get-ADUser -properties * -filter * | select SamAccountName,DisplayName,userprincipalname,mail,sn,givenname,targetaddress,distinguishedName
Connect-MsolService -Credential $O365cred

#Creation de la nouvelle liste utilisateur
$MasterADusers = New-Object system.Data.DataTable "ADUsers"
$colTomigrate = New-Object system.Data.DataColumn colTomigrate,([string])
$colSamAccountName = New-Object system.Data.DataColumn SamAccountName,([string])
$colDisplayName = New-Object system.Data.DataColumn DisplayName,([string])
$coluserprincipalname = New-Object system.Data.DataColumn userprincipalname,([string])
$colmail = New-Object system.Data.DataColumn mail,([string])
$colsn = New-Object system.Data.DataColumn sn,([string])
$colgivenname = New-Object system.Data.DataColumn givenname,([string])
$coltargetaddress = New-Object system.Data.DataColumn targetaddress,([string])
$coldistinguishedName = New-Object system.Data.DataColumn distinguishedName,([string])
$colADOU = New-Object system.Data.DataColumn colADOU,([string])
$colUPNMAIL = New-Object system.Data.DataColumn UPNMAIL,([string])
$colO36SignInName = New-Object system.Data.DataColumn O36SignInName,([string])
$MasterADusers.columns.add($colTomigrate)
$MasterADusers.columns.add($colSamAccountName)
$MasterADusers.columns.add($colDisplayName)
$MasterADusers.columns.add($coluserprincipalname)
$MasterADusers.columns.add($colUPNMAIL)
$MasterADusers.columns.add($colO36SignInName)
$MasterADusers.columns.add($colmail)
$MasterADusers.columns.add($colsn)
$MasterADusers.columns.add($colgivenname)
$MasterADusers.columns.add($colADOU)
$MasterADusers.columns.add($coltargetaddress)
$MasterADusers.columns.add($coldistinguishedName)

foreach ($ADuser in $ADusers){
    $row = $MasterADusers.NewRow()
    #Adding ADuser to list of users
    $row.$colSamAccountName = $ADuser.SamAccountName
    $row.$colDisplayName = $ADuser.DisplayName
    $row.$coluserprincipalname = $ADuser.userprincipalname
    $row.$colsn = $ADuser.sn
    $row.$colmail = $ADuser.mail
    $row.$colgivenname = $ADuser.givenname
    $row.$coltargetaddress = $ADuser.targetaddress
    $row.$coldistinguishedName = $ADuser.distinguishedName

    #Finding Organizational Unit
    Try{
        $FirstOU = $ADuser.distinguishedName.IndexOF("OU")
        $newDN = $ADuser.distinguishedName.Substring($FirstOU)
        $row.$colADOU = $newDN
    }
    catch{
        $row.$colADOU = "service account"
    }
    #Finding if user is already migrated
        try {
            $suffixtargetAddress = $ADuser.targetaddress.IndexOF("@")
            $emailSuffix = $ADuser.targetaddress.Substring($suffixtargetAddress)

            If ($emailSuffix -like "@reliancecloud.mail.onmicrosoft.com"){$row.$colTomigrate = "MIGRATED"}
            Else {$row.$colTomigrate = "On_Premises"}
        }
        catch{
           $row.$colTomigrate = "On_Premises" 
        }
    
    #UPN vs Email validation
    If ($ADuser.UserPrincipalName -like $ADuser.Mail){
        $row.$colUPNMAIL = "IDENTICAL"
    }
    Else {
        $row.$colUPNMAIL = "DIFFERENT"
    }
    
    #Office 365 SignInName validation
    $badUPN = $ADuser.SamAccountName+"@reliancecloud.onmicrosoft.com"
    try {
        Get-MsolUser -UserPrincipalName $ADuser.mail -ErrorAction SilentlyContinue
        $row.$colO36SignInName = "IDENTICAL"
    }
    catch {
        $row.$colO36SignInName = "Not Found in O365"
        If ($ADuser.mail -like "") {$row.$colmail = "NO MAILBOX ASSIGNED"}
    }
    $MasterADusers.Rows.Add($row)
}

$tabCsv = $MasterADusers | export-csv ".\MasterADusers.csv" -noType