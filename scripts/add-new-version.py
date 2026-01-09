import logging
from datetime import datetime
import pathlib
import argparse
import sys
import re
import json
import subprocess

from typing import List, Dict, Optional, Any

loggingLevel: int = logging.INFO
loggingFormat: str = "[%(levelname)s] %(message)s"

versionFormat: str = "1.2.3#4"
portVersionRegEx = re.compile(r"^(\d+\.\d+\.\d+)#(\d+)$")
gitTreePlaceholder: str = "REPLACE-THAT-WITH-ACTUAL-REV-PARSED-HASH"


def portVersionType(argumentValue):
    if not portVersionRegEx.match(argumentValue):
        raise argparse.ArgumentTypeError(
            " ".join((
                "incorrect port version format, expected something",
                f"like {versionFormat}"
            ))
        )
    return argumentValue


argParser = argparse.ArgumentParser(
    prog="add-new-version",
    description="".join((
        "-= %(prog)s =-\n\n",
        "Adds a new version for the specified port. It is assumed that ",
        "all the modifications in the portfile.cmake and vcpkg.json ",
        "are already done, and what's left is updating baseline.json ",
        "and versions file.\n\n",
        f"Copyright (C) 2025-{datetime.now().year} ",
        "Declaration of VAR\n",
        "License: GPLv3"
    )),
    formatter_class=argparse.RawDescriptionHelpFormatter,
    allow_abbrev=False
)
argParser.add_argument(
    "registryPath",
    type=pathlib.Path,
    nargs="?",
    default=pathlib.Path("."),
    metavar="/path/to/vcpkg-registry/",
    help="path to the vcpkg registry"
)
argParser.add_argument(
    "--port-name",
    required=True,
    type=str,
    metavar="some-thing",
    help="name of the port"
)
argParser.add_argument(
    "--port-version",
    required=True,
    type=portVersionType,
    metavar=versionFormat,
    help="new version of the port"
)
argParser.add_argument(
    "--ignore-version-from-manifest",
    action='store_true',
    help="ignore (potential) manifest version mismatch (default: %(default)s)"
)
argParser.add_argument(
    "--not-updating-baseline",
    action='store_true',
    help="do not update the baseline (default: %(default)s)"
)
argParser.add_argument(
    "--not-creating-versions-file",
    action='store_true',
    help="do not create missing versions file (default: %(default)s)"
)
argParser.add_argument(
    "--no-rev-parse",
    action='store_true',
    help=" ".join((
        "don't try to get the actual tree/subfolder hash",
        "for the git-tree property in the port versions file,",
        f"use the \"{gitTreePlaceholder}\" placeholder instead",
        "(default: %(default)s)"
    ))
)
argParser.add_argument(
    "--sorting-json",
    action='store_true',
    help="sort JSON before writing to file (default: %(default)s)"
)
argParser.add_argument(
    "--debug",
    action='store_true',
    help="enable debug/dev mode (default: %(default)s)"
)
cliArgs = argParser.parse_args()

registryPath: pathlib.Path = cliArgs.registryPath
portName: str = cliArgs.port_name
portVersion: str = cliArgs.port_version
ignoreVersionFromManifest: bool = cliArgs.ignore_version_from_manifest
updatingBaseline: bool = not cliArgs.not_updating_baseline
creatingVersionsFile: bool = not cliArgs.not_creating_versions_file
withRevParse: bool = not cliArgs.no_rev_parse
sortingJson: bool = cliArgs.sorting_json
debugMode: bool = cliArgs.debug

if debugMode:
    loggingLevel = logging.DEBUG
    # 8 is the length of "CRITICAL" - the longest log level name
    loggingFormat = "%(asctime)s | %(levelname)-8s | %(message)s"

logging.basicConfig(
    format=loggingFormat,
    level=loggingLevel,
    stream=sys.stdout
)

logging.debug(f"CLI arguments: {cliArgs}")
logging.debug("-")

# ---


def formatJson(originalDictionary: Dict[str, Any], sortKeys: bool) -> str:
    jsonString = json.dumps(originalDictionary, indent=4, sort_keys=sortKeys)
    # no way to make json.dumps() put openning curly braces on new lines
    # https://stackoverflow.com/a/46746660/1688203
    jsonStringFormatted = re.sub(
        r'^((\s*)".*?":)\s*([\[{])',
        r'\1\n\2\3',
        jsonString,
        flags=re.MULTILINE
    )
    return jsonStringFormatted


def executeShellCommand(args: List[str]) -> subprocess.CompletedProcess:
    try:
        return subprocess.run(
            args,
            capture_output=True
        )
    except subprocess.CalledProcessError as ex:
        logging.error(ex.output)
        raise SystemExit(18)
    except Exception as ex:
        logging.error(ex)
        raise SystemExit(18)


