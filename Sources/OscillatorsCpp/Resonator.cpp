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

void Resonator::updateAllPhases(float sample) {
    const float alphaSample = m_alpha * sample;
    const size_t localNumSamplesInPeriod = numSamplesInPeriod();
    vDSP_vsmul(&m_allPhases[0], 1, &m_omAlpha, &m_leftTerm[0], 1, localNumSamplesInPeriod);
    const size_t complement = localNumSamplesInPeriod - m_phaseIdx;
    vDSP_vsmul(&m_waveform[0], 1, &alphaSample, &m_rightTerm[m_phaseIdx], 1, complement);
    vDSP_vsmul(&m_waveform[complement], 1, &alphaSample, &m_rightTerm[0], 1, m_phaseIdx);
    vDSP_vadd(&m_leftTerm[0], 1, &m_rightTerm[0], 1, &m_allPhases[0], 1, localNumSamplesInPeriod);
    
    ++m_phaseIdx %= localNumSamplesInPeriod;
}

void Resonator::update(const float sample) {
    updateAllPhases(sample);
}

void Resonator::update(const std::vector<float> &samples) {
    for (float sample : samples) {
        updateAllPhases(sample);
    }
}

void Resonator::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (int i=0; i<frameLength; i += sampleStride) {
        updateAllPhases(frameData[i]);
    }
}

void Resonator::copyAllPhases(float *dest, size_t size) {
    memcpy(dest, &m_allPhases[0], std::min(size, m_allPhases.size()) * sizeof(float));
}

float Resonator::allPhasesValue(size_t index) {
    if (index >= 0 && index < m_allPhases.size()) {
        return m_allPhases[index];
    }
}
