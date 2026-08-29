/**
MIT License

Copyright (c) 2026 Alexandre R. J. Francois

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

#include "TrackingResonatorBankVec.hpp"
#include "FrameStride.hpp"

#include <arm_neon.h>

using namespace oscillators_cpp;

constexpr float PI = 3.14159265358979323846f; // PI
constexpr float twoPi = 2.0f * PI;
constexpr float zero = 0.0f;
constexpr float one = 1.0f;
constexpr float minusOne = -1.0f;

constexpr float minPowerThreshold = 1e-12;

TrackingResonatorBankVec::TrackingResonatorBankVec(size_t numResonators, const std::vector<float> &frequencies, float sampleRate, const std::vector<float> &alphas, const std::vector<float> &betas, const std::vector<float> &gammas, TrackingRule trackingRule, float thresholdDB)
: TrackingResonatorBankVec(numResonators, frequencies.data(), sampleRate, alphas.data(), betas.data(), gammas.data(), trackingRule, thresholdDB) {
}

TrackingResonatorBankVec::TrackingResonatorBankVec(size_t numResonators, const float* frequencies, float sampleRate, const float* alphas, const float* betas, const float* gammas, TrackingRule trackingRule, float thresholdDB)
: m_trackingRule(trackingRule), m_sampleRate(sampleRate), m_numResonators(numResonators), m_twoNumResonators(2*numResonators) {
    
    // initialize from passed frequencies
    m_naturalFrequencies.resize(m_numResonators);
    memcpy(m_naturalFrequencies.data(), frequencies, m_numResonators * sizeof(float));
    
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

    m_gammas.resize(m_twoNumResonators);
    memcpy(m_gammas.data(), gammas, m_numResonators * sizeof(float));
    memcpy(m_gammas.data() + m_numResonators, gammas, m_numResonators * sizeof(float));
        
    m_omGammas.resize(m_twoNumResonators);
    vDSP_vfill(&one, m_omGammas.data(), 1, m_twoNumResonators);
    vDSP_vsmsa(m_gammas.data(), 1, &minusOne, &one, m_omGammas.data(), 1, m_twoNumResonators);

    setPowerThresholdDB(thresholdDB);
    
    // setup resonators
    m_r.resize(m_twoNumResonators);
    vDSP_vfill(&zero, m_r.data(), 1, m_twoNumResonators);
    
    m_rr.resize(m_twoNumResonators);
    vDSP_vfill(&zero, m_rr.data(), 1, m_twoNumResonators);
    
    m_rrm.resize(m_twoNumResonators);
    m_d.resize(m_twoNumResonators);

    m_z.resize(m_twoNumResonators);
    vDSP_vfill(&one, m_z.data(), 1, m_numResonators);
    vDSP_vfill(&zero, m_z.data()+ m_numResonators, 1, m_numResonators);
    
    float minusTwoPiOverSampleRate = -twoPi / m_sampleRate;
    m_nw.resize(m_twoNumResonators);
    vDSP_vfill(&minusTwoPiOverSampleRate, m_nw.data(), 1, m_twoNumResonators);
    DSPSplitComplex nW = {m_nw.data(), m_nw.data() + m_numResonators};

    // calculate natural omegas
    // multiply 2 * PI / sampleRate by frequency for each resonator
    vDSP_vmul(nW.realp, 1,
              m_naturalFrequencies.data(), 1,
              nW.realp, 1,
              m_numResonators);
    vDSP_vmul(nW.imagp, 1,
              m_naturalFrequencies.data(), 1,
              nW.imagp, 1,
              m_numResonators);
    
    // initialize natural omegas
    // needed for ewma omegas tracking rule
    m_naturalOmegas.resize(m_numResonators);
    memcpy(m_naturalOmegas.data(), nW.realp, m_numResonators * sizeof(float));
    
    // then calculate cos and sin
    int count = static_cast<int>(m_numResonators);
    vvcosf(nW.realp, nW.realp, &count);
    vvsinf(nW.imagp, nW.imagp, &count);

    // Initialize W with nW
    m_w.resize(m_twoNumResonators);
    DSPSplitComplex W = {m_w.data(), m_w.data() + m_numResonators};
    memcpy(m_w.data(), m_nw.data(), m_twoNumResonators * sizeof(float));

    m_powers.resize(m_numResonators);
    m_mask.resize(m_numResonators);
    m_inverseMask.resize(m_numResonators);

    m_alphasSample.resize(m_twoNumResonators);
    m_sm.resize(m_numResonators);
    m_rsqrt.resize(m_numResonators);
    
    m_accPower.store(0.0001, std::memory_order_relaxed);
}

void TrackingResonatorBankVec::getAlphas(float *dest, size_t size){
    if (size < m_numResonators)
    {
        throw std::out_of_range("Buffer passed to getAlphas() is not large enough");
    }
    memcpy(dest, m_alphas.data(), m_numResonators * sizeof(float));
}

void TrackingResonatorBankVec::getNaturalFrequencies(float *dest, size_t size){
    if (size < m_numResonators)
    {
        throw std::out_of_range("Buffer passed to getNaturalFrequencies() is not large enough");
    }
    memcpy(dest, m_naturalFrequencies.data(), m_numResonators * sizeof(float));
}

void TrackingResonatorBankVec::getOmegas(float *dest, size_t size){
    if (size < m_numResonators)
    {
        throw std::out_of_range("Buffer passed to getOmegas() is not large enough");
    }
    DSPSplitComplex W = {m_w.data(), m_w.data() + m_numResonators};
    vDSP_zvphas(&W, 1, dest, 1, m_numResonators);
}

void TrackingResonatorBankVec::getResonantFrequencies(float *dest, size_t size) {
    if (size < m_numResonators)
    {
        throw std::out_of_range("Buffer passed to getResonantFrequencies() is not large enough");
    }
    DSPSplitComplex W = {m_w.data(), m_w.data() + m_numResonators};
    vDSP_zvphas(&W, 1, dest, 1, m_numResonators);
    const float minusSampleRateOverTwoPi = -m_sampleRate / twoPi;
    vDSP_vsmul (dest, 1,
                &minusSampleRateOverTwoPi,
                dest, 1,
                m_numResonators);
}

void TrackingResonatorBankVec::getPowers(float *dest, size_t size) {
    if (size < m_numResonators)
    {
        throw std::out_of_range("Buffer passed to getPowers() is not large enough");
    }
    //    DSPSplitComplex R = {m_rr.data(), m_rr.data() + m_numResonators};
    //    vDSP_zvmags(&R, 1, dest, 1, m_numResonators);
    memcpy(dest, m_powers.data(), m_numResonators * sizeof(float));
}

void TrackingResonatorBankVec::getAmplitudes(float *dest, size_t size) {
    if (size < m_numResonators)
    {
        throw std::out_of_range("Buffer passed to getAmplitudes() is not large enough");
    }
//    DSPSplitComplex R = {m_rr.data(), m_rr.data() + m_numResonators};
//    vDSP_zvmags(&R, 1, dest, 1, m_numResonators);
    int count = static_cast<int>(m_numResonators);
    vvsqrtf(dest, m_powers.data(), &count);
}

void TrackingResonatorBankVec::getPhases(float *dest, size_t size) {
    if (size < m_numResonators)
    {
        throw std::out_of_range("Buffer passed to getPhases() is not large enough");
    }
    DSPSplitComplex R = {m_rr.data(), m_rr.data() + m_numResonators};
    vDSP_zvphas(&R, 1, dest, 1, m_numResonators);
}

void TrackingResonatorBankVec::getDeltaPhases(float *dest, size_t size) {
    if (size < m_numResonators)
    {
        throw std::out_of_range("Buffer passed to getDeltaPhases() is not large enough");
    }
    DSPSplitComplex D = {m_d.data(), m_d.data() + m_numResonators};
    vDSP_zvphas(&D, 1, dest, 1, m_numResonators);
}

void TrackingResonatorBankVec::update(const float sample) {
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
 
    
    // Compute squared magnitudes
    DSPSplitComplex R = {m_rr.data(), m_rr.data() + m_numResonators};
    vDSP_zvmags(&R, 1,
                m_powers.data(), 1,
                m_numResonators);
    
    // Update accPower
    float maxPower = 0.25f;
    vDSP_maxv(m_powers.data(), 1,
              &maxPower,
              m_numResonators);
    m_accPower = (m_omSigma * m_accPower) + (m_sigma * maxPower);

    // Update phase derivatives
    // actually compute the opposite so that we can justs add later
    DSPSplitComplex Rm = {m_rrm.data(), m_rrm.data() + m_numResonators};
    DSPSplitComplex D = {m_d.data(), m_d.data() + m_numResonators};
    vDSP_zvmul(&R, 1,
               &Rm, 1,
               &D, 1,
               m_numResonators,
               -1);
    
    // Save previous smoothed value
    memcpy(m_rrm.data(), m_rr.data(), m_twoNumResonators * sizeof(float));
    
    const float trackFrequencyPowerThreshold = m_accPower * m_trackingPowerThresholdRatio;
//    const float trackFrequencyPowerThreshold = fmax(minPowerThreshold, m_accPower * m_trackingPowerThresholdRatio);

    DSPSplitComplex nW = {m_nw.data(), m_nw.data() + m_numResonators};
    DSPSplitComplex W = {m_w.data(), m_w.data() + m_numResonators};
    int count = static_cast<int>(m_numResonators);

    switch (m_trackingRule) {
            
        case TrackingRule::ewma: {
            // Compute angle from D
            // store in second half of m_d
            vDSP_zvphas(&D, 1,
                        m_d.data() + m_numResonators, 1,
                        m_numResonators);
            
            // Compute dw angle from W
            // store in first half of m_d
            vDSP_zvphas(&W, 1,
                        m_d.data(), 1,
                        m_numResonators);
            
            // Add dw
            // store in first half of m_d
            vDSP_vma(m_d.data() + m_numResonators, 1,
                     m_gammas.data(), 1,
                     m_d.data(), 1,
                     m_d.data(), 1,
                     m_numResonators);
            
            
            // Single pass threshold and merge
            // output is tracked or natural omegas in first half of m_d
            thresholdAndMerge(m_powers.data(),
                              m_d.data(),
                              m_naturalOmegas.data(),
                              m_numResonators,
                              trackFrequencyPowerThreshold);
            
            // Update W
            vvcosf(W.realp, m_d.data(), &count);
            vvsinf(W.imagp, m_d.data(), &count);
        }
            break;
            
        case TrackingRule::normalizedChord: {
//            let residualMagnitudeSquared = dpc * dpc + dps * dps
//            guard residualMagnitudeSquared > minimumResidualMagnitudeSquared,
//                  residualMagnitudeSquared.isFinite
//            else { return }
//            let inverseResidualMagnitude = 1.0 / sqrt(residualMagnitudeSquared)
//            rotateW(c: omGamma + gamma * dpc * inverseResidualMagnitude,
//                    s: -gamma * dps * inverseResidualMagnitude)

            // inverse magnitude of D
            vDSP_zvmags(&D, 1, m_sm.data(), 1, m_numResonators);
            // use reciprocal square root
            vvrsqrtf(m_rsqrt.data(), m_sm.data(), &count);
            // normalize
            vDSP_zrvmul(&D, 1, m_rsqrt.data(), 1, &D, 1, m_numResonators);

            // calculate error
            // multiply both real part and imaginary part by gammas
            vDSP_vmul(m_d.data(), 1,
                      m_gammas.data(), 1,
                      m_d.data(), 1,
                      vDSP_Length(m_twoNumResonators));

            // real part: omGamma + gamma * dpc * inverseResidualMagnitude
            // add 1-gamma to real part
            vDSP_vadd(m_d.data(), 1,
                      m_omGammas.data(), 1,
                      m_d.data(), 1,
                      vDSP_Length(m_numResonators));
            // imaginary part: -gamma * dps * inverseResidualMagnitude
            // all done - D is already conjugate
                                    
            // Calculate corrected Ws, store in D
            vDSP_zvmul(&D, 1,
                       &W, 1,
                       &D, 1,
                       vDSP_Length(m_numResonators),
                       1);

            // Single pass threshold and merge
            // input powers and D
            // output W
            thresholdAndMerge(m_powers.data(),
                              &D,
                              &nW,
                              &W,
                              m_numResonators,
                              trackFrequencyPowerThreshold
                              );
                        
            // Is this really necessary?
//            // normalize W
//            // inverse magnitude of D
//            vDSP_zvmags(&W, 1, m_sm.data(), 1, m_numResonators);
//            // use reciprocal square root
//            vvrsqrtf(m_rsqrt.data(), m_sm.data(), &count);
//            // normalize
//            vDSP_zrvmul(&W, 1, m_rsqrt.data(), 1, &W, 1, m_numResonators);
        }
            break;
            
        case TrackingRule::tangent: {
            
//            let residualMagnitudeSquared = dpc * dpc + dps * dps
//            guard residualMagnitudeSquared > minimumResidualMagnitudeSquared,
//                  residualMagnitudeSquared.isFinite
//            else { return }
//            let inverseResidualMagnitude = 1.0 / sqrt(residualMagnitudeSquared)
//            rotateW(c: 1.0,
//                    s: -gamma * dps * inverseResidualMagnitude)

            // inverse magnitude of D
            vDSP_zvmags(&D, 1, m_sm.data(), 1, m_numResonators);
            // use reciprocal square root
            vvrsqrtf(m_rsqrt.data(), m_sm.data(), &count);
            // normalize
            vDSP_zrvmul(&D, 1, m_rsqrt.data(), 1, &D, 1, m_numResonators);

            // set real part to 1.0
            vDSP_vfill(&one, m_d.data(), 1, m_numResonators);
            // imaginary part: -gamma * dps * inverseResidualMagnitude
            // multiply by gamma, D is already conjugate
            vDSP_vmul(m_d.data() + m_numResonators, 1,
                      m_gammas.data(), 1,
                      m_d.data() + m_numResonators, 1,
                      vDSP_Length(m_numResonators));
            
            // Calculate corrected Ws, store in D
            vDSP_zvmul(&D, 1,
                       &W, 1,
                       &D, 1,
                       vDSP_Length(m_numResonators),
                       1);

            // Single pass threshold and merge
            // input powers and D
            // output W
            thresholdAndMerge(m_powers.data(),
                              &D,
                              &nW,
                              &W,
                              m_numResonators,
                              trackFrequencyPowerThreshold
                              );
                        
            // Is this really necessary?
//            // normalize W
//            // inverse magnitude of D
//            vDSP_zvmags(&W, 1, m_sm.data(), 1, m_numResonators);
//            // use reciprocal square root
//            vvrsqrtf(m_rsqrt.data(), m_sm.data(), &count);
//            // normalize
//            vDSP_zrvmul(&W, 1, m_rsqrt.data(), 1, &W, 1, m_numResonators);
        }
            break;
    }
    
    // phasor
    DSPSplitComplex Z = {m_z.data(), m_z.data() + m_numResonators};
    vDSP_zvmul(&Z, 1,
               &W, 1,
               &Z, 1,
               m_numResonators,
               1);
}

void TrackingResonatorBankVec::update(const std::vector<float> &samples) {
    for (float sample : samples) {
        update(sample);
    }
    stabilize(); // this is overkill but necessary
}

/// Process a frame of samples.
/// Apply stabilization (norm correction) at the end
/// Compute amplitudes (phasor magnitudes) at the end
void TrackingResonatorBankVec::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    const size_t sampleSpan = frameSampleSpan(frameLength, sampleStride);
    for (size_t sampleIndex = 0; sampleIndex < sampleSpan; sampleIndex += sampleStride) {
        update(frameData[sampleIndex]);
    }
    stabilize(); // this is overkill but necessary
}

/// Process a frame of samples.
/// Apply stabilization (norm correction) at the end
/// Compute amplitudes (phasor magnitudes) at the end
void TrackingResonatorBankVec::update(const float *frameData, size_t frameLength, size_t sampleStride, float* powers, float* amplitudes) {
    const size_t sampleSpan = frameSampleSpan(frameLength, sampleStride);
    for (size_t sampleIndex = 0; sampleIndex < sampleSpan; sampleIndex += sampleStride) {
        update(frameData[sampleIndex]);
    }
    stabilize(); // this is overkill but necessary
}

/// Apply norm correction to phasor.
/// This can be done every few hundreds (?) of iterations
void TrackingResonatorBankVec::stabilize() {
    DSPSplitComplex Z = {m_z.data(), m_z.data() + m_numResonators};
    vDSP_zvmags(&Z, 1, m_sm.data(), 1, m_numResonators);
    // use reciprocal square root
    int count = static_cast<int>(m_numResonators);
    vvrsqrtf(m_rsqrt.data(), m_sm.data(), &count);
    vDSP_zrvmul(&Z, 1, m_rsqrt.data(), 1, &Z, 1, m_numResonators);
}


void TrackingResonatorBankVec::setTimeConstant(float tau, float sampleRate) {
    float frameDuration =  1.0f / sampleRate;
    m_sigma = 1.0f - exp(-frameDuration / tau);
    m_omSigma = 1.0f - m_sigma;
}

void TrackingResonatorBankVec::setPowerThresholdDB(float thresholdDB) {
    m_trackingPowerThresholdRatio = pow(10.0, thresholdDB / 10.0);
}

// This optimization saves a few 10s of ns per sample...
void TrackingResonatorBankVec::thresholdAndMerge(const float* powers,
                                                 float* trackedOmegas,
                                                 const float* naturalOmegas,
                                                 size_t count,
                                                 float threshold) {
    // Create a vector where all 4 lanes contain the threshold
    float32x4_t thresholdVec = vdupq_n_f32(threshold);
    float32x4_t vOne = vdupq_n_f32(1.0f);
    float32x4_t vZero = vdupq_n_f32(0.0f);
    
    int i = 0;
    // Process 4 floats at a time (128-bit NEON registers)
    for (; i <= count - 4; i += 4) {
        // 1. Load data into registers
        float32x4_t p = vld1q_f32(powers + i);
        float32x4_t t_vec = vld1q_f32(trackedOmegas + i);
        float32x4_t n = vld1q_f32(naturalOmegas + i);
        
        // 2. Compare: returns a bitmask (all 1s if true, all 0s if false)
        // vcgeq = Vector Compare Greater than or Equal
        uint32x4_t cmpMask = vcgeq_f32(p, thresholdVec);
        
        // 3. Bitwise Select: choose from d_vec if mask is 1, else choose from n
        // vbslq_f32(mask, if_true, if_false)
        float32x4_t mergedResult = vbslq_f32(cmpMask, t_vec, n);
        
        // 4. Store result back into trackedOmegas
        vst1q_f32(trackedOmegas + i, mergedResult);
    }
    
    // Scalar tail for remaining elements
    for (; i < count; ++i) {
        bool isAbove = (powers[i] >= threshold);
        trackedOmegas[i] = isAbove ? trackedOmegas[i] : naturalOmegas[i];
    }
}

// This optimization saves a few 10s of ns per sample...
void TrackingResonatorBankVec::thresholdAndMerge(const float* powers,
                                                 const DSPSplitComplex* D,
                                                 const DSPSplitComplex* nW,
                                                 DSPSplitComplex* W,
                                                 size_t count,
                                                 float threshold) {
    // Create a vector where all 4 lanes contain the threshold
    float32x4_t thresholdVec = vdupq_n_f32(threshold);
    float32x4_t vOne = vdupq_n_f32(1.0f);
    float32x4_t vZero = vdupq_n_f32(0.0f);
    
    int i = 0;
    // Process 4 floats at a time (128-bit NEON registers)
    for (; i <= count - 4; i += 4) {
        // 1. Load data into registers
        float32x4_t p = vld1q_f32(powers + i);
        float32x4_t dr = vld1q_f32(D->realp + i);
        float32x4_t di = vld1q_f32(D->imagp + i);
        float32x4_t nr = vld1q_f32(nW->realp + i);
        float32x4_t ni = vld1q_f32(nW->imagp + i);
        float32x4_t wr = vld1q_f32(W->realp + i);
        float32x4_t wi = vld1q_f32(W->imagp + i);
        
        // 2. Compare: returns a bitmask (all 1s if true, all 0s if false)
        // vcgeq = Vector Compare Greater than or Equal
        uint32x4_t cmpMask = vcgeq_f32(p, thresholdVec);
        
        // 3. Bitwise Select: choose from d_vec if mask is 1, else choose from n
        // vbslq_f32(mask, if_true, if_false)
        float32x4_t rr = vbslq_f32(cmpMask, dr, nr);
        float32x4_t ri = vbslq_f32(cmpMask, di, ni);

        // 4. Store result back into W
        vst1q_f32(W->realp + i, rr);
        vst1q_f32(W->imagp + i, ri);
    }
    
    // Scalar tail for remaining elements
    for (; i < count; ++i) {
        bool isAbove = (powers[i] >= threshold);
        D->realp[i] = isAbove ? D->realp[i] : nW->realp[i];
        D->imagp[i] = isAbove ? D->imagp[i] : nW->imagp[i];
    }
}

// This optimization saves a few 10s of ns per sample...
void TrackingResonatorBankVec::thresholdAndMerge(const float* powers,
                                                 float* trackedOmegas,
                                                 const float* naturalOmegas,
                                                 float* mask,
                                                 size_t count,
                                                 float threshold) {
    // Create a vector where all 4 lanes contain the threshold
    float32x4_t thresholdVec = vdupq_n_f32(threshold);
    float32x4_t vOne = vdupq_n_f32(1.0f);
    float32x4_t vZero = vdupq_n_f32(0.0f);
    
    int i = 0;
    // Process 4 floats at a time (128-bit NEON registers)
    for (; i <= count - 4; i += 4) {
        // 1. Load data into registers
        float32x4_t p = vld1q_f32(powers + i);
        float32x4_t t_vec = vld1q_f32(trackedOmegas + i);
        float32x4_t n = vld1q_f32(naturalOmegas + i);
        
        // 2. Compare: returns a bitmask (all 1s if true, all 0s if false)
        // vcgeq = Vector Compare Greater than or Equal
        uint32x4_t cmpMask = vcgeq_f32(p, thresholdVec);
        
        // 3. Bitwise Select: choose from d_vec if mask is 1, else choose from n
        // vbslq_f32(mask, if_true, if_false)
        float32x4_t mergedResult = vbslq_f32(cmpMask, t_vec, n);
        
        // 4. Store result back into trackedOmegas
        vst1q_f32(trackedOmegas + i, mergedResult);
        
        // 5. Convert mask to float (1.0 for true, 0.0 for false)
        // vbslq selects bits from vOne where cmpMask bits are 1, and vZero where 0
        float32x4_t floatMask = vbslq_f32(cmpMask, vOne, vZero);
        vst1q_f32(mask + i, floatMask);
    }
    
    // Scalar tail for remaining elements
    for (; i < count; ++i) {
        bool isAbove = (powers[i] >= threshold);
        trackedOmegas[i] = isAbove ? trackedOmegas[i] : naturalOmegas[i];
        mask[i] = isAbove ? 1.0f : 0.0f;
    }
}

// This optimization saves a few 10s of ns per sample...
void TrackingResonatorBankVec::thresholdAndMerge(const float* powers,
                                                 const DSPSplitComplex* D,
                                                 const DSPSplitComplex* nW,
                                                 DSPSplitComplex* W,
                                                 float* mask,
                                                 size_t count,
                                                 float threshold) {
    // Create a vector where all 4 lanes contain the threshold
    float32x4_t thresholdVec = vdupq_n_f32(threshold);
    float32x4_t vOne = vdupq_n_f32(1.0f);
    float32x4_t vZero = vdupq_n_f32(0.0f);
    
    int i = 0;
    // Process 4 floats at a time (128-bit NEON registers)
    for (; i <= count - 4; i += 4) {
        // 1. Load data into registers
        float32x4_t p = vld1q_f32(powers + i);
        float32x4_t dr = vld1q_f32(D->realp + i);
        float32x4_t di = vld1q_f32(D->imagp + i);
        float32x4_t nr = vld1q_f32(nW->realp + i);
        float32x4_t ni = vld1q_f32(nW->imagp + i);
        float32x4_t wr = vld1q_f32(W->realp + i);
        float32x4_t wi = vld1q_f32(W->imagp + i);
        
        // 2. Compare: returns a bitmask (all 1s if true, all 0s if false)
        // vcgeq = Vector Compare Greater than or Equal
        uint32x4_t cmpMask = vcgeq_f32(p, thresholdVec);
        
        // 3. Bitwise Select: choose from d_vec if mask is 1, else choose from n
        // vbslq_f32(mask, if_true, if_false)
        float32x4_t rr = vbslq_f32(cmpMask, dr, nr);
        float32x4_t ri = vbslq_f32(cmpMask, di, ni);

        // 4. Store result back into W
        vst1q_f32(W->realp + i, rr);
        vst1q_f32(W->imagp + i, ri);
        
        // 5. Convert mask to float (1.0 for true, 0.0 for false)
        // vbslq selects bits from vOne where cmpMask bits are 1, and vZero where 0
        float32x4_t floatMask = vbslq_f32(cmpMask, vOne, vZero);
        vst1q_f32(mask + i, floatMask);
    }
    
    // Scalar tail for remaining elements
    for (; i < count; ++i) {
        bool isAbove = (powers[i] >= threshold);
        D->realp[i] = isAbove ? D->realp[i] : nW->realp[i];
        D->imagp[i] = isAbove ? D->imagp[i] : nW->imagp[i];
        mask[i] = isAbove ? 1.0f : 0.0f;
    }
}
