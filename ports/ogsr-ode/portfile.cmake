# ODE fork of X-Ray / OGSR Engine. The fork has no CMake build of its own: the port adds CMakeLists.txt,
# which compiles the same sources and flags as the engine's former 3rd_party\Src\ode\contrib\msvc7\ode_default\default.vcxproj.

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO joye-ramone/ode_xray
    REF 5726224fa2c45c0b769d3f018d4612ba2f864066
    SHA512 f09f73a3a6e00a1718b6c0d01a6c585359879d693e1908e2fa051a10eae875eb6893654254fdec93395466dd03518b9a7ced6cb61113c8209ef5824179e38063
    HEAD_REF xray_v2
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" DESTINATION "${SOURCE_PATH}")

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")
vcpkg_cmake_install()
vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE-BSD.TXT" "${SOURCE_PATH}/LICENSE.TXT")
