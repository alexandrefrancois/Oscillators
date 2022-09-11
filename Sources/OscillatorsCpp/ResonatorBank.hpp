/**
MIT License

Copyright (c) 2022 Alexandre R. J. Francois

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#ifndef ResonatorBank_hpp
#define ResonatorBank_hpp

#include "Resonator.hpp"

#include <vector>

// use GCD concurrency by default
// uncomment the next line to use std::async instead
// #define STD_CONCURRENCY

#ifndef STD_CONCURRENCY
#include <dispatch/dispatch.h>
#endif

namespace oscillators_cpp {

class ResonatorBank {
private:
    float m_sampleDuration;
    float m_alpha;
    std::vector<std::unique_ptr<Resonator> > m_resonators;

#ifndef STD_CONCURRENCY
    dispatch_group_t m_dispatchGroup;
    dispatch_queue_t m_dispatchQueue;
#endif

public:
    ResonatorBank & operator=(const ResonatorBank&) = delete;
    ResonatorBank(const ResonatorBank&) = delete;

    ResonatorBank(size_t numResonators, float* targetFrequencies, float sampleDuration, float alpha);
#ifndef STD_CONCURRENCY
    ~ResonatorBank();
#endif

    float sampleDuration() { return m_sampleDuration; }
    float alpha() { return m_alpha; }
    void setAlpha(float alpha);
    float timeConstant() { return m_sampleDuration / m_alpha; }
    size_t numResonators() { return m_resonators.size(); }

    void copyAmplitudes(float *dest, size_t size);
    float amplitudeValue(size_t index);

    void update(const float sample);
    void update(const std::vector<float> &samples);
    void update(const float *frameData, size_t frameLength, size_t sampleStride);
    void updateSeq(const float *frameData, size_t frameLength, size_t sampleStride);
    
#ifdef STD_CONCURRENCY
private:
    void updateEvery(size_t mod, size_t offset, const float *frameData, size_t frameLength, size_t sampleStride);
#endif

};

} // oscillators_cpp

#endif /* ResonatorBank_hpp */
