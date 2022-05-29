/**
MIT License

Copyright (c) 2022 Alexandre R. J. Francois

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

#ifndef Oscillator_hpp
#define Oscillator_hpp

#include <vector>

namespace oscillators_cpp {

constexpr float PI = 3.14159274101257324219; // PI
constexpr float twoPi = 2.0 * PI;
constexpr float halfPi = PI / 2.0;

constexpr float trackFrequencyThreshold = 0.001;

class Oscillator {
protected:
    float m_frequency;    
    float m_sampleDuration;
    float m_amplitude;
    std::vector<float> m_waveform;
    size_t m_phaseIdx;
    
public:
    Oscillator & operator=(const Oscillator&) = delete;
    Oscillator(const Oscillator&) = delete;
    virtual ~Oscillator() = default;
    
    Oscillator(float targetFrequency, float sampleDuration);
        
    float frequency() const { return m_frequency; }
    float sampleDuration() const { return m_sampleDuration; }
    float amplitude() const { return m_amplitude; }
    size_t numSamplesInPeriod() const { return m_waveform.size(); }
    
    void setSineWave();
    
    void copyWaveform(float *dest, size_t size);
    float waveformValue(size_t index) const;
};

} // oscillators_cpp

#endif /* Oscillator_hpp */

