# Build of the FSR3 upscaler and the DX11 / DX12 backends of the OGSR FidelityFX-SDK fork for the ogsr-fidelityfx-fsr3 vcpkg port.
# Lives in <repo>/ogsr; sources and defines follow the engine's former ffx_backend_dx11_x64.vcxproj and ffx_fsr3upscaler_x64.vcxproj.
cmake_minimum_required(VERSION 3.21)
project(ogsr-fidelityfx-fsr3 LANGUAGES C CXX)

set(SDK "${CMAKE_CURRENT_SOURCE_DIR}/../sdk")
# prebuilt shader permutation headers committed in the fork; the port passes a copy in a short folder (path length limit of cl.exe)
set(FFX_SHADER_DIR "${SDK}/build/src/backends/shaders/dx11" CACHE PATH "Folder with the DX11 shader permutation headers")
set(FFX_SHADER_DIR_DX12 "${SDK}/build/src/backends/shaders/dx12" CACHE PATH "Folder with the DX12 shader permutation headers")

# FFX_GCC: FFX_API without __declspec(dllexport) (static libraries); PUBLIC, consumers need the same declarations
set(FFX_DEFINES PUBLIC FFX_GCC PRIVATE WIN32 _WINDOWS _UNICODE UNICODE)
set(FFX_OPTIONS /fp:fast)

add_library(ffx_fsr3upscaler_x64 STATIC
    "${SDK}/src/components/fsr3upscaler/ffx_fsr3upscaler.cpp"
    "${SDK}/src/shared/ffx_assert.cpp"
    "${SDK}/src/shared/ffx_object_management.cpp"
)
target_include_directories(ffx_fsr3upscaler_x64 PRIVATE "${SDK}/src/shared" PUBLIC "$<BUILD_INTERFACE:${SDK}/include>" "$<INSTALL_INTERFACE:include>")

add_library(ffx_backend_dx11_x64 STATIC
    "${SDK}/src/backends/dx11/DXBCChecksum.c"
    "${SDK}/src/backends/dx11/ffx_dx11.cpp"
    "${SDK}/src/backends/dx11/md5.c"
    "${SDK}/src/backends/shared/blob_accessors/ffx_frameinterpolation_shaderblobs.cpp"
    "${SDK}/src/backends/shared/blob_accessors/ffx_fsr1_shaderblobs.cpp"
    "${SDK}/src/backends/shared/blob_accessors/ffx_fsr2_shaderblobs.cpp"
    "${SDK}/src/backends/shared/blob_accessors/ffx_fsr3upscaler_shaderblobs.cpp"
    "${SDK}/src/backends/shared/blob_accessors/ffx_opticalflow_shaderblobs.cpp"
    "${SDK}/src/backends/shared/ffx_shader_blobs.cpp"
    "${SDK}/src/shared/ffx_assert.cpp"
)
target_include_directories(ffx_backend_dx11_x64 PRIVATE "${FFX_SHADER_DIR}" "${SDK}/src/components" "${SDK}/src/shared" "${SDK}/src/backends/shared" PUBLIC "$<BUILD_INTERFACE:${SDK}/include>" "$<INSTALL_INTERFACE:include>")
target_compile_definitions(ffx_backend_dx11_x64 PRIVATE FFX_FSR FFX_FSR3)
target_link_libraries(ffx_backend_dx11_x64 PUBLIC d3d11)

