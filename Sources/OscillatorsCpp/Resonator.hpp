/**
MIT License

Copyright (c) 2022-2024 Alexandre R. J. Francois

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

#include "Oscillator.hpp"

namespace oscillators_cpp {

constexpr float trackFrequencyThreshold = 0.001;

class Resonator : public Oscillator {
private:
    float m_alpha;
    float m_omAlpha;
    
    float m_sin;
    float m_cos;
    std::vector<float> m_waveform2;

    float m_trackedFrequency;
    float m_phase;

public:
    Resonator(float frequency, float sampleRate, float alpha);

    float alpha() const { return m_alpha; }
    void setAlpha(float alpha);
    float omAlpha() const { return m_omAlpha; }
    float timeConstant() const { return 1.0 / (m_sampleRate * m_alpha); }
    float s() const { return m_sin; }
    float c() const { return m_cos; }
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
