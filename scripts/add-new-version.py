import logging
from datetime import datetime
import pathlib
import argparse
import sys
import re
import json
from typing import Optional

from typing import List, Dict

loggingLevel: int = logging.INFO
loggingFormat: str = "[%(levelname)s] %(message)s"

versionFormat: str = "1.2.3#4"
portVersionRegEx = re.compile(r"^(\d+\.\d+\.\d+)#(\d+)$")


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
    metavar="some-thing"
)
argParser.add_argument(
    "--port-version",
    required=True,
    type=portVersionType,
    metavar=versionFormat
)
argParser.add_argument(
    "--not-updating-baseline",
    action='store_true',
    help="do not update the baseline (default: %(default)s)"
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
updatingBaseline: bool = not cliArgs.not_updating_baseline
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
    raise SystemExit(9)
else:
    newVersionMain = versionMatches.group(1)
    newVersionPort = int(versionMatches.group(2))

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
            raise SystemExit(6)
        else:
            logging.debug(f"Current port version values: {currentVersion}")
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
                raise SystemExit(7)
            else:
                parsedCurrentVersion: str = (
                    f"{currentVersionBaseline}#{currentVersionPort}"
                )
                logging.debug(
                    f"Parsed current version: {parsedCurrentVersion}"
                )
                if parsedCurrentVersion == portVersion:
                    logging.error(
                        " ".join((
                            f"The [{portName}] version in {baselinePath.resolve()}",
                            f"is already {portVersion}"
                        ))
                    )
                    raise SystemExit(8)

            # redundant check, because these are already checked with RegEx
            if newVersionMain is None or newVersionPort is None:
                logging.error(
                    " ".join((
                        f"Could not get version values from [{portVersion}],",
                        f"is it in the correct format ({versionFormat})?"
                    ))
                )
                raise SystemExit(9)
            else:
                currentVersion[baselineKey] = newVersionMain
                currentVersion[portVersionKey] = newVersionPort
                baselineVersions["default"][portName] = currentVersion

            updatedBaseline = json.dumps(baselineVersions, indent=4, sort_keys=True)
            # no way to make json.dumps() placing curly braces on new lines
            updatedBaselineFormatted = re.sub(
                r'^((\s*)".*?":)\s*([\[{])',
                r'\1\n\2\3',
                updatedBaseline,
                flags=re.MULTILINE
            )
            f.seek(0)
            f.write(updatedBaselineFormatted)
            f.write("\n")
            f.truncate()

with open(portVersionsPath, "r+", newline="") as f:
    versions = json.load(f)
    currentVersions = versions.get("versions")
    if currentVersions is None:
        logging.error(
            f"Could not get the versions from {portVersionsPath.resolve()}"
        )
        raise SystemExit(10)

    for v in currentVersions:
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
            raise SystemExit(11)
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
            raise SystemExit(12)

    # git rev-parse HEAD:ports/some-thing
    revParsedGitHash: str = "REPLACE-THAT-WITH-THE-ACTUAL-REV-PARSED-HASH"

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
    updatedVersions = json.dumps(versions, indent=4, sort_keys=False)
    # no way to make json.dumps() placing curly braces on new lines
    updatedVersionsFormatted = re.sub(
        r'^((\s*)".*?":)\s*([\[{])',
        r'\1\n\2\3',
        updatedVersions,
        flags=re.MULTILINE
    )
    f.seek(0)
    f.write(updatedVersionsFormatted)
    f.write("\n")
    f.truncate()
