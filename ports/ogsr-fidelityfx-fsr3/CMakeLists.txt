# Build of the OGSR FidelityFX-SDK fork (SDK 1.1.4 + a DX11 backend, branch release-FSR3-3.1.4-ogsr) for the ogsr-fidelityfx-fsr3 vcpkg port:
# the FSR3 upscaler, FSR3 frame generation (ffx_fsr3, frame interpolation, optical flow) and the DX11 / DX12 backends as static libraries.
# Lives in <repo>/ogsr; the shaders are the fork's prebuilt permutation headers (the SDK's own CMake needs FidelityFX_SC at build time).
cmake_minimum_required(VERSION 3.21)
project(ogsr-fidelityfx-fsr3 LANGUAGES C CXX)

set(SDK "${CMAKE_CURRENT_SOURCE_DIR}/../sdk")
# prebuilt shader permutation headers committed in the fork; the port passes a copy in a short folder (path length limit of cl.exe)
set(FFX_SHADER_DIR "${SDK}/build/src/backends/shaders/dx11" CACHE PATH "Folder with the DX11 shader permutation headers")
set(FFX_SHADER_DIR_DX12 "${SDK}/build/src/backends/shaders/dx12" CACHE PATH "Folder with the DX12 shader permutation headers")

# FFX_GCC: FFX_API without __declspec(dllexport) (static libraries); PUBLIC, consumers need the same declarations
set(FFX_DEFINES PUBLIC FFX_GCC PRIVATE WIN32 _WINDOWS _UNICODE UNICODE)
set(FFX_OPTIONS /fp:fast)
set(FFX_PUBLIC_INCLUDES "$<BUILD_INTERFACE:${SDK}/include>" "$<INSTALL_INTERFACE:include>")

# ffx_assert / ffx_message / ffx_object_management (src/shared) are in ffx_fsr3upscaler_x64, which every consumer links
add_library(ffx_fsr3upscaler_x64 STATIC
    "${SDK}/src/components/fsr3upscaler/ffx_fsr3upscaler.cpp"
    "${SDK}/src/shared/ffx_assert.cpp"
    "${SDK}/src/shared/ffx_message.cpp"
    "${SDK}/src/shared/ffx_object_management.cpp"
)
target_include_directories(ffx_fsr3upscaler_x64 PRIVATE "${SDK}/src/shared" "${SDK}/src/components" PUBLIC ${FFX_PUBLIC_INCLUDES})

# Frame generation (D3D12 build): the FSR3 context (upscaler + frame generation prepare / dispatch), frame interpolation and optical flow
add_library(ffx_frameinterpolation_x64 STATIC "${SDK}/src/components/frameinterpolation/ffx_frameinterpolation.cpp")
add_library(ffx_opticalflow_x64 STATIC "${SDK}/src/components/opticalflow/ffx_opticalflow.cpp")
add_library(ffx_fsr3_x64 STATIC "${SDK}/src/components/fsr3/ffx_fsr3.cpp")
foreach(t ffx_frameinterpolation_x64 ffx_opticalflow_x64 ffx_fsr3_x64)
    target_include_directories(${t} PRIVATE "${SDK}/src/shared" "${SDK}/src/components" PUBLIC ${FFX_PUBLIC_INCLUDES})
endforeach()

# DX11 backend (metarutaiga's 1.1.4 backend in the fork): the FSR3 upscaler only. No WIN32_LEAN_AND_MEAN: it uses MAKEFOURCC (mmsystem.h)
add_library(ffx_backend_dx11_x64 STATIC
    "${SDK}/src/backends/dx11/DXBCChecksum.c"
    "${SDK}/src/backends/dx11/ffx_dx11.cpp"
    "${SDK}/src/backends/dx11/md5.c"
    "${SDK}/src/backends/shared/blob_accessors/ffx_fsr3upscaler_shaderblobs.cpp"
    "${SDK}/src/backends/shared/ffx_shader_blobs.cpp"
)
target_include_directories(ffx_backend_dx11_x64 PRIVATE "${FFX_SHADER_DIR}" "${SDK}/src/components" "${SDK}/src/shared" "${SDK}/src/backends/shared" PUBLIC ${FFX_PUBLIC_INCLUDES})
target_compile_definitions(ffx_backend_dx11_x64 PRIVATE FFX_FSR3UPSCALER NOMINMAX)
target_link_libraries(ffx_backend_dx11_x64 PUBLIC d3d11)

