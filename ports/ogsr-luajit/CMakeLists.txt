# CMake build of the OGSR LuaJIT fork (joye-ramone/luajit2): the steps of the fork's src\msvcbuild.bat for x64 Windows, static,
# so the port follows the triplet's compiler and flags like the other ogsr-* ports. Copied by portfile.cmake into the source root.
#
#   minilua (host)  -> DynASM: vm_x64.dasc -> buildvm_arch.h;  genversion.lua: luajit_rolling.h + .relver -> luajit.h
#   buildvm (host)  -> lj_vm.obj (peobj), lj_bcdef.h, lj_ffdef.h, lj_libdef.h, lj_recdef.h, lj_folddef.h, jit/vmdef.lua
#   LuaJIT.lib      <- src\lj_*.c src\lib_*.c + lj_vm.obj
#
# Flags as msvcbuild.bat "static": /W3 /D_CRT_SECURE_NO_DEPRECATE everywhere; the library also /GS- /fp:fast /arch:AVX2 (in
# Debug too) and /GL in Release (OGSR_LUAJIT_LTCG). No LUAJIT_* defines: GC64, JIT and FFI are the x64 defaults of lj_arch.h.
# The rest (/O2 /Oi /Gy /Ob3 /Z7, /MT, /MTd) comes from vcpkg's toolchain and the triplet.
cmake_minimum_required(VERSION 3.20)
project(ogsr-luajit C)

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8 OR NOT WIN32)
    message(FATAL_ERROR "ogsr-luajit: only the x64 Windows build of msvcbuild.bat is reproduced")
endif()

# The engine built LuaJIT with /GL and links with /LTCG. Static libs with /GL objects only link with the same MSVC version,
# which holds here: vcpkg builds ports with the toolset of the consuming build. Set -DOGSR_LUAJIT_LTCG=OFF for other consumers
# (lld-link cannot read MSVC LTCG objects).
option(OGSR_LUAJIT_LTCG "Build Release with /GL (link-time code generation)" ON)

# msvcbuild.bat passes no /RTC; vcpkg's Debug flags have /RTC1 (keep Debug as it was)
foreach(var CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS)
    string(REGEX REPLACE "[/-]RTC[1csu]+" "" ${var} "${${var}}")
endforeach()

