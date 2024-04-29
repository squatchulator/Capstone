# Script: config.ps1
# Author: Maxwell Berry & Dylan Navarro
# Description: Used with user_import.ps1. 
# This file contains all the settings needed for the other script. 

$Global:master_config = @{
    general_settings = @{
        search_base = "OU=Members,OU=Generator_Users,DC=generator,DC=local"; 
        use_random_pass = $true;
        password_min_len = 12;
        password_max_len = 17;
        password_symbol_count = 5;
        default_pass = "ChangeMe!1";
        force_change_pass = $false;
        temp_OU = "OU=Staging,OU=Generator_Users,DC=generator,DC=local"; 
        domain = (Get-ADDomain | Select-Object -Property DNSRoot).DNSRoot;
        month_year = Get-Date -Format "MM/yy";
        home_directory_base = "\user-profiles";
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
        disable_users = $false;
        move_users = $false;
        disabled_user_ou = "OU=Disabled-Accounts,OU=Generator_Users,DC=generator,DC=local";
        users_to_exclude = @(  
        );   
        remove_groups = $true;
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
