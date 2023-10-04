#!/bin/bash

cmakePreset="[unknown]"
vcpkgTriplet="[unknown]"
pathToProject="."

while getopts ":c:v:p" opt; do
  case $opt in
    c) cmakePreset="$OPTARG"
    ;;
    v) vcpkgTriplet="$OPTARG"
    ;;
    p) pathToProject="$OPTARG"
    ;;
    \?)
        echo "[ERROR] Unknown option -$OPTARG" >&2
        exit 1
    ;;
  esac
done

# no checking for `pathToProject`, because `.` (current folder) is a sane default value
if [[ "$cmakePreset" == "[unknown]" || "$vcpkgTriplet" == "[unknown]" ]]; then
    echo "You need to provide CMake preset name (-c), vcpkg triplet name (-v) and target platform name (-t)" >&2
    exit 1
fi

# blacklist for excluding dependencies from being merged with the project installation and then published
#
# such dependencies would include those required for building project tools/applications/executables,
# so they are not needed to be available for end-users in order to link with the project
#
# these values will be used as wildcards, so for example `datakit` value from here will get transformed
# into `/path/to/vcpkg_installed/vcpkg/info/datakit*.list`, and so if there are several files
# in that folder starting with `datakit`, then their combined contents will be used, which is actually good,
# so this is intentional
dependenciesBlacklist=(
    "datakit"
    "gdal"
)
# and this list is exceptions from those blacklisted dependencies (for instance, we want to keep GDAL DLLs)
dependenciesBlacklistExceptions=(
    "$vcpkgTriplet/bin/gdal304.dll"
    "$vcpkgTriplet/share/gdal/dlls/freexl.dll"
    "$vcpkgTriplet/share/gdal/dlls/geos.dll"
    "$vcpkgTriplet/share/gdal/dlls/geos_c.dll"
    "$vcpkgTriplet/share/gdal/dlls/iconv-2.dll"
    "$vcpkgTriplet/share/gdal/dlls/libcrypto-1_1-x64.dll"
    "$vcpkgTriplet/share/gdal/dlls/libcurl.dll"
    "$vcpkgTriplet/share/gdal/dlls/libexpat.dll"
    "$vcpkgTriplet/share/gdal/dlls/libmysql.dll"
    "$vcpkgTriplet/share/gdal/dlls/libpq.dll"
    "$vcpkgTriplet/share/gdal/dlls/libssl-1_1-x64.dll"
    "$vcpkgTriplet/share/gdal/dlls/libxml2.dll"
    "$vcpkgTriplet/share/gdal/dlls/ogdi.dll"
    "$vcpkgTriplet/share/gdal/dlls/openjp2.dll"
    "$vcpkgTriplet/share/gdal/dlls/proj_7_2.dll"
    "$vcpkgTriplet/share/gdal/dlls/spatialite.dll"
    "$vcpkgTriplet/share/gdal/dlls/sqlite3.dll"
    "$vcpkgTriplet/share/gdal/dlls/tiff.dll"
    "$vcpkgTriplet/share/gdal/dlls/xerces-c_3_2.dll"
    "$vcpkgTriplet/share/gdal/dlls/zlib.dll"
)

vcpkgInstallationPath="$pathToProject/build/$cmakePreset/vcpkg_installed"
if [[ ! -d $vcpkgInstallationPath ]]; then
    echo "[ERROR] The path to vcpkg artifacts ($vcpkgInstallationPath) does not exist" >&2
    exit 2
fi
if [[ ! -d "$vcpkgInstallationPath/$vcpkgTriplet" ]]; then
    echo "[ERROR] The path to vcpkg triplet artifacts ($vcpkgInstallationPath/$vcpkgTriplet) does not exist" >&2
    exit 2
fi

projectInstallationPath="$pathToProject/install/$cmakePreset"
if [[ ! -d $projectInstallationPath ]]; then
    echo "[ERROR] The path to project install ($projectInstallationPath) does not exist" >&2
    exit 3
fi

filterOutBlacklistedDependencies=true
vcpkgInfoLists="$vcpkgInstallationPath/vcpkg/info"
if [[ ! -d $vcpkgInfoLists ]]; then
    echo "[WARNING] The vcpkg info lists path ($vcpkgInfoLists) does not exist, will skip filtering out blacklisted dependencies" >&2
    filterOutBlacklistedDependencies=false
fi

# --- filter out dependencies that we do not want/need to publish together with the project installation

maxJobs=$(nproc --all)
folderRegEx='^.*\/$'
if [[ $filterOutBlacklistedDependencies == true ]]; then
    echo "Filtering out blacklisted dependencies..."
    # first delete the files
    for d in "${dependenciesBlacklist[@]}"; do
        listsCount=$(find "$vcpkgInfoLists" -maxdepth 1 -type f -name ${d}*.list -printf x | wc -c)
        echo "" && echo "- $d (lists found: $listsCount)"
        if [[ ! $listsCount -gt 0 ]]; then
            echo "no lists found for that pattern (most likely this is okay, because some dependencies are platform-specific)"
            continue
        fi
        # thanks to the wildcard, all the lists starting with a given pattern will be processed, and this is good
        cat "$vcpkgInfoLists"/${d}*.list | while read artifactPath || [[ -n $artifactPath ]];
        do # need to parallelize this somehow (the commented out solution doesn't have any effect)
            #(
            # delete only files (hence no -r for rm)
            if [[ ! "$artifactPath" =~ $folderRegEx ]]; then
                # if it is not an exception
                #
                # this particular check is not very reliable, although probably is good enough for our case
                #if [[ ! "${dependenciesBlacklistExceptions[@]}" =~ "$artifactPath" ]]; then
                # this one might be better, although not perfect either, because `echo some-thing | grep -w -q some` would also return 0 (dashes are words separators)
                echo "${dependenciesBlacklistExceptions[@]}" | grep -w -q "$artifactPath"
                if [[ $? == 1 ]]; then
                    # and only if the file exists, otherwise (optionally?) print a warning (because why is it listed then)
                    artifactPathFull="$vcpkgInstallationPath/$artifactPath"
                    if [[ -f "$artifactPathFull" ]]; then
                        rm "$artifactPathFull"
                    else
                        echo "[WARNING] Listed artifact path does not exist: $artifactPathFull"
                    fi
                else
                    echo "skipping exception: $artifactPath"
                fi
            # else
            #     echo "Skipping a folder: $artifactPath"
            fi
            #) &
            ## only let to execute maximum allowed jobs in parallel
            #if [[ $(jobs -r -p | wc -l) -ge $maxJobs ]]; then
            #    echo "Reached maximum jobs: $maxJobs"
            #    # now there are maximum allowed jobs already running, so wait for any job to finish
            #    wait -n
            #fi
        done
        # no more jobs to be started, but need wait for pending jobs
        # (all need to be finished)
        #wait
    done
    # and then delete empty folders
    find "$vcpkgInstallationPath" -type d -empty -delete
else
    echo "Filtering out blacklisted dependencies has been skipped"
fi

# --- copy (or rather merge) the vcpkg installation into the project installation

echo "" && echo "Copying vcpkg installed artifacts..."
#
# one alternative (should work on all platforms)
#(cd "$vcpkgInstallationPath/$vcpkgTriplet" && tar -c .) | (cd "$projectInstallationPath" && tar -xf -)
#
# another alternative (might have a different behaviour on different platforms)
# note that `/*`` should be outside the quotes
cp -an "$vcpkgInstallationPath/$vcpkgTriplet"/* "$projectInstallationPath"


