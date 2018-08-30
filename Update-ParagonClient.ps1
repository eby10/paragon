<#
 .SYNOPSIS
  Checks for Prerequisites and then install several Paragon components

 .DESCRIPTION
  Checks for the following required software:
      - IE 11 (Install Fails if IE 11 is not found)
      - Microsoft .NET 4.5 or higher
      - Microsoft System CLR Types for SQL Server 2012
      - Microsoft Report Viewer 2012
      - Visual Studio 2010 Tools for Office Runtime
      - Microsoft SQL Server 2008 R2 Native Client
  Checks version of the following Paragon software and installs if missing or old:
      - Paragon Client
      - Paragon Reporting
      - Team Notes Form Editor
      - CPOE Reference Masters (Does NOT Install if an old version is not found)

 .PARAMETER environment
    Specifies the environment you want to install. Your options are TEST or LIVE.

 .PARAMETER paragon_version
    Specifies the the version of Paragon you are attempting to install. Needs to be in #.#.# format.

 .PARAMETER software_location
    Specifies path where the required MSI files are located. See the NOTES section of this help for the requiresments of that folder.

 .PARAMETER local_directory
    Specifies which directory will the Paragon Client will be installed?

 .PARAMETER cpoe_refmst_local_dir
    Specifies the local directory to which the CPOE Reference Masters Environment.xml file will be copied.

 .PARAMETER cpoe_refmst
    Specifies that CPOE Reference Masters is to be installed if it isn't already installed

 .PARAMETER update_client
    Copies the additional client files even if the correct version of paragon is already installed.

 .PARAMETER reboot
    Specifies if a reboot should be performed when the script completes.
 
 .PARAMETER show_log
    Specifies if the content of the log file will be displayed when the script completes. If the 'reboot' parameter is specified the 'show_log' parameter will be ignored.

 .INPUTS
    None.

 .OUTPUTS
    None.

 .NOTES
    This script was written and intended for Paragon versions 13.0.3 or 13.0.4.

    INSTRUCTIONS
    1. software_location needs to have the following structure:
          \Current_Installs
              -CPOEReferenceMasters_Setup.msi
              -environments.xml         <---For CPOE Reference Masters
              -paragon.ini              <---For your LIVE Environment
              -ParagonClient_Setup.msi
              -ParagonReports_Setup.msi
              -TeamNotesFormEditorLibrary.msi
              \additional_client_files
                  -*.pbd                <---Place all .pbd files from any supplementals or cherry picks that need installed in this folder.
              \microsoft_prereqs
                  -ReportViewer.msi     <---Microsoft Report Viewer 2012 Install File
                  -sqlncli.msi          <---Microsoft SQL Server 2008 R2 Native Client Install File
                  -SQLSysClrTypes.msi   <---Microsoft System CLR Types for SQL Server 2012 Install File
                  -vstor_redist.exe     <---Visual Studio 2010 Tools for Office Runtime Install File
              \test
                  -paragon.ini          <---For your TEST environment, assuming it is different
 .EXAMPLE
    Update-ParagonClient

 .EXAMPLE
    Update-ParagonClient -Environment TEST -Reboot

 .EXAMPLE 
     Update-ParagonClient -Environment TEST -Paragon_Version 13.0.4 -software_location \\<servername>\<folder name>\current_installs -local_directory 'c:\program files (x86)\paragon1304' -cpoe_refmst_local_dir 'C:\Program Files (x86)\McKesson\Paragon 13.0 CPOE Reference Masters\CPOE\Environment' -show_log

#>



[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=0)]
    [ValidateSet('TEST','LIVE')]
    [String]
    $environment,

    [Parameter(Mandatory=$True,Position=1)]
    [ValidatePattern("[0-9][0-9].[0-9].[0-9]")]
    [string]
    $paragon_version,

    [Parameter(Mandatory=$True,Position=2)]
    [ValidateScript({Test-Path $_})]
    [string]
    $software_location,

    [Parameter(Mandatory=$True,Position=3)]
    [string]
    $local_directory,

    [string]
    $cpoe_refmst_local_dir,

    [string]
    $log_file = "c:\paragon_software_versions.log",

    [switch]
    $cpoe_refmst,

    [switch]
    $update_client,

    [switch]
    $reboot,

    [switch]
    $show_log
    )