# DX12 backend: the SDK's ffx_backend_dx12 without GPUTimestamps (unused) and pixlib (no PIX markers in these sources).
# FrameInterpolationSwapchain stays: ffx_dx12.cpp calls it (frame generation swap chain, not used by the engine).
add_library(ffx_backend_dx12_x64 STATIC
    "${SDK}/src/backends/dx12/ffx_dx12.cpp"
    "${SDK}/src/backends/dx12/FrameInterpolationSwapchain/FrameInterpolationSwapchainDX12.cpp"
    "${SDK}/src/backends/dx12/FrameInterpolationSwapchain/FrameInterpolationSwapchainDX12_Helpers.cpp"
    "${SDK}/src/backends/dx12/FrameInterpolationSwapchain/FrameInterpolationSwapchainDX12_UiComposition.cpp"
    "${SDK}/src/backends/shared/blob_accessors/ffx_fsr1_shaderblobs.cpp"
    "${SDK}/src/backends/shared/blob_accessors/ffx_fsr2_shaderblobs.cpp"
    "${SDK}/src/backends/shared/blob_accessors/ffx_fsr3upscaler_shaderblobs.cpp"
    "${SDK}/src/backends/shared/ffx_shader_blobs.cpp"
    "${SDK}/src/shared/ffx_assert.cpp"
)
target_include_directories(ffx_backend_dx12_x64 PRIVATE "${FFX_SHADER_DIR_DX12}" "${SDK}/src/components" "${SDK}/src/shared" "${SDK}/src/backends/shared" PUBLIC "$<BUILD_INTERFACE:${SDK}/include>" "$<INSTALL_INTERFACE:include>")
# The fork commits the DX12 shaders of the upscalers only (FSR1, FSR2, FSR3): the optical flow shaders of frame generation hang the SDK's
# shader compiler (one 16-bit permutation ran for 30 minutes), and the engine has no frame generation. FFX_NO_FRAMEGEN_BLOBS (a fork
# change in ffx_shader_blobs.cpp) leaves the frame interpolation and optical flow effects out of the blob lookup.
target_compile_definitions(ffx_backend_dx12_x64 PRIVATE FFX_FSR FFX_FSR3 FFX_NO_FRAMEGEN_BLOBS)
# The shared blob accessors are compiled into both backends, with DXBC (dx11) or DXIL (dx12) blobs and the same function names.
# vcpkg's MSBuild integration links every library of the package, so the DX12 copies get names of their own: otherwise the linker
# could resolve the DX12 backend's blob lookups from the DX11 library.
foreach(fn ffxGetPermutationBlobByIndex ffxIsWave64 fsr3UpscalerGetPermutationBlobByIndex fsr3UpscalerIsWave64 fsr2GetPermutationBlobByIndex fsr2IsWave64 fsr1GetPermutationBlobByIndex fsr1IsWave64)
    target_compile_definitions(ffx_backend_dx12_x64 PRIVATE ${fn}=${fn}DX12)
endforeach()
target_link_libraries(ffx_backend_dx12_x64 PUBLIC d3d12 dxgi dwmapi)

# /GL like the engine's vcxprojs; such static libs only link with the same MSVC version (true for vcpkg manifest builds)
option(OGSR_FFX_LTCG "Build Release with /GL (link-time code generation)" ON)
foreach(t ffx_fsr3upscaler_x64 ffx_backend_dx11_x64 ffx_backend_dx12_x64)
    target_compile_definitions(${t} ${FFX_DEFINES})
    target_compile_options(${t} PRIVATE ${FFX_OPTIONS})
    set_target_properties(${t} PROPERTIES INTERPROCEDURAL_OPTIMIZATION_RELEASE ${OGSR_FFX_LTCG})
endforeach()
set_target_properties(ffx_fsr3upscaler_x64 PROPERTIES EXPORT_NAME fsr3upscaler)
set_target_properties(ffx_backend_dx11_x64 PROPERTIES EXPORT_NAME backend_dx11)
set_target_properties(ffx_backend_dx12_x64 PROPERTIES EXPORT_NAME backend_dx12)

include(CMakePackageConfigHelpers)
install(TARGETS ffx_fsr3upscaler_x64 ffx_backend_dx11_x64 ffx_backend_dx12_x64 EXPORT ogsr-fidelityfx-fsr3-targets ARCHIVE DESTINATION lib)
# the whole public include tree, as the engine used it (host API + gpu HLSL headers)
install(DIRECTORY "${SDK}/include/FidelityFX" DESTINATION include)
install(EXPORT ogsr-fidelityfx-fsr3-targets NAMESPACE ogsr::ffx:: DESTINATION share/ogsr-fidelityfx-fsr3)
configure_package_config_file(ogsr-fidelityfx-fsr3-config.cmake.in "${CMAKE_CURRENT_BINARY_DIR}/ogsr-fidelityfx-fsr3-config.cmake" INSTALL_DESTINATION share/ogsr-fidelityfx-fsr3)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/ogsr-fidelityfx-fsr3-config.cmake" DESTINATION share/ogsr-fidelityfx-fsr3)
