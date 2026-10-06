# Imported target ogsr::luajit for CMake consumers (MSBuild consumers get LuaJIT.lib through vcpkg auto-link)
if(NOT TARGET ogsr::luajit)
    get_filename_component(_ogsr_luajit_root "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
    add_library(ogsr::luajit STATIC IMPORTED)
    set_target_properties(ogsr::luajit PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_ogsr_luajit_root}/include"
        IMPORTED_CONFIGURATIONS "RELEASE;DEBUG"
        IMPORTED_LOCATION_RELEASE "${_ogsr_luajit_root}/lib/LuaJIT.lib"
        IMPORTED_LOCATION_DEBUG "${_ogsr_luajit_root}/debug/lib/LuaJIT.lib"
        MAP_IMPORTED_CONFIG_MINSIZEREL Release
        MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
    )
    unset(_ogsr_luajit_root)
endif()