<#------------------------------------
|          Declare Functions         |
------------------------------------#>

<#---Check for Microsoft System CLR Types for SQL Server 2012, Install if none---#>
function MS_CLR_SQL_2012 {
    Write-Verbose "Checking if Microsoft System CLR Types for SQL Server 2012 is installed..." 
    $reg_check_MSCLRSQL2012 = Get-ItemProperty HKLM:\software\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Microsoft*CLR*SQL*2012*'} | select -Expand PSChildName
    if ($reg_check_MSCLRSQL2012) {
        Write-Verbose "Microsoft System CLR Types for SQL Server 2012 found. Moving on...`n" 
        }
    else{
        Write-Verbose "Microsoft System CLR Types for SQL Server 2012 NOT found. Installing..." 
        start-process -FilePath msiexec -ArgumentList /i, $software_location\SQLSysClrTypes.msi, /quiet, /norestart -wait
        Write-Verbose "Done.`n" 
        }
        Write-Progress -Activity "Installing..." -PercentComplete 10 -status "Microsoft System CLR Types for SQL Server 2012 is installed. Checking for Microsoft Report Viewer 2012"
        MS_Rpt_Vwr_2012

}

<#---Check for Microsoft Report Viewer 2012, Install if none---#>
function MS_Rpt_Vwr_2012 {
    Write-Verbose "Checking if Microsoft Report Viewer 2012 is installed..."  
    $reg_check_MSRptVwr2012 = Get-ItemProperty HKLM:\software\wow6432node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Microsoft*Report*Viewer*2012*'} | select -Expand PSChildName
    if ($reg_check_MSRptVwr2012) {
        Write-Verbose "Microsoft Report Viewer 2012 found. Moving on...`n" 
        }
    else{
        Write-Verbose "Microsoft Report Viewer 2012 NOT found. Installing..." 
        start-process -FilePath msiexec -ArgumentList /i, $software_location\microsoft_prereqs\ReportViewer.msi, /quiet, /norestart -wait
        Write-Verbose "Done.`n" 
        }
        Write-Progress -Activity "Installing..." -PercentComplete 20 -status "Microsoft Report Viewer 2012 is installed. Checking for Visual Studio 2010 Tools for Office Runtime"
        Vstor_2010

}

<#---Check for Visual Studio 2010 Tools for Office Runtime, Install if none---#>
function Vstor_2010 {
    Write-Verbose "Checking if Visual Studio 2010 Tools for Office Runtime is installed..." 
    $reg_check_vstor2010 = Get-ItemProperty HKLM:\software\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Microsoft*Visual*Studio*2010*Tools*Runtime*'} | select -Last 1 -Expand PSChildName
    if ($reg_check_vstor2010) {
        Write-Verbose "Visual Studio 2010 Tools for Office Runtime found. Moving on...`n" 
        }
    else{
        Write-Verbose "Visual Studio 2010 Tools for Office Runtime NOT found. Installing..." 
        start-process $software_location\microsoft_prereqs\vstor_redist.exe -ArgumentList /q, /norestart -wait
        Write-Verbose "Done.`n" 
        }
        Write-Progress -Activity "Installing..." -PercentComplete 25 "Visual Studio 2010 Tools for Office Runtime install complete. Checking for Microsoft SQL Server 2008 R2 Native Client"

        MSSQL_Native_Client
}

<#---Check for Microsoft SQL Server 2008 R2 Native Client, Install if none---#>
function MSSQL_Native_Client {
    Write-Verbose "Checking if Microsoft SQL Server 2008 R2 Native Client is installed..." 
    $reg_check_SQL_native_clt = Get-ItemProperty HKLM:\software\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Microsoft*SQL*Server*2008*R2*Native*Client*'} | select -Expand PSChildName
    if ($reg_check_SQL_native_clt) {
        Write-Verbose "Microsoft SQL Server 2008 R2 Native Client found. Moving on...`n" 
        }
    else{
        Write-Verbose "Microsoft SQL Server 2008 R2 Native Client NOT found. Installing..." 
        start-process -FilePath msiexec -ArgumentList /i, $software_location\microsoft_prereqs\sqlncli.msi, /quiet, /norestart, IACCEPTSQLNCLILICENSETERMS=YES  -wait
        Write-Verbose "Done.`n" 
        }
        Write-Progress -Activity "Installing..." -PercentComplete 30 "Microsoft SQL Server 2008 R2 Native Client. Checking IE Version"

        OldParagonClientCheck
}

