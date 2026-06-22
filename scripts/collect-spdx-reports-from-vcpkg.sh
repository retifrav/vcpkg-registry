#!/bin/bash

vcpkgPortsInstallationPath=""
spdxReportFileName="vcpkg.spdx.json"
outputPath="./spdx"

helpMessage="Collecting SPDX files from vcpkg ports installation prefix into a single folder.

Usage:

    $(basename $0) -p PATH-TO-VCPKG-PORTS-INSTALLATION [-r REGEX-FOR-IGNORING] [-o PATH-TO-OUTPUT-FOLDER]

Example:

    $(basename $0) \\
        -p '/path/to/some/project/install/CMAKE-PRESET-NAME/share/' \\
        -r '^(cpp-|sha)' \\
        -o './some-project-spdx'

Instead of \`/path/to/some/project/install/CMAKE-PRESET-NAME/share/\` it can just as well be
\`/path/to/some/project/build/CMAKE-PRESET-NAME/vcpkg_installed/VCPKG-TRIPLET-NAME/share/\`.

The regular expression for ignoring (-r) is just an example for when you would like
to exclude some ports, but normally you wouldn't use it."

while getopts ":p:r:o:h" opt; do
  case $opt in
    p) vcpkgPortsInstallationPath="$OPTARG"
    ;;
    r) ignoringRegEx="$OPTARG"
    ;;
    o) outputPath="$OPTARG"
    ;;
    h)
        echo "$helpMessage"
        exit 0
    ;;
    \?)
        echo "Unknown option -$OPTARG" >&2
        exit 1
    ;;
  esac
done

if [ -z "$vcpkgPortsInstallationPath" ]; then
    echo "[ERROR] You need to provide path to where vcpkg installed the ports (-p)"
    exit 2
fi

if [ -d "$outputPath" ]; then
    echo "[ERROR] The output folder [$outputPath] already exists, delete it first or choose a different one (-o)"
    exit 3
else
    mkdir -p "$outputPath"
fi

#if [ -z $ignoringRegEx ]; then
#   ignoringRegEx="^(some-|thing)"
#fi

totalCopied=0
totalIgnored=0
for i in $vcpkgPortsInstallationPath/*; do
    d=$(basename $i | sed 's/_[^_]*\.list$//')
    if [[ $d =~ $ignoringRegEx ]]; then
        totalIgnored=$((totalIgnored + 1))
        echo "[$d] is ignored"
    else
        if [ -f "$i/$spdxReportFileName" ]; then
            totalCopied=$((totalCopied + 1))
            echo "[$d] copying ${spdxReportFileName}..."
            cp "$i/$spdxReportFileName" "$outputPath/$(echo $d.spdx.json | tr '[:upper:]' '[:lower:]')"
        else
            echo "[$d] does not contain ${spdxReportFileName} (and likely isn't meant to)"
        fi
    fi
done

echo ''
echo 'Total:'
echo "- copied: $totalCopied"
echo "- ignored: $totalIgnored"
