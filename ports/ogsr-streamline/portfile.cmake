# NVIDIA Streamline for OGSR Engine (DLSS Frame Generation, Reflex, PCL): only what the engine uses from the SDK release archive
# (github.com/NVIDIA-RTX/Streamline releases: the repository has sources and docs, the signed binaries come only in the release zip, 276 MB):
#   include\*.h                         -> include\streamline\
#   bin\x64\<dll>                       -> bin\streamline\         (production, signed; Release)
#   bin\x64\development\<dll>           -> debug\bin\streamline\   (development: on-screen overlay, hotkeys, sl.imgui; Debug)
# The engine loads sl.interposer.dll by path after its signature check (manual hooking): no import library is installed, so vcpkg's auto-link
# links nothing and builds without the DLLs next to the exe still start.
#
# Updating: set VERSION in vcpkg.json to the new release tag without the v, SHA512 to 0, install once: the failed download prints the real hash.

set(VCPKG_POLICY_DLLS_IN_STATIC_LIBRARY enabled)
set(VCPKG_POLICY_DLLS_WITHOUT_LIBS enabled)
# debug has one DLL more: sl.imgui (the development overlay)
set(VCPKG_POLICY_MISMATCHED_NUMBER_OF_BINARIES enabled)

vcpkg_download_distfile(archive
    URLS "https://github.com/NVIDIA-RTX/Streamline/releases/download/v${VERSION}/streamline-sdk-v${VERSION}.zip"
    FILENAME "streamline-sdk-v${VERSION}.zip"
    SHA512 4304663076f763862eafea8080d70f61f2034828dce8b167df0493414c8817b01d47f244032b324af57a44182efcb125cf8000c49026b68b43a6ef55f507c8cf
)

vcpkg_extract_source_archive(src
    ARCHIVE "${archive}"
    NO_REMOVE_ONE_LEVEL
)

# sl_pcl.h's C++23 branch aliases a function template (`using to_underlying = std::to_underlying;`), which does not compile: a using-declaration
vcpkg_replace_string("${src}/include/sl_pcl.h" "using to_underlying = std::to_underlying;" "using std::to_underlying;")

file(GLOB headers "${src}/include/*.h")
file(INSTALL ${headers} DESTINATION "${CURRENT_PACKAGES_DIR}/include/streamline")

# the plugins DLSS-G needs: the interposer, the common plugin, DLSS-G and its NGX feature, Reflex, PCL
set(dlls sl.interposer.dll sl.common.dll sl.dlss_g.dll sl.reflex.dll sl.pcl.dll nvngx_dlssg.dll)
foreach(dll IN LISTS dlls)
    file(INSTALL "${src}/bin/x64/${dll}" DESTINATION "${CURRENT_PACKAGES_DIR}/bin/streamline")
    if(NOT VCPKG_BUILD_TYPE)
        file(INSTALL "${src}/bin/x64/development/${dll}" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/bin/streamline")
    endif()
endforeach()
# the development interposer shows its on-screen data through sl.imgui
if(NOT VCPKG_BUILD_TYPE)
    file(INSTALL "${src}/bin/x64/development/sl.imgui.dll" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/bin/streamline")
endif()

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${src}/license.txt" "${src}/bin/x64/nvngx_dlss.license.txt" "${src}/bin/x64/reflex.license.txt" "${src}/3rd-party-licenses.md")