# DX12 backend: the SDK's ffx_backend_dx12 without GPUTimestamps (unused); PIX through GetProcAddress at runtime (pix3.h from sdk/libs, no
# pixlib). FrameInterpolationSwapchain: the frame generation proxy swap chain (FSR3 frame generation on the D3D12 build); it includes
# sdk/libs/antilag2 (the Anti-Lag 2 hand-off) and uses timeBeginPeriod (winmm)
add_library(ffx_backend_dx12_x64 STATIC
    "${SDK}/src/backends/dx12/ffx_dx12.cpp"
    "${SDK}/src/backends/dx12/FrameInterpolationSwapchain/FrameInterpolationSwapchainDX12.cpp"
    "${SDK}/src/backends/dx12/FrameInterpolationSwapchain/FrameInterpolationSwapchainDX12_DebugPacing.cpp"
    "${SDK}/src/backends/dx12/FrameInterpolationSwapchain/FrameInterpolationSwapchainDX12_Helpers.cpp"
    "${SDK}/src/backends/dx12/FrameInterpolationSwapchain/FrameInterpolationSwapchainDX12_UiComposition.cpp"
    "${SDK}/src/backends/shared/blob_accessors/ffx_frameinterpolation_shaderblobs.cpp"
    "${SDK}/src/backends/shared/blob_accessors/ffx_opticalflow_shaderblobs.cpp"
    "${SDK}/src/backends/shared/blob_accessors/ffx_fsr3upscaler_shaderblobs.cpp"
    "${SDK}/src/backends/shared/ffx_shader_blobs.cpp"
    "${SDK}/src/shared/ffx_breadcrumbs_list.cpp"
)
target_include_directories(ffx_backend_dx12_x64 PRIVATE "${FFX_SHADER_DIR_DX12}" "${SDK}/src/components" "${SDK}/src/shared" "${SDK}/src/backends/shared" "${SDK}/libs" PUBLIC ${FFX_PUBLIC_INCLUDES})
target_compile_definitions(ffx_backend_dx12_x64 PRIVATE FFX_FSR3UPSCALER FFX_FI FFX_OF NOMINMAX WIN32_LEAN_AND_MEAN)
# The shared blob accessors are compiled into both backends, with DXBC (dx11) or DXIL (dx12) blobs and the same function names.
# vcpkg's MSBuild integration links every library of the package, so the DX12 copies get names of their own: otherwise the linker
# could resolve the DX12 backend's blob lookups from the DX11 library.
foreach(fn ffxGetPermutationBlobByIndex ffxIsWave64 fsr3UpscalerGetPermutationBlobByIndex fsr3UpscalerIsWave64 frameInterpolationGetPermutationBlobByIndex frameInterpolationIsWave64 opticalflowGetPermutationBlobByIndex opticalflowIsWave64)
    target_compile_definitions(ffx_backend_dx12_x64 PRIVATE ${fn}=${fn}DX12)
endforeach()
target_link_libraries(ffx_backend_dx12_x64 PUBLIC d3d12 dxgi dwmapi winmm)

# /GL like the engine's vcxprojs; such static libs only link with the same MSVC version (true for vcpkg manifest builds)
option(OGSR_FFX_LTCG "Build Release with /GL (link-time code generation)" ON)
set(FFX_TARGETS ffx_fsr3upscaler_x64 ffx_frameinterpolation_x64 ffx_opticalflow_x64 ffx_fsr3_x64 ffx_backend_dx11_x64 ffx_backend_dx12_x64)
foreach(t ${FFX_TARGETS})
    target_compile_definitions(${t} ${FFX_DEFINES})
    target_compile_options(${t} PRIVATE ${FFX_OPTIONS})
    set_target_properties(${t} PROPERTIES INTERPROCEDURAL_OPTIMIZATION_RELEASE ${OGSR_FFX_LTCG})
endforeach()
set_target_properties(ffx_fsr3upscaler_x64 PROPERTIES EXPORT_NAME fsr3upscaler)
set_target_properties(ffx_frameinterpolation_x64 PROPERTIES EXPORT_NAME frameinterpolation)
set_target_properties(ffx_opticalflow_x64 PROPERTIES EXPORT_NAME opticalflow)
set_target_properties(ffx_fsr3_x64 PROPERTIES EXPORT_NAME fsr3)
set_target_properties(ffx_backend_dx11_x64 PROPERTIES EXPORT_NAME backend_dx11)
set_target_properties(ffx_backend_dx12_x64 PROPERTIES EXPORT_NAME backend_dx12)

include(CMakePackageConfigHelpers)
install(TARGETS ${FFX_TARGETS} EXPORT ogsr-fidelityfx-fsr3-targets ARCHIVE DESTINATION lib)
# the whole public include tree, as the engine used it (host API + gpu HLSL headers)
install(DIRECTORY "${SDK}/include/FidelityFX" DESTINATION include)
install(EXPORT ogsr-fidelityfx-fsr3-targets NAMESPACE ogsr::ffx:: DESTINATION share/ogsr-fidelityfx-fsr3)
configure_package_config_file(ogsr-fidelityfx-fsr3-config.cmake.in "${CMAKE_CURRENT_BINARY_DIR}/ogsr-fidelityfx-fsr3-config.cmake" INSTALL_DESTINATION share/ogsr-fidelityfx-fsr3)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/ogsr-fidelityfx-fsr3-config.cmake" DESTINATION share/ogsr-fidelityfx-fsr3)
