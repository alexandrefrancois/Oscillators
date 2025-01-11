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

#include "Resonator.hpp"

#include <Accelerate/Accelerate.h>

using namespace oscillators_cpp;

Resonator::Resonator(float frequency, float sampleRate, float alpha) : Oscillator(frequency, sampleRate),
m_alpha(alpha), m_omAlpha(1.0 - alpha), m_trackedFrequency(m_frequency), m_phase(0.0){
    // TODO: fixed and hard-coded for now
    m_beta = alpha; // 0.001 * 44100.0 / sampleRate;
    m_omBeta = 1.0 - m_beta;
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
    m_cos = m_omAlpha * m_cos + alphaSample * m_Zc;
    m_sin = m_omAlpha * m_sin + alphaSample * m_Zs;
    m_cc = m_omBeta * m_cc + m_beta * m_cos;
    m_ss = m_omBeta * m_ss + m_beta * m_sin;
    incrementPhase();
}

void Resonator::update(const float sample) {
    updateWithSample(sample);
    m_power = m_cc * m_cc + m_ss * m_ss;
    m_amplitude = sqrt(m_power);
}

void Resonator::update(const std::vector<float> &samples) {
    for (float sample : samples) {
        updateWithSample(sample);
    }
    m_power = m_cc * m_cc + m_ss * m_ss;
    m_amplitude = sqrt(m_power);
}

void Resonator::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (int i=0; i<frameLength; i += sampleStride) {
        updateWithSample(frameData[i]);
    }
    m_power = m_cc * m_cc + m_ss * m_ss;
    m_amplitude = sqrt(m_power);
}

void Resonator::updateAndTrack(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (int i=0; i<frameLength; i += sampleStride) {
        updateWithSample(frameData[i]);
    }
    m_amplitude = sqrt(m_cc * m_cc + m_ss * m_ss);
    if (m_amplitude > trackFrequencyThreshold) {
        updateTrackedFrequency(frameLength);
    } else {
        m_trackedFrequency = m_frequency;
    }
}

void Resonator::updateTrackedFrequency(size_t numSamples) {
    const float newPhase = atan2(m_ss, m_cc); // returns value in [-pi,pi]
    float phaseDrift = newPhase - m_phase;
    m_phase = newPhase;
    if (phaseDrift <= -PI) {
        phaseDrift += twoPi;
    } else if (phaseDrift > PI) {
        phaseDrift -= twoPi;
    }
    m_trackedFrequency = m_frequency - (phaseDrift * m_sampleRate) / (twoPi * static_cast<float>(numSamples));
}
