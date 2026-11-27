# LuaJIT fork of OGSR Engine. The fork builds with src\msvcbuild.bat; the port adds CMakeLists.txt, which runs the same steps
# (minilua, DynASM, genversion, buildvm, the static library) with the batch file's flags, so the triplet's compiler and flags
# apply as in the other ogsr-* ports. Until 2026-11 the port ran its own copy of msvcbuild.bat (engine_PLAN_vcpkg.md 3ac).
# Release with /GL (-DOGSR_LUAJIT_LTCG=OFF without), embedded debug info (/Z7), /MTd in Debug.
# Installs the Lua headers straight into include\ (the engine includes <lua.hpp>) and LuaJIT.lib.

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO joye-ramone/luajit2
    REF e8e6bcaba07c905d457a7c4ae69b7a651854d86e
    SHA512 64e8dc43cf80de88a0a4f6c5dc6eacfe7f3da642eea7caf955670ce2b63d4a4f84420a0d8896b0d1fa0f8ab5eef626fd615cc0f25ae7343920e79ec76b4ca5a9
    HEAD_REF xray
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" DESTINATION "${SOURCE_PATH}")

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")
vcpkg_cmake_install()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/ogsr-luajit-config.cmake" "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYRIGHT")
