/**
MIT License

Copyright (c) 2025-2026 Alexandre R. J. Francois

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

#include "TrackingResonatorBank.hpp"
#include <dispatch/dispatch.h>

#include <atomic>
#include <algorithm>

using namespace oscillators_cpp;

TrackingResonatorBank::TrackingResonatorBank(size_t numResonators, const float* naturalFrequencies, const float* alphas, const float* betas, const float* gammas, float sampleRate)
: m_sampleRate(sampleRate), m_sigma(1.0), m_omSigma(0.0)  {
    m_resonators.reserve(numResonators);
    for (size_t i=0; i<numResonators; ++i) {
        m_resonators.emplace_back(std::make_unique<TrackingResonator>(naturalFrequencies[i], alphas[i], betas[i], gammas[i], sampleRate));
    }
    m_dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    m_accPower.store(0.0001, std::memory_order_relaxed);
}

void TrackingResonatorBank::getNaturalFrequencies(float *dest, size_t size) {
    for (size_t i=0; i<std::min(size, m_resonators.size()); ++i) {
        dest[i]=m_resonators[i]->naturalFrequency();
    }
}

void TrackingResonatorBank::getResonantFrequencies(float *dest, size_t size) {
    for (size_t i=0; i<std::min(size, m_resonators.size()); ++i) {
        dest[i]=m_resonators[i]->resonantFrequency();
    }
}


float TrackingResonatorBank::resonantFrequencyValue(size_t index) {
    if (index >= m_resonators.size()) {
        throw std::out_of_range("Bad index passed to resonantFrequencyValue()");
    }
    return m_resonators[index]->frequency();
}

void TrackingResonatorBank::getPowers(float *dest, size_t size) {
    for (size_t i=0; i<std::min(size, m_resonators.size()); ++i) {
        dest[i]=m_resonators[i]->power();
    }
}

void TrackingResonatorBank::getAmplitudes(float *dest, size_t size) {
    for (size_t i=0; i<std::min(size, m_resonators.size()); ++i) {
        dest[i]=m_resonators[i]->amplitude();
    }
}

void TrackingResonatorBank::getPhases(float *dest, size_t size) {
    for (size_t i=0; i<std::min(size, m_resonators.size()); ++i) {
        dest[i]=m_resonators[i]->phase();
    }
}

void TrackingResonatorBank::getDeltaPhases(float *dest, size_t size) {
    for (size_t i=0; i<std::min(size, m_resonators.size()); ++i) {
        dest[i]=m_resonators[i]->deltaPhase();
    }
}

void TrackingResonatorBank::update(const float sample) {
    // 1. Snapshot the current atomic value
    // Using relaxed memory order is most efficient for audio parameters
    const float lastAccPower = m_accPower.load(std::memory_order_relaxed);
    
    float maxPower = 0.0f;

    // 2. Sequential processing loop
    for (auto &resonatorPtr : m_resonators) {
        resonatorPtr->update(sample, m_accPower);
        const float power = resonatorPtr->power();
        if(power > maxPower) {
            maxPower = power;
        }
    }
    
    // 3. Calculate the new moving average
    float nextAccPower = m_omSigma * lastAccPower + m_sigma * maxPower;
    
    // 4. Store the result back to the atomic variable
    m_accPower.store(nextAccPower, std::memory_order_relaxed);
}

void TrackingResonatorBank::update(const std::vector<float> &samples) {
    // 1. Snapshot the current atomic value
    // Using relaxed memory order is most efficient for audio parameters
    const float lastAccPower = m_accPower.load(std::memory_order_relaxed);
    
    float maxPower = 0.0f;
    
    // 2. Sequential processing loop
    for (auto &resonatorPtr : m_resonators) {
        resonatorPtr->update(samples, m_accPower);
        const float power = resonatorPtr->power();
        if(power > maxPower) {
            maxPower = power;
        }
    }
    
    // 3. Calculate the new moving average
    float nextAccPower = m_omSigma * lastAccPower + m_sigma * maxPower;
    
    // 4. Store the result back to the atomic variable
    m_accPower.store(nextAccPower, std::memory_order_relaxed);
}

void TrackingResonatorBank::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    // 1. Snapshot the current atomic value
    // Using relaxed memory order is most efficient for audio parameters
    const float lastAccPower = m_accPower.load(std::memory_order_relaxed);
    
    float maxPower = 0.0f;
    
    // 2. Sequential processing loop
    for (auto &resonatorPtr : m_resonators) {
        // Pass the snapshotted float value, not the atomic itself
        resonatorPtr->update(frameData, frameLength, sampleStride, lastAccPower);
        
        const float power = resonatorPtr->power();
        if (power > maxPower) {
            maxPower = power;
        }
    }
    
    // 3. Calculate the new moving average
    float nextAccPower = m_omSigma * lastAccPower + m_sigma * maxPower;
    
    // 4. Store the result back to the atomic variable
    m_accPower.store(nextAccPower, std::memory_order_relaxed);
}

// concurrency with Apple GCD
void TrackingResonatorBank::updateConcurrent(const float *frameData, size_t frameLength, size_t sampleStride) {
    const float lastAccPower = m_accPower.load(std::memory_order_relaxed);
    const size_t numResonators = m_resonators.size();
    
    // 1. Declare the atomic locally
    std::atomic<float> frameMaxPower{0.0f};

    // 2. Get a pointer to the atomic to bypass Block copy restrictions
    std::atomic<float>* frameMaxPtr = &frameMaxPower;

    const size_t numChunks = 4;
    dispatch_apply(numChunks, m_dispatchQueue, ^(size_t chunkIdx) {
        float localMax = 0.0f;
        
        size_t start = (chunkIdx * numResonators) / numChunks;
        size_t end = (chunkIdx == numChunks - 1) ? numResonators : ((chunkIdx + 1) * numResonators) / numChunks;

        for (size_t i = start; i < end; ++i) {
            m_resonators[i]->update(frameData, frameLength, sampleStride, lastAccPower);
            localMax = std::max(localMax, m_resonators[i]->power());
        }

        // 3. Use the pointer. Use the 4-argument version of compare_exchange_weak
        // to satisfy the compiler requirements for success/failure memory orders.
        float expected = frameMaxPtr->load(std::memory_order_relaxed);
        while (localMax > expected &&
               !frameMaxPtr->compare_exchange_weak(expected,
                                                  localMax,
                                                  std::memory_order_relaxed,
                                                  std::memory_order_relaxed)) {
            // 'expected' is automatically updated by compare_exchange_weak on failure
        }
    });

    float finalFrameMax = frameMaxPower.load();
    float nextAccPower = m_omSigma * lastAccPower + m_sigma * finalFrameMax;

    m_accPower.store(nextAccPower, std::memory_order_relaxed);
}

void TrackingResonatorBank::setTimeConstant(float tau, size_t frameLength, size_t sampleStride, float sampleRate) {
    float frameDuration =  static_cast<float>(frameLength / sampleStride) / sampleRate;
    m_sigma = 1.0f - exp(-frameDuration / tau);
    m_omSigma = 1.0f - m_sigma;
}
