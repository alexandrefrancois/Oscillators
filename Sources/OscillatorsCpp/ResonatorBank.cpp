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
#include <dispatch/dispatch.h>

using namespace oscillators_cpp;

ResonatorBank::ResonatorBank(size_t numResonators, float* targetFrequencies, float sampleDuration, float alpha) : m_sampleDuration(sampleDuration), m_alpha(alpha) {
    m_resonators.reserve(numResonators);
    for (size_t i=0; i<numResonators; ++i) {
        m_resonators.emplace_back(std::make_unique<Resonator>(targetFrequencies[i], sampleDuration, alpha));
    }
    m_dispatchGroup = dispatch_group_create();
    dispatch_retain(m_dispatchGroup);
    m_dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
}

ResonatorBank::~ResonatorBank() {
    dispatch_group_wait(m_dispatchGroup, dispatch_time(DISPATCH_TIME_NOW, 1000000000));
    dispatch_release(m_dispatchGroup);
}

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

// concurrency with Apple GCD
void ResonatorBank::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    // even out the task length by pairing resonators from both ends of the spectrum
    // taking into account that the complexity of the update is proportional to the size of the phases array
    size_t count = m_resonators.size();
    for (size_t index = 0; index <= count / 2; ++index) {
        size_t index2 = count - 1 - index;
        dispatch_group_async(m_dispatchGroup, m_dispatchQueue, ^{
            m_resonators[index]->update(frameData, frameLength, sampleStride);
            m_resonators[index2]->update(frameData, frameLength, sampleStride);
        });
    }
    if ((count & 1) == 1) {
        dispatch_group_async(m_dispatchGroup, m_dispatchQueue, ^{
            m_resonators[count/2]->update(frameData, frameLength, sampleStride);
        });
    }
    dispatch_group_wait(m_dispatchGroup, DISPATCH_TIME_FOREVER);
}

void ResonatorBank::updateSeq(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (auto &resonatorPtr : m_resonators) {
        resonatorPtr->update(frameData, frameLength, sampleStride);
    }
}
