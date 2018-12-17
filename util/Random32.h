#pragma once

#include <cstdint>

/// https://en.wikipedia.org/wiki/Xorshift
class Random32 {
   uint32_t state;
   public:
   explicit Random32(uint32_t seed = 314159265) : state(seed) {}

   uint32_t next() {
      state ^= (state << 13);
      state ^= (state >> 7);
      state ^= (state << 5);
      return state;
   }
};
