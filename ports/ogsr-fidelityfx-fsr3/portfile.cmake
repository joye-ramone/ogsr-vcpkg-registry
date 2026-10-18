# FidelityFX SDK fork of OGSR Engine (FSR 3.1.2 + a native DX11 backend; the fork already has the engine's former local patch ffx_dx11_cb_unmap.patch).
# The SDK's own CMake build compiles the shaders with the FidelityFX shader compiler; the fork commits the compiled permutation headers
# (sdk/build/src/backends/shaders/dx11 and dx12), so the port adds CMakeLists.txt that only builds the FSR3 upscaler and the DX11 / DX12
# backends (the engine's former ffx_backend_dx11_x64.vcxproj, ffx_fsr3upscaler_x64.vcxproj, and the SDK's ffx_backend_dx12) from sdk/,
# and FSR3 frame generation for DX12 (ffx_fsr3, frame interpolation, optical flow, the frame interpolation proxy swap chain).
# The source archive is the whole SDK repo (samples included).

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO OGSR/FidelityFX-SDK
    REF db812a9e5e858294e35ef619989492cb206ca137
    SHA512 d2d53eda29586b0d11a3ab50762b83124f21e2723cd7be56a1024451b376d09eba34e3075774e915ef378a88018f40861c348c3b34fa000bcc10975f2de3e26a
    HEAD_REF release-FSR3-3.1.2-DX11-Native-API
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" "${CMAKE_CURRENT_LIST_DIR}/ogsr-fidelityfx-fsr3-config.cmake.in" DESTINATION "${SOURCE_PATH}/ogsr")

# The shader headers have names up to 120 characters: under the extracted source (<buildtrees>/<port>/src/<hash>.clean/sdk/build/src/backends/shaders/dx11)
# their paths pass 260 characters, which cl.exe can't open even with long paths enabled. Copy them to a short folder next to the port's buildtree.
set(FFX_SHADER_DIR "${CURRENT_BUILDTREES_DIR}/sh")
file(REMOVE_RECURSE "${FFX_SHADER_DIR}")
file(COPY "${SOURCE_PATH}/sdk/build/src/backends/shaders/dx11/" DESTINATION "${FFX_SHADER_DIR}" FILES_MATCHING PATTERN "*.h")
set(FFX_SHADER_DIR_DX12 "${CURRENT_BUILDTREES_DIR}/sh12")
file(REMOVE_RECURSE "${FFX_SHADER_DIR_DX12}")
file(COPY "${SOURCE_PATH}/sdk/build/src/backends/shaders/dx12/" DESTINATION "${FFX_SHADER_DIR_DX12}" FILES_MATCHING PATTERN "*.h")

# The objects of the deep SDK sources (FrameInterpolationSwapchain/*, the blob accessors) mirror their paths under CMakeFiles/<target>.dir:
# from an install root as long as an engine worktree's they pass 260 characters (C1083). SHORT: hashed short object folders (CMake 4.2+).
vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}/ogsr" OPTIONS "-DFFX_SHADER_DIR=${FFX_SHADER_DIR}" "-DFFX_SHADER_DIR_DX12=${FFX_SHADER_DIR_DX12}" "-DCMAKE_INTERMEDIATE_DIR_STRATEGY=SHORT")
vcpkg_cmake_install()
vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
