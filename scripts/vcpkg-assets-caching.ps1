param (
    [string]$Url,
    [string]$ExpectedSHA512,
    [string]$Destination
)

# the original script is taken from https://github.com/microsoft/vcpkg/discussions/39901

$baseurl = "https://gitea.YOUR.HOST/api/packages/YOUR-ORGANIZATION-NAME/generic/vcpkg-binary-caching/_assets"
$token = "YOUR_GITEA_ACCESS_TOKEN" # $env:GITEA_ACCESS_TOKEN
$headers = @{ Authorization = "token $token" }
$contentype = "application/octet-stream"

#$baseurl = "https://artifactory.YOUR.HOST/artifactory/vcpkg-binary-caching/_assets"
#$token = "YOUR_ARTIFACTORY_ACCESS_TOKEN" # $env:YOUR_ARTIFACTORY_ACCESS_TOKEN
#$headers = @{ Authorization = "Bearer $token" }
#$contentype = "multipart/form-data"

$filename = Split-Path -Path $Destination -Leaf
$correctFilename = $filename -replace "\.\d+\.part$", ""
$cacheurl = "$baseurl/$correctFilename"

$ProgressPreferenceOriginal = $ProgressPreference
$ProgressPreference = "SilentlyContinue"

$downloadsfolder = Split-Path -Path "$Destination" -Parent
if(-not (Test-Path $downloadsfolder))
{
    $out = New-Item -Path "$downloadsfolder" -ItemType Directory
}

$LOG_FILE = Join-Path "$downloadsfolder" _assets-download.log
Start-Transcript -Path "$LOG_FILE"

function Verify-SHA512 {
    param (
        [string]$File,
        [string]$ExpectedHash
    )

    $hasher = [System.Security.Cryptography.SHA512]::Create()
    $stream = [System.IO.File]::OpenRead($File)
    $hashBytes = $hasher.ComputeHash($stream)
    $stream.Close()

    $fileHash = [BitConverter]::ToString($hashBytes) -replace "-", ""

    $hashesMatch = ($fileHash -eq $expectedHash)
    if(-not $hashesMatch) {
        Write-Error "SHA-512 hash verification failed for $File"
        Write-Error "Expected:   $expectedHash"
        Write-Error "Calculated: $fileHash"
    }

    return $hashesMatch
}

try
{
    Write-Output "Downloading $cacheurl"
    $response = Invoke-WebRequest -Uri $cacheurl -Headers $headers -SkipCertificateCheck -OutFile $Destination -ContentType $contentype
}
catch
{
    if ($_.Exception.Response)
    {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        if ($statusCode -eq 404)
        {
            Write-Warning "[$correctFilename] is not available in cache at $baseurl"
            if (Test-Path $Destination)
            {
                $out = Remove-Item -Path $Destination
            }
        }
        else
        {
            $ProgressPreference = $ProgressPreferenceOriginal
            Write-Error "Download failed with status code: $statusCode"
            exit 1
        }
    }
    else
    {
        $ProgressPreference = $ProgressPreferenceOriginal
        Write-Error "Download failed with error: $_"
        exit 1
    }
}

# vcpkg will do hash verification after downloading from $cacheurl
if (-not (Test-Path $Destination))
{
    Write-Warning "Falling back to download from $Url"
    try
    {
        $domainsThatRequireAuthentication = @(
            "artifactory.some.host"
            "some.other.domain"
        )
        $downloadRequiresAuthentication = $false
        # https://stackoverflow.com/a/25703406/1688203
        $regexDomain = "^(?:https?:\/\/)?(?:[^@\/\n]+@)?(?:www\.)?([^:\/?\n]+)"
        $downloadDomain = "unknown"
        if ($Url -match $regexDomain)
        {
            $downloadDomain = $Matches.1
            Write-Output "Domain: ${downloadDomain}"
            if ($downloadDomain -in $domainsThatRequireAuthentication)
            {
                $downloadRequiresAuthentication = $true
            }
        }
        Write-Output "The download requires authentication: $downloadRequiresAuthentication"

        if ($downloadRequiresAuthentication)
        {
            # https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/add-credentials-to-powershell-functions#creating-credential-object
            #$downloadCredentials = Get-Credential

            switch ($downloadDomain)
            {
                "artifactory.YOUR.HOST" {
                    # YOUR-ARTIFACTORY-LOGIN and YOUR-ARTIFACTORY-API-KEY could also be environment variables,
                    # or you might want to read them from some common credentials file, such as that very same .netrc
                    $password = ConvertTo-SecureString "YOUR-ARTIFACTORY-API-KEY" -AsPlainText -Force
                    $downloadCredentials = New-Object System.Management.Automation.PSCredential("YOUR-ARTIFACTORY-LOGIN", $password)
                    $response = Invoke-WebRequest -Uri $Url -SkipCertificateCheck -OutFile $Destination -Authentication Basic -Credential $downloadCredentials
                    # could probably also do this with `-Headers` and `X-JFrog-Art-Api` instead
                }
                #"some.other.domain" {
                #    #$downloadCredentials = [...]
                #    #$response = Invoke-WebRequest -Uri $Url -SkipCertificateCheck -OutFile $Destination [...]
                #}
                default {
                    $ProgressPreference = $ProgressPreferenceOriginal
                    Write-Error "Authenticating with this host has not been implemented yet"
                    exit 2
                }
            }
        }
        else # no authentication, just a regular download
        {
            $response = Invoke-WebRequest -Uri $Url -SkipCertificateCheck -OutFile $Destination
        }
    }
    catch
    {
        $ProgressPreference = $ProgressPreferenceOriginal

        if ($_.Exception.Response)
        {
            $statusCode = $_.Exception.Response.StatusCode.Value__
            if ($statusCode -eq 404)
            {
                Write-Error "Unable to download from $Url"
                exit 2
            }
            else
            {
                Write-Error "Download failed with status code: $statusCode"
                exit 2
            }
        }
        else
        {
            Write-Error "Download failed with error: $_"
            exit 2
        }
    }

    # verify the hash before uploading
    if (-not (Verify-SHA512 -File $Destination -ExpectedHash $ExpectedSHA512))
    {
        $ProgressPreference = $ProgressPreferenceOriginal
        exit 2
    }

    Write-Output "Uploading to $cacheurl"
    try
    {
        $response = Invoke-WebRequest -Uri $cacheurl -Method Put -Headers $headers -SkipCertificateCheck -InFile $Destination -ContentType $contentype
    }
    catch
    {
        $ProgressPreference = $ProgressPreferenceOriginal

        if ($_.Exception.Response)
        {
            $statusCode = $_.Exception.Response.StatusCode.Value__
            Write-Error "Download failed with status code: $statusCode"
        }
        else
        {
            Write-Error "Upload failed with error: $_"
        }

        exit 3
    }
}

$ProgressPreference = $ProgressPreferenceOriginal
