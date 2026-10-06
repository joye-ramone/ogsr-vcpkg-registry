# ODE fork of X-Ray / OGSR Engine. The fork has no CMake build of its own: the port adds CMakeLists.txt,
# which compiles the same sources and flags as the engine's former 3rd_party\Src\ode\contrib\msvc7\ode_default\default.vcxproj.

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO joye-ramone/ode_xray
    REF fbeaa90764f024944671c7b54a88ecb89d0c35f9
    SHA512 7bf1a39b6abb57b5d03a8cca8d48bc78530a1a77be49e829ea2a57d5721e7b89302d60a43b0a4543263478813bc2a3f9ee004a1d9e5ac7e51dd10c4f95a45a0c
    HEAD_REF xray_v2
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" DESTINATION "${SOURCE_PATH}")

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")
vcpkg_cmake_install()
vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE-BSD.TXT" "${SOURCE_PATH}/LICENSE.TXT")
