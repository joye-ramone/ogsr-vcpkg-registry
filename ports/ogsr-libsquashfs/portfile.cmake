# libsquashfs (the library part of squashfs-tools-ng) for OGSR Engine. Upstream builds with autotools only: the port adds
# CMakeLists.txt with the sources, defines and the pre-generated inc\config.h of the engine's former 3rd_party\Src\libsquashfs\libsquashfs.vcxproj.

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO AgentD/squashfs-tools-ng
    REF e3dcf1770fd77a0babcca422dcbe7b2cc7b8ab90
    SHA512 7085e36acac6a5ddd4d53feefae2b4a433e1520b4ffe55e753446d754d696fa2839dfeaec83fb30a8d9b29c44d1b67fc6055d42444964a1ffaf06309a69dbe8e
    HEAD_REF master
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" "${CMAKE_CURRENT_LIST_DIR}/ogsr-libsquashfs-config.cmake.in" DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/inc" DESTINATION "${SOURCE_PATH}/ogsr")

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")
vcpkg_cmake_install()
vcpkg_cmake_config_fixup()

# static only: consumers don't have to define SQFS_STATIC (without it predef.h declares the API dllimport)
vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/sqfs/predef.h" "#if defined(SQFS_STATIC)" "#if 1 /* ogsr-libsquashfs: static library */")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.md" "${SOURCE_PATH}/licenses/LGPLv3.txt" "${SOURCE_PATH}/licenses/xxhash.txt" "${SOURCE_PATH}/licenses/hash_table.txt")
