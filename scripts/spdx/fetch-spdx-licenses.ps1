[CmdletBinding(PositionalBinding=$false)]
Param(
    #[Parameter(Mandatory=$True)]
    [Parameter()]
    [string]$Version = "refs/tags/v3.28.0", # or `c4a7237ec8f4654e867546f9f409749300f1bf4c`

    [Parameter()]
    [string]$LicensesOutFile = "$PSScriptRoot/licenses.txt",

    [Parameter()]
    [string]$ExceptionsOutFile = "$PSScriptRoot/exceptions.txt"
)

# original script: https://github.com/microsoft/vcpkg-tool/blob/593345b7782c602a0ae072870721cc3c210a3c5f/Generate-SpdxLicenseList.ps1

function Transform-JsonFile
{
    [CmdletBinding()]
    Param(
        [string]$Uri,
        [string]$OutFile,
        [string]$OuterName,
        [string]$Id
    )

    $req = Invoke-WebRequest -Uri $Uri

    if ($req.StatusCode -ne 200)
    {
        Write-Error "Failed to GET $Uri"
        throw
    }

    $json = $req.Content | ConvertFrom-Json -Depth 10
    Write-Verbose "Writing output to $OutFile"

    #$fileContent = @(
    #    "// $Uri`n"
    #)
    $fileContent = @()
    $json.$OuterName |
        Sort-Object -Property $Id -Culture '' |
        ForEach-Object {
        $fileContent += "$($_.$Id)"
    }

    ($fileContent -join "`n") + "`n" `
        | Out-File -FilePath $OutFile -Encoding 'utf8' -NoNewline
}

$baseUrl = "https://raw.githubusercontent.com/spdx/license-list-data/$Version/json"
Write-Verbose "Getting json files from $baseUrl"

Transform-JsonFile `
    -Uri "$baseUrl/licenses.json" `
    -OutFile $LicensesOutFile `
    -OuterName 'licenses' `
    -Id 'licenseId'

# what are these for?
#Transform-JsonFile `
#    -Uri "$baseUrl/exceptions.json" `
#    -OutFile $ExceptionsOutFile `
#    -OuterName 'exceptions' `
#    -Id 'licenseExceptionId'
