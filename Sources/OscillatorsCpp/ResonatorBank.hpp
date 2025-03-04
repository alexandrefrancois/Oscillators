/**
MIT License

Copyright (c) 2022-2025 Alexandre R. J. Francois

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
    float m_sampleRate;
    std::vector<std::unique_ptr<Resonator> > m_resonators;

#ifndef STD_CONCURRENCY
    dispatch_group_t m_dispatchGroup;
    dispatch_queue_t m_dispatchQueue;
#endif

public:
    ResonatorBank & operator=(const ResonatorBank&) = delete;
    ResonatorBank(const ResonatorBank&) = delete;

    ResonatorBank(size_t numResonators, const float* frequencies, const float* alphas, const float* betas, float sampleRate);
#ifndef STD_CONCURRENCY
    ~ResonatorBank();
#endif

    float sampleRate() { return m_sampleRate; }
    size_t numResonators() { return m_resonators.size(); }
    float frequencyValue(size_t index);
    float alphaValue(size_t index);
    void setAllAlphas(float alpha);
    void getPowers(float *dest, size_t size);
    void getAmplitudes(float *dest, size_t size);
    void update(const float sample);
    void update(const std::vector<float> &samples);
    void update(const float *frameData, size_t frameLength, size_t sampleStride);
    void updateConcurrent(const float *frameData, size_t frameLength, size_t sampleStride);
    
#ifdef STD_CONCURRENCY
private:
    void updateEvery(size_t mod, size_t offset, const float *frameData, size_t frameLength, size_t sampleStride);
#endif

};

} // oscillators_cpp

#endif /* ResonatorBank_hpp */
