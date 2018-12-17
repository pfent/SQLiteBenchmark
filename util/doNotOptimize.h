#pragma once

#if defined(__GNUC__)
#define BENCHMARK_UNUSED __attribute__((unused))
#define BENCHMARK_ALWAYS_INLINE __attribute__((always_inline))
#define BENCHMARK_NOEXCEPT noexcept
#define BENCHMARK_NOEXCEPT_OP(x) noexcept(x)
#elif defined(_MSC_VER) && !defined(__clang__)
#define BENCHMARK_UNUSED
#define BENCHMARK_ALWAYS_INLINE __forceinline
#if _MSC_VER >= 1900
#define BENCHMARK_NOEXCEPT noexcept
#define BENCHMARK_NOEXCEPT_OP(x) noexcept(x)
#else
#define BENCHMARK_NOEXCEPT
#define BENCHMARK_NOEXCEPT_OP(x)
#endif
#define __func__ __FUNCTION__
#else
#define BENCHMARK_UNUSED
#define BENCHMARK_ALWAYS_INLINE
#define BENCHMARK_NOEXCEPT
#define BENCHMARK_NOEXCEPT_OP(x)
#endif

// see: https://github.com/google/benchmark/blob/master/include/benchmark/benchmark.h

#if (!defined(__GNUC__) && !defined(__clang__)) || defined(__pnacl__) || \
    defined(__EMSCRIPTEN__)
#define BENCHMARK_HAS_NO_INLINE_ASSEMBLY
#endif

// The DoNotOptimize(...) function can be used to prevent a value or
// expression from being optimized away by the compiler. This function is
// intended to add little to no overhead.
// See: https://youtu.be/nXaxk27zwlk?t=2441
#ifndef BENCHMARK_HAS_NO_INLINE_ASSEMBLY
template <class Tp>
inline __attribute__((always_inline)) void DoNotOptimize(Tp const& value) {
	asm volatile("" : : "r,m"(value) : "memory");
}

template <class Tp>
inline __attribute__((always_inline)) void DoNotOptimize(Tp& value) {
#if defined(__clang__)
	asm volatile("" : "+r,m"(value) : : "memory");
#else
	asm volatile("" : "+m,r"(value) : : "memory");
#endif
}

// Force the compiler to flush pending writes to global memory. Acts as an
// effective read/write barrier
inline __attribute__((always_inline)) void ClobberMemory() {
	asm volatile("" : : : "memory");
}
#elif defined(_MSC_VER)
#pragma optimize("", off)

// See: https://github.com/facebook/folly/blob/a3c67e006de0e32ecad1bc406ab74ca767e4caee/folly/Benchmark.h#L243
template <class Tp>
inline BENCHMARK_ALWAYS_INLINE void DoNotOptimize(Tp && value) {
	value = value;
	_ReadWriteBarrier();
}

#pragma optimize("", on)

inline BENCHMARK_ALWAYS_INLINE void ClobberMemory() { _ReadWriteBarrier(); }
#else
template <class Tp>
inline BENCHMARK_ALWAYS_INLINE void DoNotOptimize(Tp const& value) {
	internal::UseCharPointer(&reinterpret_cast<char const volatile&>(value));
}
// FIXME Add ClobberMemory() for non-gnu and non-msvc compilers
#endif
