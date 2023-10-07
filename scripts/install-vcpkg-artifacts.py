import logging
from datetime import datetime
import pathlib
import argparse
import re
import os
import shutil

import typing

loggingLevel: int = logging.INFO
loggingFormat: str = "[%(levelname)s] %(message)s"

argParser = argparse.ArgumentParser(
    prog="install-vcpkg-artifacts",
    description="".join((
        "%(prog)s\n",
        "Merges vcpkg installation into the project installation, ",
        "while filtering out blacklisted dependencies\n\n",
        f"Copyright (C) 2023-{datetime.now().year} ",
        "Declaration of VAR\n",
        "License: GPLv3"
    )),
    formatter_class=argparse.RawDescriptionHelpFormatter,
    allow_abbrev=False
)
requiredNamed = argParser.add_argument_group("required arguments")
requiredNamed.add_argument(
    "--cmake-preset",
    required=True,
    metavar="windows-msvc143",
    help="CMake preset"
)
requiredNamed.add_argument(
    '--vcpkg-triplet',
    required=True,
    metavar="decovar-x64-windows-static-md-v143",
    help="vcpkg triplet"
)
argParser.add_argument(
    "projectPath",
    type=pathlib.Path,
    nargs="?",
    default=pathlib.Path("."),
    metavar="/path/to/project/",
    help="Path to the project"
)
argParser.add_argument(
    "--dry-run",
    action='store_true',
    help="only list things to be copied/moved/deleted (default: %(default)s)"
)
argParser.add_argument(
    "--debug",
    action='store_true',
    help="enable debug/dev mode (default: %(default)s)"
)
cliArgs = argParser.parse_args()

projectPath: pathlib.Path = cliArgs.projectPath
cmakePreset: str = cliArgs.cmake_preset
vcpkgTriplet: str = cliArgs.vcpkg_triplet
dryRun: bool = cliArgs.dry_run
debugMode: bool = cliArgs.debug

if debugMode:
    loggingLevel = logging.DEBUG
    # 8 is the length of "CRITICAL" - the longest log level name
    loggingFormat = "%(asctime)s | %(levelname)-8s | %(message)s"
logging.basicConfig(
    format=loggingFormat,
    level=loggingLevel
)

logging.debug(f"CLI arguments: {cliArgs}")
logging.debug("-")

# --- do some checks first

if not projectPath.is_dir():
    logging.error(f"Project path [{projectPath.resolve()}] doesn't exist")
    raise SystemExit(1)

if not (projectPath / "vcpkg.json").is_file():
    logging.warning(
        " ".join((
            "There is no [vcpkg.json] manifest in the project folder,",
            "you might have provided a wrong project path"
        ))
    )

vcpkgInstallationPath: pathlib.Path = (
    projectPath / "build" / cmakePreset / "vcpkg_installed"
)
if not vcpkgInstallationPath.is_dir():
    logging.error(
        " ".join((
            f"Path to vcpkg installation [{vcpkgInstallationPath.resolve()}]",
            "does not exist"
        ))
    )
    raise SystemExit(2)

vcpkgTripletInstallationPath: pathlib.Path = (
    vcpkgInstallationPath / vcpkgTriplet
)
if not vcpkgTripletInstallationPath.is_dir():
    logging.error(
        " ".join((
            "Path to vcpkg triplet artifacts",
            f"[{vcpkgTripletInstallationPath.resolve()}] does not exist"
        ))
    )
    raise SystemExit(2)

projectInstallationPath: pathlib.Path = projectPath / "install" / cmakePreset
if not projectInstallationPath.is_dir():
    logging.error(
        " ".join((
            "Path to project installation",
            f"[{projectInstallationPath.resolve()}] does not exist"
        ))
    )
    raise SystemExit(3)

filterOutBlacklistedDependencies: bool = True
vcpkgInfoLists: pathlib.Path = vcpkgInstallationPath / "vcpkg" / "info"
if not vcpkgInfoLists.is_dir():
    logging.warning(
        " ".join((
            f"The vcpkg info lists path [{vcpkgInfoLists.resolve()}]",
            "does not exist, will skip filtering out blacklisted dependencies"
        ))
    )
    logging.info("-")
    filterOutBlacklistedDependencies = False

# --- filter out dependencies

# blacklist for excluding dependencies from being merged with the project
# installation and then published
#
# such dependencies would include those required for building project
# tools/applications/executables, so they are not needed to be available
# for end-users in order to link with the project
#
# these values will be used as wildcards, so for example `datakit` value
# from here will get transformed into
# `/path/to/vcpkg_installed/vcpkg/info/datakit*.list`,
# and so if there are several files in that folder starting with `datakit`,
# then their combined contents will be used, which is actually good,
# so this is intentional
#
# there are also exceptions for some files from those blacklisted dependencies
# (for instance, we want to keep GDAL DLLs)
dependenciesBlacklist: typing.Dict[str, typing.Dict[str, typing.Any]] = {
    "datakit":
    {
        "exceptions": []
    },
    "gdal":
    {
        "exceptions":
        [
            "bin/gdal304.dll",
            "share/gdal/dlls/freexl.dll",
            "share/gdal/dlls/geos.dll",
            "share/gdal/dlls/geos_c.dll",
            "share/gdal/dlls/iconv-2.dll",
            "share/gdal/dlls/libcrypto-1_1-x64.dll",
            "share/gdal/dlls/libcurl.dll",
            "share/gdal/dlls/libexpat.dll",
            "share/gdal/dlls/libmysql.dll",
            "share/gdal/dlls/libpq.dll",
            "share/gdal/dlls/libssl-1_1-x64.dll",
            "share/gdal/dlls/libxml2.dll",
            "share/gdal/dlls/ogdi.dll",
            "share/gdal/dlls/openjp2.dll",
            "share/gdal/dlls/proj_7_2.dll",
            "share/gdal/dlls/spatialite.dll",
            "share/gdal/dlls/sqlite3.dll",
            "share/gdal/dlls/tiff.dll",
            "share/gdal/dlls/xerces-c_3_2.dll",
            "share/gdal/dlls/zlib.dll"
        ]
    }
}