<#---Old Paragon Client Check/Uninstall---#>
Function OldParagonClientCheck{
    Write-Progress -Activity "Installing..." -PercentComplete 35 -Status "Checking Paragon Client Version"
    Write-Verbose "Checking if Pargon Client Software is installed..."
    $reg_check_paragon_client=Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Paragon*Client*'} | select -Expand PSChildName

    if ($reg_check_paragon_client) {
        Write-Verbose "Adding entry to out-file $log_file"
        $out_file_info = Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Paragon*Client*'} | ft DisplayVersion,DisplayName -autosize -HideTableHeaders
        out-file $log_file -InputObject $out_file_info -Append

        Write-Verbose "Getting Current Paragon Client Software Version..."
        $display_version = Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Paragon*Client*'} | select -expand DisplayVersion
        Write-Verbose "Current Version is $display_version"
        if($display_version -eq $paragon_version){
            Write-Verbose "Paragon Client Software is the current version. Moving on...`n"
            if($update_client){
                Write-Verbose "Update_client switch detected. Copying new client files."
                additional_client_files
                }
            Write-Progress -Activity "Installing..." -PercentComplete 50 -Status "Paragon Client Installed. Checking Paragon Reporting Version"
            OldParagonReporting
            }

        else{
            Write-Verbose "Paragon Client Software is an old version. Uninstalling now..."
            start-process -File msiexec -ArgumentList /x, $reg_check_paragon_client, /quiet -wait
            Write-Verbose "Uninstall Complete.`n"
            Write-Progress -Activity "Installing..." -PercentComplete 40 -Status "Old Paragon Client Uninstalled. Installing New Paragon Client"
            ParagonClientInstall
            }
        }
     
    else{
        Write-Verbose "Paragon Client Not Installed. Installing Now..."
        Write-Verbose "Adding line to $log_file"
        out-file $log_file -InputObject "NONE          Paragon Client Software" -Append
        Write-Progress -Activity "Installing..." -PercentComplete 40 -Status "Paragon Client Not Installed. Installing Now..."
        ParagonClientInstall
        }
        
}

<#--- Paragon Client Install ---#>

function ParagonClientInstall{
    Write-Verbose "Removing old ParagonClient_Setup.msi file."
    Remove-item C:\ParagonClient_Setup.msi -ErrorAction SilentlyContinue

    Write-Verbose "Copying Paragon Client installer file to local directory..." 
    Copy -Path "$software_location\ParagonClient_Setup.msi" -Destination C:\
    
    Write-Verbose "Copy complete. Starting install of Paragon Client..." 
    start-process -FilePath msiexec -ArgumentList /i, c:\ParagonClient_Setup.msi, ADDLOCAL=ALL, KEY_AC=4f2, KEY_CC=lz9, KEY_ED=qv4, KEY_FA=3i8, KEY_LB=a16, KEY_MA=b0o, KEY_MM=2a1, KEY_MT=j8c, KEY_OR=i7k, KEY_PR=9s1, KEY_RD=22y, KEY_RS=1ep, KEY_RX=h0m, KEY_RI=9uz, /quiet , /norestart -wait
    
    <#-Paragon.ini Copy-#>
    Write-Progress -Activity "Installing..." -PercentComplete 20 -Status "Paragon Client installed. Copying Needed Files"
    Write-Verbose "Copying Paragon.ini to local directory."    

    if($environment -eq 'LIVE'){
        Copy -Path "$software_location\paragon.ini" -Destination $local_directory
        }
    else{
        Copy -Path "$software_location\test\paragon.ini" -Destination $local_directory
        }

    Write-Verbose "Paragon.ini Copy Complete."

    <#-Call Additional_client_files Function-#>
    additional_client_files

    <#-ParagonCom.dll Register-#>
    
    Write-Verbose "Registering ParagonCOM.dll" 
    Start-Process C:\Windows\Microsoft.NET\Framework\v4.0.30319\RegAsm.exe  "$local_directory\ParagonCOM.dll" -wait
    Write-Verbose "Registration of ParagonCOM.dll Complete."
    
    Write-Verbose "Paragon Client Install complete.`n" 
    
    Write-Verbose "Cleaning up Paragon_Client_Setup.msi from C:\"
    Remove-item C:\ParagonClient_Setup.msi -ErrorAction SilentlyContinue
    Write-Verbose "Done"

    Write-Progress -Activity "Installing..." -PercentComplete 50 -Status "Paragon Client Installed. Checking Paragon Reporting Version"
    OldParagonReporting
}
<#---Function to install additional client files from Paragon Cherry-Picks and supplementals---#>
function additional_client_files{
    Write-Verbose "Copying additional client files..." 
    Copy -Path "$software_location\additional_client_files\*" -Destination $local_directory
    Write-Verbose "Additional file copy complete."
}

