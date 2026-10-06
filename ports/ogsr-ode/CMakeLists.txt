# Build of the ode_xray fork for the ogsr-ode vcpkg port (the fork itself has no CMake build).
# Sources, defines and flags follow the engine's former contrib\msvc7\ode_default\default.vcxproj.
cmake_minimum_required(VERSION 3.21)
project(ogsr-ode LANGUAGES C CXX)

set(ODE_SOURCES
    array.cpp collision_kernel.cpp collision_quadtreespace.cpp collision_space.cpp collision_std.cpp collision_transform.cpp collision_util.cpp error.cpp export-dif.cpp
    fastdot.c fastldlt.c fastlsolve.c fastltsolve.c
    joint.cpp lcp.cpp mass.cpp mat.cpp matrix.cpp memory.cpp misc.cpp obstack.cpp ode.cpp odemath.cpp quickstep.cpp rotation.cpp step.cpp stepfast.cpp testing.cpp timer.cpp util.cpp
)
list(TRANSFORM ODE_SOURCES PREPEND "${CMAKE_CURRENT_SOURCE_DIR}/ode/src/")

add_library(ode STATIC ${ODE_SOURCES})
add_library(ogsr::ode ALIAS ode)

target_include_directories(ode PUBLIC "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>" "$<INSTALL_INTERFACE:include>")
target_compile_definitions(ode PUBLIC dSINGLE MSVC PRIVATE WIN32 _WINDOWS dNODEBUG)
target_compile_options(ode PRIVATE /W3 /wd4456 /wd4457 /wd4458 /wd4577 /wd4244 "$<$<CONFIG:Release>:/Ot;/Oy-;/GS-;/GF>")

# The engine built ODE with /GL and links with /LTCG. Static libs with /GL objects only link with the same MSVC version,
# which holds here: vcpkg builds ports with the toolset of the consuming build. Set -DOGSR_ODE_LTCG=OFF for other consumers.
option(OGSR_ODE_LTCG "Build Release with /GL (link-time code generation)" ON)
set_target_properties(ode PROPERTIES INTERPROCEDURAL_OPTIMIZATION_RELEASE ${OGSR_ODE_LTCG})

install(TARGETS ode EXPORT ogsr-ode-targets ARCHIVE DESTINATION lib)
install(DIRECTORY include/ode/ DESTINATION include/ode FILES_MATCHING PATTERN "*.h")
# internal headers: the engine includes "ode/src/joint.h", "ode/src/objects.h", ... (xrPhysics)
install(DIRECTORY ode/src/ DESTINATION include/ode/src FILES_MATCHING PATTERN "*.h")
install(EXPORT ogsr-ode-targets NAMESPACE ogsr:: FILE ogsr-ode-config.cmake DESTINATION share/ogsr-ode)
