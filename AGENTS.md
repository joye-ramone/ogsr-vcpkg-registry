# OGSR vcpkg registry — agent guide

How to update a package in this registry and how to add a new one. `README.md` is the user-facing list of packages and how an engine fork consumes the registry; this file is the maintenance workflow.

The consumer is OGSR Engine (`F:\games\OGSR\OGSR_Engine_private`, its `vcpkg-configuration.json` and `agent/engine_PLAN_vcpkg.md`). Its triplets are `x64-windows-static` and `x64-windows-static-asan` (`<engine>\ogsr-triplets`): static libraries, static CRT, Debug with `_ITERATOR_DEBUG_LEVEL=0`, Release with `/arch:AVX2`.

## 1. How the registry works

```
ports/<port>/            vcpkg.json, portfile.cmake and every file the portfile copies (CMakeLists.txt, patches, config files, usage)
versions/baseline.json   the latest version of every port
versions/o-/<port>.json  every published version -> the git tree of ports/<port> at that version
```

- vcpkg resolves a version through `versions/` and checks out `ports/<port>` from the git tree recorded there. So a published version can't change: any change to a port (even its `usage` text) needs a new version or `port-version`.
- The engine pins the registry by commit (`baseline` in its `vcpkg-configuration.json`). New versions reach the engine only when that baseline moves.

## 2. Rules for every port

