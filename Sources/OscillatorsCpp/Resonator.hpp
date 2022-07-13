#ifndef Resonator_hpp
#define Resonator_hpp

#include "Oscillator.hpp"

namespace oscillators_cpp {

class Resonator : public Oscillator {
private:
    float m_alpha;
    float m_omAlpha;
    std::vector<float> m_allPhases;
    std::vector<float> m_leftTerm;
    std::vector<float> m_rightTerm;
    
public:
    Resonator(float targetFrequency, float sampleDuration, float alpha);
    
    float alpha() { return m_alpha; }

    void updateAllPhases(float sample);
    void update(const float sample);
    void update(const std::vector<float> &samples);
    void update(const float *frameData, size_t frameLength, size_t sampleStride);

    void copyAllPhases(float *dest, size_t size);
    float allPhasesValue(size_t index);
};

} // oscillators_cpp

#endif /* Resonator_hpp */
