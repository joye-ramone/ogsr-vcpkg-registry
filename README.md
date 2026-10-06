# OGSR vcpkg registry

vcpkg ports for the third-party libraries of OGSR Engine (forks and custom builds). All are static, Windows x64 only.

## Packages

| Package | Version | Source |
|---|---|---|
| `ogsr-luajit` | 2026-09-30 | https://github.com/joye-ramone/luajit2 (`xray`) |
| `ogsr-ode` | 2026-10-01 | https://github.com/joye-ramone/ode_xray (`xray_v2`) |
| `ogsr-libsquashfs` | 2024-03-24 | https://github.com/AgentD/squashfs-tools-ng (`master`) |
| `ogsr-directxtex` | 2026-08-28 | https://github.com/solbjorn/DirectXTex (`master`) |
| `ogsr-nvidia-dlss` | 310.9.1#1 | https://github.com/NVIDIA/DLSS (`v310.9.1`) |
| `ogsr-fidelityfx-fsr3` | 2026-10-04 | https://github.com/OGSR/FidelityFX-SDK (`release-FSR3-3.1.2-DX11-Native-API`) |

Each port is pinned to one commit of its source; the exact commit is `REF` in `ports/<package>/portfile.cmake`.

## Adding it to an engine fork

1. `vcpkg-configuration.json` next to `vcpkg.json`: add the registry. `baseline` is a commit of this repo (the latest: `git ls-remote https://github.com/joye-ramone/ogsr-vcpkg-registry.git main`).

   ```json
   {
     "registries": [
       {
         "kind": "git",
         "repository": "https://github.com/joye-ramone/ogsr-vcpkg-registry.git",
         "baseline": "<commit>",
         "packages": [ "ogsr-*" ]
       }
     ],
     "overlay-triplets": [ "./ogsr-triplets" ]
   }
   ```

2. `vcpkg.json`: add the packages to `dependencies`.

   ```json
   "dependencies": [ "ogsr-luajit", "ogsr-ode", "ogsr-libsquashfs", "ogsr-directxtex", "ogsr-nvidia-dlss", "ogsr-fidelityfx-fsr3" ]
   ```

3. Build with a static triplet (`x64-windows-static` or `x64-windows-static-asan` from the engine's `ogsr-triplets`) and the same Visual Studio version that builds the engine (Release libs use `/GL`).

4. Engine side:
   - Remove the old copies from `3rd_party` (projects in the solution, include and library paths). vcpkg adds `vcpkg_installed\<triplet>\include` and links every installed `.lib` itself.
   - Includes: `<lua.hpp>`, `<ode/ode.h>`, `"ode/src/joint.h"`, `<sqfs/super.h>`, `<DirectXTex.h>`, `<nvsdk_ngx.h>`, `<FidelityFX/host/ffx_fsr3.h>`.
   - Keep the defines `dSINGLE`, `MSVC` (ODE) and `FFX_GCC` (FidelityFX).
   - Copy the DLSS runtime next to the exe in a post-build step: `$(SolutionDir)vcpkg_installed\$(VcpkgTriplet)\bin\nvngx_dlss.dll` (Release), `...\$(VcpkgTriplet)\debug\bin\nvngx_dlss.dll` (Debug).

Private source repos (and this registry, if it is private) need git access without a prompt: Git Credential Manager or an SSH URL.
