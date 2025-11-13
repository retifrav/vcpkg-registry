# Scripts

<!-- MarkdownTOC -->

- [check-versions-and-hashes](#check-versions-and-hashes)
- [install-vcpkg-artifacts](#install-vcpkg-artifacts)
- [vcpkg-assets-caching](#vcpkg-assets-caching)
- [license-based-todos](#license-based-todos)
- [add-new-version](#add-new-version)

<!-- /MarkdownTOC -->

For executing Python scripts, the following packages are expected to be installed and available in your current environment:

``` sh
$ pip install \
    colorama \
    pandas \
    pandera \
    tabulate
```

## check-versions-and-hashes

Checks that declared rev-parse hashes in ports versions match their actual values:

``` sh
$ cd /path/to/vcpkg-registry
$ pip install pandas pandera tabulate colorama
$ python ./scripts/check-versions-and-hashes.py
```

More details [here](https://decovar.dev/blog/2022/10/30/cpp-dependencies-with-vcpkg/#checking-versions-and-hashes).

## install-vcpkg-artifacts

Merges vcpkg installation with project installation:

``` sh
$ cd /path/to/project
$ python /path/to/vcpkg-registry/scripts/install-vcpkg-artifacts.py \
    --cmake-preset vcpkg-default-triplet \
    --vcpkg-triplet arm64-osx \
    --blacklist "vcpkg-cmake,json-nlohmann"
```

More details [here](https://decovar.dev/blog/2022/10/30/cpp-dependencies-with-vcpkg/#distributing-your-project).

## vcpkg-assets-caching

Downloading/uploading vcpkg assets (*required build tools*) from/to a remote cache of HTTP type (*such as JFrog Artifactory*).

More details [here](https://decovar.dev/blog/2022/10/30/cpp-dependencies-with-vcpkg/#asset-caching).

## license-based-todos

To print a list of license-based ToDos:

``` sh
$ cd /path/to/vcpkg-registry
$ python ./scripts/license-based-todos.py
...
[INFO] Ports that require publishing patches (total 1): datachannel
```

## add-new-version

It is almost the same as what [x-add-version](https://learn.microsoft.com/en-us/vcpkg/commands/add-version) does (*which expects you to have `./scripts/vcpkg-tools.json` in your registry*):

``` sh
$ cd /path/to/your/registry/
$ vcpkg x-add-version --vcpkg-root . --skip-formatting-check some
```

But I didn't like the way `x-add-version` formats and sorts the JSON files, so I made this script instead. In addition to the JSON formatting that I like, it does some more(?) checks and allows you to specify the version (*and also to skip updating the baseline*):

``` sh
$ python ./scripts/add-new-version.py --port-name some --port-version 1.2.3#4
```

It assumes that version values in the ports files are in SemVer format (*with a separate line for the `port-version` value*).

The result:

``` diff
diff --git a/versions/baseline.json b/versions/baseline.json
index a8fcdde..46975db 100644
--- a/versions/baseline.json
+++ b/versions/baseline.json
@@ -358,8 +358,8 @@
         },
         "some":
         {
-            "baseline": "0.9.1",
-            "port-version": 0
+            "baseline": "1.2.3",
+            "port-version": 4
         },
         "spectra":
         {
diff --git a/versions/s-/some.json b/versions/s-/some.json
index 21d0ea5..ade48ab 100644
--- a/versions/s-/some.json
+++ b/versions/s-/some.json
@@ -1,6 +1,11 @@
 {
     "versions":
     [
+        {
+            "version": "1.2.3",
+            "port-version": 4,
+            "git-tree": "99548035005d6946463bec440b872e2907ca6684"
+        },
         {
             "version": "0.9.1",
             "git-tree": "41efdeb379935af4f2cf2299be6aa1c0c73f257f"
```

I usually do those modifications myself, so I don't really need such a script, but it becomes a different story when you need to update the ports automatically in your CI/CD. Here's a crude example of how the entire process might look like in a Bash script:

``` sh
#!/bin/bash

set -Eeuo pipefail

portName='some'
newPortVersion='1.2.3'

cd ./path/to/vcpkg-registry

sed -i 's/REF .*$/REF NEW-GIT-HASH-FROM-THE-ORIGINAL-REPOSITOR/' \
    ./ports/$portName/portfile.cmake
sed -i "s/\"version\": \"[0-9]\+\.[0-9]\+\.[0-9]\+\",$/\"version\": \"$newPortVersion\",/" \
    ./ports/$portName/vcpkg.json

python ./scripts/add-new-version.py \
    --port-name $portName \
    --port-version "$newPortVersion#0"

export GIT_AUTHOR_NAME='buildbot'
export GIT_AUTHOR_EMAIL='buildbot@your.company'
export GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME
export GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL

echo 'Staging ./ports/$portName might be redundant, if it is already staged/committed'
git add \
    ./ports/$portName \
    ./versions/baseline.json \
    ./versions/${portName:0:1}-/$portName.json
git commit -m "[$portName] version $newPortVersion"

git log -n2 --oneline

git push
```
