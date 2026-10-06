# FidelityFX SDK fork of OGSR Engine (FSR 3.1.2 + a native DX11 backend; the fork already has the engine's former local patch ffx_dx11_cb_unmap.patch).
# The SDK's own CMake build compiles the shaders with the FidelityFX shader compiler; the fork commits the compiled permutation headers
# (sdk/build/src/backends/shaders/dx11), so the port adds CMakeLists.txt that only builds the two libraries of the engine's former
# ffx_backend_dx11_x64.vcxproj and ffx_fsr3upscaler_x64.vcxproj from sdk/. The source archive is the whole SDK repo (~140 MB, samples included).

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO OGSR/FidelityFX-SDK
    REF 1a6b6b804b05137d03f6901d63d39ed45a3d0cee
    SHA512 908e7fcc8fa29bedb2436d77749bc30bb6ad2e3758c2b80f05c6eaa0ec20265352c629dbfebcdf88d8fcab46bd428a18ce2321b92c05fb51e2d3db02d2b31bde
    HEAD_REF release-FSR3-3.1.2-DX11-Native-API
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" "${CMAKE_CURRENT_LIST_DIR}/ogsr-fidelityfx-fsr3-config.cmake.in" DESTINATION "${SOURCE_PATH}/ogsr")

# The shader headers have names up to 120 characters: under the extracted source (<buildtrees>/<port>/src/<hash>.clean/sdk/build/src/backends/shaders/dx11)
# their paths pass 260 characters, which cl.exe can't open even with long paths enabled. Copy them to a short folder next to the port's buildtree.
set(FFX_SHADER_DIR "${CURRENT_BUILDTREES_DIR}/sh")
file(REMOVE_RECURSE "${FFX_SHADER_DIR}")
file(COPY "${SOURCE_PATH}/sdk/build/src/backends/shaders/dx11/" DESTINATION "${FFX_SHADER_DIR}" FILES_MATCHING PATTERN "*.h")

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}/ogsr" OPTIONS "-DFFX_SHADER_DIR=${FFX_SHADER_DIR}")
vcpkg_cmake_install()
vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
