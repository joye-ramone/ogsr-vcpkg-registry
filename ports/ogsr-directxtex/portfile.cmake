# DirectXTex for OGSR Engine: upstream microsoft/DirectXTex built with its own CMakeLists.txt. The options give the same library as the
# engine's former 3rd_party\Src\DirectXTex\DirectXTex.vcxproj: D3D11 helpers and the BC6H/BC7 GPU encoder (shaders compiled with the
# Windows SDK fxc.exe), no D3D12 (so _WIN32_WINNT=0x0603), no OpenMP (BC6H/BC7 CPU compression single-threaded, no vcomp DLL), /GL in Release.
#
# load-dds-stream.patch (until 2026-11 the solbjorn/DirectXTex fork, branch master): DirectX::InputStream (Read / Seek / Size) and
# LoadFromDDSStream / LoadFromDDSStreamEx, LoadFromDDSFileEx with every read through the stream; the engine's texture loader reads DDS files
# from its archives with it (xrRender Resources\TextureLoader.cpp). Also renames DirectXTexEXR.cpp's InputStream to EXRInputStream (it
# would clash with DirectX::InputStream; EXR support is off here). The fork's non-owning ScratchImage is not carried over: the engine never
# used it. Updating: the patch is against upstream's clang-formatted sources (2026-09-21, #740); keep it in that style.

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO microsoft/DirectXTex
    REF 6e88c1c52e977cfd9c30671240f7995cba6d4968
    SHA512 eead8cee1506ab6ad0e5bc6aef4c30952c5f916b76a3a19d01db2e5a5a5ca18b7c10fa893cb5f5af7345d15fac109ede8e52fd5c84f7641a28021780bf456909
    HEAD_REF main
    PATCHES
        load-dds-stream.patch
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
