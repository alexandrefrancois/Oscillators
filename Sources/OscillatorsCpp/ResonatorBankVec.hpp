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

#ifndef ResonatorBankVec_hpp
#define ResonatorBankVec_hpp

#include <vector>

namespace oscillators_cpp {

class ResonatorBankVec {
private:
    float m_sampleRate;
    size_t m_numResonators;
    
    std::vector<float> m_frequencies;
    std::vector<float> m_alphas;
    std::vector<float> m_omAlphas;
    std::vector<float> m_betas;
    std::vector<float> m_omBetas;
    
    size_t m_twoNumResonators;

    /// Accumulated resonance values, non-interlaced real (cos) | imaginary (sin) parts
    std::vector<float> m_r;
    /// Smoothed accumulated resonance values, non-interlaced real (cos) | imaginary (sin) parts
    std::vector<float> m_rr;
    
    /// Phasors
    std::vector<float> m_z;
    /// Phasor multipliers
    std::vector<float> m_w;
    
    /// hold sample value * alphas
    std::vector<float> m_alphasSample;

    /// Squared magnitudes buffer (ntermediate calculations)
    std::vector<float> m_sm;
    /// Reverse square root buffer (intermediate calculations)
    std::vector<float> m_rsqrt;

    
public:
    ResonatorBankVec & operator=(const ResonatorBankVec&) = delete;
    ResonatorBankVec(const ResonatorBankVec&) = delete;

    ResonatorBankVec(size_t numResonators, const std::vector<float> &frequencies, const std::vector<float> &alphas, const std::vector<float> &betas, float sampleRate);
    ResonatorBankVec(size_t numResonators, const float* frequencies, const float* alphas, const float* betas, float sampleRate);

    float sampleRate() { return m_sampleRate; }
    size_t numResonators() { return m_numResonators; }
    float frequencyValue(size_t index);
    float alphaValue(size_t index);
    void setAllAlphas(float alpha);
    float betaValue(size_t index);

    void getPowers(float *dest, size_t size);
    void getAmplitudes(float *dest, size_t size);

    void update(const float sample);
    void update(const std::vector<float> &samples);
    void update(const float *frameData, size_t frameLength, size_t sampleStride);
    void update(const float *frameData, size_t frameLength, size_t sampleStride, float* powers, float* amplitudes);

    void stabilize();
};

} // oscillators_cpp

#endif /* ResonatorBankVec_hpp */
