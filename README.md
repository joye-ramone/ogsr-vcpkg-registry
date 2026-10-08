# OGSR vcpkg registry

vcpkg ports for the third-party libraries of OGSR Engine (forks and custom builds). All are static, Windows x64 only.

Updating a package or adding a new one: `AGENTS.md`.

## Packages

| Package | Version | Source |
|---|---|---|
| `ogsr-luajit` | 2026-10-08 | https://github.com/joye-ramone/luajit2 (`xray`) |
| `ogsr-ode` | 2026-10-01 | https://github.com/joye-ramone/ode_xray (`xray_v2`) |
| `ogsr-libsquashfs` | 2024-03-24 | https://github.com/AgentD/squashfs-tools-ng (`master`) |
| `ogsr-directxtex` | 2026-08-28 | https://github.com/solbjorn/DirectXTex (`master`) |
| `ogsr-nvidia-dlss` | 310.9.1#1 | https://github.com/NVIDIA/DLSS (`v310.9.1`) |
| `ogsr-fidelityfx-fsr3` | 2026-10-04 | https://github.com/OGSR/FidelityFX-SDK (`release-FSR3-3.1.2-DX11-Native-API`) |
| `ogsr-tracy` | 2026-10-03 | https://github.com/wolfpld/tracy (`master` after v0.14.1, 0.14.2 dev, protocol 83) |

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
   "dependencies": [ "ogsr-luajit", "ogsr-ode", "ogsr-libsquashfs", "ogsr-directxtex", "ogsr-nvidia-dlss", "ogsr-fidelityfx-fsr3", "ogsr-tracy" ]
   ```

3. Build with a static triplet (`x64-windows-static` or `x64-windows-static-asan` from the engine's `ogsr-triplets`) and the same Visual Studio version that builds the engine (Release libs use `/GL`).

4. Engine side:
   - Remove the old copies from `3rd_party` (projects in the solution, include and library paths). vcpkg adds `vcpkg_installed\<triplet>\include` and links every installed `.lib` itself.
   - Includes: `<lua.hpp>`, `<ode/ode.h>`, `"ode/src/joint.h"`, `<sqfs/super.h>`, `<DirectXTex.h>`, `<nvsdk_ngx.h>`, `<FidelityFX/host/ffx_fsr3.h>`.
   - Keep the defines `dSINGLE`, `MSVC` (ODE) and `FFX_GCC` (FidelityFX).
   - Tracy: add `$(SolutionDir)vcpkg_installed\$(VcpkgTriplet)\include\ogsr-tracy` to the include path and compile `...\include\ogsr-tracy\TracyClient.cpp` in one project (xrCore, no precompiled header). See below.
   - Copy the DLSS runtime next to the exe in a post-build step: `$(SolutionDir)vcpkg_installed\$(VcpkgTriplet)\bin\nvngx_dlss.dll` (Release), `...\$(VcpkgTriplet)\debug\bin\nvngx_dlss.dll` (Debug).

## Why `ogsr-tracy` is sources only

`ogsr-tracy` installs Tracy's `public/` tree to `include\ogsr-tracy\` and builds nothing. The engine compiles `TracyClient.cpp` itself, as Tracy's manual recommends:

- All Tracy settings are defines (`TRACY_ENABLE`, `TRACY_ON_DEMAND`, `TRACY_NO_FRAME_IMAGE`, `TRACY_DBGHELP_LOCK=OgsrDbgHelp`), and the client and every file that includes `Tracy.hpp` must use the same ones. The engine builds two variants from one `vcpkg_installed`: the normal one and `BUILD_TRACE=1` with Tracy on. Only the engine's own compile of `TracyClient.cpp` follows the variant.
- Without `TRACY_ENABLE` the client compiles to a few thread-name helpers (`common/TracySystem.cpp`, about 13 KB of object code, no profiler, no thread, no socket) and every Tracy macro is empty. With it, it is the full client (about 900 KB).
- vcpkg's own `tracy` port builds a library with `TRACY_ENABLE` on, and the vcpkg MSBuild integration links every installed `.lib` into every build: a normal build could then start the profiler from that library's static initializers. Its options also don't cover `TRACY_NO_FRAME_IMAGE` or `TRACY_DBGHELP_LOCK`, and its version (0.13.1 at the engine's vcpkg baseline) doesn't match the viewer.
- The client must speak the protocol of `tracy-profiler.exe` / `tracy-capture.exe`, so the commit is pinned. Master builds have no release: the matching tools come from the `windows` artifact of upstream CI for that commit (`gh run download <run id> -R wolfpld/tracy -n windows`).
- `unused-variables.patch` adds `[[maybe_unused]]` to five variables that only `TRACY_ASSERT` reads. With `NDEBUG` the asserts are empty, and the engine builds with `/we4189`, so Release Tracy builds fail without it.

Private source repos (and this registry, if it is private) need git access without a prompt: Git Credential Manager or an SSH URL.
