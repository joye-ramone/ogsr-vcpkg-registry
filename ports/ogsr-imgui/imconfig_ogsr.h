//---- OGSR (ports/ogsr-imgui): item hooks and asserts in every configuration.
// IMGUI_ENABLE_TEST_ENGINE only compiles in the item hooks (imgui_internal.h): the consumer defines ImGuiTestEngineHook_ItemAdd,
// ImGuiTestEngineHook_ItemInfo, ImGuiTestEngineHook_Log and ImGuiTestEngine_FindItemDebugLabel; they run only while
// ImGuiContext::TestEngineHookItems is set. The Dear ImGui Test Engine library is not part of this port.
#define IMGUI_ENABLE_TEST_ENGINE
// IM_ASSERT stays on in Release: the consumer defines ImGuiOgsr_AssertFailed (log, break, or fail).
void ImGuiOgsr_AssertFailed(const char* expr, const char* file, int line);
#define IM_ASSERT(_EXPR) ((_EXPR) ? (void)0 : ImGuiOgsr_AssertFailed(#_EXPR, __FILE__, __LINE__))
//---- OGSR end

