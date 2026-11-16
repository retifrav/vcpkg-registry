# Version bookkeeping

Evidence and precedents behind the "Versions database" section of `CLAUDE.md`. The rules live there; this file explains them.

## What `add-new-version.py` does to the index

`revParseSubfolder()` runs `git add ports/X` first and then `git diff --cached --exit-code --no-patch ports/X`. When that shows changes, it takes `git write-tree --prefix ports/X` and then runs `git reset --quiet ports/X`. Otherwise it takes `git rev-parse HEAD:ports/X`. The `add` is what makes unstaged edits count: without it the script would fall back to the committed tree. The final `reset` unstages everything in that folder, including hunks that were staged on purpose, and that is why the script runs on a copy of the index.

The temporary-index recipe from `CLAUDE.md` was cross-checked on `spng` on 2026-10-29: the `git-tree` the script wrote matched `GIT_INDEX_FILE=<copy> git add ports/spng && GIT_INDEX_FILE=<copy> git write-tree --prefix ports/spng`. The script imports only the standard library, so `python3 -I` runs it without the packages from `scripts/README.md`.

Exit codes that come up in practice:

- `9`: the port is not in `baseline.json` (a new port; add the entry by hand and use `--not-updating-baseline`)
- `11`: the baseline already has exactly that version
- `15`: that version is already in the versions file with a different `git-tree`, so the port changed after the version was added. It needs either a new `port-version` or a hand-made in-place replacement, which the script never does.
- `17`: that `git-tree` is already in the versions file, so nothing in the port folder has changed

The versions file is written before the baseline, so a failure while writing leaves a version that is merely held back from the baseline, not a baseline pointing at a missing version.

## Bump or replace in place: precedents

- `30c23a4` `[png][1.6.53] port version 1`: a fix to a pushed version. The patch change, `vcpkg.json`, `baseline.json` and the new versions entry are all in one commit.
- `e98c70a` added curl 8.23.0, and `ac856c6` replaced its `git-tree` in place two commits later, when the wolfSSL BIO patch was added.
- `9c5939f` added the `spng` port, and `dc9ed82` replaced its `git-tree` in place on the same day.
- `58096f1` added proj 9.7.0#1, and `413ae94` (`[proj][9.7.0][1] …`) replaced that entry's `git-tree` in place.
- `8dc6815` `[sqlite][3.53.1] disabled ICU feature for good, fixing DLL` replaced the `git-tree` of 3.53.1 in place, although that version had been in `origin/master` since `466b9a5` (2026-05-18). The user explicitly waived the bump there, which is the kind of exception that is theirs to make.

## Knock-on changes in dependent ports

Link-level changes do get propagated. When `sqlite` and `curl` moved to namespaced targets, the dependents' patches were updated to match: `58096f1` and `413ae94` for proj, `b9931c7` for gdal.

Optional features that nobody uses do not get updated. That rule is in the global `CLAUDE.md`, because it covers other registries too. It came from this registry: on 2026-10-29 the user declined updating the dependents affected by the new `icu[data]` feature ("those aren't really used, I will update them myself if I'll actually need that"), and the broken `sqlite[icu]` was removed instead. That removal landed in `8dc6815`, with the waived bump described above.
