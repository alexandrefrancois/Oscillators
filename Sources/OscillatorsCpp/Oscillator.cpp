#include "Oscillator.hpp"

#include <cmath>
#include <iostream>

#include <Accelerate/Accelerate.h>

using namespace oscillators_cpp;

Oscillator::Oscillator(float targetFrequency, float sampleDuration) : m_sampleDuration(sampleDuration), m_amplitude(0.0), m_phaseIdx(0) {
    int numSamplesInPeriod = static_cast<int>(std::round((1.0 / (sampleDuration * targetFrequency))));
    m_frequency = 1.0 / (numSamplesInPeriod * sampleDuration);
    m_waveform = std::vector<float>(numSamplesInPeriod, 0);

    std::cout << "New OscillatorCpp: target frequency: " << targetFrequency
    << ", num samples in period: " << numSamplesInPeriod
    << " -> " << m_frequency << std::endl;
}

void Oscillator::setSineWave() {
    const float delta = twoPi * m_frequency * m_sampleDuration;
    const float initialValue = 0.0;
    const int size = m_waveform.size();
    vDSP_vramp(&initialValue, &delta, &m_waveform[0], 1, size);
    vvsinf(&m_waveform[0], &m_waveform[0], &size);
}

void Oscillator::copyWaveform(float *dest, size_t size) {
    memcpy(dest, &m_waveform[0], std::min(size, m_waveform.size()) * sizeof(float));
}

float Oscillator::waveformValue(size_t index) {
    if (index >= 0 && index < m_waveform.size()) {
        return m_waveform[index];
    }
}
