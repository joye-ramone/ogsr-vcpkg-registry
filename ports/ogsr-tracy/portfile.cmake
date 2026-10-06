# Tracy client for OGSR Engine as sources only. Nothing is compiled here on purpose:
# - Tracy is configured by defines (TRACY_ENABLE, TRACY_ON_DEMAND, TRACY_NO_FRAME_IMAGE, TRACY_DBGHELP_LOCK=..., ...) that must be the same
#   in the client and in every file that includes Tracy.hpp. The engine builds two variants from one vcpkg_installed (normal, and
#   BUILD_TRACE=1 with Tracy on), so a prebuilt library would have to be right for both, and only the engine's own compile of
#   TracyClient.cpp is. Without TRACY_ENABLE it compiles to almost nothing (common/TracySystem.cpp) and all Tracy macros are empty.
# - vcpkg's own tracy port builds a library with TRACY_ENABLE on; the vcpkg MSBuild integration links every installed .lib into
#   every build, so a non-Tracy build could start the profiler (thread, socket) from that library's static initializers.
# - The client must speak the protocol of the viewer (tracy-profiler.exe / tracy-capture.exe): the commit is pinned here instead.
# Installs public/ to include/ogsr-tracy/: add that folder to the include path (<tracy/Tracy.hpp>) and compile its TracyClient.cpp.

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO wolfpld/tracy
    REF 23755c9fc84680c86a863ea72b845dad26ddaded
    SHA512 e85cff12e3c0b1d2ce09d835c33e8ec35a823cdd15547b1babcc215cc12bc87e7f1ee557ffd1e649280c14fa110eb5323c033f27da779963502d3a6b56df6de4
    HEAD_REF master
    PATCHES
        unused-variables.patch # [[maybe_unused]] on variables read only by TRACY_ASSERT: the engine builds with /we4189 and NDEBUG
)

set(VCPKG_BUILD_TYPE release) # sources only, nothing per configuration
set(VCPKG_POLICY_SKIP_MISPLACED_CMAKE_FILES_CHECK enabled)

file(INSTALL "${SOURCE_PATH}/public/" DESTINATION "${CURRENT_PACKAGES_DIR}/include/ogsr-tracy")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/ogsr-tracy-config.cmake" "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
