#!/bin/sh

# find the longest port name
maxPortNameLength=$(find ./ports -maxdepth 1 | awk 'function base(f){sub(".*/", "", f); return f;} {print length(base($0))}'| sort -nr | head -1)
# increment it for some padding
portColumnWidth=$((maxPortNameLength+1))
# subtract the length of "port" for the column header
portColumnHeaderWidth=$((maxPortNameLength-4))

gitHashLength=40
maxVersionLength=12

exitCode=0
problematicPorts=()

printf "%*s port |      version | %${gitHashLength}s | %${gitHashLength}s\n" $portColumnHeaderWidth
printf %$((portColumnWidth+${gitHashLength}*2+$maxVersionLength+3*3))s | tr " " "-"
echo
for p in $(find ports/* -maxdepth 1 -type d | cut -d / -f2)
do
    # if [ ! -d ./ports/${p} ]; then
    #     echo "The [${p}] port path doesn't exit, check that you ran this script from the vcpkg registry"
    #     exit 2
    # fi

    # get the line that looks like
    #     "version": "8.1.2"
    # or
    #     "version-date": "2022-02-06"
    versionString=$(grep -e \"version\" -e \"version-date\" ./ports/${p}/vcpkg.json)
    versionValue=$(echo ${versionString} | cut -d \" -f4)
    # is it "version" (proper SemVer) or "version-date"
    versionKind=$(echo ${versionString} | cut -d \" -f2)

    gitHashStated=$(grep -E "\"${versionKind}\"\\s*:\\s*\"${versionValue}\"" -A 1 ./versions/${p:0:1}-/${p}.json | grep git-tree | cut -d \" -f4)
    gitHashActual=$(git rev-parse HEAD:./ports/${p})

    # the `==` comparison doesn't work on ash, dash and some other POSIX implementations,
    # so it should be `=` here, even though it is against the laws of nature
    if [ "$gitHashStated" = "$gitHashActual" ]; then
        printf "%${portColumnWidth}s | %${maxVersionLength}s | %s | \e[32m%s\e[0m\n" $p $versionValue $gitHashStated $gitHashActual
    else
        exitCode=1
        problematicPorts=("${problematicPorts[@]}" $p)
        printf "%${portColumnWidth}s | %${maxVersionLength}s | %s | \e[31m%s\e[0m\n" $p $versionValue $gitHashStated $gitHashActual
    fi
done

if [ $exitCode -ne 0 ]; then
    printf "\nThe following ports have a mismatch between their stated and actual Git hashes:\n\n"
    for p in "${problematicPorts[@]}"; do echo "- $p" ; done
fi

exit $exitCode
