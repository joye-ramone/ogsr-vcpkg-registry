# ODE fork of X-Ray / OGSR Engine. The fork has no CMake build of its own: the port adds CMakeLists.txt,
# which compiles the same sources and flags as the engine's former 3rd_party\Src\ode\contrib\msvc7\ode_default\default.vcxproj.

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO joye-ramone/ode_xray
    REF c6c6224352040c9d0b1420fd9b5613331fc54ae1
    SHA512 58de59b739fb66dcd7d2abe710c7df59ffefe306d6c37149641999e7afe891d8a7937f3fbbf50680969e2dfeb7862e9f0fc61e5479d8bdd2dc8176835df4e348
    HEAD_REF xray_v2
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" DESTINATION "${SOURCE_PATH}")

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")
vcpkg_cmake_install()
vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE-BSD.TXT" "${SOURCE_PATH}/LICENSE.TXT")