<#---Old Paragon Reporting Check/Uninstall---#>
function OldParagonReporting{
    Write-Verbose "Checking if Old Paragon Reporting is installed..." 
    $reg_check_paragon_reporting = Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Paragon*Report*'} | select -Expand PSChildName 
    if ($reg_check_paragon_reporting) {
        Write-Verbose "Adding entry to out-file $log_file"
        $out_file_info=Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Paragon*Report*'} | ft DisplayVersion,DisplayName -autosize -HideTableHeaders
        out-file $log_file -InputObject $out_file_info -append

        Write-Verbose "Getting Current Paragon Reporting Version..."
        $display_version = Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Paragon*Report*'} | select -expand DisplayVersion
        Write-Verbose "Current Version is $display_version"
        if($display_version -eq $paragon_version){
            Write-Verbose "Paragon Reporting is the current version. Moving on...`n" 
            Write-Progress -Activity "Installing..." -PercentComplete 70 "Paragon Reporting is the current version. Checking TeamNotesFormEditor version"
            OldTNFE
            }

        else{
            Write-Verbose "Paragon Reporting is an old version. Uninstalling now..." 
            start-process -File msiexec -ArgumentList /x, $reg_check_paragon_reporting, /quiet -wait
            Write-Verbose "Uninstall Complete." 
            Write-Progress -Activity "Installing..." -PercentComplete 60 -Status "Old Paragon Reporting Uninstalled. Installing New Paragon Reporting"
            ParagonReportingInstall
            }
        }
     
    else{
        Write-Verbose "Paragon Reporting Not Installed. Installing Now..." 
        Write-Verbose "Adding line to $log_file"
        out-file $log_file -InputObject "NONE          Paragon Reports" -Append
        Write-Progress -Activity "Installing..." -PercentComplete 60 -Status "Paragon Reporting Not Installed. Installing Now..."
        ParagonReportingInstall
        }
        
}

<#---Paragon Reporting Install---#>
function ParagonReportingInstall {
    start-process -FilePath msiexec -ArgumentList /i, $software_location\ParagonReports_Setup.msi, /norestart, /quiet -wait
    Write-Verbose "Paragon Reports Install Complete.`n" 
    Write-Progress -Activity "Installing..." -PercentComplete 70 -Status "Paragon Reporting is now the current version. Checking TeamNotesFormEditor version"
    OldTNFE
}

