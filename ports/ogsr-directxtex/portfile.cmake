# DirectXTex fork of OGSR Engine, built with the fork's own CMakeLists.txt. The options give the same library as the engine's former
# 3rd_party\Src\DirectXTex\DirectXTex.vcxproj: D3D11 helpers and the BC6H/BC7 GPU encoder (shaders compiled with the Windows SDK fxc.exe),
# no D3D12 (so _WIN32_WINNT=0x0603), no OpenMP (BC6H/BC7 CPU compression single-threaded, no vcomp DLL), /GL in Release.

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO solbjorn/DirectXTex
    REF 60dabb3f2a5aec75d04126a80f280ce75985f483
    SHA512 38b5786b134bcb5657ed609ca9e6036b88556d47b393a781f27e376d38a2dbaaf2309b736c7b83dd4fa85f5df26ceb679d930781f32c79d57f1f969390fdb4e5
    HEAD_REF master
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TOOLS=OFF
        -DBUILD_SAMPLE=OFF
        -DBUILD_DX11=ON
        -DBUILD_DX12=OFF
        -DBC_USE_OPENMP=OFF
        -DENABLE_OPENEXR_SUPPORT=OFF
        -DENABLE_LIBJPEG_SUPPORT=OFF
        -DENABLE_LIBPNG_SUPPORT=OFF
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE=ON
    MAYBE_UNUSED_VARIABLES
        CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE # read by CMake itself (/GL, lib /LTCG), not by CMakeLists.txt
)
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME directxtex)
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include" "${CURRENT_PACKAGES_DIR}/debug/share")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
