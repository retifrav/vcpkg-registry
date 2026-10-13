import logging
import pathlib
import argparse
import sys
import subprocess
import json
import re
import datetime
import pandas
from pandera import pandas as pandera
from tabulate import tabulate
from colorama import Fore, Style

import typing

loggingLevel: int = logging.INFO
loggingFormat: str = "[%(levelname)s] %(message)s"

versionRegEx = re.compile(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)")
versionDateRegEx = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2}")
# vcpkg version schemes that are not used in this registry
unsupportedVersionKeys: typing.List[str] = [
    "version-semver",
    "version-string"
]

argParser = argparse.ArgumentParser(
    prog="check-versions-and-hashes",
    description="".join((
        "-= %(prog)s =-\n",
        "Verifies currently stated port versions ",
        "and their rev-parse hashes.\n\n",
        f"Copyright (C) 2025-{datetime.datetime.now().year} ",
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
    "--debug",
    action='store_true',
    help="enable debug/dev mode (default: %(default)s)"
)
cliArgs = argParser.parse_args()

registryPath: pathlib.Path = cliArgs.registryPath
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


def getRevParseHash(
    pathToRepository: pathlib.Path,
    commitHash: str,
    pathInRepository: str
) -> str:
    logging.debug(
        " ".join((
            f"Getting rev-parse hash value of [{pathInRepository}]",
            f"in repository [{pathToRepository}]"
        ))
    )
    cmdResult = subprocess.run(
        [
            "git",
            "-C",
            pathToRepository.as_posix(),
            "rev-parse",
            f"{commitHash}:{pathInRepository}"
        ],
        # check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT
    )
    if cmdResult.returncode != 0:
        logging.error(
            "".join((
                f"The command was: {' '.join(cmdResult.args)}\n",
                f"Output: {cmdResult.stdout.strip()}"
            ))
        )
        raise OSError(
            f"Failed to get rev-parse hash"
        )
    else:
        revParsedHash = cmdResult.stdout.strip()
        if len(revParsedHash) != 40:
            raise ValueError(
                " ".join((
                    "Rev-parsed value doesn't look like",
                    f"a valid Git hash: [{revParsedHash}]",
                    "(must be a string of 40 symbols length",
                    "without newlines)"
                ))
            )
        else:
            logging.debug(f"- {revParsedHash}")
            return revParsedHash


def getVersionFormatProblem(
    versionKey: str,
    versionValue: typing.Any
) -> typing.Optional[str]:
    """
    Returns a description of what is wrong with the version value format,
    or `None` if there is nothing wrong with it.
    """
    if not isinstance(versionValue, str):
        return f"[{versionValue}] is not a string"
    if versionKey == "version":
        if not versionRegEx.fullmatch(versionValue):
            return " ".join((
                f"[{versionValue}] is not in X.Y.Z format",
                "(must be 3 numeric components without leading zeros)"
            ))
    elif versionKey == "version-date":
        if not versionDateRegEx.fullmatch(versionValue):
            return f"[{versionValue}] is not in YYYY-MM-DD format"
        try:
            datetime.date.fromisoformat(versionValue)
        except ValueError:
            return f"[{versionValue}] is not a real date"
    else:
        return f"[{versionKey}] version scheme is not allowed in this registry"
    return None


def formatVersion(version: typing.Any, portVersion: typing.Any) -> str:
    return (
        f"{version}#{portVersion}"
        if portVersion != 0
        else f"{version}"
    )


# --- do some checks first

if not registryPath.is_dir():
    logging.error(f"Registry path [{registryPath.resolve()}] doesn't exist")
    raise SystemExit(2)

portsPath: pathlib.Path = registryPath / "ports"
if not portsPath.is_dir():
    logging.error(
        " ".join((
            "There is no [ports] folder inside the registry,",
            "you might have provided a wrong path to the registry"
        ))
    )
    raise SystemExit(3)

baselinePath: pathlib.Path = registryPath / "versions" / "baseline.json"
if not baselinePath.is_file():
    logging.error(
        " ".join((
            "There is no [versions/baseline.json] file inside the registry,",
            "you might have provided a wrong path to the registry"
        ))
    )
    raise SystemExit(4)

baseline: typing.Dict[str, typing.Any] = {}
with open(baselinePath, "r") as f:
    try:
        baseline = json.load(f).get("default", {})
    except (ValueError, AttributeError) as ex:
        logging.error(f"Could not read/parse [versions/baseline.json]: {ex}")
        raise SystemExit(5)

# ---

valueErrorTemplateString = "".join((
    Fore.RED,
    Style.BRIGHT,
    "{errorval}",
    Style.RESET_ALL
))
valueSuccessTemplateString = "".join((
    Fore.GREEN,
    Style.BRIGHT,
    "{successval}",
    Style.RESET_ALL
))

portsSchema = pandera.DataFrameSchema(
    {
        "version": pandera.Column(str),
        "stated-hash": pandera.Column(str),
        "actual-hash": pandera.Column(str)
    },
    index=pandera.Index(str, unique=True),
    strict=True,
    coerce=False
)

ports: pandas.DataFrame = pandas.DataFrame()
problematicPorts: typing.Set[str] = set()
# ports with an invalid version value format in their manifest
invalidVersionPorts: typing.Set[str] = set()
# ports whose baseline differs from the manifest, which is not necessarily a problem,
# because a new version might be intentionally held back from the baseline
baselineDifferences: typing.Dict[str, str] = {}

for p in sorted([p.name for p in portsPath.iterdir() if p.is_dir()]):
    version: typing.Optional[str] = None
    versionKey: typing.Optional[str] = None
    statedHash: typing.Optional[str] = None
    actualHash: typing.Optional[str] = None
    portVersion: int = 0

    manifest: pathlib.Path = portsPath / p / "vcpkg.json"
    if not manifest.is_file():
        problematicPorts.add(p)
        logging.error(f"Port [{p}] has no manifest")
    else:
        manifestContent: typing.Dict[str, typing.Any] = {}
        with open(manifest, "r") as f:
            manifestContent = json.load(f)

        if "version" in manifestContent.keys():
            versionKey = "version"
        elif "version-date" in manifestContent.keys():
            versionKey = "version-date"
        else:
            problematicPorts.add(p)
            unsupportedKeys: typing.List[str] = [
                k for k in unsupportedVersionKeys if k in manifestContent
            ]
            if unsupportedKeys:
                logging.error(
                    " ".join((
                        f"Port [{p}] manifest uses the [{unsupportedKeys[0]}]",
                        "version scheme, which is not allowed in this registry",
                        "(only [version] and [version-date] are)"
                    ))
                )
            else:
                logging.error(f"Port [{p}] manifest has no version value")

        if versionKey is not None:
            version = manifestContent.get(versionKey)
            versionProblem: typing.Optional[str] = getVersionFormatProblem(
                versionKey,
                version
            )
            if versionProblem is not None:
                problematicPorts.add(p)
                invalidVersionPorts.add(p)
                logging.error(
                    " ".join((
                        f"Port [{p}] manifest has an invalid [{versionKey}]",
                        f"value: {versionProblem}"
                    ))
                )

        if "port-version" in manifestContent.keys():
            portVersion = manifestContent.get("port-version")

        baselineEntry: typing.Optional[typing.Dict[str, typing.Any]] = (
            baseline.get(p)
        )
        if baselineEntry is None:
            problematicPorts.add(p)
            logging.error(
                f"Port [{p}] is missing in [versions/baseline.json]"
            )
        elif versionKey is not None:
            baselineVersion: typing.Any = baselineEntry.get("baseline")
            baselinePortVersion: typing.Any = baselineEntry.get("port-version")
            baselineProblem: typing.Optional[str] = (
                getVersionFormatProblem(versionKey, baselineVersion)
                if baselineVersion is not None
                else "there is no [baseline] value"
            )
            if baselineProblem is None and not isinstance(
                baselinePortVersion,
                int
            ):
                baselineProblem = "there is no integer [port-version] value"
            if baselineProblem is not None:
                problematicPorts.add(p)
                logging.error(
                    " ".join((
                        f"Port [{p}] has an invalid entry",
                        f"in [versions/baseline.json]: {baselineProblem}"
                    ))
                )
            # a port with an invalid manifest version is already reported
            elif p not in invalidVersionPorts and (
                baselineVersion != version
                or
                baselinePortVersion != portVersion
            ):
                baselineDifferences[p] = " ".join((
                    "baseline",
                    formatVersion(baselineVersion, baselinePortVersion),
                    "/ manifest",
                    formatVersion(version, portVersion)
                ))

    if version is not None:
        versionsFile: pathlib.Path = (
            registryPath / "versions" / f"{p[0]}-" / f"{p}.json"
        )
        if not versionsFile.is_file():
            problematicPorts.add(p)
            logging.error(f"Port [{p}] has no versions file")
        else:
            versionsFileContent: typing.Dict[str, typing.Any] = {}
            with open(versionsFile, "r") as f:
                try:
                    versionsFileContent = json.load(f)
                except Exception as ex:
                    problematicPorts.add(p)
                    logging.error(ex)
                    continue

            for v in versionsFileContent["versions"]:
                versionsFileVersion: str = v.get("version")
                versionsFilePortVersion: typing.Optional[int] = 0
                foundMatchingVersion: bool = False
                if versionsFileVersion is None:
                    versionsFileVersion = v.get("version-date")
                if versionsFileVersion is None:
                    logging.warning(
                        " ".join((
                            f"Port [{p}] is missing one of the version values",
                            "in its versions file"
                        ))
                    )
                else:
                    versionsFilePortVersion = v.get("port-version", 0)
                if (
                    version == versionsFileVersion
                    and
                    portVersion == versionsFilePortVersion
                ):
                    foundMatchingVersion = True

                    # stated hash is read from the port versions file
                    statedHash = v.get("git-tree", statedHash)

                    # actual hash is calculated with a bare `git rev-parse`
                    try:
                        actualHash = getRevParseHash(
                            registryPath,
                            "HEAD",
                            f"ports/{p}"
                        )
                        # both stated and actual hash values can be None,
                        # so comparing them not only will be useless
                        # but also incorrect, as None == None
                        if actualHash is None:
                            problematicPorts.add(p)
                        elif (
                            actualHash != statedHash
                        ):
                            problematicPorts.add(p)
                            actualHash = valueErrorTemplateString.format(
                                errorval=actualHash
                            )
                    except Exception as ex:
                        problematicPorts.add(p)
                        logging.error(ex)

                    break
            if not foundMatchingVersion:
                problematicPorts.add(p)
                logging.error(
                    " ".join((
                        f"Version [{version}#{portVersion}] for the port",
                        f"[{p}] is not present in its versions file"
                    ))
                )

    if version is not None and portVersion != 0:
        version = f"{version}#{portVersion}"
    port: pandas.DataFrame = pandas.DataFrame(
        {
            "version": (
                (
                    valueErrorTemplateString.format(errorval=version)
                    if p in invalidVersionPorts
                    else f"{Style.DIM}{version}{Style.RESET_ALL}"
                )
                if version is not None
                else valueErrorTemplateString.format(
                    errorval="could not get version"
                )
            ),
            "stated-hash": (
                f"{Style.DIM}{statedHash}{Style.RESET_ALL}"
                if statedHash is not None
                else valueErrorTemplateString.format(
                    errorval="could not get stated hash"
                )
            ),
            "actual-hash": (
                valueSuccessTemplateString.format(
                    successval=actualHash
                )
                if actualHash is not None
                else valueErrorTemplateString.format(
                    errorval="could not get actual hash"
                )
            )
        },
        index=[f"{Style.DIM}{p}{Style.RESET_ALL}"]
    )
    ports = pandas.concat([ports, port])

portsSchema.validate(ports)

print(
    tabulate(
        ports,
        headers=[
            f"{Style.DIM}{header.replace('-', ' ')}{Style.RESET_ALL}"
            for header
            in ports.columns.values.tolist()
        ],
        tablefmt="psql",
        floatfmt="g"
    )
)

baselineDifferencesCnt: int = len(baselineDifferences)
if baselineDifferencesCnt > 0:
    print()
    print(
        "\n".join(
            [
                " ".join((
                    "Ports whose baseline differs from the manifest, although",
                    f"that might be intentional (total {baselineDifferencesCnt}):"
                ))
            ]
            +
            [
                f"- {Fore.YELLOW}{p}{Style.RESET_ALL}: {d}"
                for p, d in sorted(baselineDifferences.items())
            ]
        )
    )

problematicPortsCnt: int = len(problematicPorts)
if problematicPortsCnt > 0:
    print()
    print(
        "".join((
            f"Problematic ports (total {problematicPortsCnt}): ",
            ", ".join(
                [
                    f"{Fore.RED}{p}{Style.RESET_ALL}"
                    for p in sorted(problematicPorts)
                ]
            )
        ))
    )
    raise SystemExit(1)
