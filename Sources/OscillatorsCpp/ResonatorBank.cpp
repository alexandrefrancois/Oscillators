/**
MIT License

Copyright (c) 2022-2024 Alexandre R. J. Francois

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

ResonatorBank::ResonatorBank(size_t numResonators, float* frequencies, float sampleRate, float* alphas) : m_sampleRate(sampleRate) {
    m_resonators.reserve(numResonators);
    for (size_t i=0; i<numResonators; ++i) {
        m_resonators.emplace_back(std::make_unique<Resonator>(frequencies[i], sampleRate, alphas[i]));
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

float ResonatorBank::timeConstantValue(size_t index) {
    if (index >= m_resonators.size()) {
        throw std::out_of_range("Bad index passed to timeConstantValue()");
    }
    return m_resonators[index]->timeConstant();
}

void ResonatorBank::copyPowers(float *dest, size_t size) {
    for (size_t i=0; i<std::min(size, m_resonators.size()); ++i) {
        dest[i]=m_resonators[i]->power();
    }
}

float ResonatorBank::powerValue(size_t index) {
    if (index >= m_resonators.size()) {
        throw std::out_of_range("Bad index passed to amplitudeValue()");
    }
    return m_resonators[index]->power();
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

void ResonatorBank::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (auto &resonatorPtr : m_resonators) {
        resonatorPtr->update(frameData, frameLength, sampleStride);
    }
}

#ifndef STD_CONCURRENCY
// concurrency with Apple GCD

void ResonatorBank::updateConcurrent(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (size_t offset = 0; offset < resonatorStride; ++offset) {
        dispatch_group_async(m_dispatchGroup, m_dispatchQueue, ^{
            size_t index = offset;
            while (index < m_resonators.size()) {
                m_resonators[index]->update(frameData, frameLength, sampleStride);
                index += resonatorStride;
            }
        });
    }
    dispatch_group_wait(m_dispatchGroup, DISPATCH_TIME_FOREVER);
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

