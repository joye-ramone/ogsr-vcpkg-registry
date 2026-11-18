vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

# Upstream tag v${VERSION}-docking. A patch release with a letter suffix (v1.92.9b-docking) is not a valid vcpkg version:
# keep the base version and write the letter into REF.
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ocornut/imgui
    REF "v${VERSION}-docking"
    SHA512 00ade7a3e2c2e34465f1bb9fafd78733d3e659617b0857cf1b3c7f04cfc1d8566d1fd6a8697946f0de7c808cce1c4d0a4b2195c7bc20144cfd8b1e9b1cfba621
    HEAD_REF docking
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/imgui-config.cmake.in" DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" DESTINATION "${SOURCE_PATH}")

# OGSR settings, before the build: the library and every consumer see the same imconfig.h
file(READ "${CMAKE_CURRENT_LIST_DIR}/imconfig_ogsr.h" IMCONFIG_OGSR)
vcpkg_replace_string("${SOURCE_PATH}/imconfig.h" "#pragma once\n" "#pragma once\n\n${IMCONFIG_OGSR}")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS_DEBUG
        -DIMGUI_SKIP_HEADERS=ON
)

vcpkg_cmake_install()

vcpkg_copy_pdbs()
vcpkg_cmake_config_fixup(PACKAGE_NAME imgui)

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
