configure_and_build(sqlite)

# Add fmt directly to our build
#add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/external/sqlite
#        ${CMAKE_BINARY_DIR}/sqlite
#        EXCLUDE_FROM_ALL)
add_library(sqlite STATIC
        ${CMAKE_BINARY_DIR}/sqlite/sqlite3.c
        ${CMAKE_BINARY_DIR}/sqlite/sqlite3.h
        )
target_include_directories(sqlite SYSTEM PUBLIC ${CMAKE_BINARY_DIR}/sqlite/)
target_link_libraries(sqlite INTERFACE pthread)
target_link_libraries(sqlite INTERFACE dl)

