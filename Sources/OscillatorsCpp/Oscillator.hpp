#ifndef Oscillator_hpp
#define Oscillator_hpp

#include <vector>

namespace oscillators_cpp {

const float PI = 3.14159274101257324219; // PI
const float twoPi = 2.0 * PI;
const float halfPi = PI / 2.0;

class Oscillator {
private:
    float m_frequency;
    float m_sampleDuration;
    
protected:
    float m_amplitude;
    std::vector<float> m_waveform;
    size_t m_phaseIdx;
    
public:
    Oscillator(float targetFrequency, float sampleDuration);
    
    float frequency() { return m_frequency; }
    float sampleDuration() { return m_sampleDuration; }
    float amplitude() { return m_amplitude; }
    size_t numSamplesInPeriod() { return m_waveform.size(); }
    
    void setSineWave();
    
    void copyWaveform(float *dest, size_t size);
    float waveformValue(size_t index);
};

} // oscillators_cpp

#endif /* Oscillator_hpp */

