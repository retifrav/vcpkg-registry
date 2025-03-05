import sys
import logging
import pathlib
import json

from typing import List, Dict, Optional, Any

logging.basicConfig(
    format="[%(levelname)s] %(message)s",
    level=logging.DEBUG,
    stream=sys.stdout
)

# not a full list
licensesThatRequirePublishingPatches: List[str] = [
    "LGPL-2.0-only",
    "LGPL-2.0-or-later",
    "LGPL-2.1-only",
    "LGPL-2.1-or-later",
    "LGPL-3.0-only",
    "LGPL-3.0-or-later",
    "MPL-2.0"
]
licensesThatRequireOpeningSources: List[str] = [
    "GPL-2.0-only",
    "GPL-2.0-or-later",
    "GPL-3.0-only",
    "GPL-3.0-or-later"
]

todos: Dict[str, List[str]] = {
    # these ports have no `license` field in the manifest at all
    "missing-license": [],
    # these ports have their `license` value either set to `null`
    # or to one that is not listed in https://spdx.org/licenses/
    "non-spdx-license": [],
    # these ports licenses require publishing patches
    "publish-patches": [],
    # these ports licenses require opening/sharing our sources
    "open-sources": []
}


def validSPDXidentifier(license: str) -> bool:
    """
    If `license` is an identifier from the SPDX list
    at <https://spdx.org/licenses/>, then return `True`,
    otherwise return `False`.
    """
    # not implemented yet, need to fetch a plain-text list of SPDX licenses
    # (or store it right here inline), so until then any `license` value
    # will be a valid SPDX identifier
    return True


registryPath: pathlib.Path = pathlib.Path(".").resolve()
if registryPath.name != "vcpkg-registry":
    logging.warning(
        " ".join((
            "The script is expected to run from vcpkg registry path, however",
            "current folder name is not [vcpkg-registry]. But perhaps",
            "you cloned the registry repository under a different name?"
        ))
    )

portsPath: pathlib.Path = registryPath / "ports"
if not portsPath.is_dir():
    logging.error(
        " ".join((
            "Couldn't find the ports folder, expected it to be at",
            f"[{portsPath.resolve()}]"
        ))
    )
    raise SystemExit(1)

ports: List[str] = sorted([p.name for p in portsPath.iterdir() if p.is_dir()])
logging.info(f"Total ports: {len(ports)}")

for p in ports:
    manifest: pathlib.Path = portsPath / p / "vcpkg.json"
    if not manifest.is_file():
        logging.warning(f"Port [{p}] has no manifest")
        todos["missing-license"].append(p)
    else:
        manifestContent: Dict[str, Any] = {}
        with open(manifest, "r") as f:
            manifestContent = json.load(f)
        if "license" in manifestContent.keys():
            # the `license` field might be present and have `null` value,
            # which means that this port license is not a SPDX license
            # expression, so the license is expected to be found
            # in `/share/PORT/copyright` file
            # https://learn.microsoft.com/en-us/vcpkg/reference/vcpkg-json#license
            license: Optional[str] = manifestContent.get("license")
            if license is None:
                license = "copyright"

            # logging.debug(f"Port [{p}] license: {license}")
            if license == "copyright" or not validSPDXidentifier(license):
                todos["non-spdx-license"].append(p)
            else:
                if license in licensesThatRequirePublishingPatches:
                    todos["publish-patches"].append(p)
                elif license in licensesThatRequireOpeningSources:
                    todos["open-sources"].append(p)
        else:
            todos["missing-license"].append(p)

portsWithoutLicenseCnt: int = len(todos["missing-license"])
if portsWithoutLicenseCnt > 0:
    logging.warning(
        " ".join((
            f"Ports without licenses (total {portsWithoutLicenseCnt}):",
            ', '.join(todos["missing-license"])
        ))
    )

portsWithNonSpdxLicensesCnt = len(todos["non-spdx-license"])
if portsWithNonSpdxLicensesCnt > 0:
    logging.info(
        " ".join((
            f"Ports with non-SPDX licenses",
            f"(total {portsWithNonSpdxLicensesCnt}):",
            ', '.join(todos["non-spdx-license"])
        ))
    )

portsRequirePublishingPatchesCnt: int = len(todos["publish-patches"])
if portsRequirePublishingPatchesCnt > 0:
    # logging.info(
    #     " ".join((
    #         "Ports that require publishing patches:\n-",
    #         '\n- '.join(todos["publish-patches"])
    #     ))
    # )
    logging.info(
        " ".join((
            "Ports that require publishing patches",
            f"(total {portsRequirePublishingPatchesCnt}):",
            ", ".join(todos["publish-patches"])
        ))
    )

portsRequireOpeningSourcesCnt: int = len(todos["open-sources"])
if portsRequireOpeningSourcesCnt > 0:
    logging.info(
        " ".join((
            "Ports that require opening sources",
            f"(total {portsRequireOpeningSourcesCnt}):",
            ", ".join(todos["open-sources"])
        ))
    )
