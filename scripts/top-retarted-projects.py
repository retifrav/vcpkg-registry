import logging
from datetime import datetime
import pathlib
import argparse
import json
import sys

from typing import List, Dict, Optional, Any

loggingLevel: int = logging.INFO
loggingFormat: str = "[%(levelname)s] %(message)s"

argParser = argparse.ArgumentParser(
    prog="top-retarted-projects",
    description="".join((
        "-= %(prog)s =-\n\n",
        "Prints out a list of the most retarded ports (projects), where ",
        "the criteria of retardiness is the total size of all the patches ",
        "that need to be applied to the original sources to make them ",
        "build or/and install properly.\n\n",
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
    "--top",
    type=int,
    default=10,
    metavar="10",
    help="how long is the top list"
)
argParser.add_argument(
    "--threshold",
    type=int,
    default=20480,
    metavar="20480",
    help="size of patches (in bytes) to become retarded"
)
argParser.add_argument(
    "--without-portfile",
    action='store_true',
    help="do not count the size of portfile.cmake"
)
argParser.add_argument(
    "--debug",
    action='store_true',
    help="enable debug/dev mode (default: %(default)s)"
)
cliArgs = argParser.parse_args()

registryPath: pathlib.Path = cliArgs.registryPath
topListLength: int = cliArgs.top
retartedThreshold: int = cliArgs.threshold
withoutPortfile: bool = cliArgs.without_portfile
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

if topListLength < 1:
    logging.error(
        " ".join((
            f"Provided top list length ({topListLength}) is less than 1",
            "- that does not make sense"
        ))
    )
    raise SystemExit(3)

if retartedThreshold < 0:
    logging.error(
        " ".join((
            f"Provided threshold for the patches size ({retartedThreshold})",
            "is less than 0 - that does not make sense"
        ))
    )
    raise SystemExit(4)

# ---


def bytesToHumanReadableSize(bts: int) -> str:
    if bts < 1024:
        return f"{bts} Bytes"
    elif bts < 1024 * 1024:
        return f"{round(bts / 1024, 1)} KiloBytes"
    else:
        return f"{round(bts / 1024 / 1024, 1)} MegaBytes"


patchesSizePerProject: Dict[str, int] = {}

ports: List[str] = sorted([p.name for p in portsPath.iterdir() if p.is_dir()])
logging.info(f"Total number of ports in the registry: {len(ports)}")
logging.info("-")

for p in ports:
    portFolder: pathlib.Path = portsPath / p
    portfile: pathlib.Path = portFolder / "portfile.cmake"
    if not portfile.is_file():
        logging.warning(f"Port [{p}] has no portfile, skipping it")
    else:
        patchesList = list(portFolder.rglob("*.patch"))  # recursive
        patchesCnt: int = len(patchesList)
        logging.debug(f"[{p}] number of patches: {patchesCnt}")
        if patchesCnt > 0:
            patchesSizeInBytes: int = 0
            for ptch in patchesList:
                patchSize: int = ptch.stat().st_size
                logging.debug(f"- [{ptch.name}] size (in bytes): {patchSize}")
                patchesSizeInBytes += patchSize
            andPortfile: str = ""
            if not withoutPortfile:
                portfileSize: int = portfile.stat().st_size
                logging.debug(
                    f"- [{portfile.name}] size (in bytes): {portfileSize}"
                )
                if portfileSize > 2048:  # 2 KB "ought to be enough", innit
                    patchesSizeInBytes += portfileSize
                    andPortfile = " and portfile"
            # should probably also count all the other `*.cmake` files
            # aside from the `portfile.cmake`, as some ports do `include()`;
            # and there are also `Find*.cmake` modules too, which is almost
            # the same thing as patching the original project
            logging.debug(
                " ".join((
                    f"- total size of patches{andPortfile}",
                    f"(in bytes): {patchesSizeInBytes}"
                ))
            )
            patchesSizePerProject[p] = patchesSizeInBytes

logging.debug("-")
logging.info(
    f"Number of ports that have any patches: {len(patchesSizePerProject)}"
)
logging.debug(patchesSizePerProject)
logging.info("-")

projectsSortedByPatchesSize = dict(
    sorted(
        patchesSizePerProject.items(),
        key=lambda i: i[1],
        reverse=True
    )[:topListLength]
)
topRetardedProjects = {
    key: value
    for key, value in projectsSortedByPatchesSize.items()
    if value > retartedThreshold
}
andPortfile: str = ""
if not withoutPortfile:
    andPortfile = " and portfile"
if (len(topRetardedProjects) > 0):
    logging.info(
        " ".join((
            f"Top {topListLength} retarded projects (whose total",
            f"patches{andPortfile} size is bigger than",
            f"{bytesToHumanReadableSize(retartedThreshold)}):"
        ))
    )
    pstn: int = 1
    for rp in topRetardedProjects:
        logging.info(
            f"({pstn}) {rp}, {bytesToHumanReadableSize(topRetardedProjects[rp])}"
        )
        pstn += 1
else:
    logging.info(
        " ".join((
            f"Not a single port has the total size of patches{andPortfile}",
            "bigger than the retarted threshold",
            f"({bytesToHumanReadableSize(retartedThreshold)}).",
            "That is simply too good to be true, so you probably provided",
            "a way too high of a threshold. Or maybe your registry",
            "actually doesn't have any retarded ports yet (lucky you)."
        ))
    )
