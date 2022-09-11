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

#include "ResonatorBank.hpp"

#ifndef STD_CONCURRENCY
#include <dispatch/dispatch.h>
#else
#include <future>
#endif

using namespace oscillators_cpp;

ResonatorBank::ResonatorBank(size_t numResonators, float* targetFrequencies, float sampleDuration, float alpha) : m_sampleDuration(sampleDuration), m_alpha(alpha) {
    m_resonators.reserve(numResonators);
    for (size_t i=0; i<numResonators; ++i) {
        m_resonators.emplace_back(std::make_unique<Resonator>(targetFrequencies[i], sampleDuration, alpha));
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

void ResonatorBank::setAlpha(float alpha) {
    if (alpha < 0.0 || alpha >1.0) {
        throw std::out_of_range("Bad alpha passed to setAlpha()");
    }
    m_alpha = alpha;
    for (auto &resonatorPtr : m_resonators) {
        resonatorPtr->setAlpha(alpha);
    }

}

void ResonatorBank::copyAmplitudes(float *dest, size_t size) {
    for (size_t i=0; i<std::min(size, m_resonators.size()); ++i) {
        dest[i]=m_resonators[i]->amplitude();
    }
}

float ResonatorBank::amplitudeValue(size_t index) {
    if (index >= m_resonators.size()) {
        throw std::out_of_range("Bad index passed to amplitudeValue()");
    }
    return m_resonators[index]->amplitude();
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

#ifndef STD_CONCURRENCY
// concurrency with Apple GCD
void ResonatorBank::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    size_t count = m_resonators.size();
    // make one single task with the top frequency oscillators as their runtime does not justify independent tasks
    size_t count2 = count / 2;
    dispatch_group_async(m_dispatchGroup, m_dispatchQueue, ^{
        for (size_t index = count2; index < count; ++index) {
            m_resonators[index]->update(frameData, frameLength, sampleStride);
        }
    });
    // for the lower frequency oscillators
    // even out the task length by pairing resonators from both ends of the spectrum
    // taking into account that the complexity of the update is proportional to the size of the phases array
    for (size_t index = 0; index < count2 / 2; ++index) {
        size_t index2 = count2 - 1 - index;
        dispatch_group_async(m_dispatchGroup, m_dispatchQueue, ^{
            m_resonators[index]->update(frameData, frameLength, sampleStride);
            m_resonators[index2]->update(frameData, frameLength, sampleStride);
        });
    }
    if ((count2 & 1) == 1) {
        dispatch_group_async(m_dispatchGroup, m_dispatchQueue, ^{
            m_resonators[count2/2]->update(frameData, frameLength, sampleStride);
        });
    }
    dispatch_group_wait(m_dispatchGroup, DISPATCH_TIME_FOREVER);
}

// concurrency with Apple GCD - alternate heuristic
// does not seem to make much of a difference one way or the other
//void ResonatorBank::update(const float *frameData, size_t frameLength, size_t sampleStride) {
//    constexpr size_t stride = 8;
//    for (size_t offset = 0; offset < stride; ++offset) {
//        dispatch_group_async(m_dispatchGroup, m_dispatchQueue, ^{
//            size_t index = offset;
//            while (index < m_resonators.size()) {
//                m_resonators[index]->update(frameData, frameLength, sampleStride);
//                index += stride;
//            }
//        });
//    }
//    dispatch_group_wait(m_dispatchGroup, DISPATCH_TIME_FOREVER);
//}

#else
// concurrency with std::async
void ResonatorBank::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    constexpr size_t stride = 8;
    std::vector<std::future<void>> handles;
    handles.reserve(stride);
    for (size_t offset = 0; offset < stride; ++offset) {
        auto handle = std::async(std::launch::async, &ResonatorBank::updateEvery, this, stride, offset, frameData, frameLength, sampleStride);
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

void ResonatorBank::updateSeq(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (auto &resonatorPtr : m_resonators) {
        resonatorPtr->update(frameData, frameLength, sampleStride);
    }
}
