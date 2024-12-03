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

#ifndef ResonatorBankVecCpp_hpp
#define ResonatorBankVecCpp_hpp

#include <vector>

namespace oscillators_cpp {

class ResonatorBankVec {
private:
    float m_sampleRate;
    size_t m_numResonators;
    float* m_frequencies;
    float* m_amplitudes;
    float* m_alphas;
    float* m_omAlphas;
    float m_beta;
    float m_omBeta;
    
    size_t m_twoNumResonators;

    /// Accumulated resonance values, non-interlaced real (cos) | imaginary (sin) parts
    float* m_rPtr;
    /// Smoothed accumulated resonance values, non-interlaced real (cos) | imaginary (sin) parts
    float* m_rrPtr;
    
    /// Phasors
    float* m_zPtr;
    /// Phasor multipliers
    float* m_wPtr;
    
    /// Squared magnitudes buffer (ntermediate calculations)
    float* m_smPtr;
    /// Reverse square root buffer (intermediate calculations)
    float* m_rsqrtPtr;

    
public:
    ResonatorBankVec & operator=(const ResonatorBankVec&) = delete;
    ResonatorBankVec(const ResonatorBankVec&) = delete;

    ResonatorBankVec(size_t numResonators, float* frequencies, float sampleRate, float* alphas);
    ~ResonatorBankVec();

    float sampleRate() { return m_sampleRate; }
    size_t numResonators() { return m_numResonators; }
    float frequencyValue(size_t index);
    float alphaValue(size_t index);
    void setAllAlphas(float alpha);
    float timeConstantValue(size_t index);

    void copyAmplitudes(float *dest, size_t size);
    float amplitudeValue(size_t index);

    void update(const float sample);
    void update(const std::vector<float> &samples);
    void update(const float *frameData, size_t frameLength, size_t sampleStride);
    void update(const float *frameData, size_t frameLength, size_t sampleStride, float* amplitudes);

    void stabilize();
};

} // oscillators_cpp

#endif /* ResonatorBankVecCpp_hpp */
