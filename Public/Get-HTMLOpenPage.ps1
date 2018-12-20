Function Get-HTMLOpenPage {
    <#
	.SYNOPSIS
		Get's HTML for the header of the HTML report
    .PARAMETER TitleText
		The title of the report
	.PARAMETER CSSLocation
		Directory containing CSS files. used in conjuction with CSSName
	.PARAMETER CSSName
		If only used with CSSLocation path will search for CSS file with CSSName, otherwise the CSSName can refernce one of the three built in templates.
        This function will Append .css extension
#>
    [alias('Get-HTMLPageOpen')]
    [CmdletBinding(DefaultParameterSetName = 'options')]
    param
    (
        [Parameter(Mandatory = $false, ParameterSetName = 'options')]
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][String]$TitleText,
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][String]$CSSPath,
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][String]$CSSName = "default",
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][String]$ScriptPath,
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][String]$ColorSchemePath,
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][String]$LogoPath,
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][string]$LeftLogoName = "Sample",
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][string]$RightLogoName = "Alternate",
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][string]$LeftLogoString,
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][string]$RightLogoString,

        [Parameter(Mandatory = $false, ParameterSetName = 'options')]
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][switch]$HideLogos,

        [Parameter(Mandatory = $false, ParameterSetName = 'options')]
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][switch]$HideTitle,

        [Parameter(Mandatory = $false, ParameterSetName = 'options')]
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][switch]$NoScript,

        [Parameter(Mandatory = $false, ParameterSetName = 'options')][PSobject]$Options,
        [Parameter(Mandatory = $false, ParameterSetName = 'explicit')][string]$PrimaryColorHex,

        [switch] $AddAuthor,
        [string] $Author,
        [switch] $HideDate,
        [string] $DateFormat = 'yyyy-MM-dd HH:mm:ss',
        [switch] $UseCssLinks,
        [switch] $UseStyleLinks
    )

    [string] $CurrentDate = (Get-Date).ToString($DateFormat) #Get-Date #-format "MMM d, yyyy hh:mm tt"

    if ($PSCmdlet.ParameterSetName -eq 'options') {
        if ($Options -eq $null) {
            $Options = New-HTMLReportOptions -UseCssLinks:$UseCssLinks -UseStyleLinks:$UseStyleLinks
        }
    } else {
        if ([String]::IsNullOrEmpty($RightLogoString) -eq $false -or [String]::IsNullOrEmpty($LeftLogoString) -eq $false) {
            $LogoSources = @{}
            if ([String]::IsNullOrEmpty($RightLogoString) -eq $false) {
                $LogoSources.Add($RightLogoName, $RightLogoString)
            }
            if ([String]::IsNullOrEmpty($LeftLogoString) -eq $false) {
                $LogoSources.Add($LeftLogoName, $LeftLogoString)
            }
        }
        if (!([String]::IsNullOrEmpty($LogoPath))) {
            $LogoSources = Get-HTMLLogos -logopath $LogoPath
        }

        $Options = New-HTMLReportOptions -LogoSources $LogoSources -CSSName $CSSName -CSSPath $CSSPath -ScriptPath $ScriptPath -ColorSchemePath $ColorSchemePath -UseCssLinks:$UseCssLinks -UseStyleLinks:$UseStyleLinks
    }
    if ($HideLogos -eq $false) {
        $Leftlogo = $Options.Logos[$LeftLogoName]
        $Rightlogo = $Options.Logos[$RightLogoName]
        $LogoContent = @"
            <table><tbody>
            <tr>
                <td class="clientlogo"><img src="$Leftlogo" /></td>
                <td class="MainLogo"><img src="$Rightlogo" /></td>
            </tr>
            </tbody></table>
"@
    }
    # Replace PNG / JPG files in Styles

    if ($null -ne $Options.StyleContent) {

        Write-Verbose "Logos: $($Options.Logos.Keys -join ',')"
        foreach ($Logo in $Options.Logos.Keys) {
            $Search = "../images/$Logo.png", "DataTables-1.10.18/images/$Logo.png"
            $Replace = $Options.Logos[$Logo]
            foreach ($S in $Search) {
                $Options.StyleContent = ($Options.StyleContent).Replace($S, $Replace)
            }
        }
    }

    $HtmlContent = New-GenericList -Type [string]
    $HtmlContent.Add("<!DOCTYPE HTML>")
    if ($AddAuthor) {
        if ([String]::IsNullOrWhiteSpace($Author)) {
            $Author = $env:USERNAME
        }
        $HtmlContent.Add("<!--- This page was autogenerated $CurrentDate By $Author -->")
    }
    $HtmlContent.Add("<html>")
    $HtmlContent.Add('<!-- Header -->')
    $HtmlContent.Add('<head>')
    if ($HideTitle -eq $false) {
        $HtmlContent.Add("<Title>$TitleText</Title>")
    }
    $HtmlContent.Add("<!-- Styles -->")
    $HtmlContent.Add("$($Options.StyleContent)")
    $HtmlContent.Add('<!-- Scripts -->')
    $HtmlContent.Add("$($Options.ScriptContent)")
    $HtmlContent.Add('</head>')
    $HtmlContent.Add('')
    $HtmlContent.Add('<!-- Body -->')
    $HtmlContent.Add('<body onload="hide();">')

    if (-not $HideTitle) {
        $HtmlContent.Add("<!-- Report Header -->")
        $HtmlContent.Add($LogoContent)
        $HtmlContent.Add("<div class=`"pageTitle`">$TitleText</div>")
        $HtmlContent.Add("<hr />")
    }
    if (-not $HideDate) {
        $HtmlContent.Add("<div class=`"ReportCreated`">Report created on $($CurrentDate)</div>")
    }

    if (!([string]::IsNullOrEmpty($PrimaryColorHex))) {
        if ($PrimaryColorHex.Length -eq 7) {
            $HtmlContent = $HtmlContent -replace '#337E94', $PrimaryColorHex
        } else {
            Write-Warning '$PrimaryColorHex must be 7 characters with hash eg "#337E94"'
        }
    }

    Write-Output $HtmlContent
}