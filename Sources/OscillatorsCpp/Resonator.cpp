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

#include "Resonator.hpp"

#include <Accelerate/Accelerate.h>

using namespace oscillators_cpp;

Resonator::Resonator(float targetFrequency, float sampleDuration, float alpha) : Oscillator(targetFrequency, sampleDuration), m_alpha(alpha), m_omAlpha(1.0 - alpha) {

    // initialize waveform
    setSineWave();
    
    m_allPhases = std::vector<float>(numSamplesInPeriod(), 0);
    m_leftTerm = std::vector<float>(numSamplesInPeriod(), 0);
    m_rightTerm = std::vector<float>(numSamplesInPeriod(), 0);
}

void Resonator::setAlpha(float alpha) {
    if (alpha < 0.0 || alpha >1.0) {
        throw std::out_of_range("Bad alpha passed to setAlpha()");
    }
    m_alpha = alpha;
    m_omAlpha = 1.0 - m_alpha;
}

void Resonator::copyAllPhases(float *dest, size_t size) {
    memcpy(dest, &m_allPhases[0], std::min(size, m_allPhases.size()) * sizeof(float));
}

float Resonator::allPhasesValue(size_t index) const {
    if (index >= m_allPhases.size()) {
        throw std::out_of_range("Bad index passed to allPhasesValue()");
    }
    return m_allPhases[index];
}

void Resonator::updateAllPhases(float sample) {
    const float alphaSample = m_alpha * sample;
    const size_t localNumSamplesInPeriod = numSamplesInPeriod();
    vDSP_vsmul(&m_allPhases[0], 1, &m_omAlpha, &m_leftTerm[0], 1, localNumSamplesInPeriod);
    const size_t complement = localNumSamplesInPeriod - m_phaseIdx;
    vDSP_vsmul(&m_waveform[m_phaseIdx], 1, &alphaSample, &m_rightTerm[0], 1, complement);
    vDSP_vsmul(&m_waveform[0], 1, &alphaSample, &m_rightTerm[complement], 1, m_phaseIdx);
    vDSP_vadd(&m_leftTerm[0], 1, &m_rightTerm[0], 1, &m_allPhases[0], 1, localNumSamplesInPeriod);
    ++m_phaseIdx %= localNumSamplesInPeriod;
}

void Resonator::update(const float sample) {
    updateAllPhases(sample);
    vDSP_maxv(&m_allPhases[0], 1, &m_amplitude, numSamplesInPeriod());
}

void Resonator::update(const std::vector<float> &samples) {
    for (float sample : samples) {
        updateAllPhases(sample);
    }
    vDSP_maxv(&m_allPhases[0], 1, &m_amplitude, numSamplesInPeriod());
}

void Resonator::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (int i=0; i<frameLength; i += sampleStride) {
        updateAllPhases(frameData[i]);
    }
    vDSP_maxv(&m_allPhases[0], 1, &m_amplitude, numSamplesInPeriod());
}

void Resonator::updateAndTrack(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (int i=0; i<frameLength; i += sampleStride) {
        updateAllPhases(frameData[i]);
    }
    vDSP_Length idx = 0;
    vDSP_maxvi(&m_allPhases[0], 1, &m_amplitude, &idx, m_allPhases.size());
    if (m_amplitude > trackFrequencyThreshold) {
        updateTrackedFrequency(idx, frameLength);
    } else {
        m_trackedFrequency = m_frequency;
    }
}

void Resonator::updateTrackedFrequency(size_t newMaxIdx, size_t numSamples) {
    const int size = static_cast<int>(m_allPhases.size());
    int numSamplesDrift = (static_cast<int>(newMaxIdx) - static_cast<int>(m_maxIdx));
    if (numSamplesDrift < -size/2) {
        numSamplesDrift += size-1;
    } else if (numSamplesDrift > size/2) {
        numSamplesDrift -= size-1;
    }
    const float alpha = m_alpha * numSamples;
    const float omAlpha = 1.0 - alpha;
    m_trackedFrequency = (omAlpha * m_trackedFrequency) + (alpha / (m_sampleDuration * static_cast<float>(size) * (1.0f - static_cast<float>(numSamplesDrift) / static_cast<float>(numSamples))));
    m_maxIdx = newMaxIdx;
}
