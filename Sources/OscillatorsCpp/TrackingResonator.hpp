/**
MIT License

Copyright (c) 2025-2026 Alexandre R. J. Francois

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

#ifndef TrackingResonator_hpp
#define TrackingResonator_hpp

#include "Phasor.hpp"

namespace oscillators_cpp {

class TrackingResonator : public Phasor {
private:
    float m_alpha;
    float m_omAlpha;
    float m_cos;
    float m_sin;
    // smoothed
    float m_beta;
    float m_omBeta;
    float m_cc;
    float m_ss;
    // multipled by conjugate, smoothed (delta-phase)
    float m_dpc;
    float m_dps;
    float m_gamma;
    float m_omGamma;

    float m_naturalFrequency;
    float m_trackFrequencyPowerThreshold;

public:
    TrackingResonator(float naturalFrequency, float alpha, float beta, float gamma, float sampleRate);    
    float naturalFrequency() const { return m_naturalFrequency; }
    void setNaturalFrequency(float frequency, float alpha, float beta, float gamma);
    float resonantFrequency() const { return frequency(); }
    float power() const { return m_cc * m_cc + m_ss * m_ss; }
    float amplitude() const { return sqrt(m_cc * m_cc + m_ss * m_ss); }
    float alpha() const { return m_alpha; }
    void setAlpha(float alpha);
    float omAlpha() const { return m_omAlpha; }
    float beta() const { return m_beta; }
    void setBeta(float beta);
    float omBeta() const { return m_omBeta; }
    float gamma() const { return m_gamma; }
    void setGamma(float gamma);
    float omGamma() const { return m_omGamma; }
    float c() const { return m_cos; }
    float s() const { return m_sin; }
    float cc() const { return m_cc; }
    float ss() const { return m_ss; }
    float dpc() const { return m_dpc; }
    float dps() const { return m_dps; }
    float phase() const;
    float phaseX() const { return m_cc / sqrt(m_cc * m_cc + m_ss * m_ss); }
    float phaseY() const { return m_ss / sqrt(m_cc * m_cc + m_ss * m_ss); }
    float deltaPhase() const;
    float deltaPhaseX() const { return m_dpc / sqrt(m_dpc * m_dpc + m_dps * m_dps); }
    float deltaPhaseY() const { return m_dps / sqrt(m_dpc * m_dpc + m_dps * m_dps); }
    void updateWithSample(float sample);
    void update(float sample, float maxPower);
    void update(const std::vector<float> &samples, float maxPower);
    void update(const float *frameData, size_t frameLength, size_t sampleStride, float maxPower);
};

} // oscillators_cpp

#endif /* TrackingResonator_hpp */