<#---TeamNotesFormEditor Check/Uninstall---#>
function OldTNFE{
    Write-Verbose "Checking for TeamNotesFormEditor (TNFE)..." 
    $reg_check_TNFE = Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Team*Note*'} | select -Expand PSChildName
    if ($reg_check_TNFE) {
        Write-Verbose "Adding entry to out-file $log_file"
        $out_file_info=Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Team*Note*'} | ft DisplayVersion,DisplayName -autosize -HideTableHeaders
        out-file $log_file -InputObject $out_file_info -append

        Write-Verbose "Getting Current TNFE Version..."
        $display_version = Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Team*Note*'} | select -expand DisplayVersion
        Write-Verbose "Current Version is $display_version"
        if($display_version -eq $paragon_version){
            Write-Verbose "TNFE is the current version. Moving on...`n" 
            Write-Progress -Activity "Installing..." -PercentComplete 80 -Status "TeamNotesFormEditor is the current version. Checking for CPOE Reference Masters."
            oldCPOERefMasters
            }

        else{
            Write-Verbose "Uninstalling Old TNFE now..." 
            start-process -File msiexec -ArgumentList /x, $reg_check_TNFE, /q -wait
            Write-Verbose "Uninstall complete. Installing new version now.." 
            Write-Progress -Activity "Installing..." -PercentComplete 75 -status "Old TNFE Uninstalled. Installing new version now"
            TNFEInstall
            }
        }

    else{
        Write-Verbose "TNFE is not installed. Installing Now..." 
        Write-Verbose "Adding line to $log_file"
        out-file $log_file -InputObject "NONE          TeamNotesFormEditorLibrary38" -Append
        Write-Progress -Activity "Installing..." -PercentComplete 75 -status "TNFE not installed. Installing current version now"
        TNFEInstall
        }

}

<#---TeamNotesFormEditor Install---#>
function TNFEInstall{
    start-process -FilePath msiexec -ArgumentList /i, $software_location\TeamNotesFormEditorLibrary.msi, /quiet -wait
    Write-Verbose "TNFE Install Complete.`n" 
    Write-Progress -Activity "Installing..." -PercentComplete 85 -Status "TeamNotesFormEditor is the current version. Checking for CPOE Reference Masters."
    oldCPOERefMasters
}

<#---Old CPOE Reference Masters Check/Uninstall---#>
function oldCPOERefMasters{
        Write-Verbose "Checking for CPOE Reference Masters" 
        $reg_check_CPOERefMasters = Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Paragon*CPOE*Reference*Masters*'} | select -Expand PSChildName
        if ($reg_check_CPOERefMasters) {
            Write-Verbose "Adding entry to out-file $log_file"
            $out_file_info=Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Paragon*CPOE*Reference*Masters*'} | ft DisplayVersion,DisplayName -autosize -HideTableHeaders
            out-file $log_file -InputObject $out_file_info -append

            Write-Verbose "Getting Current CPOE Reference Masters Version..."
            $display_version = Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Paragon*CPOE*Reference*Masters*'} | select -expand DisplayVersion
            Write-Verbose "Current Version is $display_version"
            if($display_version -eq $paragon_version){
                Write-Verbose "CPOE Reference Masters is the current version. Moving on...`n" 
                Write-Progress -Activity "Installing..." -PercentComplete 95 -Status "CPOE Reference Masters is the current version. Gathering information..."
                currentsoftwareinstalled
                }

            else{
                Write-Verbose "Uninstalling Old CPOE Reference Masters now..." 
                start-process -File msiexec -ArgumentList /x, $reg_check_CPOERefMasters, /q -wait
                Write-Verbose "Uninstall complete. Installing new version now.." 
                Write-Progress -Activity "Installing..." -PercentComplete 90 -status "Old CPOE Reference Masters Uninstalled. Installing new version now"
                CPOERefMastersInstall
                }
            }

        elseif($cpoe_refmst){
            Write-Verbose "CPOE Reference Masters Switch Detected."
            CPOERefMastersInstall
            }

        else{
            Write-Verbose "CPOE Reference Masters is not installed. Moving on..." 
            Write-Verbose "Adding line to $log_file"
            out-file $log_file -InputObject "NONE          CPOE Reference Masters" -Append
            Write-Progress -Activity "Installing..." -PercentComplete 90 -status "CPOE Reference Masters not need on this computer. Gathering information..."
            currentsoftwareinstalled
            }
        #}

}

