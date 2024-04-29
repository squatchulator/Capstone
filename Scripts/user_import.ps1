# Generator Version
# Script: user_import.ps1
# Author:  Maxwell 'Maz9' Berry / Dylan Navarro
# Description: Automates the addition of user accounts and the updating of existing accounts. 
. .\config.ps1

Add-Type -AssemblyName System.Web
$user_list_file_path=$args[0]
if ($null -eq $user_list_file_path){
    Write-Host("No CSV file was provided... Using the default user_list.csv")
    $user_list_file_path = "user_list.csv"
}
# Check to see if the CSV file exists
if ((Test-Path $user_list_file_path) -eq $false) {
    Write-Host ("No CSV file found, exitting....")
    Exit
}

if ($($master_config.disable_settings.disable_users)) {
    $current_users = Get-ADUser -Filter * -SearchBase $($master_config.general_settings.search_base)
    foreach ($current_user in $current_users)
    {
        if (!($current_user.SamAccountName -in $($master_config.disable_settings.users_to_exclude))) {
            if($($master_config.disable_settings.move_users)){
                Write-Host ("Moving $($current_user.SamAccountName)")
                Move-ADObject -Identity $current_user.ObjectGUID -TargetPath $($master_config.disable_settings.disabled_user_ou)
            }
            if ($($master_config.disable_settings.remove_groups)) {
                Write-Host("Removing $($current_user.SamAccountName) from groups")
                Get-ADUser -Identity $current_user.ObjectGUID -Properties MemberOf | `
                ForEach-Object {
                    $_.MemberOf | Remove-ADGroupMember -Members $_.ObjectGUID -Confirm:$false
                }
            }
            Write-Host ("Disabling $($current_user.SamAccountName)")
            Disable-ADAccount -Identity $current_user.ObjectGUID
        }
    }
}

function generate_password {
    if ($master_config.general_settings.use_random_pass) {
        $password_len = Get-Random -Minimum $master_config.general_settings.password_min_len -Maximum $master_config.general_settings.password_max_len
        $password_plaintext = [System.Web.Security.Membership]::GeneratePassword($password_len, $master_config.general_settings.password_symbol_count)
    } else {
        $password_plaintext = $master_config.general_settings.default_pass
    }
    $password = ConvertTo-SecureString -String $password_plaintext -AsPlainText -Force
    $passwords = @{plaintext=$password_plaintext; secure=$password}
    return $passwords
}

function send_email {
    param (
        $recipient,
        $email_data_username,
        $email_data_password
    )
    $SMTPClient = New-Object Net.Mail.SmtpClient($master_config.mail_settings.mail_server, 587)
    $SMTPClient.EnableSsl = $true
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential("support@leahycenter.org", "04UWk122phFm")

    if ($master_config.mail_settings.send_email) {
        Write-Host "Sending $email_data_username account credentials email."
        $email_data_body = "Howdy,<br>Your account has been created for Generator. " +
        "For support with your account, please email support@leahycenter.org or call (802)-865-5457<br><br><b>Account Information:</b>" +
        "<br>- Username: $email_data_username<br>- Password: $email_data_password"

        $MailMessage = New-Object System.Net.Mail.MailMessage
        $MailMessage.From = $master_config.mail_settings.mail_from
        $MailMessage.To.Add($recipient)
        $MailMessage.Subject = $master_config.mail_settings.mail_subject
        $MailMessage.Body = $email_data_body
        $MailMessage.IsBodyHtml = $true

        $SMTPClient.Send($MailMessage)
    }
}

function account_update {
    param (
        $user_data,
        $username,
        $admin
    )
    if (!($username -in $($master_config.disable_settings.users_to_exclude))) {
        $user_password = generate_password
        if ($admin) {
            $full_name = $user_data.pfName + " " + $user_data.lName + " Admin"
        } else {
            $full_name = $user_data.pfName + " " + $user_data.lName
        }

        $userPrincipalName = $username + "@" + $($master_config.general_settings.domain)
        If ($username.length -gt 20) {
            $username = $username.ToCharArray(0,20)
            $ofs =''
            $username = [string]$username
        }
        If ($Null -eq (Get-ADUser -Filter 'UserPrincipalName -eq $userPrincipalName' -SearchBase "$($master_config.general_settings.search_base)")) {
            Write-Host("Adding user $userPrincipalName.")
            New-ADUser -ChangePasswordAtLogon $($master_config.general_settings.force_change_pass) -Enabled $True -SamAccountName $username -Name $full_name `
            -UserPrincipalName $userPrincipalName `
            -DisplayName $full_name -Surname $user_data.lName -GivenName $user_data.pfName -EmailAddress $user_data.Email `
            -Office $user_data.Class -Path $($master_config.general_settings.temp_OU) -AccountPassword $($user_password.secure) `
            -HomeDirectory "$($master_config.general_settings.home_directory_base)\$username" -HomeDrive $($master_config.general_settings.home_directory_letter)
        } else {
            Write-Host("Activating user $userPrincipalName.")
            Get-AdUser -Filter 'UserPrincipalName -eq $userPrincipalName' | Enable-ADAccount
            Get-AdUser -Filter 'UserPrincipalName -eq $userPrincipalName' | Set-ADAccountPassword -NewPassword $($user_password.secure)
            Get-AdUser -Filter 'UserPrincipalName -eq $userPrincipalName' | Set-ADUser `
            -HomeDirectory "$($master_config.general_settings.home_directory_base)\$username" -HomeDrive $($master_config.general_settings.home_directory_letter) `
            -Office $user_data.Class
        }
        
        if ($admin){
            foreach ($role in $($master_config.group_settings.$($user_data.Role).admin_groups)){
                Write-Host("Adding $userPrincipalName to $role group.")
                $member = Get-AdUser -Filter 'UserPrincipalName -eq $userPrincipalName'
                Add-ADGroupMember -Identity $role -Members $member
            }
        }else{
            foreach ($role in $($master_config.group_settings.$($user_data.Role).groups_to_add)){
                Write-Host("Adding $userPrincipalName to $role group.")
                $member = Get-AdUser -Filter 'UserPrincipalName -eq $userPrincipalName'
                Add-ADGroupMember -Identity $role -Members $member
            }
        }

        Write-Host("Moving $userPrincipalName to the correct OU.")
        if ($admin) {
            $location = "$($master_config.group_settings.$($user_data.Role).admin_ou)"
        } else {
            $location = "$($master_config.group_settings.$($user_data.Role).ou_location)"
        }
        Get-AdUser -Filter 'UserPrincipalName -eq $userPrincipalName' | Move-ADObject -TargetPath $location
        Get-AdUser -Filter 'UserPrincipalName -eq $userPrincipalName' | Set-ADUser -Description "$($master_config.group_settings.$($user_data.Role).description) - $($master_config.general_settings.month_year)"
        send_email $($user_data.Email) $username $($user_password.plaintext)
    }   
}

$user_list = Import-Csv $user_list_file_path
foreach ($user in $user_list) {
    $account = $user.pfName + "." + $user.lName
    account_update $user $account $false
    if ($($master_config.group_settings.$($user.Role).needs_admin)) {
        $admin_account = $account + "-adm"
        account_update $user $admin_account $true
    }
}