def revParseSubfolder(subfolder: str) -> str:
    # stage possible modifications in the port folder
    # (for `git diff --cached` to reliably report the changes)
    executeShellCommand(
        [
            "git",
            "-C", registryPath.resolve(),
            "add",
            subfolder
        ]
    )
    # check whether there are any modifications in the port folder
    portFilesModified = executeShellCommand(
        [
            "git",
            "-C", registryPath.resolve(),
            "diff",
            "--exit-code",
            "--cached",
            "--no-patch",
            subfolder
        ]
    )
    gitResult: Optional[subprocess.CompletedProcess] = None
    if portFilesModified.returncode == 0:
        logging.debug(
            "No modifications in the port folder, will use rev-parse"
        )
        gitResult = executeShellCommand(
            [
                "git",
                "-C", registryPath.resolve(),
                "rev-parse",
                f"HEAD:{subfolder}"
            ]
        )
    else:
        logging.debug(
            "There are modifications in the port folder, will use write-tree"
        )
        # https://stackoverflow.com/questions/23816330/compute-git-hash-of-all-uncommitted-code/48213033#48213033
        # might want/need to use a temporary index via GIT_INDEX_FILE:
        # ```
        # $ cp .git/index /tmp/git_index
        # $ export GIT_INDEX_FILE=/tmp/git_index
        # $ git add ./ports/some
        # $ git write-tree --prefix=ports/some
        # $ unset GIT_INDEX_FILE
        # ```
        gitResult = executeShellCommand(
            [
                "git",
                "-C", registryPath.resolve(),
                "write-tree",
                "--prefix",
                subfolder
            ]
        )
        # unstage the port folder modifications (though that could have been
        # staged before running this script, so unstaging them here is probably
        # not desirable)
        executeShellCommand(
            [
                "git",
                "-C", registryPath.resolve(),
                "reset",
                "--quiet",
                subfolder
            ]
        )

    if gitResult.returncode != 0:
        logging.error(gitResult.stderr.decode().strip())
        raise SystemExit(18)
    else:
        resultValue: str = gitResult.stdout.decode().strip()
        logging.debug(
            f"Tree/subfolder hash for the (updated) port: {resultValue}"
        )
        return resultValue


# --- do some checks first

if not registryPath.is_dir():
    logging.error(
        " ".join((
            f"Registry path [{registryPath.resolve()}] doesn't exist",
            "or not a folder"
        ))
    )
    raise SystemExit(1)

portsPath: pathlib.Path = registryPath / "ports"
if not portsPath.is_dir():
    logging.error(
        " ".join((
            "There is no [ports] folder inside the registry,",
            "you might have provided a wrong path to the registry"
        ))
    )
    raise SystemExit(2)

portPath: pathlib.Path = portsPath / portName
if not portPath.is_dir():
    logging.error(
        f"Provided port [{portName}] does not exist in the given registry"
    )
    raise SystemExit(3)

baselinePath: pathlib.Path = registryPath / "versions" / "baseline.json"
if not baselinePath.is_file():
    logging.error(
        " ".join((
            "The baseline.json file is missing, expected to find",
            f"it here: {baselinePath.resolve()}"
        ))
    )
    raise SystemExit(4)

portVersionsPath: pathlib.Path = (
    registryPath / "versions" / f"{portName[0]}-" / f"{portName}.json"
)
if not portVersionsPath.is_file():
    if creatingVersionsFile:
        with open(portVersionsPath, "w", newline="") as f:
            f.write("{\"versions\":[]}\n")
    else:
        logging.error(
            " ".join((
                "The port versions file is missing, expected to find",
                f"it here: {portVersionsPath.resolve()}"
            ))
        )
        raise SystemExit(5)

newVersionMain: Optional[str] = None
newVersionPort: Optional[int] = None
versionMatches = portVersionRegEx.match(portVersion)
if versionMatches is None or len(versionMatches.groups()) < 2:
    logging.error(
        " ".join((
            f"Could not get version values from [{portVersion}],",
            f"is it in the correct format ({versionFormat})?"
        ))
    )
    raise SystemExit(12)
else:
    newVersionMain = versionMatches.group(1)
    newVersionPort = int(versionMatches.group(2))

if not ignoreVersionFromManifest:
    portManifestPath: pathlib.Path = portsPath / portName / "vcpkg.json"
    if not portManifestPath.is_file():
        logging.error(
            " ".join((
                "The port manifest is missing, expected to find",
                f"it here: {portManifestPath.resolve()}"
            ))
        )
        raise SystemExit(6)
    with open(portManifestPath, "r") as f:
        manifest = json.load(f)
        currentManifestVersion = manifest.get("version")
        if currentManifestVersion is None:
            logging.error(
                f"Could not get the version from {portManifestPath.resolve()}"
            )
            raise SystemExit(7)
        currentManifestPortVersion = manifest.get("port-version", 0)
        currentManifestVersion = (
            f"{currentManifestVersion}#{currentManifestPortVersion}"
        )
        logging.debug(
            f"Parsed current manifest version: {currentManifestVersion}"
        )
        if currentManifestVersion != portVersion:
            logging.error(
                " ".join((
                    f"The current version {currentManifestVersion}",
                    "in the port manifest is different from the provided",
                    f"version {portVersion} (you can ignore",
                    "that with --ignore-version-from-manifest)"
                ))
            )
            raise SystemExit(8)
