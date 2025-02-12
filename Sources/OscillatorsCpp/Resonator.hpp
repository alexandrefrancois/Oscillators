/**
MIT License

Copyright (c) 2022-2025 Alexandre R. J. Francois

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

#ifndef Resonator_hpp
#define Resonator_hpp

#include "Phasor.hpp"

namespace oscillators_cpp {

constexpr float trackFrequencyThreshold = 0.001;

class Resonator : public Phasor {
private:
    float m_alpha;
    float m_omAlpha;
    
    float m_beta;
    float m_omBeta;
    
    float m_cos;
    float m_sin;
    // smoothed
    float m_cc;
    float m_ss;
    
    float m_trackedFrequency;
    float m_phase;
    
public:
    Resonator(float frequency, float alpha, float sampleRate);
    
    float power() const { return m_cc * m_cc + m_ss * m_ss; }
    float amplitude() const { return sqrt(m_cc * m_cc + m_ss * m_ss); }
    float alpha() const { return m_alpha; }
    void setAlpha(float alpha);
    float omAlpha() const { return m_omAlpha; }
    float timeConstant() const { return 1.0 / (m_sampleRate * m_alpha); }
    float beta() const { return m_beta; }
    float c() const { return m_cos; }
    float s() const { return m_sin; }
    float cc() const { return m_cc; }
    float ss() const { return m_ss; }
    float phase() const { return m_phase; }
    float trackedFrequency() const { return m_trackedFrequency; }

    void updateWithSample(float sample);
    void update(const float sample);
    void update(const std::vector<float> &samples);
    void update(const float *frameData, size_t frameLength, size_t sampleStride);
    void updateAndTrack(const float *frameData, size_t frameLength, size_t sampleStride);

private:
    void updateTrackedFrequency(size_t numSamples);
};

} // oscillators_cpp

#endif /* Resonator_hpp */
