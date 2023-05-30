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

Resonator::Resonator(float targetFrequency, float sampleDuration, float alpha) : Oscillator(targetFrequency, sampleDuration),
    m_alpha(alpha), m_omAlpha(1.0 - alpha), m_trackedFrequency(m_frequency), m_phase(0.0){
    m_waveform2 = std::vector<float>(m_waveform.size(), 0);
    // initialize waveforms
    setSineWave();
    setCosineWave();
}

void Resonator::setCosineWave() {
    const float delta = twoPi * m_frequency * m_sampleDuration;
    const float initialValue = 0.0;
    const int size = static_cast<int>(m_waveform2.size());
    vDSP_vramp(&initialValue, &delta, &m_waveform2[0], 1, size);
    vvcosf(&m_waveform2[0], &m_waveform2[0], &size);
}

float Resonator::waveform2Value(size_t index) const {
    if (index >= m_waveform2.size()) {
        throw std::out_of_range("Bad index passed to waveform2Value()");
    }
    return m_waveform2[index];
}

void Resonator::setAlpha(float alpha) {
    if (alpha < 0.0 || alpha >1.0) {
        throw std::out_of_range("Bad alpha passed to setAlpha()");
    }
    m_alpha = alpha;
    m_omAlpha = 1.0 - m_alpha;
}

void Resonator::updateWithSample(float sample) {
    const float alphaSample = m_alpha * sample;
    m_sin = m_omAlpha * m_sin + alphaSample * m_waveform[m_phaseIdx];
    m_cos = m_omAlpha * m_cos + alphaSample * m_waveform2[m_phaseIdx];

    ++m_phaseIdx %= numSamplesInPeriod();
}

void Resonator::update(const float sample) {
    updateWithSample(sample);
    m_amplitude = sqrt(m_sin * m_sin + m_cos * m_cos);
}

void Resonator::update(const std::vector<float> &samples) {
    for (float sample : samples) {
        updateWithSample(sample);
    }
    m_amplitude = sqrt(m_sin * m_sin + m_cos * m_cos);
}

void Resonator::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (int i=0; i<frameLength; i += sampleStride) {
        updateWithSample(frameData[i]);
    }
    m_amplitude = sqrt(m_sin * m_sin + m_cos * m_cos);
}

void Resonator::updateAndTrack(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (int i=0; i<frameLength; i += sampleStride) {
        updateWithSample(frameData[i]);
    }
    m_amplitude = sqrt(m_sin * m_sin + m_cos * m_cos);
    if (m_amplitude > trackFrequencyThreshold) {
        updateTrackedFrequency(frameLength);
    } else {
        m_trackedFrequency = m_frequency;
    }
}

void Resonator::updateTrackedFrequency(size_t numSamples) {
    //    const int size = static_cast<int>(m_allPhases.size());
    //    int numSamplesDrift = (static_cast<int>(newMaxIdx) - static_cast<int>(m_maxIdx));
    //    if (numSamplesDrift < -size/2) {
    //        numSamplesDrift += size-1;
    //    } else if (numSamplesDrift > size/2) {
    //        numSamplesDrift -= size-1;
    //    }
    //    const float alpha = m_alpha * numSamples;
    //    const float omAlpha = 1.0 - alpha;
    //    m_trackedFrequency = (omAlpha * m_trackedFrequency) + (alpha / (m_sampleDuration * static_cast<float>(size) * (1.0f - static_cast<float>(numSamplesDrift) / static_cast<float>(numSamples))));
    //    m_maxIdx = newMaxIdx;
    
    const float newPhase = atan2(m_sin, m_cos); // returns value in [-pi,pi]
    float phaseDrift = newPhase - m_phase;
    m_phase = newPhase;
    if (phaseDrift <= -PI) {
        phaseDrift += twoPi;
    } else if (phaseDrift > PI) {
        phaseDrift -= twoPi;
    }
    m_trackedFrequency = m_frequency - phaseDrift / (twoPi * static_cast<float>(numSamples) * m_sampleDuration);
}
