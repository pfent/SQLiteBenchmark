# Set the default CMAKE_BUILD_TYPE (default to Release).
# This should be done before the project command since the latter can set CMAKE_BUILD_TYPE itself.
function(cmake_set_default_build_type)
    if(ARGC GREATER 0)
        set(buildtype ${ARGV1})
    else()
        set(buildtype Release)
    endif()

    if (NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE ${buildtype} CACHE STRING
                "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel.")
    endif ()
endfunction(cmake_set_default_build_type)
