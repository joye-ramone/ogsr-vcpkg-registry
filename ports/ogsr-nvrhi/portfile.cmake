# NVRHI (NVIDIA Rendering Hardware Interface) for OGSR Engine's xrRender_R4 (agent/render_PLAN_rhi.md): static libraries nvrhi (common +
# validation layer), nvrhi_d3d11 and nvrhi_d3d12; no Vulkan, NVAPI, Aftermath or RTXMU. The D3D12 backend uses vcpkg's directx-headers instead
# of fetching DirectX-Headers at configure time. Patches (render_PLAN_rhi.md section 2.6):
#   semantic-index-base.patch        patch 1: VertexAttributeDesc::semanticIndex, the semantic index of the first element (D3D11 and D3D12)
#   directx-headers-from-vcpkg.patch find_package(directx-headers) when NVRHI_FETCH_DIRECTX_HEADERS is off
#   directx-headers-release.patch    builds against vcpkg's release headers (1.619): the preview-only linear algebra barrier sync is a no-op
#   d3d11-deferred-command-lists.patch  D3D11: createCommandList without enableImmediateExecution records into an own deferred context
#                                    (close = FinishCommandList, executeCommandLists = ExecuteCommandList in order); locks for the view
#                                    and state caches; writeBuffer into a dynamic buffer: offset 0 discards, further in NO_OVERWRITE
#   sampler-desc-compare-lod.patch   SamplerDesc::comparisonFunc, minLod, maxLod, anisotropicFilter (D3D11 / D3D12; defaults = the former
#                                    behaviour): the renderer's samplers compare with LESS_EQUAL, clamp from -FLT_MAX and stay anisotropic
#                                    at anisotropy 1; D3D11 samplers give their ID3D11SamplerState (ObjectTypes::D3D11_SamplerState)
#   texture3d-rtv-a8-unorm.patch     a 3D texture's RTV covers the requested W slices (resolve kept one), Format::A8_UNORM (the font atlas)
#   native-shaders-vertex-stride.patch  nvrhi::d3d11::createShaderHandleForNative / createInputLayoutHandleForNative (handles over the
#                                    renderer's own D3D11 shaders and input layouts); VertexBufferBinding::stride (D3D11 / D3D12, 0 = the
#                                    input layout's): the renderer sets the stride per draw
#   d3d11-native-pipeline.patch      nvrhi::d3d11::createGraphicsPipelineForNative (a pipeline over the renderer's canonical D3D11 state
#                                    objects and topology: the same objects as today, no IndependentBlendEnable rewrite),
#                                    nvrhi::d3d11::invalidateState (forget the bound state after native D3D11 binding calls)
#   d3d11-null-bindings.patch        D3D11: a null texture / buffer / sampler in a binding set binds null at its slot (the renderer leaves
#                                    declared slots empty: zeros, the default sampler), allowed by the validation layer on D3D11
#   d3d11-graphics-state-cost.patch  D3D11 setGraphicsState records only the parts that changed, element by element (a static_vector
#                                    assignment copies its whole capacity): most draws change only their vertex / index buffers
#   d3d11-changed-bindings-only.patch  D3D11: a binding set binds only the CB / SRV / sampler slots that differ from what the stage has
#                                    bound (whole constant buffers through *SetConstantBuffers, not *1), a pipeline only the shaders /
#                                    input layout / topology / RS / blend / depth-stencil state that differ from the bound pipeline
#   d3d11-buffer-bindings-unreferenced.patch  D3D11: the bound vertex / index buffers are kept as their D3D11 buffers, without references
#                                    (an interlocked AddRef / Release per draw on buffers several lists bind) and compared with them
#   d3d11-set-vertex-index-buffers.patch  nvrhi::d3d11::setVertexIndexBuffers: the vertex / index buffers of a draw that changes nothing else,
#                                    with their D3D11 buffers given (no full state comparison, no lookup through the buffers)
#   d3d11-same-layout-sets.patch     D3D11: binding sets that replace bound sets of the same layout (same slots) skip the unbind / superset
#                                    tests on every pair of sets
#   d3d11-graphics-bindings.patch    nvrhi::d3d11::setGraphicsBindings: a graphics stage's CB / SRV / sampler slots bound from the caller's
#                                    arrays through the list's record of bound slots, for pipelines without binding layouts (no binding sets);
#                                    nvrhi::d3d11::hasGraphicsState (a draw that changes nothing needs no state call)
#   d3d12-view-cache-lock.patch      D3D12: a texture's view caches (getNativeView, getClearMipLevelUAV) under a lock, filled on first use from
#                                    lists recorded on several threads (the sun cascades clear slices of one shadow map); the upload
#                                    manager returns false when a chunk's buffer is not created (after a device removal) instead of
#                                    dereferencing it
#   d3d12-referenced-once.patch      D3D12: a command list instance references a pipeline, framebuffer, binding set or buffer once (a set of
#                                    addresses per instance), not at every bind: no interlocked AddRef per pipeline / buffer change on objects
#                                    all recording threads bind
#   d3d12-volatile-cb-latest.patch   D3D12: writeBuffer into a volatile constant buffer stores the new address in the bound slots of that buffer;
#                                    the draw / dispatch rebinds the slots that changed without a hash map lookup per bound buffer
#   d3d12-set-vertex-index-buffers.patch  nvrhi::d3d12::setVertexIndexBuffers (the vertex / index buffers of a draw that changes nothing else)
#                                    and nvrhi::d3d12::hasGraphicsState, the D3D12 twins of patches 13 and 15's; setGraphicsState records the
#                                    state element by element (a static_vector assignment copies its whole capacity, about 1 KB a draw)
#   d3d12-referenced-textures.patch  nvrhi::d3d12::getReferencedTextures: the textures a command list instance uses (through its binding
#                                    sets, clears, copies, writes, state calls), each once, from close() to executeCommandLists: the
#                                    application's residency (a texture it evicted is made resident before a list that uses it runs)
#   d3d12-root-signature-lock.patch  D3D12: Device::getRootSignature and ~RootSignature use the root signature cache under a lock
#                                    (pipelines are created from several threads); a cached one being deleted is replaced, not revived
#   d3d12-viewport-framebuffer.patch  D3D12: setGraphicsState sends the viewports / scissor rects again when the framebuffer or the
#                                    pipeline's scissorEnable changes (both change the clamped rects convertViewportState makes)

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO NVIDIA-RTX/NVRHI
    REF 6b96fb03e07539f08327aea76c56d55f1de9d906
    SHA512 039c3f96edf1180e8267f801fa9585b2145a372b33ec72293369c9965f9c30ae894e0a1fd80e2eed9fa731e2580a9980b3ee9ff4b377d777d6791bd44173773b
    HEAD_REF main
    PATCHES
        semantic-index-base.patch
        directx-headers-from-vcpkg.patch
        directx-headers-release.patch
        d3d11-deferred-command-lists.patch
        sampler-desc-compare-lod.patch
        texture3d-rtv-a8-unorm.patch
        native-shaders-vertex-stride.patch
        d3d11-native-pipeline.patch
        d3d11-null-bindings.patch
        d3d11-graphics-state-cost.patch
        d3d11-changed-bindings-only.patch
        d3d11-buffer-bindings-unreferenced.patch
        d3d11-set-vertex-index-buffers.patch
        d3d11-same-layout-sets.patch
        d3d11-graphics-bindings.patch
        d3d12-view-cache-lock.patch
        d3d12-referenced-once.patch
        d3d12-volatile-cb-latest.patch
        d3d12-set-vertex-index-buffers.patch
        d3d12-referenced-textures.patch
        d3d12-root-signature-lock.patch
        d3d12-viewport-framebuffer.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DNVRHI_BUILD_SHARED=OFF
        -DNVRHI_BUILD_TESTS=OFF
        -DNVRHI_INSTALL=ON
        -DNVRHI_INSTALL_EXPORTS=OFF
        -DNVRHI_WITH_VALIDATION=ON
        -DNVRHI_WITH_DX11=ON
        -DNVRHI_WITH_DX12=ON
        -DNVRHI_WITH_VULKAN=OFF
        -DNVRHI_WITH_NVAPI=OFF
        -DNVRHI_WITH_AFTERMATH=OFF
        -DNVRHI_WITH_RTXMU=OFF
        -DNVRHI_FETCH_DIRECTX_HEADERS=OFF
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE=ON
    MAYBE_UNUSED_VARIABLES
        CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE # read by CMake itself (/GL, lib /LTCG), not by CMakeLists.txt
        NVRHI_INSTALL_EXPORTS
)
vcpkg_cmake_install()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include" "${CURRENT_PACKAGES_DIR}/debug/share")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