- Name `ogsr-<lib>`, so it never shadows a port of the main vcpkg registry (the engine maps `ogsr-*` to this registry).
- Static only: `vcpkg_check_linkage(ONLY_STATIC_LIBRARY)` and `"supports": "windows & x64 & !uwp & static"` (or `& staticcrt` for prebuilt binaries).
- Sources pinned to a commit: `vcpkg_from_github` with `REF <full commit SHA>` and `SHA512`, `HEAD_REF <branch>` for reference. Never a branch name as `REF`.
- Versions: `version-date` = the source commit date (forks and libraries without a fitting tag), `version` = the upstream version when the port pins a release tag (`ogsr-nvidia-dlss` 310.9.1). Port-only changes bump `port-version`.
- Match the engine's former build where there was one: same sources, defines and flags (`/fp:fast` where the engine had it, `/GL` in Release via `INTERPROCEDURAL_OPTIMIZATION_RELEASE`). Release objects with `/GL` link only with the same MSVC version; vcpkg builds ports with the consumer's toolset, so that holds.
- Ship a `usage` file (how to include and link it, for MSBuild and CMake) and, for CMake builds, an exported config (`ogsr::<name>` targets or the upstream package's own names).
- Install the license with `vcpkg_install_copyright`.
- `vcpkg.json` must be in canonical form: run `vcpkg format-manifest ports/<port>/vcpkg.json` (else `x-add-version` refuses it).

## 3. Port patterns in this repo

| Pattern | Example | When |
|---|---|---|
| Upstream CMake, options only | `ogsr-directxtex` | the source has a usable CMake build |
| Own `CMakeLists.txt` copied into the source | `ogsr-ode`, `ogsr-libsquashfs`, `ogsr-fidelityfx-fsr3` | no CMake upstream, or only a small part is needed; list the sources explicitly (the engine's former vcxproj is the reference) |
| Upstream build script | `ogsr-luajit` (`msvcbuild.bat`, run per configuration in its own copy of the source) | the build generates code (LuaJIT's buildvm) |
| Prebuilt files, each downloaded by itself | `ogsr-nvidia-dlss` (`vcpkg_download_distfile` from `raw.githubusercontent.com/<repo>/<commit>/<path>`) | binaries in a huge repo: only the needed files |
| Sources only, nothing built | `ogsr-tracy` (installs `public/` to `include\ogsr-tracy`) | the consumer must compile the code with its own defines (see README "Why `ogsr-tracy` is sources only") |
| Patch on top of upstream | `ogsr-tracy/unused-variables.patch` (`PATCHES` of `vcpkg_from_github`) | a small fix that upstream doesn't have; prefer pushing it to a fork |

## 4. Updating a package

1. Find the new source commit: `git ls-remote <repo-url> refs/heads/<branch>` (or `refs/tags/<tag>^{}` for a tag).
2. In `ports/<port>/portfile.cmake` set `REF` to it and `SHA512` to `0`. In `vcpkg.json` set `version-date` (or `version`) and remove `port-version` (back to 0).
3. Test the port as an overlay from a scratch folder outside the engine (section 6). The first run fails on the hash and prints the real `SHA512`: put it in the portfile and run again. For `ogsr-nvidia-dlss`, every listed file has its own hash (set them all to `0`, one install prints them one by one) and the header list may change between releases.
4. Read the port's comments for what can break: `ogsr-fidelityfx-fsr3` copies the prebuilt shader headers to a short folder; `ogsr-tracy` must match the viewer's protocol (`tracy-capture.exe` in the game's `bin_x64`) and its patch must still apply; `ogsr-luajit`'s `msvcbuild.bat` is the engine's copy, compare it with the fork's after big upstream merges.
5. Commit the port (section 5), record the version, commit again, push.
6. In the engine: move `baseline` in `vcpkg-configuration.json` to the new registry commit, build Release, run the tests of that library, and record it in `agent/engine_PLAN_vcpkg.md`.

A change to the port only (flags, install layout, `usage` text, a patch): increase `port-version` in `vcpkg.json`, then steps 3, 5, 6.

## 5. Recording a version

`x-add-version` reads the committed git tree of the port, so the port must be committed first:

```
vcpkg format-manifest ports\<port>\vcpkg.json
git add -A
git commit -m "ports: <port> <version>"
vcpkg x-add-version <port> --x-builtin-ports-root=.\ports --x-builtin-registry-versions-dir=.\versions
git add -A
git commit -m "versions: <port> <version>"
git push
```

- `vcpkg` is the one bundled with Visual Studio (`C:\Program Files\Microsoft Visual Studio\18\Professional\VC\vcpkg\vcpkg.exe`); no `VCPKG_ROOT` or vcpkg clone is needed.
- `x-add-version` refuses to change the git tree of an existing version. Never use `--overwrite-version` on a pushed version: bump `port-version` instead.
- Two commits per change (port, then versions), messages `ports: <port> <version>` / `versions: <port> <version>`. Commits made by an agent end with the attribution line the session asks for.
- Update the package table in `README.md` (version column) in the same change.

## 6. Testing a port

Overlay test (no commit needed), in a scratch folder with this `vcpkg.json`:

```json
{ "builtin-baseline": "<the engine's builtin-baseline>", "dependencies": [ "<port>" ] }
```

and this `vcpkg-configuration.json`:

```json
{ "overlay-ports": [ "F:/games/OGSR/ogsr-vcpkg-registry/ports" ], "overlay-triplets": [ "F:/games/OGSR/OGSR_Engine_private/ogsr-triplets" ] }
```

```
vcpkg install --triplet x64-windows-static --x-install-root=<scratch>\installed
```

- Check the build logs in `<scratch>\installed\vcpkg\blds\<port>\` (compiler flags, warnings), the installed tree (`include\`, `lib\`, `debug\lib\`, `share\<port>\`).
- A small CMake consumer (`find_package(<port> CONFIG)`, call a function of the library, build Release and Debug) catches wrong export names and missing link dependencies. C++ consumers need `_ITERATOR_DEBUG_LEVEL=0` in Debug, like the engine. Example from the first ports: create a D3D11 device of feature level 11_1 and an FSR3 context; load a DDS from memory; open a Lua state.
- Registry test after the versions commit: the same scratch folder with a `registries` entry (`"kind": "git"`, `"repository": "F:/games/OGSR/ogsr-vcpkg-registry"`, `"baseline": "<new commit>"`, `"packages": ["ogsr-*"]`) instead of `overlay-ports`. It proves the versions database points at the right tree.
- Final test is always the engine build and its tests (`agent/engine_PLAN_vcpkg.md` lists the ones used per library).

## 7. Adding a new package

1. Decide the source: a fork under `joye-ramone` / `OGSR` (preferred for engine-specific changes) or upstream pinned to a commit. Check the main vcpkg registry first: if it has the library at a usable version and build, the engine should use that port directly (as it does with `tinyxml2`), not a copy here.
2. Create `ports/ogsr-<lib>/` with `vcpkg.json` (name, version, description, homepage, license, supports, `vcpkg-cmake` / `vcpkg-cmake-config` host dependencies for CMake builds) and `portfile.cmake`, using the closest pattern from section 3 as the template.
3. Compare with how the engine built it before (its vcxproj or build script): sources, defines, `/fp`, CRT, warnings disabled, generated files. Keep public defines the consumer needs in the exported CMake target and in `usage` (e.g. `dSINGLE`, `FFX_GCC`).
4. Test as an overlay (section 6), commit, record the version (section 5), add a row to `README.md`, push.
5. In the engine: add the package to `vcpkg.json`, remove its project, include paths, name-only links (`#pragma comment(lib)`, `AdditionalDependencies`) and download line; check for includes that only resolved through a removed include path. Steps and findings: `agent/engine_PLAN_vcpkg.md`.

## 8. Gotchas

- Paths over 260 characters: `cl.exe` can't open them even with long paths enabled, and vcpkg's buildtree paths are long (`<install root>\vcpkg\blds\<port>\src\<hash>.clean\...`). Copy deep files to a short folder (`${CURRENT_BUILDTREES_DIR}/sh`, see `ogsr-fidelityfx-fsr3`).
- `.bat` files are stored with CRLF (`*.bat -text` in `.gitattributes`): vcpkg extracts the port tree as stored, and cmd.exe mis-parses labels in LF files. Everything else is LF.
- Download file names must be unique in vcpkg's download cache: prefix them with the port and version (`nvidia-dlss-${VERSION}-<path>`).
- vcpkg warns about CMake variables the project doesn't read; variables read by CMake itself (`CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE`) go into `MAYBE_UNUSED_VARIABLES`.
- A prebuilt DLL in a static port needs `VCPKG_POLICY_DLLS_IN_STATIC_LIBRARY` and `VCPKG_POLICY_DLLS_WITHOUT_LIBS`. Install exactly one variant of a prebuilt library per configuration: vcpkg's MSBuild auto-link links every `.lib` in `lib\` / `debug\lib\`, and variants of one library clash.
- Port files with backslashes edited through a Bash heredoc or inline Python get their backslashes mangled: write them with an editor or the agent's file tools.
- Don't test from inside a folder vcpkg must delete or rename (a shell whose current directory is in `buildtrees` makes `vcpkg_extract_source_archive` fail with "file RENAME failed").
