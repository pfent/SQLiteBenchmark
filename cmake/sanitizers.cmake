# Sanitizers compile flags
# Make sure to include SANITIZE_COMPILE_FLAGS and SANITIZE_LINK_FLAGS, like add_executable_with_warnings does
#
# IMPORTANT: not all runtime ASAN checks are enabled by default, even when compiled with support for it.
# To actually run the checks, the program needs to be started with proper environment variables set.
# E.g.: ASAN_OPTIONS="detect_invalid_pointer_pairs=1" ./a.out
# For a detailed list, see: https://github.com/google/sanitizers/wiki/SanitizerCommonFlags
include(CheckCXXCompilerFlag)
function(test_add_flag target flag)
    check_cxx_compiler_flag(${flag} result)
    if (result)
        set(${target} ${${target}} ${flag} PARENT_SCOPE)
    endif ()
endfunction(test_add_flag)

macro(add_sanitize_flag flag)
    test_add_flag(SANITIZE_COMPILE_FLAGS ${flag})
    test_add_flag(SANITIZE_LINK_FLAGS ${flag})
endmacro()

if (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    add_sanitize_flag(-fsanitize=address)
    add_sanitize_flag(-undefined)
    add_sanitize_flag(-fsanitize-address-use-after-scope)
    add_sanitize_flag(-fsanitize=undefined)
    add_sanitize_flag(-fsanitize=leak)
    add_sanitize_flag(-fsanitize=pointer-compare)
    add_sanitize_flag(-fsanitize=pointer-subtract)
    test_add_flag(SANITIZE_COMPILE_FLAGS -fno-omit-frame-pointer)
endif ()

if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_sanitize_flag(-fsanitize=address)
    add_sanitize_flag(-fsanitize=integer)
    add_sanitize_flag(-fsanitize=undefined)
    test_add_flag(SANITIZE_COMPILE_FLAGS -fno-omit-frame-pointer)
endif ()

if (MSVC)
    set(SANITIZE_COMPILE_FLAGS "")
    set(SANITIZE_LINK_FLAGS "")
endif ()

# transforms the given list of flags to be cmake-generator-expressions, active for Debug build
# those can easily be used in target_compile_options()
function(add_debug_generator_expression target)
    set(transformed "")
    foreach(flag ${ARGN})
        LIST(APPEND transformed "$<$<CONFIG:Debug>:${flag}>")
    endforeach(flag)
    set(${target} "${transformed}" PARENT_SCOPE)
endfunction(add_debug_generator_expression)

add_debug_generator_expression(SANITIZE_COMPILE_FLAGS ${SANITIZE_COMPILE_FLAGS})
add_debug_generator_expression(SANITIZE_LINK_FLAGS ${SANITIZE_LINK_FLAGS})
