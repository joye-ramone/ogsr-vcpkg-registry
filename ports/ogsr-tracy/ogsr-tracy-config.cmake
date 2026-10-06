# ogsr::tracy: include path of the Tracy client sources; add OGSR_TRACY_CLIENT_SOURCE (TracyClient.cpp) to one of your targets
# and set the TRACY_* defines on everything that includes Tracy headers.
get_filename_component(_ogsr_tracy_dir "${CMAKE_CURRENT_LIST_DIR}/../../include/ogsr-tracy" ABSOLUTE)
if(NOT TARGET ogsr::tracy)
    add_library(ogsr::tracy INTERFACE IMPORTED)
    set_target_properties(ogsr::tracy PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${_ogsr_tracy_dir}")
endif()
set(OGSR_TRACY_CLIENT_SOURCE "${_ogsr_tracy_dir}/TracyClient.cpp")
unset(_ogsr_tracy_dir)
