cmake_minimum_required(VERSION 3.12)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(defaultBuildType)
cmake_set_default_build_type()

project(SQLiteBenchmark)

include(utils)
include(sanitizers)

include(downloadSqlite)

add_executable_with_warnings(SQLiteBenchmark main.cpp)
enable_lto_in_release(SQLiteBenchmark)

target_link_libraries(SQLiteBenchmark sqlite)