# check which of the blacklisted dependencies are actually installed
actuallyInstalledDependencies: typing.Dict[str, typing.List[pathlib.Path]] = {}
for d in dependenciesBlacklist.keys():
    dependencyLists = list(vcpkgInfoLists.glob(f"{d}*.list"))
    listsCount: int = len(dependencyLists)
    logging.info(f"- {d} (lists found: {listsCount})")
    if not listsCount > 0:
        logging.info(
            " ".join((
                "no lists found for that pattern (most likely",
                "this is okay, because some dependencies",
                "are platform-specific)"
            ))
        )
    else:
        actuallyInstalledDependencies[d] = dependencyLists
logging.info("-")

# first process the exceptions

actuallyInstalledDependenciesCnt: int = len(actuallyInstalledDependencies)

if actuallyInstalledDependenciesCnt > 0:
    logging.info("Copying exceptions...")
    if dryRun:
        logging.info("dry run, not copying exceptions")
    else:
        for dpndnc in actuallyInstalledDependencies:
            # should probably check first if it has any
            for dbe in dependenciesBlacklist[dpndnc]["exceptions"]:
                dbePathSource: pathlib.Path = (
                    vcpkgInstallationPath / vcpkgTriplet / dbe
                )
                dbePathDestination: pathlib.Path = (
                    projectInstallationPath / dbe
                )
                dbePathDestination.parent.mkdir(parents=True, exist_ok=True)
                try:
                    shutil.copy(dbePathSource, dbePathDestination)
                except FileNotFoundError:
                    logging.error(
                        " ".join((
                            f"file [{dbePathSource.resolve()}]",
                            "does not exist"
                        ))
                    )
                    raise SystemExit(4)
else:
    logging.info(
        " ".join((
            "None of the blacklisted dependencies are installed,",
            "no exceptions to copy"
        ))
    )
logging.info("-")

# and then delete artifacts of blacklisted ports

folderRegEx = re.compile(r"^.*\/$")
portNameRegEx = r"(?:\w+-|\w)+[^-]\/"
commonFoldersRegEx = re.compile(
    "".join((
        fr"^(?:{portNameRegEx})",
        r"(?:bin|debug\/lib|include|lib|share|tools)\/",
        fr"{portNameRegEx}"
    ))
)

if actuallyInstalledDependenciesCnt > 0:
    if filterOutBlacklistedDependencies:
        logging.info("Filtering out blacklisted dependencies...")
        # first delete the files
        for d in actuallyInstalledDependencies:
            artifactsPaths: typing.List[str] = []
            for lst in actuallyInstalledDependencies[d]:
                with open(lst, "r") as lf:
                    artifactsPaths.extend(lf.read().splitlines())

            foldersToDelete: typing.Set[str] = set()
            for ap in artifactsPaths:
                commonFoldersMatches = commonFoldersRegEx.match(ap)
                if commonFoldersMatches:
                    # ap = re.sub(commonFoldersRegEx, r"\2", ap)
                    foldersToDelete.add(commonFoldersMatches.group(0))
            logging.debug(f"folders to delete: {foldersToDelete}")

            filesToDelete: typing.Set[str] = set(
                ap for ap in artifactsPaths
                if (
                    not folderRegEx.match(ap)
                    and not ap.startswith(tuple(foldersToDelete))
                )
            )
            logging.debug(f"files to delete: {filesToDelete}")

            if dryRun:
                logging.info("dry run, not deleting anything")
            else:
                logging.info("deleting artifacts...")
                for fl in filesToDelete:
                    try:
                        os.remove(vcpkgInstallationPath / fl)
                    except FileNotFoundError:
                        logging.error(
                            " ".join((
                                f"file [{vcpkgInstallationPath / fl}]",
                                "is marked for deletion, but it isn't there"
                            ))
                        )
                for fld in foldersToDelete:
                    try:
                        shutil.rmtree(vcpkgInstallationPath / fld)
                    except FileNotFoundError:
                        logging.error(
                            " ".join((
                                f"directory [{vcpkgInstallationPath / fld}]",
                                "is marked for deletion, but it isn't there"
                            ))
                        )
    else:
        logging.info("Filtering out blacklisted dependencies has been skipped")
else:
    logging.info(
        " ".join((
            "None of the blacklisted dependencies are installed,",
            "nothing to filter out"
        ))
    )
logging.info("-")

# --- copy (or rather merge) the vcpkg installation into project installation

logging.info("Merging vcpkg installed artifacts into project installation...")
if dryRun:
    logging.info(
        " ".join((
            f"dry run, not merging {vcpkgTripletInstallationPath.resolve()}",
            f"into {projectInstallationPath.resolve()}"
        ))
    )
else:
    shutil.copytree(
        vcpkgTripletInstallationPath,
        projectInstallationPath,
        dirs_exist_ok=True
    )

logging.info("-")
logging.info("Done")
