# OGSR vcpkg registry

A [vcpkg git registry](https://learn.microsoft.com/vcpkg/maintainers/registries) with the third-party libraries that OGSR Engine uses in forked or customized form. Ports are named `ogsr-*` so they never shadow ports of the main vcpkg registry.

| Port | Source | Notes |
|---|---|---|
| `ogsr-luajit` | [joye-ramone/luajit2](https://github.com/joye-ramone/luajit2), branch `xray` | Static `LuaJIT.lib`, built with the port's copy of the engine's `msvcbuild.bat` (AVX2, `/fp:fast`, `/GL` in Release). Headers go straight into `include\` (`#include <lua.hpp>`). |
| `ogsr-ode` | [joye-ramone/ode_xray](https://github.com/joye-ramone/ode_xray), branch `xray_v2` | Static `ode.lib` (`dSINGLE`), built with the port's `CMakeLists.txt` (same sources and flags as the engine's former `default.vcxproj`). Also installs the internal headers as `include\ode\src\*.h`. |

| `ogsr-libsquashfs` | [AgentD/squashfs-tools-ng](https://github.com/AgentD/squashfs-tools-ng), `master` (after 1.3.2) | Static `squashfs.lib`, only the library (`lib/sqfs`, `lib/util`, `lib/compat`) with the lz4 and zstd compressors (vcpkg's `lz4`, `zstd`). Upstream has autotools only: the port's `CMakeLists.txt` and pre-generated `inc\config.h` follow the engine's former `libsquashfs.vcxproj`. The installed `sqfs/predef.h` is patched to the static API, so consumers don't need `SQFS_STATIC`. |
| `ogsr-directxtex` | [solbjorn/DirectXTex](https://github.com/solbjorn/DirectXTex), branch `master` | Fork with `LoadFromDDSStream` and non-owning `ScratchImage`. Built with the fork's own CMake: D3D11 support and the BC6H/BC7 GPU encoder (shaders compiled with the Windows SDK `fxc.exe`), no tools, no D3D12 (`_WIN32_WINNT=0x0603`), no OpenMP, `/GL` in Release. Same CMake package as the upstream `directxtex` port (`find_package(directxtex)`, `Microsoft::DirectXTex`), so don't install both. |
| `ogsr-nvidia-dlss` | [NVIDIA/DLSS](https://github.com/NVIDIA/DLSS), tag `v310.9.1` | Prebuilt, no build. Only the files the engine uses, each downloaded by itself from `raw.githubusercontent.com` at the pinned commit (not the 1.3 GB repo): `include\*.h`, `nvsdk_ngx_s.lib` (Release) / `nvsdk_ngx_s_dbg_iterator0.lib` (Debug), and the `nvngx_dlss.dll` runtime in `bin\` (release) / `debug\bin\` (dev, with the debug overlay). The consumer copies the DLL next to its exe. |
| `ogsr-fidelityfx-fsr3` | [OGSR/FidelityFX-SDK](https://github.com/OGSR/FidelityFX-SDK), branch `release-FSR3-3.1.2-DX11-Native-API` | Static `ffx_fsr3upscaler_x64.lib` and `ffx_backend_dx11_x64.lib`, built with the port's `CMakeLists.txt` (sources and defines of the engine's former two vcxprojs). The fork commits the compiled DX11 shader permutation headers, so no shader compiler is needed; the port copies them to a short folder (`<buildtrees>\ogsr-fidelityfx-fsr3\sh`) because their full paths in the extracted sources pass the 260-character limit of `cl.exe`. Installs the whole `include\FidelityFX` tree. Consumers define `FFX_GCC` (CMake targets do it), the static `FFX_API`. The source archive is the whole SDK repo, about 140 MB. |

All ports are static only and Windows x64 only (the engine's `x64-windows-static` / `x64-windows-static-asan` triplets). Release objects are built with `/GL`, so they link only with the same MSVC version; vcpkg builds ports with the consumer's toolset, so this holds for manifest-mode builds.

## Using it

In the consumer's `vcpkg-configuration.json`, add the registry with the commit to use as its baseline:

```json
{
  "registries": [
    {
      "kind": "git",
      "repository": "https://github.com/<owner>/ogsr-vcpkg-registry",
      "baseline": "<commit sha of this repo>",
      "packages": [ "ogsr-*" ]
    }
  ]
}
```

and list the ports in `vcpkg.json` (`"dependencies": [ "ogsr-luajit", "ogsr-ode" ]`). A private repository works as long as `git` can fetch it without a prompt (Git Credential Manager, SSH URL).

## Layout

```
ports/<port>/            vcpkg.json, portfile.cmake and files the portfile copies
versions/baseline.json   latest version of every port
versions/o-/<port>.json  every published version of the port -> git tree of ports/<port>
```

vcpkg resolves a port version through `versions/`, and fetches `ports/<port>` from the git tree recorded there, so a version is fixed once it's committed: change a port only together with a new version (or `port-version`) entry.

## Updating a port

1. Edit `ports/<port>`. For a new upstream commit: set `REF` in `portfile.cmake` to the commit SHA, set `SHA512` to `0` and run an install once: vcpkg fails and prints the real hash. Set `version-date` in `vcpkg.json` to the commit date. For a change in the port only (flags, install layout), increase `port-version` instead.
2. Test it without committing, as an overlay port, from a scratch folder with a `vcpkg.json` that depends on the port:
   ```
   vcpkg install --overlay-ports=<this repo>\ports --overlay-triplets=<engine>\ogsr-triplets --triplet x64-windows-static
   ```
3. Commit the port, then record the version (it reads the committed git tree, so the port must be committed first) and commit again:
   ```
   vcpkg x-add-version --all --x-builtin-ports-root=.\ports --x-builtin-registry-versions-dir=.\versions
   git commit -am "versions: <port> <version>"
   ```
   `vcpkg` is the one bundled with Visual Studio (`<VS>\VC\vcpkg\vcpkg.exe`) or a standalone one. `x-add-version` refuses to change an existing version's git tree; bump the version rather than passing `--overwrite-version` once the commit is pushed.
4. Push, then move the consumer's `baseline` to the new commit.

## Adding a port

Create `ports/ogsr-<name>/` with `vcpkg.json` and `portfile.cmake` (fetch sources with `vcpkg_from_github` pinned to a commit, never a branch), test it as an overlay, then follow steps 3-4 above. `x-add-version` adds the port to `versions/baseline.json`.
