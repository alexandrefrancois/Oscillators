#include "Oscillator.hpp"
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

#include <cmath>
#include <iostream>

#include <Accelerate/Accelerate.h>

using namespace oscillators_cpp;

Oscillator::Oscillator(float targetFrequency, float sampleDuration) : m_sampleDuration(sampleDuration), m_amplitude(0.0), m_phaseIdx(0) {
    int numSamplesInPeriod = static_cast<int>(std::round((1.0 / (sampleDuration * targetFrequency))));
    m_frequency = 1.0 / (numSamplesInPeriod * sampleDuration);
    m_waveform = std::vector<float>(numSamplesInPeriod, 0);
}

void Oscillator::setSineWave() {
    const float delta = twoPi * m_frequency * m_sampleDuration;
    const float initialValue = 0.0;
    const int size = static_cast<int>(m_waveform.size());
    vDSP_vramp(&initialValue, &delta, &m_waveform[0], 1, size);
    vvsinf(&m_waveform[0], &m_waveform[0], &size);
}

void Oscillator::copyWaveform(float *dest, size_t size) {
    memcpy(dest, &m_waveform[0], std::min(size, m_waveform.size()) * sizeof(float));
}

float Oscillator::waveformValue(size_t index) const {
    if (index >= m_waveform.size()) {
        throw std::out_of_range("Bad index passed to waveformValue()");
    }
    return m_waveform[index];
}
