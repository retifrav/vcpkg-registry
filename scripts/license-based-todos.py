import sys
import logging
import pathlib
import json
from license_expression import get_spdx_licensing

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

registryPath: pathlib.Path = pathlib.Path(".").resolve()
if registryPath.name != "vcpkg-registry":
    logging.warning(
        " ".join((
            "The script is expected to run from vcpkg registry path, however",
            "current folder name is not [vcpkg-registry]. Perhaps",
            "you cloned the registry repository under a different name?"
        ))
    )

spdxLicensing = get_spdx_licensing()
#spdxLicenses: List[str] = []
#spdxLicensesFile: pathlib.Path = registryPath / "scripts" / "spdx" / "licenses.txt"
#if not spdxLicensesFile.is_file():
#    logging.warning(
#        " ".join((
#            "Could not find the SPDX licenses file, expected to find it at",
#            f"[{spdxLicensesFile}]. Have you fetched the licenses with",
#            "./scripts/spdx/fetch-spdx-licenses.ps1? Until you do that,",
#            "licenses identifiers won't be validated."
#        ))
#    )
#else:
#    with open(spdxLicensesFile, "r") as f:
#        spdxLicenses = f.read().splitlines()
#        logging.debug(f"Number of known SPDX licenses: {len(spdxLicenses)}")

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
print(f"Total ports: {len(ports)}\n")

for p in ports:
    manifest: pathlib.Path = portsPath / p / "vcpkg.json"
    if not manifest.is_file():
        logging.warning(f"[{p}] has no port manifest")
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
            # and `null` in JSON translates/converts to `None` in Python dictionary
            license: Optional[str] = manifestContent.get("license")
            if license is None:
                todos["non-spdx-license"].append(p)
            else:
                #logging.debug(f"[{p}] license: {license}")
                #licenseExpressionParsed = spdxLicensing.parse(licenseExpression)
                #logging.debug(licenseExpressionParsed.pretty())
                licenseExpressionValidated = spdxLicensing.validate(license)
                if licenseExpressionValidated.errors:
                    todos["non-spdx-license"].append(p)
                    logging.error(f"[{p}] license is not a valid SPDX license expression")
                    for e in licenseExpressionValidated.errors:
                        print(f"- {e}")
                else:
                    if license in licensesThatRequirePublishingPatches:
                        todos["publish-patches"].append(p)
                    elif license in licensesThatRequireOpeningSources:
                        todos["open-sources"].append(p)
        else:
            todos["missing-license"].append(p)

print("\nResults:")

portsWithoutLicenseCnt: int = len(todos["missing-license"])
if portsWithoutLicenseCnt > 0:
    print(
        " ".join((
            f"- ports without licenses (total {portsWithoutLicenseCnt}):",
            ', '.join(todos["missing-license"])
        ))
    )

portsWithNonSpdxLicensesCnt = len(todos["non-spdx-license"])
if portsWithNonSpdxLicensesCnt > 0:
    print(
        " ".join((
            "- ports with non-SPDX licenses",
            f"(total {portsWithNonSpdxLicensesCnt}):",
            ', '.join(todos["non-spdx-license"])
        ))
    )

portsRequirePublishingPatchesCnt: int = len(todos["publish-patches"])
if portsRequirePublishingPatchesCnt > 0:
    # print(
    #     " ".join((
    #         "- ports that require publishing patches:\n-",
    #         '\n- '.join(todos["publish-patches"])
    #     ))
    # )
    print(
        " ".join((
            "- ports that require publishing patches",
            f"(total {portsRequirePublishingPatchesCnt}):",
            ", ".join(todos["publish-patches"])
        ))
    )

portsRequireOpeningSourcesCnt: int = len(todos["open-sources"])
if portsRequireOpeningSourcesCnt > 0:
    print(
        " ".join((
            "- ports that require opening sources",
            f"(total {portsRequireOpeningSourcesCnt}):",
            ", ".join(todos["open-sources"])
        ))
    )