<#---CPOE Reference Masters Install---#>
function CPOERefMastersInstall{
    Start-Process -FilePath msiexec -ArgumentList /i, $software_location\CPOEReferenceMasters_Setup.msi, /quiet, /norestart -wait
    Write-Verbose "CPOE Reference Masters Install Complete.`n"
    Write-Verbose "Copying environments.xml..."
    Copy -Path "$software_location\environments.xml" -Destination $cpoe_refmst_local_dir
    Write-Verbose "Environments.xml copy complete."
    Write-Progress -Activity "Installing..." -PercentComplete 95 -Status "TeamNotesFormEditor is the current version. Gathering information..."
    currentsoftwareinstalled
}




<#---Gather Current Software and the corresponding version---#>

function currentsoftwareinstalled{
    Out-file $log_file -InputObject "==========================================================================" -Append
    Out-file $log_file -InputObject "`n\\\CURRENTLY INSTALLED SOFTWARE///`n" -Append
    Out-file $log_file -InputObject "DisplayVersion DisplayName`n-------------- -----------" -Append

    Write-Verbose "Getting Current Software version of Paragon Client..."
    $out_file_info=Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Paragon*Client*'} | ft DisplayVersion,DisplayName -autosize -HideTableHeaders
    out-file $log_file -InputObject $out_file_info -Append

    Write-Verbose "Getting Current Software version of Paragon Reports..."
    $out_file_info=Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Paragon*Report*'} | ft DisplayVersion,DisplayName -autosize -HideTableHeaders
    out-file $log_file -InputObject $out_file_info -append
    
    Write-Verbose "Getting Current Software version of TNFE..."
    $out_file_info=Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Team*Note*'} | ft DisplayVersion,DisplayName -autosize -HideTableHeaders
    out-file $log_file -InputObject $out_file_info -append
    
    Write-Verbose "Getting Current Software version of CPOE Reference Masters..."
    $out_file_info=Get-ItemProperty HKLM:\software\WOW6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Paragon*CPOE*Reference*Masters*'} | ft DisplayVersion,DisplayName -autosize -HideTableHeaders
    out-file $log_file -InputObject $out_file_info -append

    Write-Verbose "Getting Current Software version of Microsoft System CLR Types for SQL Server 2012..."
    $out_file_info=Get-ItemProperty HKLM:\software\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Microsoft*CLR*SQL*2012*'} | ft DisplayVersion,DisplayName -autosize -HideTableHeaders
    out-file $log_file -InputObject $out_file_info -append

    Write-Verbose "Getting Current Software version of Microsoft Report Viewer 2012..."
    $out_file_info=Get-ItemProperty HKLM:\software\Wow6432Node\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Microsoft*Report*Viewer*2012*'} | ft DisplayVersion,DisplayName -autosize -HideTableHeaders
    out-file $log_file -InputObject $out_file_info -append

    Write-Verbose "Getting Current Software version of Visual Studio 2010 Tools for Office Runtime..."
    $out_file_info=Get-ItemProperty HKLM:\software\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Microsoft*Visual*Studio*2010*Tools*Runtime*'} | ft DisplayVersion,DisplayName -autosize -HideTableHeaders
    out-file $log_file -InputObject $out_file_info -append

    Write-Verbose "Getting Current Software version of Microsoft SQL Server 2008 R2 Native Client..."
    $out_file_info=Get-ItemProperty HKLM:\software\microsoft\windows\currentversion\uninstall\* | Where {$_.DisplayName -like '*Microsoft*SQL*Server*2008*R2*Native*Client*'} | ft DisplayVersion,DisplayName -autosize -HideTableHeaders
    out-file $log_file -InputObject $out_file_info -append

    Write-Verbose "Getting Current Software version of Internet Explorer..."
    $reg_ieversion = $ieversion = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Internet Explorer' | Select -expand SVCVersion -ErrorAction SilentlyContinue
    if ($reg_ieversion){
        if($reg_ieversion -like '11.*'){
            out-file $log_file -InputObject "11             Internet Explorer`n" -append
        }
        else{
            out-file $log_file -InputObject "Unknown        Internet Explorer`n" -append 
        }
    }

    <#---Complete the log file and display it---#>

    Write-Verbose "Getting Current Software version of Microsoft .NET..."
    Out-File $log_file -InputObject         "$latest_MS_NET_version            Microsoft .NET`n" -append

    Out-file $log_file -InputObject "##########################################################################" -Append

    Write-Progress -Activity "Installing..." -Complete -status "Installation Complete."


    <#---Reboot if requested or else display the contents of the log file---#>

    if($reboot){
        Restart-Computer -Force
        }
    if($show_log){
        Get-Content $log_file
        }
    else{
        Write-Host "Upgrade Complete"
        }
        
}