set(LJ_SRC "${CMAKE_CURRENT_SOURCE_DIR}/src")
set(LJ_DASM_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dynasm")
set(LJ_GEN "${CMAKE_CURRENT_BINARY_DIR}/gen")
file(MAKE_DIRECTORY "${LJ_GEN}/jit")

# Library modules in msvcbuild.bat's ALL_LIB order (it numbers the fast functions)
set(LJ_LIB_SOURCES lib_base.c lib_math.c lib_bit.c lib_string.c lib_table.c lib_io.c lib_os.c lib_package.c lib_debug.c lib_jit.c lib_ffi.c lib_buffer.c)

# --- minilua: runs DynASM and genversion.lua ---------------------------------------------------------------------------------
add_executable(minilua "${LJ_SRC}/host/minilua.c")
target_compile_options(minilua PRIVATE /W3)
target_compile_definitions(minilua PRIVATE _CRT_SECURE_NO_DEPRECATE)

set(LJ_DASM_FLAGS -D WIN -D JIT -D FFI -D ENDIAN_LE -D FPU -D P64)
add_custom_command(
    OUTPUT "${LJ_GEN}/buildvm_arch.h"
    COMMAND minilua "${LJ_DASM_DIR}/dynasm.lua" -LN ${LJ_DASM_FLAGS} -o "${LJ_GEN}/buildvm_arch.h" vm_x64.dasc
    DEPENDS minilua "${LJ_SRC}/vm_x64.dasc"
    WORKING_DIRECTORY "${LJ_SRC}"
    COMMENT "DynASM vm_x64.dasc"
    VERBATIM
)

# The source archive has no .git: msvcbuild.bat then takes the release version from .relver (the commit time, export-subst)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/.relver" "${LJ_GEN}/luajit_relver.txt" COPYONLY)
add_custom_command(
    OUTPUT "${LJ_GEN}/luajit.h"
    COMMAND minilua "${LJ_SRC}/host/genversion.lua" "${LJ_SRC}/luajit_rolling.h" "${LJ_GEN}/luajit_relver.txt" "${LJ_GEN}/luajit.h"
    DEPENDS minilua "${LJ_SRC}/host/genversion.lua" "${LJ_SRC}/luajit_rolling.h" "${LJ_GEN}/luajit_relver.txt"
    WORKING_DIRECTORY "${LJ_SRC}"
    COMMENT "genversion luajit.h"
    VERBATIM
)

# --- buildvm: the VM object and the generated headers --------------------------------------------------------------------------
file(GLOB LJ_BUILDVM_SOURCES CONFIGURE_DEPENDS "${LJ_SRC}/host/buildvm*.c")
add_executable(buildvm ${LJ_BUILDVM_SOURCES} "${LJ_GEN}/buildvm_arch.h" "${LJ_GEN}/luajit.h")
target_include_directories(buildvm PRIVATE "${LJ_GEN}" "${LJ_SRC}" "${LJ_DASM_DIR}")
target_compile_options(buildvm PRIVATE /W3)
target_compile_definitions(buildvm PRIVATE _CRT_SECURE_NO_DEPRECATE)

# Inputs by name, run in src\ like the batch file
function(ljbuildvm output mode)
    list(TRANSFORM ARGN PREPEND "${LJ_SRC}/" OUTPUT_VARIABLE inputs)
    add_custom_command(
        OUTPUT "${output}"
        COMMAND buildvm -m ${mode} -o "${output}" ${ARGN}
        DEPENDS buildvm ${inputs}
        WORKING_DIRECTORY "${LJ_SRC}"
        COMMENT "buildvm -m ${mode}"
        VERBATIM
    )
endfunction()
ljbuildvm("${LJ_GEN}/lj_vm.obj" peobj)
ljbuildvm("${LJ_GEN}/lj_bcdef.h" bcdef ${LJ_LIB_SOURCES})
ljbuildvm("${LJ_GEN}/lj_ffdef.h" ffdef ${LJ_LIB_SOURCES})
ljbuildvm("${LJ_GEN}/lj_libdef.h" libdef ${LJ_LIB_SOURCES})
ljbuildvm("${LJ_GEN}/lj_recdef.h" recdef ${LJ_LIB_SOURCES})
ljbuildvm("${LJ_GEN}/jit/vmdef.lua" vmdef ${LJ_LIB_SOURCES})
ljbuildvm("${LJ_GEN}/lj_folddef.h" folddef lj_opt_fold.c)
set(LJ_GENERATED_HEADERS "${LJ_GEN}/luajit.h" "${LJ_GEN}/lj_bcdef.h" "${LJ_GEN}/lj_ffdef.h" "${LJ_GEN}/lj_libdef.h" "${LJ_GEN}/lj_recdef.h" "${LJ_GEN}/lj_folddef.h")
add_custom_target(luajit_vmdef ALL DEPENDS "${LJ_GEN}/jit/vmdef.lua")

# --- LuaJIT.lib: msvcbuild.bat "static" ------------------------------------------------------------------------------------------
# lj_*.c lib_*.c like the batch file (ljamalg.c and luajit.c don't match)
file(GLOB LJ_CORE_SOURCES CONFIGURE_DEPENDS "${LJ_SRC}/lj_*.c" "${LJ_SRC}/lib_*.c")
set_source_files_properties("${LJ_GEN}/lj_vm.obj" PROPERTIES EXTERNAL_OBJECT TRUE GENERATED TRUE)
add_library(luajit STATIC ${LJ_CORE_SOURCES} ${LJ_GENERATED_HEADERS} "${LJ_GEN}/lj_vm.obj")
set_target_properties(luajit PROPERTIES OUTPUT_NAME LuaJIT INTERPROCEDURAL_OPTIMIZATION_RELEASE ${OGSR_LUAJIT_LTCG})
target_include_directories(luajit PRIVATE "${LJ_GEN}" "${LJ_SRC}")
target_compile_options(luajit PRIVATE /W3 /GS- /fp:fast /arch:AVX2)
target_compile_definitions(luajit PRIVATE _CRT_SECURE_NO_DEPRECATE)

install(TARGETS luajit ARCHIVE DESTINATION lib)
install(FILES "${LJ_SRC}/lua.h" "${LJ_SRC}/lualib.h" "${LJ_SRC}/lauxlib.h" "${LJ_SRC}/luaconf.h" "${LJ_SRC}/lua.hpp" "${LJ_GEN}/luajit.h" DESTINATION include)
