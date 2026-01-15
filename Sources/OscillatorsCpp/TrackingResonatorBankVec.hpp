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

#ifndef TrackingResonatorBankVec_hpp
#define TrackingResonatorBankVec_hpp

#include <vector>

namespace oscillators_cpp {

class TrackingResonatorBankVec {
private:
    float m_sampleRate;
    size_t m_numResonators;

    // max power accumulation
    float m_sigma;
    float m_omSigma;
    std::atomic<float> m_accPower;
    
    std::vector<float> m_naturalFrequencies;
    std::vector<float> m_alphas;
    std::vector<float> m_omAlphas;
    std::vector<float> m_betas;
    std::vector<float> m_omBetas;
    std::vector<float> m_gammas;
    std::vector<float> m_omGammas;

    size_t m_twoNumResonators;

    /// Accumulated resonance values, non-interlaced real (cos) | imaginary (sin) parts
    std::vector<float> m_r;
    /// Smoothed accumulated resonance values, non-interlaced real (cos) | imaginary (sin) parts
    std::vector<float> m_rr;
    
    /// Previous Smoothed accumulated resonance values, non-interlaced real (cos) | imaginary (sin) parts
    std::vector<float> m_rrm;

    /// Phase derivative components:
    /// current multiplied by conjugate of previous, non-interlaced real (cos) | imaginary (sin) parts
    /// The delta phase is the arg of this complex number
    std::vector<float> m_d;

    /// Phasors
    std::vector<float> m_z;
    /// Phasor multipliers
    std::vector<float> m_w;
    
    /// hold sample value * alphas
    std::vector<float> m_alphasSample;

    std::vector<float> m_naturalOmegas;
    std::vector<float> m_powers;
    std::vector<float> m_mask;
    std::vector<float> m_inverseMask;

    /// Squared magnitudes buffer (ntermediate calculations)
    std::vector<float> m_sm;
    /// Reverse square root buffer (intermediate calculations)
    std::vector<float> m_rsqrt;

    
public:
    TrackingResonatorBankVec & operator=(const TrackingResonatorBankVec&) = delete;
    TrackingResonatorBankVec(const TrackingResonatorBankVec&) = delete;

    TrackingResonatorBankVec(size_t numResonators, const std::vector<float> &frequencies, const std::vector<float> &alphas, const std::vector<float> &betas, const std::vector<float> &gammas, float sampleRate);
    TrackingResonatorBankVec(size_t numResonators, const float* frequencies, const float* alphas, const float* betas, const float* gammas, float sampleRate);

    float sampleRate() { return m_sampleRate; }
    size_t numResonators() { return m_numResonators; }
    void getNaturalFrequencies(float *dest, size_t size);
    void getResonantFrequencies(float *dest, size_t size);

    void getPowers(float *dest, size_t size);
    void getAmplitudes(float *dest, size_t size);
    void getPhases(float *dest, size_t size);
    void getDeltaPhases(float *dest, size_t size);
    float accPower() const { return m_accPower; };

    void update(const float sample);
    void update(const std::vector<float> &samples);
    void update(const float *frameData, size_t frameLength, size_t sampleStride);
    void update(const float *frameData, size_t frameLength, size_t sampleStride, float* powers, float* amplitudes);

    void stabilize();

    void setTimeConstant(float tau, float sampleRate);
    
    static void fuseThresholdAndMerge(const float* powers,
                                      float* trackedOmegas,
                                      const float* naturalOmegas,
                                      float* mask,
                                      size_t count,
                                      float threshold);
};

} // oscillators_cpp

#endif /* TrackingResonatorBankVec_hpp */