<#################
#   START HERE   #
#################>

<#----------------------------------------------------------------
|                 Creating the Install Log File                  |
----------------------------------------------------------------#>

$check_log_path=Test-Path $log_file
if(!($check_log_path)){
    try{
        $writetest = [IO.FILE]::OpenWrite($log_file)
        $writetest.close()
        }
    catch{ 
        Write-Host "Unable to write to log file. Check permissions or change location." -BackgroundColor Yellow -ForegroundColor Black
        Throw
        }
    }
   

Out-file $log_file -InputObject "##########################################################################"
$date_var = Get-Date -Format g 
Out-File $log_file -InputObject "Date: $date_var" -Append
Out-File $log_file -InputObject $env:COMPUTERNAME -Append
Out-file $log_file -InputObject "`n///PREVIOUSLY INSTALLED SOFTWARE\\\`n" -Append
Out-file $log_file -InputObject "DisplayVersion DisplayName`n-------------- -----------" -Append

<#---------------------------------------------------------------
|                Check for Required Programs                    |
---------------------------------------------------------------#>

Write-Verbose "Checking for required programs..."
<#---IE 11 Check---#>
Write-Verbose "Checking for IE 11..."
$reg_ieversion = $ieversion = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Internet Explorer' | Select -expand SVCVersion -ErrorAction SilentlyContinue
    if ($reg_ieversion){
        if($reg_ieversion -like '11.*'){
        Write-Verbose "IE 11 detected. Moving on..."
        }
        else{
            out-file $log_file -InputObject "Unknown        Internet Explorer" -append
            Throw "Internet Explorer 11 is not detected. Install IE 11 and retry script"
            }
    }
    
<#---MS .NET Version Check---#>
<# This section of code was taken from http://stackoverflow.com/questions/3487265/powershell-script-to-return-versions-of-net-framework-on-a-machine, written by user Jaykul. The last three pipes were additions I made.#>
Write-Verbose "Checking for .NET 4.5 or higher..."
$latest_MS_NET_version = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse | Get-ItemProperty -name Version,Release -EA 0 | Where { $_.PSChildName -match '^(?!S)\p{L}'} | 
    Select PSChildName, Version, Release, @{
      name="Product"
      expression={
          switch -regex ($_.Release) {
            {$_ -eq $null} { "Error" }
            {$_ -lt 378389} { "Version Less Than 4.5. please install 4.5 or higher" }
            "378389" { "4.5" }
            "378675|378758" { "4.5.1" }
            "379893" { "4.5.2" }
            "393295|393297" { "4.6" }
            "394254|394271" { "4.6.1" }
            "394802|394806" { "4.6.2" }
            {$_ -gt 394806} { "Undocumented 4.6.2 or higher, please update script" }
          }
        }
    } |
    sort version |
    select -last 1 |
    select -expand Product

if($latest_MS_NET_version -eq "Error"){
    Throw "No version of .NET is installed. Please install and then re-run this script"
    }
    elseif($latest_MS_NET_version -eq "4.5" -or $latest_MS_NET_version -eq "4.5.1" -or $latest_MS_NET_version -eq "4.5.2" -or $latest_MS_NET_version -eq "4.6" -or $latest_MS_NET_version -eq "4.6.1" -or $latest_MS_NET_version -eq "4.6.2"){
	write-verbose ".NET version $latest_MS_NET_version detected. Moving on..."
	}
	else{
	Out-File $log_file -InputObject "`n!!!!!!!!!!!!!!!!!!!!!!!!!!!`nMISSING .NET 4.5 OR HIGHER`n!!!!!!!!!!!!!!!!!!!!!!!!!!!`n" -Append
	}

MS_CLR_SQL_2012
