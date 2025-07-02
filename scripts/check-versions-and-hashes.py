import logging
import pathlib
import argparse
import sys
import subprocess
import json
import pandas
from pandera import pandas as pandera
from tabulate import tabulate
from colorama import Fore, Style

import typing

loggingLevel: int = logging.INFO
loggingFormat: str = "[%(levelname)s] %(message)s"

argParser = argparse.ArgumentParser(
    prog="check-versions-and-hashes",
    description=" ".join((
        "%(prog)s  Declaration of VAR\nVerifies",
        "currently stated port versions and their rev-parse hashes."
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
            return revParsedHash


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

if not (registryPath / "versions" / "baseline.json").is_file():
    logging.error(
        " ".join((
            "There is no [versions/baseline.json] file inside the registry,",
            "you might have provided a wrong path to the registry"
        ))
    )
    raise SystemExit(4)

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

for p in sorted([p.name for p in portsPath.iterdir() if p.is_dir()]):
    version: typing.Optional[str] = None
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
            version = manifestContent.get("version")
        elif "version-date" in manifestContent.keys():
            version = manifestContent.get("version-date")
        else:
            problematicPorts.add(p)
            logging.error(f"Port [{p}] manifest has no version value")

        if "port-version" in manifestContent.keys():
            portVersion = manifestContent.get("port-version")

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
                versionsFileContent = json.load(f)

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
                f"{Style.DIM}{version}{Style.RESET_ALL}"
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

problematicPortsCnt: int = len(problematicPorts)
if problematicPortsCnt > 0:
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
