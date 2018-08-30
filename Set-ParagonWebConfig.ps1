<#
 .SYNOPSIS
  Checks three XML config files on the Paragon Web Server and corrects them if needed.

 .DESCRIPTION
  This module looks at AppSettings.Config, specifically the AuthorizationCacheExpirationMinutes entry, and sets the value to '1' if it is not '1' already.
  Then it looks at the Config.Xml for the PrintWaterMark value and sets it to 'true' if it is not 'true' already.
  Finally it looks at the Web.Config file for the requireSSL="true" setting and sets it to 'true' if it isn't already.

 .PARAMETER AuthorizationCacheExpirationMinutes
  Specifies the numerical value to be set for the AuthorizationCacheExpirationMinutes Key in the AppSettings.Config file.

 .PARAMETER PrintWaterMark
  Specifies the true or false value to be set for the PrintWaterMark key in the Config.Xml file.

 .PARAMETER RequireSSL
  Specifies the boolean value to be set for the RequireSSL key in the Web.Config file.

 .INPUTS
  None.

 .OUTPUTS
  None.

 .NOTES
  None.

 .EXAMPLE
    Set-ParagonWebConfig

    This command sets the three config files to the default values of '1', 'False', and 'False'.

 .EXAMPLE
    Set-ParagonWebConfig -AuthorizationCacheExpirationMinutes 5 -PrintWaterMark $true -RequireSSL $false

    This command in this example would set the AuthorizationCacheExpirationMinutes parameter to 5 minutes, 

#>

function Set-ParagonWebConfig{

    [CmdletBinding()]
    Param(
        [Parameter(Position=0)]
        [ValidateRange(1,99)]
        [Int]
        $AuthorizationCacheExpirationMinutes = 1,

        [Parameter(Position=1)]
        [bool]
        $PrintWaterMark = $false,

        [Parameter(Position=2)]
        [bool]
        $RequireSSL = $false
        )

    <#-Check AppSettings.Config-#>
    $Path = 'C:\inetpub\wwwroot\PCH\App_Data\Paragon\Config\appSettings.config'
    [xml]$xml_appSettingsconfig = Get-Content $Path
    $xml_AuthCache = $xml_appSettingsconfig.appSettings.add | where {$_.key -eq 'AuthorizationCacheExpirationMinutes'}
    $xml_AuthCacheValue = $xml_AuthCache.value 
    if(!($xml_AuthCacheValue -eq $AuthorizationCacheExpirationMinutes)){
        Write-Verbose "Found that the AuthorizationCacheExpirationMinutes was not set to $AuthorizationCacheExpirationMinutes. It has been changed."
        [string]$output1 = '<add key="AuthorizationCacheExpirationMinutes" value="'+$xml_AuthCacheValue+'"/>'
        [string]$output2 = '<add key="AuthorizationCacheExpirationMinutes" value="'+$AuthorizationCacheExpirationMinutes+'"/>'
        (get-content $Path) -replace "$output1","$output2" | set-content $Path
        }
    else{
        Write-Verbose "Found AuthroizationCacheExpirationMinutes already set to $AuthorizationCacheExpirationMinutes. We're done here."
        }


    <#-Check Config.Xml-#>
    $Path = 'C:\inetpub\wwwroot\Environment\config.xml'
    [xml]$xml_config = Get-Content $Path
    $xml_watermark = $xml_config.config.PrintWaterMark
    $xml_watermarkValue = $xml_watermark.value
    if(!($xml_watermarkValue -eq $PrintWaterMark)){
        Write-Verbose "Found that the PrintWaterMark Value was not set to $PrintWaterMark. It has been changed."
        [string]$output1 = '<PrintWaterMark Value="'+$xml_watermarkValue+'"/>'
        [string]$output2 = '<PrintWaterMark Value="'+$PrintWaterMark+'"/>'
        (get-content $Path) -replace $output1,$output2 | set-content $Path
        }
    else{
        Write-Verbose "Found PrintWaterMark already set to $PrintWaterMark. We're done here."
        }

    <#-Check Web.Config-#>
    $Path = 'C:\inetpub\wwwroot\PCH\web.config'
    [xml]$xml_webconfig = Get-Content $Path
    $xml_requiressl = $xml_webconfig.configuration.'system.web'.httpCookies.requireSSL
    if(!($xml_requiressl -eq $RequireSSL)){
        Write-Verbose "Found that the RequireSSL was not set to false. It has been changed."
        [string]$output1 = 'requireSSL="'+$xml_requiressl+'"'
        [string]$output2 = 'requireSSL="'+$RequireSSL+'"'
        (get-content $Path) -replace $output1,$output2 | set-content $Path
        }
    else{
        Write-Verbose "Found RequireSSL already set to $RequireSSL. We're done here."
        }
}
