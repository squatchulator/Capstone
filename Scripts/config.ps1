# Script: config.ps1
# Author: Dylan 'Chromosom3' Navarro
# Last Modified: Paul Gleason (1/27/2023)
# Description: Used with user_import.ps1. 
# This file contains all the settings needed for the other script. 

$Global:master_config = @{
    general_settings = @{
        search_base = "OU=Members,OU=Generator_Users,DC=generator,DC=local";  # The OU the script checks.
        use_random_pass = $true;
        password_min_len = 12;
        password_max_len = 17;
        password_symbol_count = 5;
        default_pass = "ChangeMe!1";  # Only used if $user_random_pass is False.
        force_change_pass = $false;
        temp_OU = "OU=Staging,OU=Generator_Users,DC=generator,DC=local";  # OU to put accounts in temporarily
        domain = (Get-ADDomain | Select-Object -Property DNSRoot).DNSRoot;
        month_year = Get-Date -Format "MM/yy";
        home_directory_base = "\user-profiles"; # DO NOT INCLUDE TRAILING \
        home_directory_letter = "C";
    };
    mail_settings = @{
        send_email = $true;
        mail_from = "support@leahycenter.org";
        mail_subject = "[Generator] Account Creation";
        mail_server = "smtp.gmail.com";
        org_name = "Leahy Center";

    };
    disable_settings = @{
        disable_users = $false;  # Disable all current user accounts 
        move_users = $false;  # Move the newley disabled accounts
        disabled_user_ou = "OU=Disabled-Accounts,OU=Generator_Users,DC=generator,DC=local";  # Where to move the accounts to. move_users needs to be $true.
        # Array of usernames to exclude when disabaling users. Service accounts should go here.
        users_to_exclude = @(  
        );   
        remove_groups = $true;  # Remove user groups when disabling accounts
    };
    group_settings = @{
        template_group = @{
            description = ""; 
            groups_to_add = @("");
            ou_location = "";
            needs_admin = $false;
            admin_ou = "";
            admin_groups = @("");
        };
    # Generator
        # Staff
        Staff = @{
            description = "Staff Account"; 
            groups_to_add = @("Domain Admins", "Domain Users", "Generator Staff", "Protected Users");
            ou_location = "OU=Staff,OU=Generator_Users,DC=generator,DC=local";
            needs_admin = $false;
            admin_ou = "OU=Staff,OU=Generator_Users,DC=generator,DC=local";
            admin_groups = @("Domain Admins", "Domain Users", "Generator Staff", "Protected Users");
        };
        # Member
        Member = @{
            description = "Member Account"; 
            groups_to_add = @("Domain Users");
            ou_location = "OU=Members,OU=Generator_Users,DC=generator,DC=local";
            needs_admin = $false;
            admin_ou = "OU=Members,OU=Generator_Users,DC=generator,DC=local";
            admin_groups = @("Domain Users");
        };
    }
}