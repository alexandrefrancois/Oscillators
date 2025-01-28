/**
MIT License

Copyright (c) 2024 Alexandre R. J. Francois

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

#include "ResonatorBankVecCpp.hpp"

#include <Accelerate/Accelerate.h>

using namespace oscillators_cpp;

constexpr float PI = 3.14159274101257324219; // PI
constexpr float twoPi = 2.0 * PI;

ResonatorBankVec::ResonatorBankVec(size_t numResonators, const float* frequencies, const float* alphas, float sampleRate)
: m_sampleRate(sampleRate), m_numResonators(numResonators), m_twoNumResonators(2*numResonators) {
    
    constexpr float zero = 0.0f;
    constexpr float one = 1.0f;
    constexpr float minusOne = -1.0f;

    // initialize from passed frequencies
    m_frequencies = new float[m_numResonators];
    memcpy(m_frequencies, frequencies, m_numResonators * sizeof(float));
    m_powers = new float[m_numResonators];
    vDSP_vfill(&zero, m_powers, 1, m_numResonators);
    m_amplitudes = new float[m_numResonators];
    vDSP_vfill(&zero, m_amplitudes, 1, m_numResonators);

    // These must be 2 * numResonators size
    m_alphas = new float[m_twoNumResonators];
    memcpy(m_alphas, alphas, m_numResonators * sizeof(float));
    memcpy(m_alphas + m_numResonators, alphas, m_numResonators * sizeof(float));
        
    m_omAlphas = new float[m_twoNumResonators];
    vDSP_vfill(&one, m_omAlphas, 1, m_twoNumResonators);
    vDSP_vsmsa(m_alphas, 1, &minusOne, &one, m_omAlphas, 1, m_twoNumResonators);
    
    // TODO: fixed and hard-coded for now...
//    m_beta = 0.001 * 44100.0 / m_sampleRate;
//    m_omBeta = 1.0 - m_beta;
    
    // setup resonators
    m_rPtr = new float[m_twoNumResonators];
    vDSP_vfill(&zero, m_rPtr, 1, m_twoNumResonators);
    
    m_rrPtr = new float[m_twoNumResonators];
    vDSP_vfill(&zero, m_rrPtr, 1, m_twoNumResonators);
    
    m_zPtr = new float[m_twoNumResonators];
    vDSP_vfill(&one, m_zPtr, 1, m_numResonators);
    vDSP_vfill(&zero, m_zPtr + m_numResonators, 1, m_numResonators);
    
    float twoPiOverSampleRate = twoPi / m_sampleRate;
    m_wPtr = new float[m_twoNumResonators];
    vDSP_vfill(&twoPiOverSampleRate, m_wPtr, 1, m_twoNumResonators);

    DSPSplitComplex W = {m_wPtr, m_wPtr + m_numResonators};
    // multiply 2 * PI / sampleRate by frequency for each resonator
    vDSP_vmul(W.realp, 1,
              m_frequencies, 1,
              W.realp, 1,
              m_numResonators);
    vDSP_vmul(W.imagp, 1,
              m_frequencies, 1,
              W.imagp, 1,
              m_numResonators);
    
    // then calculate cos and sin
    int count = static_cast<int>(m_numResonators);
    vvcosf(W.realp, W.realp, &count);
    vvsinf(W.imagp, W.imagp, &count);
    
    m_alphasSample = new float[m_twoNumResonators];
    m_smPtr = new float[m_numResonators];
    m_rsqrtPtr = new float[m_numResonators];
}

ResonatorBankVec::~ResonatorBankVec() {
    delete [] m_frequencies;
    delete [] m_powers;
    delete [] m_amplitudes;
    delete [] m_alphas;
    delete [] m_rPtr;
    delete [] m_rrPtr;
    delete [] m_zPtr;
    delete [] m_wPtr;
    delete [] m_alphasSample;
    delete [] m_smPtr;
    delete [] m_rsqrtPtr;
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

float ResonatorBankVec::timeConstantValue(size_t index) {
    if (index >= m_numResonators) {
        throw std::out_of_range("Bad index passed to timeConstantValue()");
    }
    // if alpha is 0 then time constant should be infinity...
    return m_alphas[index] > 0.0 ? 1.0 / (m_sampleRate * m_alphas[index]) : 0.0f;
}

void ResonatorBankVec::copyPowers(float *dest, size_t size) {
    memcpy(dest, m_powers, m_numResonators * sizeof(float));
}

float ResonatorBankVec::powerValue(size_t index) {
    if (index >= m_numResonators) {
        throw std::out_of_range("Bad index passed to amplitudeValue()");
    }
    return m_powers[index];
}

void ResonatorBankVec::copyAmplitudes(float *dest, size_t size) {
    memcpy(dest, m_amplitudes, m_numResonators * sizeof(float));
}

float ResonatorBankVec::amplitudeValue(size_t index) {
    if (index >= m_numResonators) {
        throw std::out_of_range("Bad index passed to amplitudeValue()");
    }
    return m_amplitudes[index];
}

void ResonatorBankVec::update(const float sample) {
    vDSP_vsmul(m_alphas, 1, &sample, m_alphasSample, 1, m_twoNumResonators);
        
    // resonator
    vDSP_vmma(m_rPtr, 1,
              m_omAlphas, 1,
              m_zPtr, 1,
              m_alphasSample, 1,
              m_rPtr, 1,
              m_twoNumResonators);
  
    // this is for fixed value of beta
//    vDSP_vsmsma(m_rrPtr, 1,
//                &m_omBeta,
//                m_rPtr, 1,
//                &m_beta,
//                m_rrPtr, 1,
//                m_twoNumResonators);
    
    // Smoothing with alphas
    vDSP_vmma(m_rrPtr, 1,
              m_omAlphas, 1,
              m_rPtr, 1,
              m_alphas, 1,
              m_rrPtr, 1,
              m_twoNumResonators);
 
    // phasor
    DSPSplitComplex Z = {m_zPtr, m_zPtr + m_numResonators};
    DSPSplitComplex W = {m_wPtr, m_wPtr + m_numResonators};
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
    // compute amplitudes
    DSPSplitComplex R = {m_rrPtr, m_rrPtr + m_numResonators};
    vDSP_zvmags(&R, 1, m_powers, 1, m_numResonators);
    int count = static_cast<int>(m_numResonators);
    vvsqrtf(m_amplitudes, m_powers, &count);
}

/// Process a frame of samples.
/// Apply stabilization (norm correction) at the end
/// Compute amplitudes (phasor magnitudes) at the end
void ResonatorBankVec::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (int i=0; i<frameLength; i += sampleStride) {
        update(frameData[i]);
    }
    stabilize(); // this is overkill but necessary
    // compute amplitudes
    DSPSplitComplex R = {m_rrPtr, m_rrPtr + m_numResonators};
    vDSP_zvmags(&R, 1, m_powers, 1, m_numResonators);
    int count = static_cast<int>(m_numResonators);
    vvsqrtf(m_amplitudes, m_powers, &count);
}

/// Process a frame of samples.
/// Apply stabilization (norm correction) at the end
/// Compute amplitudes (phasor magnitudes) at the end
void ResonatorBankVec::update(const float *frameData, size_t frameLength, size_t sampleStride, float* powers, float* amplitudes) {
    for (int i=0; i<frameLength; i += sampleStride) {
        update(frameData[i]);
    }
    stabilize(); // this is overkill but necessary
    // compute amplitudes
    DSPSplitComplex R = {m_rrPtr, m_rrPtr + m_numResonators};
    vDSP_zvmags(&R, 1, powers, 1, m_numResonators);
    int count = static_cast<int>(m_numResonators);
    vvsqrtf(amplitudes, powers, &count);
}

/// Apply norm correction to phasor.
/// This can be done every few hundreds (?) of iterations
void ResonatorBankVec::stabilize() {
    DSPSplitComplex Z = {m_zPtr, m_zPtr + m_numResonators};
    vDSP_zvmags(&Z, 1, m_smPtr, 1, m_numResonators);
    // use reciprocal square root
    int count = static_cast<int>(m_numResonators);
    vvrsqrtf(m_rsqrtPtr, m_smPtr, &count);
    vDSP_zrvmul(&Z, 1, m_rsqrtPtr, 1, &Z, 1, m_numResonators);
}
