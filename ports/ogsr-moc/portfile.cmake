# Intel Masked Occlusion Culling (GameTechDev/MaskedOcclusionCulling) for OGSR Engine: the rasterizer only (SSE4.1 / AVX2,
# picked at run time), no CullingThreadpool, no frame recorder. The port's CMakeLists.txt replaces upstream's, which has no
# install rules and gives the engine's /arch:AVX2 to a file that must not have it.

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO GameTechDev/MaskedOcclusionCulling
    REF 1fd7974456cffa481a1a534328a1d02523d19ce8
    SHA512 adffed495363faa3c3e25bf2f8aa36b524e38030fb15261ba373d82766715603a7afb98ea18cab838912b907c7f270816e5f0fe3e96ea186c6ba513ea0f615e7
    HEAD_REF master
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" DESTINATION "${SOURCE_PATH}")

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")
vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/license.txt")
