include(warnings)

# add_executable with defaults for warnings and compile flags
function(add_executable_with_warnings name)
    # ARGN refers to additional arguments after 'name'
    add_executable(${name} ${ARGN})

    target_compile_options(${name} PRIVATE ${PEDANTIC_COMPILE_FLAGS})
    target_compile_features(${name} PUBLIC cxx_std_17)
    set_target_properties(${name} PROPERTIES CXX_EXTENSIONS OFF)

    # sanitizers, if any
    if (SANITIZE_COMPILE_FLAGS)
        target_compile_options(${name} PRIVATE ${SANITIZE_COMPILE_FLAGS})
        foreach (linkFlag ${SANITIZE_LINK_FLAGS})
            target_link_libraries(${name} ${linkFlag})
        endforeach (linkFlag)
    endif ()
endfunction(add_executable_with_warnings)

# Tests for interprocedural optimization availability and enables it if possible
function(enable_lto_in_release target)
    if (NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
        include(CheckIPOSupported)
        check_ipo_supported(RESULT result)
        if (result)
            set_property(TARGET ${target} PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
        endif ()
    endif ()
endfunction(enable_lto_in_release)

# Aggressive warning settings can cause noisy warnings in dependency includes
# This function silences those warnings by rewriting the include directories to be considered SYSTEM
# see: https://stackoverflow.com/a/52136398
function(target_link_libraries_dont_warn target)
    set(libs ${ARGN})
    foreach (lib ${libs})
        get_target_property(lib_include_dirs ${lib} INTERFACE_INCLUDE_DIRECTORIES)
        target_include_directories(${target} SYSTEM PRIVATE ${lib_include_dirs})
        target_link_libraries(${target} ${lib})
    endforeach (lib)
endfunction(target_link_libraries_dont_warn)

# Run cmake build generation on the target directory
function(cmake_generate_directory dir)
    execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
            RESULT_VARIABLE result
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/${dir})
    if (result)
        message(FATAL_ERROR "CMake step for ${dir} failed: ${result}")
    endif ()
endfunction(cmake_generate_directory)

# Run the configured build system for the target directory
function(build_directory dir)
    execute_process(COMMAND ${CMAKE_COMMAND} --build .
            RESULT_VARIABLE result
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/${dir})
    if (result)
        message(FATAL_ERROR "Build step for ${dir} failed: ${result}")
    endif ()
endfunction(build_directory)

# Capitalize the first letter of string and save the result in the out-var
function(capitalize string result)
    string(SUBSTRING ${string} 0 1 FIRST_LETTER)
    string(TOUPPER ${FIRST_LETTER} FIRST_LETTER)
    string(REGEX REPLACE "^.(.*)" "${FIRST_LETTER}\\1" string "${string}")

    set(${result} ${string} PARENT_SCOPE)
endfunction(capitalize)

# Configure and build the specified dependency
# This function assumes, there is a externalProject<Dependency>.txt.in file
# initial functionality based on abseil's use of Gtest https://github.com/abseil/abseil-cpp
function(configure_and_build dependency)
    capitalize(${dependency} Dependency)

    if (NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/externalProject${Dependency}.txt.in")
        message(FATAL_ERROR "Could not find file: ${CMAKE_CURRENT_LIST_DIR}/externalProject${Dependency}.txt.in\n"
                "Please specify the externalProject file to download the dependency's source")
    endif ()

    # Configure dependency from externalProject
    configure_file(
            ${CMAKE_CURRENT_LIST_DIR}/externalProject${Dependency}.txt.in
            ${dependency}-download/CMakeLists.txt
    )

    # run cmake and build the downloaded source
    cmake_generate_directory(${dependency}-download)
    build_directory(${dependency}-download)
endfunction(configure_and_build)
