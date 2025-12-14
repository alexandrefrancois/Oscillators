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

#include "ResonatorBank.hpp"

#ifndef STD_CONCURRENCY
#include <dispatch/dispatch.h>
#else
#include <future>
#endif

using namespace oscillators_cpp;

constexpr size_t resonatorStride = 6;

ResonatorBank::ResonatorBank(size_t numResonators, const float* frequencies, const float* alphas, const float* betas, const float* gammas, float sampleRate) : m_sampleRate(sampleRate) {
    m_resonators.reserve(numResonators);
    for (size_t i=0; i<numResonators; ++i) {
        m_resonators.emplace_back(std::make_unique<Resonator>(frequencies[i], alphas[i], betas[i], gammas[i], sampleRate));
    }
#ifndef STD_CONCURRENCY
    m_dispatchGroup = dispatch_group_create();
    dispatch_retain(m_dispatchGroup);
    m_dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
#endif
}

#ifndef STD_CONCURRENCY
ResonatorBank::~ResonatorBank() {
    dispatch_group_wait(m_dispatchGroup, dispatch_time(DISPATCH_TIME_NOW, 1000000000));
    dispatch_release(m_dispatchGroup);
}
#endif

float ResonatorBank::frequencyValue(size_t index) {
    if (index >= m_resonators.size()) {
        throw std::out_of_range("Bad index passed to frequencyValue()");
    }
    return m_resonators[index]->frequency();
}

float ResonatorBank::alphaValue(size_t index) {
    if (index >= m_resonators.size()) {
        throw std::out_of_range("Bad index passed to alphaValue()");
    }
    return m_resonators[index]->alpha();
}

void ResonatorBank::setAllAlphas(float alpha) {
    if (alpha < 0.0 || alpha >1.0) {
        throw std::out_of_range("Bad alpha passed to setAllAlphas()");
    }
    for (auto &resonatorPtr : m_resonators) {
        resonatorPtr->setAlpha(alpha);
    }
}

void ResonatorBank::getPowers(float *dest, size_t size) {
    for (size_t i=0; i<std::min(size, m_resonators.size()); ++i) {
        dest[i]=m_resonators[i]->power();
    }
}

void ResonatorBank::getAmplitudes(float *dest, size_t size) {
    for (size_t i=0; i<std::min(size, m_resonators.size()); ++i) {
        dest[i]=m_resonators[i]->amplitude();
    }
}

void ResonatorBank::getPhases(float *dest, size_t size) {
    for (size_t i=0; i<std::min(size, m_resonators.size()); ++i) {
        dest[i]=m_resonators[i]->phase();
    }
}

void ResonatorBank::getDeltaPhases(float *dest, size_t size) {
    for (size_t i=0; i<std::min(size, m_resonators.size()); ++i) {
        dest[i]=m_resonators[i]->deltaPhase();
    }
}

void ResonatorBank::getInstantaneousFrequencies(float *dest, size_t size) {
    for (size_t i=0; i<std::min(size, m_resonators.size()); ++i) {
        dest[i]=m_resonators[i]->instantaneousFrequency();
    }
}

void ResonatorBank::update(const float sample) {
    for (auto &resonatorPtr : m_resonators) {
        resonatorPtr->update(sample);
    }
}

void ResonatorBank::update(const std::vector<float> &samples) {
    for (auto &resonatorPtr : m_resonators) {
        resonatorPtr->update(samples);
    }
}

void ResonatorBank::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (auto &resonatorPtr : m_resonators) {
        resonatorPtr->update(frameData, frameLength, sampleStride);
    }
}

#ifndef STD_CONCURRENCY
// concurrency with Apple GCD

void ResonatorBank::updateConcurrent(const float *frameData, size_t frameLength, size_t sampleStride) {
    const size_t numResonators = m_resonators.size();
    if (numResonators == 0) return;

    // We split the work into a fixed number of chunks.
    // Usually, 4 to 8 chunks is ideal for mobile/desktop CPUs to balance
    // core utilization vs GCD overhead.
    const size_t numChunks = 4;

    dispatch_apply(numChunks, m_dispatchQueue, ^(size_t chunkIdx) {
        // Calculate the contiguous range for this chunk
        size_t start = (chunkIdx * numResonators) / numChunks;
        size_t end = (chunkIdx == numChunks - 1) ? numResonators : ((chunkIdx + 1) * numResonators) / numChunks;

        for (size_t i = start; i < end; ++i) {
            m_resonators[i]->update(frameData, frameLength, sampleStride);
        }
    });    
    // dispatch_apply does not return until all blocks are finished.
}

#else
// concurrency with std::async

void ResonatorBank::updateConcurrent(const float *frameData, size_t frameLength, size_t sampleStride) {
    std::vector<std::future<void>> handles;
    handles.reserve(resonatorStride);
    for (size_t offset = 0; offset < resonatorStride; ++offset) {
        auto handle = std::async(std::launch::async, &ResonatorBank::updateEvery, this, resonatorStride, offset, frameData, frameLength, sampleStride);
        handles.emplace_back(std::move(handle));
    }
    for (auto& handle : handles) {
        handle.wait();
    }
}

void ResonatorBank::updateEvery(size_t stride, size_t offset, const float *frameData, size_t frameLength, size_t sampleStride) {
    size_t index = offset;
    while (index < m_resonators.size()) {
        m_resonators[index]->update(frameData, frameLength, sampleStride);
        index += stride;
    }
}
#endif

