param (
    [string]$Url,
    [string]$ExpectedSHA512,
    [string]$Destination
)

# the original script is taken from https://github.com/microsoft/vcpkg/discussions/39901

$baseurl = "https://artifactory.YOUR.HOST/artifactory/vcpkg-binary-caching/_assets"
$token = "YOUR_ARTIFACTORY_ACCESS_TOKEN" # $env:YOUR_ARTIFACTORY_ACCESS_TOKEN
$headers = @{ Authorization = "Bearer $token" }
$contentype = "multipart/form-data"
$filename = Split-Path -Path $Destination -Leaf
$correctFilename = $filename -replace '\.\d+\.part$', ''
$cacheurl = "$baseurl/$correctFilename"

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

    $fileHash = [BitConverter]::ToString($hashBytes) -replace '-', ''

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
    $response = Invoke-WebRequest -Uri $cacheurl -Headers $headers -OutFile $Destination -ContentType $contentype
}
catch
{
    if ($_.Exception.Response)
    {
        $statusCode = $_.Exception.Response.StatusCode
        if ($statusCode -eq "404")
        {
            Write-Warning "[$correctFilename] is not available in cache at $baseurl"
            if (Test-Path $Destination)
            {
                $out = Remove-Item -Path $Destination
            }
        }
        else
        {
            Write-Error "Download failed with status code: $statusCode"
            exit 1
        }
    }
    else
    {
        Write-Output "Download failed with error: $_"
        exit 1
    }
}

# vcpkg will do hash verification after downloading from $cacheurl
if (-not (Test-Path $Destination))
{
    Write-Warning "Falling back to download from $Url"
    try
    {
        $response = Invoke-WebRequest -Uri $Url -OutFile $Destination
    }
    catch
    {
        if ($_.Exception.Response)
        {
            $statusCode = $_.Exception.Response.StatusCode
            if ($statusCode -eq "404")
            {
                Write-Error "Unable to download from $Url"
                exit 1
            }
            else
            {
                Write-Error "Download failed with status code: $statusCode"
                exit 1
            }
        }
        else
        {
            Write-Error "Download failed with error: $_"
            exit 1
        }
    }

    # verify the hash before uploading
    if (-not (Verify-SHA512 -File $Destination -ExpectedHash $ExpectedSHA512))
    {
        exit 1
    }
    else
    {
        Write-Output "Uploading to $cacheurl"
        $response = Invoke-WebRequest -Uri $cacheurl -Method Put -Headers $headers -InFile $Destination -ContentType $contentype
    }
}
