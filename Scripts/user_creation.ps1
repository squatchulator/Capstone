# Script: user_import.ps1
# Author: Dylan 'Chromosom3' Navarro / Maxwell 'Maz9' Berry / Miles 'Squatch' Cummings
# Description: Automates the addition of user accounts and the updating of existing accounts.

# Import master config hash table
. .\config.ps1

# Function to interactively prompt for user information
function Get-UserData {
    $userData = @{
        Name = Read-Host "Enter full name"
        pfName = Read-Host "Enter first name"
        lName = Read-Host "Enter last name"
        Role = Read-Host "Enter role (e.g., Staff, Member)"
        Email = Read-Host "Enter email address"
    }
    return $userData
}

# Requirment needed to generate a random password.
Add-Type -AssemblyName System.Web

# Function to generate a password for user accounts
function Generate-Password {
    if ($master_config.general_settings.use_random_pass) {
        $password_len = Get-Random -Minimum $master_config.general_settings.password_min_len -Maximum $master_config.general_settings.password_max_len
        $password_plaintext = [System.Web.Security.Membership]::GeneratePassword($password_len, $master_config.general_settings.password_symbol_count)
    } else {
        $password_plaintext = $master_config.general_settings.default_pass
    }
    $password = ConvertTo-SecureString -String $password_plaintext -AsPlainText -Force
    $passwords = @{plaintext = $password_plaintext; secure = $password}
    return $passwords
}

# Function to send email
function Send-Email {
    param (
        $recipient,
        $email_data_username,
        $email_data_password
    )
    $SMTPClient = New-Object Net.Mail.SmtpClient($master_config.mail_settings.mail_server, 587)
    $SMTPClient.EnableSsl = $true
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential("support@leahycenter.org", "04UWk122phFm")

    if ($master_config.mail_settings.send_email) {
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

# Function to update the user account
function Update-Account {
    param (
        $user_data,
        $username,
        $admin
    )
    if (!($username -in $($master_config.disable_settings.users_to_exclude))) {
        $user_password = Generate-Password
        if ($admin) {
            $full_name = $user_data.pfName + " " + $user_data.lName + " Admin"
        } else {
            $full_name = $user_data.pfName + " " + $user_data.lName
        }

        $userPrincipalName = $username + "@" + $($master_config.general_settings.domain)
        
        # Check if the user already exists
        $userExists = Get-ADUser -Filter "UserPrincipalName -eq '$userPrincipalName'" -SearchBase $master_config.general_settings.search_base
        
        if ($null -eq $userExists) {
            # User doesn't exist, create new account
            Write-Host("Adding user $userPrincipalName.")
            New-ADUser -ChangePasswordAtLogon $($master_config.general_settings.force_change_pass) -Enabled $True -SamAccountName $username -Name $full_name `
            -UserPrincipalName $userPrincipalName `
            -DisplayName $full_name -Surname $user_data.lName -GivenName $user_data.pfName -EmailAddress $user_data.Email `
            -Path $($master_config.general_settings.temp_OU) -AccountPassword $($user_password.secure) `
            -HomeDirectory "$($master_config.general_settings.home_directory_base)\$username" -HomeDrive $($master_config.general_settings.home_directory_letter)

            # Add user to groups
            if ($admin){
                foreach ($role in $($master_config.group_settings.$($user_data.Role).admin_groups)){
                    Write-Host("Adding $userPrincipalName to $role group.")
                    $member = Get-AdUser -Filter "UserPrincipalName -eq '$userPrincipalName'"
                    Add-ADGroupMember -Identity $role -Members $member
                }
            }else{
                foreach ($role in $($master_config.group_settings.$($user_data.Role).groups_to_add)){
                    Write-Host("Adding $userPrincipalName to $role group.")
                    $member = Get-AdUser -Filter "UserPrincipalName -eq '$userPrincipalName'"
                    Add-ADGroupMember -Identity $role -Members $member
                }
            }

            Write-Host("Moving $userPrincipalName to the correct OU.")
            if ($admin) {
                $location = "$($master_config.group_settings.$($user_data.Role).admin_ou)"
            } else {
                $location = "$($master_config.group_settings.$($user_data.Role).ou_location)"
            }
            # Move user to the correct OU and set account description. 
            Get-AdUser -Filter "UserPrincipalName -eq '$userPrincipalName'" | Move-ADObject -TargetPath $location
            Get-AdUser -Filter "UserPrincipalName -eq '$userPrincipalName'" | Set-ADUser -Description "$($master_config.group_settings.$($user_data.Role).description) - $($master_config.general_settings.month_year)"

            Send-Email $($user_data.Email) $username $($user_password.plaintext)
        } else {
            # User already exists, log a message
            Write-Host("User $userPrincipalName already exists. Skipping account creation.")
        }
    }   
}

# Main script logic
function Main {
    $user_data = Get-UserData
    $account = $user_data.pfName + "." + $user_data.lName
    Update-Account $user_data $account $false
    if ($($master_config.group_settings.$($user_data.Role).needs_admin)) {
        $admin_account = $account + "-adm"
        Update-Account $user_data $admin_account $true
    }
}

# Call the Main function
Main
