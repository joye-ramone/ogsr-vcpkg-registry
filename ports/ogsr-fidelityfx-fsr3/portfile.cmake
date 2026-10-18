# FidelityFX SDK fork of OGSR Engine: upstream SDK 1.1.4 (FSR 3.1.4 upscaler, FSR3 frame generation) + metarutaiga's 1.1.4 DX11 backend
# (branch release-FSR3-3.1.4-ogsr: FXC fixes for the SM 5.0 shaders, the DX11 shader rules, the DX11 constant ring mapped per upload, the
# interpolation-only FSR3 context's shared resources).
# The SDK's own CMake build compiles the shaders with the FidelityFX shader compiler; the fork commits the compiled permutation headers
# (sdk/build/src/backends/shaders/dx11 and dx12), so the port adds CMakeLists.txt that builds the FSR3 upscaler, ffx_fsr3, frame
# interpolation, optical flow and the DX11 / DX12 backends (with the frame interpolation proxy swap chain) from sdk/ without the SDK's CMake.
# The source archive is the whole SDK repo (samples included).

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO OGSR/FidelityFX-SDK
    REF 04808bb239fb196c8d7401b376e039e82e78d2b2
    SHA512 42b47a24995a32251e35ce57e8e14c49677c1e8ecbebaa136fb2cfa8c5824d1d171a44f57e494fb7b70fdb41a2307e5a005c8bd69dbdb03e30370f5f939bb51a
    HEAD_REF release-FSR3-3.1.4-ogsr
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
