vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

# Upstream tag is v1.92.9b-docking (a patch of 1.92.9); the letter suffix is not a valid vcpkg version.
# Same sources as the main registry's imgui 1.92.9 with the docking-experimental feature.
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ocornut/imgui
    REF "v${VERSION}b-docking"
    SHA512 7eddcdb475f1db1fc8242d918533b955c964d2267abe713bdf23f8e2444770946d3c79c7855e360bab6168e36231b95bd05a84106c08f876dcd53daac9caccac
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
