# Build of libsquashfs for the ogsr-libsquashfs vcpkg port (upstream has autotools only).
# Sources and defines follow the engine's former 3rd_party\Src\libsquashfs\libsquashfs.vcxproj; ogsr\inc holds its config.h and handleapi.h.
cmake_minimum_required(VERSION 3.21)
project(ogsr-libsquashfs LANGUAGES C)

find_package(lz4 CONFIG REQUIRED)
find_package(zstd CONFIG REQUIRED)

set(SQFS_SOURCES
    lib/compat/src/strchrnul.c lib/compat/src/strndup.c
    lib/sqfs/src/block_processor/backend.c lib/sqfs/src/block_processor/block_processor.c lib/sqfs/src/block_processor/frontend.c lib/sqfs/src/block_processor/ostream.c
    lib/sqfs/src/block_writer.c
    lib/sqfs/src/comp/compressor.c lib/sqfs/src/comp/lz4.c lib/sqfs/src/comp/zstd.c
    lib/sqfs/src/data_reader.c lib/sqfs/src/dir_entry.c lib/sqfs/src/dir_iterator.c lib/sqfs/src/dir_reader.c lib/sqfs/src/dir_writer.c lib/sqfs/src/frag_table.c lib/sqfs/src/id_table.c lib/sqfs/src/inode.c
    lib/sqfs/src/io/dir_hl.c lib/sqfs/src/io/dir_rec.c lib/sqfs/src/io/dir_win32.c lib/sqfs/src/io/file.c lib/sqfs/src/io/istream.c lib/sqfs/src/io/ostream.c lib/sqfs/src/io/stream_api.c lib/sqfs/src/io/win32.c
    lib/sqfs/src/meta_reader.c lib/sqfs/src/meta_writer.c lib/sqfs/src/misc.c lib/sqfs/src/read_inode.c lib/sqfs/src/read_super.c lib/sqfs/src/read_table.c lib/sqfs/src/readdir.c lib/sqfs/src/super.c
    lib/sqfs/src/write_inode.c lib/sqfs/src/write_super.c lib/sqfs/src/write_table.c
    lib/sqfs/src/xattr/xattr.c lib/sqfs/src/xattr/xattr_reader.c lib/sqfs/src/xattr/xattr_writer.c lib/sqfs/src/xattr/xattr_writer_flush.c lib/sqfs/src/xattr/xattr_writer_record.c
    lib/util/src/alloc.c lib/util/src/array.c lib/util/src/file_cmp.c lib/util/src/hash_table.c lib/util/src/is_memory_zero.c lib/util/src/mempool.c lib/util/src/rbtree.c lib/util/src/str_table.c lib/util/src/threadpool.c lib/util/src/xxhash.c
)

add_library(squashfs STATIC ${SQFS_SOURCES})
add_library(ogsr::libsquashfs ALIAS squashfs)
set_target_properties(squashfs PROPERTIES EXPORT_NAME libsquashfs)

# ogsr/inc first: its config.h and handleapi.h replace the configure output and the SDK header
target_include_directories(squashfs PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/ogsr/inc" PUBLIC "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>" "$<INSTALL_INTERFACE:include>")
target_compile_definitions(squashfs PUBLIC SQFS_STATIC PRIVATE WIN32 _WINDOWS WITH_LZ4 WITH_ZSTD)
target_compile_options(squashfs PRIVATE /fp:fast "$<$<CONFIG:Release>:/Ot;/Oy-;/GF>")
target_link_libraries(squashfs PRIVATE lz4::lz4 zstd::libzstd)

# /GL like the engine's vcxproj; such static libs only link with the same MSVC version (true for vcpkg manifest builds)
option(OGSR_SQFS_LTCG "Build Release with /GL (link-time code generation)" ON)
set_target_properties(squashfs PROPERTIES INTERPROCEDURAL_OPTIMIZATION_RELEASE ${OGSR_SQFS_LTCG})

include(CMakePackageConfigHelpers)
install(TARGETS squashfs EXPORT ogsr-libsquashfs-targets ARCHIVE DESTINATION lib)
install(DIRECTORY include/sqfs/ DESTINATION include/sqfs FILES_MATCHING PATTERN "*.h")
install(EXPORT ogsr-libsquashfs-targets NAMESPACE ogsr:: DESTINATION share/ogsr-libsquashfs)
configure_package_config_file(ogsr-libsquashfs-config.cmake.in "${CMAKE_CURRENT_BINARY_DIR}/ogsr-libsquashfs-config.cmake" INSTALL_DESTINATION share/ogsr-libsquashfs)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/ogsr-libsquashfs-config.cmake" DESTINATION share/ogsr-libsquashfs)
