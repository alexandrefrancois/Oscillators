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

#include "ResonatorBase.hpp"
#include "TrackingRule.hpp"

namespace oscillators_cpp {

class TrackingResonator : public ResonatorBase {
private:
    static constexpr float minimumResidualMagnitudeSquared = 1e-20f;

    float m_naturalWc;
    float m_naturalWs;
    float m_trackingPowerThresholdRatio;
    float m_trackingPowerThreshold;
    TrackingRule m_trackingRule;

    void setNaturalW(float c, float s);
    void restoreNaturalW();
    
    void updateTracking(); // virtual function override
    
    void applyEWMATracking();
    void applyChordCorrectionTracking();
    void applyTangentCorrectionTracking();
    
public:
    TrackingResonator(float naturalFrequency, float sampleRate, float alpha, float beta, float gamma, TrackingRule trackingRule, float thresholdDB);
    
    float naturalFrequency() const { return -m_sampleRate * atan2(m_naturalWs, m_naturalWc) / twoPi; }
    void setNaturalFrequency(float frequency, float alpha, float beta, float gamma);
    float resonantFrequency() const { return frequency(); }
    void setPowerThresholdDB(float thresholdDB);

    void updateWithSample(float sample); // virtual function override
    void update(float sample, float maxPower);
    void update(const std::vector<float> &samples, float maxPower);
    void update(const float *frameData, size_t frameLength, size_t sampleStride, float maxPower);
};

} // oscillators_cpp

#endif /* TrackingResonator_hpp */
