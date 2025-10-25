/**
MIT License

Copyright (c) 2024-2025 Alexandre R. J. Francois

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

#include "ResonatorBankVec.hpp"

#include <Accelerate/Accelerate.h>

using namespace oscillators_cpp;

constexpr float PI = 3.14159265358979323846; // PI
constexpr float twoPi = 2.0 * PI;

ResonatorBankVec::ResonatorBankVec(size_t numResonators, const std::vector<float> &frequencies, const std::vector<float> &alphas, const std::vector<float> &betas, float sampleRate)
: ResonatorBankVec(numResonators, frequencies.data(), alphas.data(), betas.data(), sampleRate) {
}

ResonatorBankVec::ResonatorBankVec(size_t numResonators, const float* frequencies, const float* alphas, const float* betas, float sampleRate)
: m_sampleRate(sampleRate), m_numResonators(numResonators), m_twoNumResonators(2*numResonators) {
    
    constexpr float zero = 0.0f;
    constexpr float one = 1.0f;
    constexpr float minusOne = -1.0f;

    // initialize from passed frequencies
    m_frequencies.resize(m_numResonators);
    memcpy(m_frequencies.data(), frequencies, m_numResonators * sizeof(float));

    // These must be 2 * numResonators size
    m_alphas.resize(m_twoNumResonators);
    memcpy(m_alphas.data(), alphas, m_numResonators * sizeof(float));
    memcpy(m_alphas.data() + m_numResonators, alphas, m_numResonators * sizeof(float));
        
    m_omAlphas.resize(m_twoNumResonators);
    vDSP_vfill(&one, m_omAlphas.data(), 1, m_twoNumResonators);
    vDSP_vsmsa(m_alphas.data(), 1, &minusOne, &one, m_omAlphas.data(), 1, m_twoNumResonators);
    
    m_betas.resize(m_twoNumResonators);
    memcpy(m_betas.data(), betas, m_numResonators * sizeof(float));
    memcpy(m_betas.data() + m_numResonators, betas, m_numResonators * sizeof(float));
        
    m_omBetas.resize(m_twoNumResonators);
    vDSP_vfill(&one, m_omBetas.data(), 1, m_twoNumResonators);
    vDSP_vsmsa(m_betas.data(), 1, &minusOne, &one, m_omBetas.data(), 1, m_twoNumResonators);

    // setup resonators
    m_r.resize(m_twoNumResonators);
    vDSP_vfill(&zero, m_r.data(), 1, m_twoNumResonators);
    
    m_rr.resize(m_twoNumResonators);
    vDSP_vfill(&zero, m_rr.data(), 1, m_twoNumResonators);
    
    m_z.resize(m_twoNumResonators);
    vDSP_vfill(&one, m_z.data(), 1, m_numResonators);
    vDSP_vfill(&zero, m_z.data()+ m_numResonators, 1, m_numResonators);
    
    float twoPiOverSampleRate = twoPi / m_sampleRate;
    m_w.resize(m_twoNumResonators);
    vDSP_vfill(&twoPiOverSampleRate, m_w.data(), 1, m_twoNumResonators);

    DSPSplitComplex W = {m_w.data(), m_w.data() + m_numResonators};
    // multiply 2 * PI / sampleRate by frequency for each resonator
    vDSP_vmul(W.realp, 1,
              m_frequencies.data(), 1,
              W.realp, 1,
              m_numResonators);
    vDSP_vmul(W.imagp, 1,
              m_frequencies.data(), 1,
              W.imagp, 1,
              m_numResonators);
    
    // then calculate cos and sin
    int count = static_cast<int>(m_numResonators);
    vvcosf(W.realp, W.realp, &count);
    vvsinf(W.imagp, W.imagp, &count);
    
    m_alphasSample.resize(m_twoNumResonators);
    m_sm.resize(m_numResonators);
    m_rsqrt.resize(m_numResonators);
}

float ResonatorBankVec::frequencyValue(size_t index) {
    if (index >= m_numResonators) {
        throw std::out_of_range("Bad index passed to frequencyValue()");
    }
    return m_frequencies[index];
}

float ResonatorBankVec::alphaValue(size_t index) {
    if (index >= m_numResonators) {
        throw std::out_of_range("Bad index passed to alphaValue()");
    }
    return m_alphas[index];
}

float ResonatorBankVec::betaValue(size_t index) {
    if (index >= m_numResonators) {
        throw std::out_of_range("Bad index passed to alphaValue()");
    }
    return m_alphas[index];
}

void ResonatorBankVec::getPowers(float *dest, size_t size) {
    if (size < m_numResonators)
    {
        throw std::out_of_range("Buffer passed to getPowers() is not large enough");
    }
    DSPSplitComplex R = {m_rr.data(), m_rr.data() + m_numResonators};
    vDSP_zvmags(&R, 1, dest, 1, m_numResonators);
}

void ResonatorBankVec::getAmplitudes(float *dest, size_t size) {
    if (size < m_numResonators)
    {
        throw std::out_of_range("Buffer passed to getAmplitudes() is not large enough");
    }
    DSPSplitComplex R = {m_rr.data(), m_rr.data() + m_numResonators};
    vDSP_zvmags(&R, 1, dest, 1, m_numResonators);
    int count = static_cast<int>(m_numResonators);
    vvsqrtf(dest, dest, &count);
}

void ResonatorBankVec::update(const float sample) {
    vDSP_vsmul(m_alphas.data(), 1, &sample, m_alphasSample.data(), 1, m_twoNumResonators);
        
    // resonator
    vDSP_vmma(m_r.data(), 1,
              m_omAlphas.data(), 1,
              m_z.data(), 1,
              m_alphasSample.data(), 1,
              m_r.data(), 1,
              m_twoNumResonators);

    // Smoothing with betas
    vDSP_vmma(m_rr.data(), 1,
              m_omBetas.data(), 1,
              m_r.data(), 1,
              m_betas.data(), 1,
              m_rr.data(), 1,
              m_twoNumResonators);
 
    // phasor
    DSPSplitComplex Z = {m_z.data(), m_z.data() + m_numResonators};
    DSPSplitComplex W = {m_w.data(), m_w.data() + m_numResonators};
    vDSP_zvmul(&Z, 1,
               &W, 1,
               &Z, 1,
               m_numResonators,
               1);
}

void ResonatorBankVec::update(const std::vector<float> &samples) {
    for (float sample : samples) {
        update(sample);
    }
    stabilize(); // this is overkill but necessary
}

/// Process a frame of samples.
/// Apply stabilization (norm correction) at the end
/// Compute amplitudes (phasor magnitudes) at the end
void ResonatorBankVec::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (int i=0; i<frameLength; i += sampleStride) {
        update(frameData[i]);
    }
    stabilize(); // this is overkill but necessary
}

/// Process a frame of samples.
/// Apply stabilization (norm correction) at the end
/// Compute amplitudes (phasor magnitudes) at the end
void ResonatorBankVec::update(const float *frameData, size_t frameLength, size_t sampleStride, float* powers, float* amplitudes) {
    for (int i=0; i<frameLength; i += sampleStride) {
        update(frameData[i]);
    }
    stabilize(); // this is overkill but necessary
}

/// Apply norm correction to phasor.
/// This can be done every few hundreds (?) of iterations
void ResonatorBankVec::stabilize() {
    DSPSplitComplex Z = {m_z.data(), m_z.data() + m_numResonators};
    vDSP_zvmags(&Z, 1, m_sm.data(), 1, m_numResonators);
    // use reciprocal square root
    int count = static_cast<int>(m_numResonators);
    vvrsqrtf(m_rsqrt.data(), m_sm.data(), &count);
    vDSP_zrvmul(&Z, 1, m_rsqrt.data(), 1, &Z, 1, m_numResonators);
}
