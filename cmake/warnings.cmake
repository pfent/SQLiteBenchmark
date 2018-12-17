# From: https://github.com/fmtlib/fmt/blob/master/CMakeLists.txt
# Popular compile warnings, depending on the compiler used

include(CheckCXXCompilerFlag)
if (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    set(PEDANTIC_COMPILE_FLAGS -pedantic-errors -Wall -Wextra -pedantic # these are not discussable
            -Wold-style-cast
            -Wlogical-op
            -Wundef
            -Wredundant-decls
            -Wshadow=local
            -Wwrite-strings
            -Wpointer-arith
            -Wcast-qual
            -Wformat=2
            -Wmissing-include-dirs
            -Wcast-align
            -Wnon-virtual-dtor
            -Wctor-dtor-privacy
            -Wdisabled-optimization
            -Winvalid-pch
            -Woverloaded-virtual
            -Wno-ctor-dtor-privacy
            -Wno-dangling-else
            -Wno-format-nonliteral
            -Wno-sign-conversion
            )
    if (NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 4.6)
        set(PEDANTIC_COMPILE_FLAGS ${PEDANTIC_COMPILE_FLAGS}
                -Wnoexcept
                )
    endif ()
    if (NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 5.0)
        set(PEDANTIC_COMPILE_FLAGS ${PEDANTIC_COMPILE_FLAGS}
                -Wdouble-promotion
                -Wtrampolines
                -Wzero-as-null-pointer-constant
                -Wuseless-cast
                -Wvector-operation-performance
                -Wsized-deallocation
                -Wodr
                )
    endif ()
    if (NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 6.0)
        set(PEDANTIC_COMPILE_FLAGS ${PEDANTIC_COMPILE_FLAGS}
                -Wshift-overflow=2
                -Wnull-dereference
                -Wduplicated-cond
                -Wduplicated-branches
                )
    endif ()

    set(WERROR_FLAG -Werror)
endif ()

if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    set(PEDANTIC_COMPILE_FLAGS -Wall -Wextra -Wpedantic
            -Wno-weak-vtables
            -Wno-padded
            -Wno-gnu-statement-expression
            -Wno-c++98-compat
            -Wno-c++98-compat-pedantic
            -Wno-reserved-id-macro
            -Wno-global-constructors
            -Wno-disabled-macro-expansion
            -Wno-switch-enum
            -Wno-documentation-unknown-command
            -Wno-unused-member-function
            -Wno-format-nonliteral
            -Wno-missing-noreturn
            -Wno-undefined-func-template
            -Wno-shadow
            -Wno-sign-conversion
            -Wno-used-but-marked-unused
            -Wno-covered-switch-default
            -Wno-missing-prototypes
            -Wno-missing-variable-declarations
            -Wno-double-promotion
            )
    set(WERROR_FLAG -Werror)

    check_cxx_compiler_flag(-Wno-zero-as-null-pointer-constant HAS_NULLPTR_WARNING)
    if (HAS_NULLPTR_WARNING)
        set(PEDANTIC_COMPILE_FLAGS ${PEDANTIC_COMPILE_FLAGS}
                -Wno-zero-as-null-pointer-constant
                )
    endif ()
endif ()

if (MSVC)
    set(PEDANTIC_COMPILE_FLAGS /W3)
    set(WERROR_FLAG /WX)
endif ()
