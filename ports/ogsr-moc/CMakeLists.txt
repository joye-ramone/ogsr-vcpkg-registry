# Build of Intel's Masked Occlusion Culling for the ogsr-moc vcpkg port (upstream's CMakeLists.txt has no install rules
# and builds the CullingThreadpool the engine does not use).
#
# Every source picks its own instruction set, as upstream asks:
# - MaskedOcclusionCulling.cpp (SSE2 / SSE4.1 code and the CPUID dispatch) must be built without VEX encoding: it has an
#   #error for __AVX__ / __AVX2__. The engine's triplet puts /arch:AVX2 into every Release file, so it is taken out here.
# - MaskedOcclusionCullingAVX2.cpp and MaskedOcclusionCullingAVX512.cpp get /arch:AVX2 in every configuration (each has an
#   #error without __AVX2__). USE_AVX512 stays 0 (the header's default): the AVX-512 file then only defines a factory that
#   returns nullptr, and MaskedOcclusionCulling::Create picks AVX2 on the CPUs the engine runs on.
cmake_minimum_required(VERSION 3.21)
project(ogsr-moc LANGUAGES CXX)

foreach(flags_var CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_RELEASE CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELWITHDEBINFO CMAKE_CXX_FLAGS_MINSIZEREL)
    string(REGEX REPLACE "[/-]arch:[A-Za-z0-9_.]+" "" ${flags_var} "${${flags_var}}")
endforeach()

set(MOC_SSE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MaskedOcclusionCulling.cpp")
set(MOC_AVX_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MaskedOcclusionCullingAVX2.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/MaskedOcclusionCullingAVX512.cpp")
set_source_files_properties(${MOC_AVX_SOURCES} PROPERTIES COMPILE_OPTIONS "/arch:AVX2")

add_library(MaskedOcclusionCulling STATIC ${MOC_SSE_SOURCES} ${MOC_AVX_SOURCES})
add_library(ogsr::moc ALIAS MaskedOcclusionCulling)
# the installed config exports it as ogsr::moc too (an ALIAS is not exported)
set_target_properties(MaskedOcclusionCulling PROPERTIES EXPORT_NAME moc)

target_include_directories(MaskedOcclusionCulling PUBLIC "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>" "$<INSTALL_INTERFACE:include>")
# The recorder and the statistics stay off (the header's defaults); set here too, so the library and every consumer agree
target_compile_definitions(MaskedOcclusionCulling PUBLIC MOC_RECORDER_ENABLE=0 ENABLE_STATS=0)
target_compile_options(MaskedOcclusionCulling PRIVATE /W3)

# Release with /GL like the other ogsr-* ports: such static libs link only with the same MSVC version, which holds because
# vcpkg builds ports with the consumer's toolset. -DOGSR_MOC_LTCG=OFF for other consumers.
option(OGSR_MOC_LTCG "Build Release with /GL (link-time code generation)" ON)
set_target_properties(MaskedOcclusionCulling PROPERTIES INTERPROCEDURAL_OPTIMIZATION_RELEASE ${OGSR_MOC_LTCG})

install(TARGETS MaskedOcclusionCulling EXPORT ogsr-moc-targets ARCHIVE DESTINATION lib)
# Self-contained while MOC_RECORDER_ENABLE is 0 (FrameRecorder.h and CompilerSpecific.inl are only included by the sources)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/MaskedOcclusionCulling.h" DESTINATION include)
install(EXPORT ogsr-moc-targets NAMESPACE ogsr:: FILE ogsr-moc-config.cmake DESTINATION share/ogsr-moc)
