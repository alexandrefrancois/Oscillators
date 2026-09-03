#pragma once

#include <cstddef>

namespace oscillators_cpp {

inline std::size_t frameSampleSpan(std::size_t frameLength, std::size_t sampleStride) {
    return frameLength * sampleStride;
}

}