else:
    logging.info("Not checking the version value in the port manifest")

# ---

if updatingBaseline:
    with open(baselinePath, "r+", newline="") as f:
        baselineVersions = json.load(f)
        currentVersion = baselineVersions.get("default", {}).get(portName)
        if currentVersion is None:
            logging.error(
                " ".join((
                    f"Could not get the [{portName}] version",
                    f"from {baselinePath.resolve()}"
                ))
            )
            raise SystemExit(9)
        else:
            # logging.debug(
            #     f"Current baseline version values: {currentVersion}"
            # )
            baselineKey: str = "baseline"
            currentVersionBaseline: str = currentVersion.get(baselineKey)
            portVersionKey: str = "port-version"
            currentVersionPort: int = currentVersion.get(portVersionKey)
            if currentVersionBaseline is None or currentVersionPort is None:
                logging.error(
                    " ".join((
                        f"The {baselinePath.resolve()} is missing",
                        f"[{baselineKey}] or/and [{portVersionKey}] value",
                        f"for the [{portName}] port"
                    ))
                )
                raise SystemExit(10)
            else:
                parsedCurrentVersion: str = (
                    f"{currentVersionBaseline}#{currentVersionPort}"
                )
                logging.debug(
                    f"Parsed current baseline version: {parsedCurrentVersion}"
                )
                if parsedCurrentVersion == portVersion:
                    logging.error(
                        " ".join((
                            f"The version of [{portName}] port in",
                            f"{baselinePath.resolve()} is",
                            f"already {portVersion}"
                        ))
                    )
                    raise SystemExit(11)

            # redundant check, because these are already checked with RegEx
            if newVersionMain is None or newVersionPort is None:
                logging.error(
                    " ".join((
                        f"Could not get version values from [{portVersion}],",
                        f"is it in the correct format ({versionFormat})?"
                    ))
                )
                raise SystemExit(12)
            else:
                currentVersion[baselineKey] = newVersionMain
                currentVersion[portVersionKey] = newVersionPort
                baselineVersions["default"][portName] = currentVersion

            f.seek(0)
            f.write(
                formatJson(
                    baselineVersions,
                    sortKeys=sortingJson
                )
            )
            f.write("\n")
            f.truncate()
else:
    logging.info("Not updating the baseline")

with open(portVersionsPath, "r+", newline="") as f:
    revParsedGitHash: str = gitTreePlaceholder
    if withRevParse:
        revParsedGitHash = revParseSubfolder(
            portPath.relative_to(registryPath).as_posix()
        )
    else:
        logging.info(
            " ".join((
                "Not trying to get the actual tree/subfolder hash,",
                "will use a placeholder instead"
            ))
        )

    versions = None
    try:
        versions = json.load(f)
    except Exception as ex:
        logging.error(f"Could not read/parse the versions file: {ex}")
        raise SystemExit(13)
    currentVersions = versions.get("versions")
    if currentVersions is None:
        logging.error(
            f"Could not get the versions from {portVersionsPath.resolve()}"
        )
        raise SystemExit(13)

    for v in currentVersions:
        # verify that this version has not been already added before
        versionKey: str = "version"
        vrsn = v.get(versionKey)
        if vrsn is None:
            logging.error(
                " ".join((
                    "One of the version values in",
                    f"{portVersionsPath.resolve()} does not have",
                    f"the [{versionKey}] key"
                ))
            )
            raise SystemExit(14)
        if (
            vrsn == newVersionMain
            and
            # missing is okay, defaulting to 0
            v.get("port-version", 0) == newVersionPort
        ):
            logging.error(
                " ".join((
                    f"Version {portVersion} is already present",
                    f"in {portVersionsPath.resolve()}"
                ))
            )
            raise SystemExit(15)
        # also verify that none of the existing versions have the same
        # tree/port hash (the one from `git rev-parse`/`git write-tree`)
        gitTree: str = "git-tree"
        gttr = v.get(gitTree)
        if gttr is None:
            logging.error(
                " ".join((
                    "One of the version values in",
                    f"{portVersionsPath.resolve()} does not have",
                    f"the [{gitTree}] key"
                ))
            )
            raise SystemExit(16)
        if (gttr == revParsedGitHash):
            logging.error(
                " ".join((
                    f"The tree hash {revParsedGitHash} is already present",
                    f"in {portVersionsPath.resolve()}"
                ))
            )
            raise SystemExit(17)

    if newVersionPort == 0:
        versions["versions"].insert(
            0,
            {
                "version": newVersionMain,
                "git-tree": revParsedGitHash
            }
        )
    else:
        versions["versions"].insert(
            0,
            {
                "version": newVersionMain,
                "port-version": newVersionPort,
                "git-tree": revParsedGitHash
            }
        )

    f.seek(0)
    f.write(
        formatJson(
            versions,
            sortKeys=False  # should never sort these
        )
    )
    f.write("\n")
    f.truncate()

logging.info(f"Updated the port to version {portVersion}")
raise SystemExit(0)
